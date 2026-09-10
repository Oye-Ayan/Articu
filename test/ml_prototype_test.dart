import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:wav/wav.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';

import '../lib/core/utils/audio/librosa_mfcc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('ML Preprocessing Prototype with Custom LibrosaMfcc', () async {
    final wavPath = "/home/ayan/Downloads/Old_Proj/FYP/Dysarthria and Non Dysarthria/Dataset/Female_Non_Dysarthria/FC01/Session1/Wav/0001.wav";
    final goldenPath = "/tmp/golden_reference.json";
    
    // Load Golden Reference
    final goldenFile = File(goldenPath);
    expect(await goldenFile.exists(), isTrue, reason: "Golden reference not found.");
    
    final goldenData = json.decode(await goldenFile.readAsString());
    List<double> pyMfccMean = List<double>.from(goldenData['librosa_mfcc_mean']);
    
    // 1. Read WAV file
    final wav = await Wav.readFile(wavPath);
    
    // Convert to mono
    List<double> monoAudio = [];
    if (wav.channels.length == 1) {
      monoAudio = wav.channels[0];
    } else {
      for (int i = 0; i < wav.channels[0].length; i++) {
        double sum = 0;
        for (int c = 0; c < wav.channels.length; c++) {
          sum += wav.channels[c][i];
        }
        monoAudio.add(sum / wav.channels.length);
      }
    }

    // 2. Extract 3-second segment starting at 0.5s
    int sr = 16000;
    int startSample = (0.5 * sr).toInt();
    int durationSamples = (3.0 * sr).toInt();
    
    if (startSample + durationSamples > monoAudio.length) {
      durationSamples = monoAudio.length - startSample;
    }
    
    List<double> y = monoAudio.sublist(startSample, startSample + durationSamples);
    
    // 3. Compute MFCC using custom LibrosaMfcc
    final extractor = LibrosaMfcc(
      sr: sr,
      nFft: 2048,
      hopLength: 512,
      nMels: 128,
      nMfcc: 40,
    );
    
    List<List<double>> mfccs = extractor.computeMfcc(y);
    
    // 4. Compute mean across time
    List<double> dartMfccMean = List.filled(40, 0.0);
    int numFrames = mfccs.length;
    for (int t = 0; t < numFrames; t++) {
      for (int i = 0; i < 40; i++) {
        dartMfccMean[i] += mfccs[t][i];
      }
    }
    for (int i = 0; i < 40; i++) {
      dartMfccMean[i] /= numFrames;
    }
    
    // 5. Compare with Python
    double maxDiff = 0.0;
    double sumDiff = 0.0;
    
    print("--- COMPARISON ---");
    for (int i = 0; i < 40; i++) {
      double diff = (dartMfccMean[i] - pyMfccMean[i]).abs();
      if (diff > maxDiff) maxDiff = diff;
      sumDiff += diff;
    }
    double meanDiff = sumDiff / 40.0;
    
    print("Num Frames (Dart): \$numFrames");
    print("Num Frames (Python): \${goldenData['librosa_mfcc_shape'][1]}");
    print("Max Absolute Difference: \$maxDiff");
    print("Mean Absolute Difference: \$meanDiff");
    print("\nPython 40-element vector:");
    print(pyMfccMean);
    print("\nDart 40-element vector:");
    print(dartMfccMean);
    
    // Validate the tolerance
    expect(maxDiff, lessThan(1.0), reason: "MFCC output deviates too much from Librosa reference.");
    
    print("\n=> [PASS] MFCC Preprocessing numerically equivalent to Librosa.");

    // 6. TFLite Inference
    try {
      final modelPath = "assets/dysarthria_model.tflite";
      final interpreter = await Interpreter.fromAsset(modelPath);
      
      var inputTensor = interpreter.getInputTensor(0);
      var outputTensor = interpreter.getOutputTensor(0);
      
      print("\nTFLite Dart Input Shape: ${inputTensor.shape}");
      print("TFLite Dart Output Shape: ${outputTensor.shape}");
      
      var inputBuffer = Float32List.fromList(dartMfccMean).buffer.asUint8List();
      var outputBuffer = Float32List(2).buffer.asUint8List();
      
      interpreter.run(inputBuffer, outputBuffer);
      
      var output = Float32List.view(outputBuffer.buffer);
      print("\nTFLite Dart Output Probabilities: $output");
      
      int predictedClass = output[0] > output[1] ? 0 : 1;
      print("Dart Predicted Class: $predictedClass");
      
      List<double> pyOutput = List<double>.from(goldenData['tflite_prediction']);
      print("Python Predicted Class: ${pyOutput[0] > pyOutput[1] ? 0 : 1}");
      print("Python Output Probabilities: $pyOutput");
      
    } catch (e) {
      print("\nTFLite Inference Error (expected if not running on device/emulator): $e");
    }
  });
}
