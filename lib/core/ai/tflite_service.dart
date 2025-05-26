// lib/core/ai/tflite_service.dart

import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:care/core/constants/app_constants.dart' as app_const;

class TFLiteService {
  Interpreter? _binaryClassifierInterpreter;
  bool _isBinaryClassifierLoaded = false;
  List<String> _binaryLabels = [];
  List<int> _binaryClassifierInputShape = [];
  List<int> _binaryClassifierOutputShape = [];


  TFLiteService() {
    _loadBinaryLabels().then((_) {
      if (_binaryLabels.isNotEmpty) {
        _loadBinaryClassifierModel().catchError((e) => print("TFLiteService: Binary Classifier load error: $e"));

      } else {
        print("TFLiteService: Skipping binary classifier model loading as labels failed.");
      }
    }).catchError((e) {
      print("TFLiteService: Error during initial binary labels loading: $e");
    });
  }

  // MODIFIED: isLoaded now only depends on the binary classifier and its labels
  bool get isLoaded => _isBinaryClassifierLoaded && _binaryLabels.isNotEmpty;

  bool get isBinaryClassifierLoaded => _isBinaryClassifierLoaded && _binaryClassifierInterpreter != null && _binaryLabels.isNotEmpty;

  List<String> get labels => _binaryLabels; // These are the binary labels

  Future<void> _loadBinaryLabels() async {
    try {
      String labelsString = await rootBundle.loadString(app_const.AssetPaths.binaryClassifierLabels);
      _binaryLabels = labelsString.split('\n').map((label) => label.trim()).where((label) => label.isNotEmpty).toList();
      print('TFLiteService: Binary Labels loaded successfully (${_binaryLabels.length}) from ${app_const.AssetPaths.binaryClassifierLabels}');
      if (_binaryLabels.length != 2) { print('TFLiteService Warning: Binary labels count is ${_binaryLabels.length}, expected 2.'); }
    } catch (e) { print('TFLiteService Error loading binary labels: $e'); _binaryLabels = []; throw e; }
  }

  Future<void> _loadBinaryClassifierModel() async {
    if (_isBinaryClassifierLoaded || _binaryClassifierInterpreter != null) return;
    final String modelPath = app_const.AssetPaths.binaryClassifierModel;
    try {
      print('TFLiteService: Loading binary classifier model from: $modelPath');
      var interpreterOptions = InterpreterOptions();
      _binaryClassifierInterpreter = await Interpreter.fromAsset(modelPath, options: interpreterOptions);
      var inputTensor = _binaryClassifierInterpreter!.getInputTensor(0);
      var outputTensor = _binaryClassifierInterpreter!.getOutputTensor(0);
      _binaryClassifierInputShape = List<int>.from(inputTensor.shape);
      _binaryClassifierOutputShape = List<int>.from(outputTensor.shape);

      if (_binaryLabels.isEmpty) { print('TFLiteService Error: Labels empty for binary classifier.'); _isBinaryClassifierLoaded = false; return; }
      if (_binaryClassifierOutputShape.length != 2 || _binaryClassifierOutputShape[0] != 1 || _binaryClassifierOutputShape.last != _binaryLabels.length) { print('TFLiteService Error: Binary model output shape ${_binaryClassifierOutputShape} != [1, ${_binaryLabels.length}].'); _binaryClassifierInterpreter?.close(); _binaryClassifierInterpreter = null; _isBinaryClassifierLoaded = false; _binaryClassifierOutputShape = []; throw Exception("Binary model output shape mismatch."); }
      if (_binaryClassifierInputShape.length != 4 || _binaryClassifierInputShape[0] != 1 || _binaryClassifierInputShape[1] != app_const.BINARY_CLASSIFICATION_INPUT_SIZE || _binaryClassifierInputShape[2] != app_const.BINARY_CLASSIFICATION_INPUT_SIZE || _binaryClassifierInputShape[3] != 3) { print('TFLiteService Error: Binary model input shape ${_binaryClassifierInputShape} != [1, ${app_const.BINARY_CLASSIFICATION_INPUT_SIZE}, ${app_const.BINARY_CLASSIFICATION_INPUT_SIZE}, 3].'); _binaryClassifierInterpreter?.close(); _binaryClassifierInterpreter = null; _isBinaryClassifierLoaded = false; _binaryClassifierInputShape = []; throw Exception("Binary model input shape mismatch."); }

      _binaryClassifierInterpreter!.allocateTensors();
      _isBinaryClassifierLoaded = true;
      print('TFLiteService: Binary Classifier Loaded. Input: $_binaryClassifierInputShape, Output: $_binaryClassifierOutputShape');
    } catch (e) {
      print('TFLiteService Error loading binary classifier: $e');
      _isBinaryClassifierLoaded = false; _binaryClassifierInterpreter?.close(); _binaryClassifierInterpreter = null;
      _binaryClassifierInputShape = []; _binaryClassifierOutputShape = []; // Clear on error
      throw e;
    }
  }


