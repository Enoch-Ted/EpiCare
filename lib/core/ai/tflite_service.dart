// lib/core/ai/tflite_service.dart

import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {
  Interpreter? _classifierInterpreter;
  bool _isClassifierLoaded = false;

  // Store shapes/types retrieved from model
  List<int> _classifierInputShape = [];
  TensorType? _classifierInputType; // Should be float32
  List<int> _classifierOutputShape = [];
  TensorType? _classifierOutputType; // Should be float32

  TFLiteService() {
    _loadClassifierModel();
  }

  Future<void> _loadClassifierModel() async {
    if (_isClassifierLoaded || _classifierInterpreter != null) return;
    // *** Ensure this path is correct ***
    final String modelPath = 'models/skin_cancer_best_model.tflite';
    try {
      print('Loading classifier model from: $modelPath');
      // No special options needed for now based on example
      _classifierInterpreter = await Interpreter.fromAsset(modelPath);

      var inputTensor = _classifierInterpreter!.getInputTensor(0);
      var outputTensor = _classifierInterpreter!.getOutputTensor(0);
      _classifierInputShape = List<int>.from(inputTensor.shape);
      _classifierInputType = inputTensor.type;
      _classifierOutputShape = List<int>.from(outputTensor.shape);
      _classifierOutputType = outputTensor.type;

      // Note: allocateTensors() might not be needed if run() handles it,
      // but keeping it is generally safe. Remove if it causes issues.
      _classifierInterpreter!.allocateTensors();

      _isClassifierLoaded = true;
      print('Classifier Model Loaded Successfully.');
      print('  Input Shape: $_classifierInputShape, Type: $_classifierInputType'); // Expect [1, 224, 224, 3], float32
      print('  Output Shape: $_classifierOutputShape, Type: $_classifierOutputType'); // Expect [1, 7], float32

    } catch (e) {
      print('Error loading classifier model: $e');
      _isClassifierLoaded = false;
      _classifierInterpreter?.close();
      _classifierInterpreter = null;
    }
  }

  /// Prepares the image bytes into a normalized flat Float32List.
  Float32List _preprocessImage(Uint8List imageBytes) {
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception("Failed to decode image");
    }

    // Resize (Assuming model expects 224x224 based on example)
    // Get expected dimensions from loaded model shape if possible for robustness
    int inputHeight = _classifierInputShape.length > 1 ? _classifierInputShape[1] : 224;
    int inputWidth = _classifierInputShape.length > 2 ? _classifierInputShape[2] : 224;

    img.Image resizedImage = img.copyResize(image, width: inputWidth, height: inputHeight,);

    // Normalize & Convert to flat Float32List
    var imageBytesList = Float32List(1 * inputHeight * inputWidth * 3); // flat list
    int pixelIndex = 0;
    for (int y = 0; y < inputHeight; y++) {
      for (int x = 0; x < inputWidth; x++) {
        var pixel = resizedImage.getPixel(x, y);
        imageBytesList[pixelIndex++] = pixel.r / 255.0; // Normalize
        imageBytesList[pixelIndex++] = pixel.g / 255.0; // Normalize
        imageBytesList[pixelIndex++] = pixel.b / 255.0; // Normalize
      }
    }
    return imageBytesList;
  }


  /// Runs inference using the loaded classifier model.
  /// Returns the List<double> of probabilities, or null on error.
  Future<List<double>?> runClassifierModel(Uint8List imageBytes) async {
    if (!_isClassifierLoaded || _classifierInterpreter == null) {
      print('Classifier model is not loaded. Attempting load...');
      await _loadClassifierModel();
      if (!_isClassifierLoaded || _classifierInterpreter == null) return null;
    }
    if (_classifierInputShape.isEmpty || _classifierOutputShape.isEmpty) {
      print('Error: Model tensor shapes not determined.');
      return null;
    }

    try {
      // 1. Preprocess image to get flat, normalized Float32List
      Float32List inputFloats = _preprocessImage(imageBytes);

      // 2. Reshape the input list to match model's expected input shape [1, H, W, C]
      // Ensure the shape used for reshape matches the loaded model's input shape
      var reshapedInput = inputFloats.reshape(_classifierInputShape);

      // 3. Prepare the output buffer explicitly as List<List<double>>
      // Ensure shape matches model's output shape, e.g., [1, 7]
      var outputBuffer = List.generate(
          _classifierOutputShape[0], // Should be 1 (batch size)
              (_) => List<double>.filled(_classifierOutputShape[1], 0.0) // Should be 7 (classes)
      );

      print("Running inference with reshaped input and explicit output buffer...");
      // 4. Run inference
      _classifierInterpreter!.run(reshapedInput, outputBuffer);
      print("Inference complete. Output buffer: $outputBuffer");

      // 5. Return the inner list of probabilities (outputBuffer[0])
      if (outputBuffer.isNotEmpty && outputBuffer[0].length == _classifierOutputShape[1]) {
        return outputBuffer[0];
      } else {
        print("Error: Output buffer has unexpected structure: $outputBuffer");
        return null;
      }

    } catch (e) {
      print('Error running classifier model: $e');
      // print(StackTrace.current);
      return null;
    }
  }

  void dispose() {
    _classifierInterpreter?.close();
    _classifierInterpreter = null;
    _isClassifierLoaded = false;
    print('TFLite interpreters closed.');
  }
}