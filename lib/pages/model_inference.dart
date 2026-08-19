import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';

class ModelInference {
  late Interpreter _interpreter;

  // Load the TFLite model
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/dysarthria_model.tflite');
      print("Model loaded successfully.");
    } catch (e) {
      print("Failed to load model: $e");
    }
  }

  // Run inference on MFCC features
  Future<String> predict(List<List<List<double>>> mfcc) async {
    try {
      // Flatten the MFCC data as the model expects it to be in a specific format (usually a 1D array or a 2D array)
      List<double> flattenedMfcc = [];
      for (var frame in mfcc) {
        for (var feature in frame) {
          flattenedMfcc.addAll(feature);
        }
      }

      // Prepare the input tensor (it's a 1D array, so we need to convert the data to the correct format)
      var inputTensor = Float32List.fromList(flattenedMfcc);

      // Prepare the output tensor
      var outputTensor = Float32List(3); // Assuming the model has 3 output classes (adjust accordingly)
      var outputBuffer = outputTensor.buffer.asUint8List();

      // Run inference on the model
      _interpreter.run(inputTensor.buffer.asUint8List(), outputBuffer);

      // Process the output
      List<double> output = outputTensor;
      print("Prediction: $output");

      // Get the predicted class (find the index of the max value)
      int predictedClass = output.indexOf(output.reduce((a, b) => a > b ? a : b));
      return "Predicted Class: $predictedClass";
    } catch (e) {
      print("Error during inference: $e");
      return "Model not loaded for prediction yet.";
    }
  }

  // Close the interpreter when done
  void close() {
    _interpreter.close();
  }
}