  Float32List? _preprocessImageForBinaryClassifier(Uint8List imageBytes) {
    if (!_isBinaryClassifierLoaded || _binaryClassifierInputShape.isEmpty) { print("TFLiteService: Binary Classifier not ready for preprocessing."); return null; }
    final int inputHeight = _binaryClassifierInputShape[1];
    final int inputWidth = _binaryClassifierInputShape[2];
    img.Image? decoded = img.decodeImage(imageBytes);
    if (decoded == null) { print("TFLiteService Classifier: Failed to decode image."); return null; }
    img.Image workingImage = decoded;
    try { img.Image? oriented = img.bakeOrientation(workingImage); if (oriented != null) workingImage = oriented; } catch (e) { print("TFLiteService Classifier: EXIF failed: $e"); }
    if (workingImage.numChannels != 3) {
      if (workingImage.numChannels == 4) { img.Image? rgbImage = img.decodePng(img.encodePng(workingImage)); if (rgbImage != null && rgbImage.numChannels == 3) { workingImage = rgbImage; } else { print("TFLiteService Classifier: RGBA->RGB failed."); return null; } }
      else { print("TFLiteService Classifier: Image not 3/4 channels: ${workingImage.numChannels}."); return null; }
    }
    img.Image resized = img.copyResize(workingImage, width: inputWidth, height: inputHeight, interpolation: workingImage.width > inputWidth || workingImage.height > inputHeight ? img.Interpolation.average : img.Interpolation.linear);
    var floatData = Float32List(inputHeight * inputWidth * 3);
    int idx = 0;
    for (int y = 0; y < inputHeight; y++) {
      for (int x = 0; x < inputWidth; x++) {
        final p = resized.getPixel(x, y);
        // Apply normalization based on the constant from app_constants.dart
        if (app_const.BINARY_CLASSIFIER_NORMALIZATION_TYPE == 'ZERO_TO_ONE') {
          floatData[idx++] = p.r / 255.0; floatData[idx++] = p.g / 255.0; floatData[idx++] = p.b / 255.0;
        } else if (app_const.BINARY_CLASSIFIER_NORMALIZATION_TYPE == 'MINUS_ONE_TO_ONE') {
          floatData[idx++] = (p.r / 127.5) - 1.0; floatData[idx++] = (p.g / 127.5) - 1.0; floatData[idx++] = (p.b / 127.5) - 1.0;
        } else if (app_const.BINARY_CLASSIFIER_NORMALIZATION_TYPE == 'IMAGENET') {
          print("IMAGENET norm not fully impl for binary. Define mean/std in app_constants."); return null;
        } else {
          print("Unknown BINARY_CLASSIFIER_NORMALIZATION_TYPE: ${app_const.BINARY_CLASSIFIER_NORMALIZATION_TYPE}"); return null;
        }
      }
    }
    return floatData;
  }

  // This method now exclusively runs the binary classifier
  Future<List<double>?> runClassifierModel(Uint8List imageBytes) async {
    if (!_isBinaryClassifierLoaded || _binaryClassifierInterpreter == null) {
      print("TFLiteService: Binary Classifier model not loaded for run.");
      return null;
    }

    Float32List? inputFloats = _preprocessImageForBinaryClassifier(imageBytes);
    if (inputFloats == null) {
      print("TFLiteService: Binary Classifier preprocessing failed for run.");
      return null;
    }

    final inputList = inputFloats.buffer.asFloat32List(); // Simplified input

    final output = Float32List(_binaryClassifierOutputShape[1]); // Flat output
    try {
      print("TFLiteService Binary Classifier: Running inference...");
      _binaryClassifierInterpreter!.run(inputList, output);
    } catch (e) {
      print("TFLiteService Error running Binary Classifier interpreter: $e");
      return null;
    }

    return output.toList();
  }

  void dispose() {
    _binaryClassifierInterpreter?.close();
    // REMOVED: _yoloInterpreter?.close();
    _binaryClassifierInterpreter = null;
    // REMOVED: _yoloInterpreter = null;
    _isBinaryClassifierLoaded = false;
    // REMOVED: _isYoloLoaded = false;
    _binaryLabels = [];
    print('TFLiteService: Binary Classifier interpreter closed.');
  }
}