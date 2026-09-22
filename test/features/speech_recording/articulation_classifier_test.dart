import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:articulicare/core/audio/articulation_classifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ArticulationClassifier classifier;
  const String modelPath = 'assets/models/articuli_care_v2.tflite';

  setUp(() async {
    classifier = ArticulationClassifier();
  });

  tearDown(() async {
    await classifier.dispose();
  });

  group('ArticulationClassifier - Isolate Engine & Execution Gates', () {
    test('successfully initializes persistent background isolate from local model file', () async {
      expect(File(modelPath).existsSync(), isTrue,
          reason: 'Compiled TFLite model must exist at $modelPath');

      expect(classifier.isReady, isFalse);
      await classifier.initialize(modelPath: modelPath);
      expect(classifier.isReady, isTrue);
    });

    test('evaluates synthetic audio and yields calibrated probabilities summing to 1.0', () async {
      await classifier.initialize(modelPath: modelPath);

      // Generate 48,000 synthetic audio samples with child-like formants (F0=300Hz, F1=1200Hz, F2=3200Hz)
      final Float32List testSamples = _generateSyntheticAudio(48000);

      final ArticulationResult result = await classifier.classifySamples(testSamples);

      expect(result.typicalProbability >= 0.0 && result.typicalProbability <= 1.0, isTrue);
      expect(result.disorderProbability >= 0.0 && result.disorderProbability <= 1.0, isTrue);
      expect(result.typicalProbability + result.disorderProbability, closeTo(1.0, 1e-4));
      expect(result.confidence, closeTo((result.disorderProbability - result.typicalProbability).abs(), 1e-5));
    });

    test('25-iteration stress test confirms stable execution and sub-30ms round-trip latency', () async {
      await classifier.initialize(modelPath: modelPath);
      final Float32List testSamples = _generateSyntheticAudio(48000);

      final Stopwatch stopwatch = Stopwatch();
      final List<double> latencies = [];

      // Warmup
      await classifier.classifySamples(testSamples);

      // 25 sequential stress-test iterations
      for (int i = 0; i < 25; i++) {
        stopwatch.reset();
        stopwatch.start();
        final ArticulationResult res = await classifier.classifySamples(testSamples);
        stopwatch.stop();

        latencies.add(stopwatch.elapsedMicroseconds / 1000.0);
        expect(res.typicalProbability + res.disorderProbability, closeTo(1.0, 1e-4));
      }

      final double avgLatency = latencies.reduce((a, b) => a + b) / latencies.length;
      final double maxLatency = latencies.reduce(max);

      // ignore: avoid_print
      print('\n[Phase 3 Benchmark] 25 Consecutive Isolate Inferences:');
      // ignore: avoid_print
      print('  -> Average Round-Trip Latency : ${avgLatency.toStringAsFixed(2)} ms');
      // ignore: avoid_print
      print('  -> Max Round-Trip Latency     : ${maxLatency.toStringAsFixed(2)} ms');
      // ignore: avoid_print
      print('  -> Latency Budget Threshold   : < 30.00 ms');

      expect(avgLatency < 30.0, isTrue,
          reason: 'Average round-trip latency ($avgLatency ms) must be under 30 ms budget');
    });

    test('cleanly tears down background isolate and rejects subsequent calls with StateError', () async {
      await classifier.initialize(modelPath: modelPath);
      expect(classifier.isReady, isTrue);

      await classifier.dispose();
      expect(classifier.isReady, isFalse);

      final Float32List testSamples = Float32List(48000);
      expect(
        () async => await classifier.classifySamples(testSamples),
        throwsA(isA<StateError>()),
      );
    });
  });
}

Float32List _generateSyntheticAudio(int sampleCount) {
  final Float32List samples = Float32List(sampleCount);
  for (int i = 0; i < sampleCount; i++) {
    final double t = i / 16000.0;
    samples[i] = (0.4 * sin(2 * pi * 300.0 * t) +
            0.3 * sin(2 * pi * 1200.0 * t) +
            0.2 * sin(2 * pi * 3200.0 * t))
        .clamp(-1.0, 1.0);
  }
  return samples;
}
