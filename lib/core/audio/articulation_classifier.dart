import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'pcm_audio_normalizer.dart';

/// Clinical Prediction Result Data Model for Speech Sound Disorder Screening.
class ArticulationResult {
  /// Probability that speech articulation is clinically typical [0.0, 1.0].
  final double typicalProbability;

  /// Probability of a speech sound disorder (distortion, substitution, omission) [0.0, 1.0].
  final double disorderProbability;

  /// Binary classification indicator based on standard 0.5 decision threshold.
  final bool hasDisorder;

  /// Confidence margin: |disorderProbability - typicalProbability|.
  final double confidence;

  const ArticulationResult({
    required this.typicalProbability,
    required this.disorderProbability,
    required this.hasDisorder,
    required this.confidence,
  });

  @override
  String toString() =>
      'ArticulationResult(Disorder: ${(disorderProbability * 100).toStringAsFixed(1)}%, '
      'Typical: ${(typicalProbability * 100).toStringAsFixed(1)}%, '
      'Confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
}

/// Lifecycle states of the classifier
enum _ClassifierState { uninitialized, initializing, ready, disposed }

/// Messages sent between the main isolate and the background worker isolate
class _InitMessage {
  final SendPort replyPort;
  final Uint8List modelBytes;
  _InitMessage(this.replyPort, this.modelBytes);
}

class _InferenceRequest {
  final int id;
  final TransferableTypedData data;
  _InferenceRequest(this.id, this.data);
}

class _InferenceResponse {
  final int id;
  final double typicalProb;
  final double disorderProb;
  final String? errorMessage;

  _InferenceResponse.success(this.id, this.typicalProb, this.disorderProb)
      : errorMessage = null;

  _InferenceResponse.error(this.id, this.errorMessage)
      : typicalProb = 0.0,
        disorderProb = 0.0;
}

class _TeardownRequest {}

/// Production Engine for On-Device Articulation Screening.
///
/// Runs TFLite inference inside a persistent background isolate using pre-allocated
/// native C++ tensors and zero-copy TransferableTypedData transfers.
class ArticulationClassifier {
  static const String defaultAssetPath = 'assets/models/articuli_care_v2.tflite';
  static const int expectedSampleCount = PcmAudioNormalizer.defaultTargetSamples; // 48,000

  _ClassifierState _state = _ClassifierState.uninitialized;
  Isolate? _workerIsolate;
  SendPort? _workerSendPort;
  ReceivePort? _mainReceivePort;
  StreamSubscription? _portSubscription;

  int _nextRequestId = 0;
  final Map<int, Completer<ArticulationResult>> _pendingRequests = {};

  bool get isReady => _state == _ClassifierState.ready;

