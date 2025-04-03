// lib/core/ai/model_handler.dart

import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'tflite_service.dart';

class ClassificationResult {
  final String label;
  final double confidence;
  ClassificationResult({required this.label, required this.confidence});
  @override
  String toString() => 'ClassificationResult(label: $label, confidence: ${confidence.toStringAsFixed(4)})';
}

class ModelHandler {
  final TFLiteService _tfliteService;
  ModelHandler(this._tfliteService);

  // --- Classification Function ---
  Future<List<ClassificationResult>?> classifyLesion(Uint8List lesionImageBytes) async {
    try {
      // 1. Run inference using the TFLite service (now returns List<double>?)
      final List<double>? probabilities = await _tfliteService.runClassifierModel(lesionImageBytes);

      if (probabilities == null) {
        print("Error: Classifier model returned null probabilities.");
        return null;
      }

      // 2. Post-process the results (probabilities) using the existing helper
      List<ClassificationResult> classificationResults = _mapProbabilitiesToResults(probabilities);

      // Optional: Sort by confidence descending
      classificationResults.sort((a, b) => b.confidence.compareTo(a.confidence));

      return classificationResults;

    } catch (e) {
      print("Error during lesion classification: $e");
      return null;
    }
  }

  // Helper method to map probabilities to results
  List<ClassificationResult> _mapProbabilitiesToResults(List<double> probabilities) {
    // --- Class Labels Based on User Info ---
    const List<String> classLabels = [
      'Actinic Keratosis / Intraepithelial Carcinoma', // Index 0
      'Basal Cell Carcinoma',                       // Index 1
      'Benign Keratosis',                           // Index 2
      'Dermatofibroma',                             // Index 3
      'Melanoma',                                   // Index 4
      'Melanocytic Nevus',                          // Index 5
      'Vascular Lesion'                             // Index 6
    ];
    // --- End Labels ---

    if (probabilities.length != classLabels.length) {
      print("Error: Probabilities length (${probabilities.length}) != Labels length (${classLabels.length}).");
      return [];
    }

    List<ClassificationResult> results = [];
    for (int i = 0; i < probabilities.length; i++) {
      results.add(ClassificationResult(
        label: classLabels[i],
        confidence: probabilities[i],
      ));
    }
    return results;
  }

  void dispose() {
    // _tfliteService disposal is handled by its provider
  }
}