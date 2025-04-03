// lib/core/providers/ai_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../ai/tflite_service.dart';
import '../ai/model_handler.dart';

// Import generated file
part 'ai_providers.g.dart';

// Provider for TFLiteService
// keepAlive = true is important here as loading models is expensive
// We also need to handle disposal.
@Riverpod(keepAlive: true)
TFLiteService tfliteService(TfliteServiceRef ref) {
  final service = TFLiteService();
  // Ensure the dispose method is called when the provider is disposed
  ref.onDispose(() {
    print("Disposing TFLiteService...");
    service.dispose();
  });
  return service;
}

// Provider for ModelHandler
// Depends on TFLiteService
@Riverpod(keepAlive: true) // Keep alive, depends on keepAlive TFLiteService
ModelHandler modelHandler(ModelHandlerRef ref) {
  // Get the TFLiteService instance
  final tfliteSvc = ref.watch(tfliteServiceProvider);
  // Inject it into ModelHandler
  return ModelHandler(tfliteSvc);
  // Note: ModelHandler's dispose just calls tfliteService.dispose(),
  // which is handled by the tfliteServiceProvider's onDispose.
}