  /// Initializes the classifier and spawns the persistent background worker isolate.
  ///
  /// Supports headless test environments by allowing an explicit [modelPath] or [modelBytes].
  Future<void> initialize({
    String? modelPath,
    Uint8List? modelBytes,
  }) async {
    if (_state == _ClassifierState.ready) return;
    if (_state == _ClassifierState.initializing) {
      throw StateError('ArticulationClassifier is already initializing.');
    }
    if (_state == _ClassifierState.disposed) {
      throw StateError('Cannot initialize a disposed ArticulationClassifier.');
    }

    _state = _ClassifierState.initializing;

    try {
      // 1. Resolve model bytes decoupling from Flutter Engine inside the isolate
      final Uint8List bytes = await _resolveModelBytes(
        modelPath: modelPath,
        modelBytes: modelBytes,
      );

      // 2. Set up communication ports
      _mainReceivePort = ReceivePort();
      final Completer<SendPort> handshakeCompleter = Completer<SendPort>();

      _portSubscription = _mainReceivePort!.listen((message) {
        if (message is SendPort) {
          if (!handshakeCompleter.isCompleted) {
            handshakeCompleter.complete(message);
          }
        } else if (message is _InferenceResponse) {
          final completer = _pendingRequests.remove(message.id);
          if (completer != null && !completer.isCompleted) {
            if (message.errorMessage != null) {
              completer.completeError(Exception(message.errorMessage));
            } else {
              final typical = message.typicalProb;
              final disorder = message.disorderProb;
              completer.complete(
                ArticulationResult(
                  typicalProbability: typical,
                  disorderProbability: disorder,
                  hasDisorder: disorder >= 0.5,
                  confidence: (disorder - typical).abs(),
                ),
              );
            }
          }
        }
      });

      // 3. Spawn persistent background worker isolate
      _workerIsolate = await Isolate.spawn(
        _workerEntryPoint,
        _InitMessage(_mainReceivePort!.sendPort, bytes),
        debugName: 'ArticulationClassifierWorker',
      );

      _workerSendPort = await handshakeCompleter.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Isolate handshake timed out.'),
      );

      _state = _ClassifierState.ready;
      debugPrint('[ML Engine] Persistent Articulation Worker Isolate Ready.');
    } catch (e) {
      _state = _ClassifierState.uninitialized;
      await dispose();
      rethrow;
    }
  }

  /// Evaluates an exact 48,000-sample normalized Float32List [-1.0, 1.0].
  Future<ArticulationResult> classifySamples(Float32List samples) async {
    if (_state != _ClassifierState.ready || _workerSendPort == null) {
      throw StateError('ArticulationClassifier is not initialized. Call initialize() first.');
    }

    final Float32List standardized = PcmAudioNormalizer.applyDeterministicWindow(samples);

    final int requestId = _nextRequestId++;
    final Completer<ArticulationResult> completer = Completer<ArticulationResult>();
    _pendingRequests[requestId] = completer;

    // Zero-copy transfer across isolate boundary via TransferableTypedData
    final transferable = TransferableTypedData.fromList([
      standardized.buffer.asUint8List(),
    ]);

    _workerSendPort!.send(_InferenceRequest(requestId, transferable));

    // 3-second safety timeout to prevent indefinite UI hangs
    return completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        _pendingRequests.remove(requestId);
        throw TimeoutException('Inference request $requestId timed out after 3 seconds.');
      },
    );
  }

  /// Classifies audio directly from a recorded WAV or raw PCM file path.
  Future<ArticulationResult> classifyAudioFile(String wavFilePath) async {
    final file = File(wavFilePath);
    if (!await file.exists()) {
      throw FileSystemException('Audio recording file does not exist', wavFilePath);
    }

    final Uint8List rawBytes = await file.readAsBytes();
    final Float32List normalized = PcmAudioNormalizer.wavToFloat32(rawBytes);
    return classifySamples(normalized);
  }

  /// Shuts down the background isolate, closes native C++ pointers, and frees ports.
  Future<void> dispose() async {
    if (_state == _ClassifierState.disposed) return;
    _state = _ClassifierState.disposed;

    // Fail any pending requests
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('ArticulationClassifier disposed during inference.'));
      }
    }
    _pendingRequests.clear();

    // Signal worker isolate to tear down native interpreter
    if (_workerSendPort != null) {
      try {
        _workerSendPort!.send(_TeardownRequest());
      } catch (_) {}
    }

    await _portSubscription?.cancel();
    _mainReceivePort?.close();
    _workerIsolate?.kill(priority: Isolate.immediate);

    _workerIsolate = null;
    _workerSendPort = null;
    _mainReceivePort = null;
    _portSubscription = null;
  }

  /// Headless-safe model bytes resolution.
  static Future<Uint8List> _resolveModelBytes({
    String? modelPath,
    Uint8List? modelBytes,
  }) async {
    if (modelBytes != null && modelBytes.isNotEmpty) {
      return modelBytes;
    }

    if (modelPath != null && File(modelPath).existsSync()) {
      return File(modelPath).readAsBytes();
    }

    // Check direct filesystem fallback (headless testing)
    final localFile = File(defaultAssetPath);
    if (localFile.existsSync()) {
      return localFile.readAsBytes();
    }

    // Flutter asset bundle fallback (live mobile app runtime)
    try {
      final byteData = await rootBundle.load(defaultAssetPath);
      return byteData.buffer.asUint8List();
    } catch (e) {
      throw StateError(
        'Could not load TFLite model from asset bundle or local filesystem ($defaultAssetPath): $e',
      );
    }
  }

  /// Background Isolate Worker Entrypoint.
  static void _workerEntryPoint(_InitMessage initMessage) {
    final ReceivePort workerReceivePort = ReceivePort();

    Interpreter? interpreter;
    // Pre-allocated native buffer structures
    final List<Float32List> inputBuffer = [Float32List(expectedSampleCount)];
    final List<List<double>> outputBuffer = List<List<double>>.generate(
      1,
      (_) => List<double>.filled(2, 0.0),
      growable: false,
    );

    try {
      final options = InterpreterOptions()..threads = 2; // Optimal thermal envelope
      interpreter = Interpreter.fromBuffer(initMessage.modelBytes, options: options);
      interpreter.allocateTensors();
      // Only complete handshake after interpreter is loaded and tensors allocated
      initMessage.replyPort.send(workerReceivePort.sendPort);
    } catch (e) {
      initMessage.replyPort.send(
        _InferenceResponse.error(-1, 'Failed to initialize interpreter in worker: $e'),
      );
      workerReceivePort.close();
      return;
    }

    workerReceivePort.listen((message) {
      if (message is _InferenceRequest) {
        try {
          // Materialize zero-copy transferable buffer
          final ByteBuffer byteBuffer = message.data.materialize().asUint8List().buffer;
          final Float32List floatSamples = byteBuffer.asFloat32List();

          // Copy into pre-allocated input buffer
          inputBuffer[0].setRange(0, expectedSampleCount, floatSamples);

          // Run inference using pre-allocated memory
          interpreter!.run(inputBuffer, outputBuffer);

          final double typicalProb = outputBuffer[0][0];
          final double disorderProb = outputBuffer[0][1];

          initMessage.replyPort.send(
            _InferenceResponse.success(message.id, typicalProb, disorderProb),
          );
        } catch (e) {
          initMessage.replyPort.send(
            _InferenceResponse.error(message.id, e.toString()),
          );
        }
      } else if (message is _TeardownRequest) {
        interpreter?.close();
        workerReceivePort.close();
        Isolate.current.kill(priority: Isolate.immediate);
      }
    });
  }
}
