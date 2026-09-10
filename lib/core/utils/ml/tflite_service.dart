import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteService {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _interpreter = await Interpreter.fromAsset('assets/dysarthria_model.tflite');
      _isInitialized = true;
    } catch (e) {
      print('Failed to load TFLite model: $e');
      rethrow;
    }
  }

  /// Takes a 40-element MFCC mean vector and returns the predicted class.
  /// 0 = Non-Dysarthria, 1 = Dysarthria
  Future<int> predict(List<double> mfccMean) async {
    if (!_isInitialized || _interpreter == null) {
      await initialize();
    }

    // Input shape: [1, 40]
    var inputBuffer = Float32List.fromList(mfccMean).buffer.asUint8List();
    
    // Output shape: [1, 2]
    var outputBuffer = Float32List(2).buffer.asUint8List();

    _interpreter!.run(inputBuffer, outputBuffer);

    var output = Float32List.view(outputBuffer.buffer);
    
    // Softmax probabilities
    double nonDysarthriaProb = output[0];
    double dysarthriaProb = output[1];

    print("Inference Probabilities -> Non-Dysarthria: $nonDysarthriaProb, Dysarthria: $dysarthriaProb");

    return nonDysarthriaProb > dysarthriaProb ? 0 : 1;
  }
}
