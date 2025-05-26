// lib/core/providers/ai_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
// Import the actual service and handler classes
import 'package:care/core/ai/tflite_service.dart';
import 'package:care/core/ai/model_handler.dart';

part 'ai_providers.g.dart'; // For riverpod_generator

// Provider for TFLiteService (kept alive, as it loads models)
@Riverpod(keepAlive: true)
TFLiteService tfliteService(TfliteServiceRef ref) { // Ref type matches generated
  print("Creating TFLiteService instance via provider.");
  return TFLiteService(); // Instantiate the service
}

// Provider for ModelHandler (depends on TFLiteService)
// Kept alive because it holds a reference to TFLiteService which is kept alive.
@Riverpod(keepAlive: true)
ModelHandler modelHandler(ModelHandlerRef ref) { // Ref type matches generated
  // Watch the tfliteServiceProvider to get the TFLiteService instance
  final tfliteServ = ref.watch(tfliteServiceProvider); // Use the generated provider name
  print("Creating ModelHandler instance, injecting TFLiteService.");
  return ModelHandler(tfliteServ); // Inject the service
}