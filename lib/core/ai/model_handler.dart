// lib/core/ai/model_handler.dart

import 'dart:typed_data';
import 'dart:math' as math;
import 'package:care/core/ai/tflite_service.dart';
import 'package:care/utils/list_extensions.dart';

class ClassificationResult {
  final String label;
  final double confidence;
  ClassificationResult({required this.label, required this.confidence});
  @override
  String toString() => 'ClassificationResult(label: $label, confidence: ${confidence.toStringAsFixed(4)})';

  static List<double> softmax(List<double> logits) {
    if (logits.isEmpty) return [];
    final maxLogit = logits.reduce(math.max);
    final expLogits = logits.map((logit) => math.exp(logit - maxLogit)).toList();
    final sumExpLogits = expLogits.sum;
    if (sumExpLogits == 0) {
      print("ModelHandler Warning: Softmax sum is zero.");
      return List<double>.filled(logits.length, 1.0 / logits.length);
    }
    return expLogits.map((e) => e / sumExpLogits).toList();
  }
}


class AiPipelineResult {
  final Uint8List? imageUsedForClassification; // Will be fullImageBytes
  final List<ClassificationResult>? classificationResults;

  AiPipelineResult({
    this.imageUsedForClassification,
    this.classificationResults,
  });
}


class ModelHandler {
  final TFLiteService _tfliteService;
  ModelHandler(this._tfliteService);

  bool get isLoaded => _tfliteService.isLoaded;

  Future<AiPipelineResult> detectAndClassifyLesion(Uint8List fullImageBytes) async {

    if (!_tfliteService.isLoaded) { // isLoaded now refers to binary classifier readiness
      print("ModelHandler: Binary Classifier not loaded for analysis.");
      return AiPipelineResult(imageUsedForClassification: fullImageBytes);
    }
    print("ModelHandler: Running binary classification on FULL image...");
    // Directly call the internal classifyLesion, which uses the binary model service
    final List<ClassificationResult>? classificationResults = await classifyLesion(fullImageBytes);

    return AiPipelineResult(
      imageUsedForClassification: fullImageBytes, // Full image was used
      classificationResults: classificationResults,
    );
  }

  /// Internal helper: Runs binary classification on the provided image bytes.
  Future<List<ClassificationResult>?> classifyLesion(Uint8List imageBytes) async {
    if (!_tfliteService.isLoaded) { // Check binary classifier readiness
      print("ModelHandler: Binary Classifier or labels not loaded for classifyLesion call.");
      return null;
    }

    final List<double>? rawOutputs = await _tfliteService.runClassifierModel(imageBytes);
    if (rawOutputs == null || rawOutputs.isEmpty) {
      print("ModelHandler: Binary Classifier inference returned null from service.");
      return null;
    }

    // MODIFIED: Use the public getter `labels` from TFLiteService
    final labels = _tfliteService.labels;

    if (labels.isEmpty) {
      print("ModelHandler Error: No labels available from TFLiteService.");
      return [];
    }
    if (labels.length != rawOutputs.length) {
      print("ModelHandler Error: Binary Classifier outputs count (${rawOutputs.length}) "
          "does not match loaded labels count (${labels.length}).");
      print("  Labels: $labels");
      print("  Outputs: $rawOutputs");
      return [];
    }

    final List<double> probabilities = ClassificationResult.softmax(rawOutputs);
    print("ModelHandler: Binary Classifier Probabilities : $probabilities");

    var results = <ClassificationResult>[];
    for (int i = 0; i < probabilities.length; i++) {
      results.add(ClassificationResult(label: labels[i], confidence: probabilities[i]));
    }
    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    print("ModelHandler: Sorted Classification Results: $results");
    return results;
  }



  void dispose() {
    _tfliteService.dispose();
    print('ModelHandler disposed.');
  }
}