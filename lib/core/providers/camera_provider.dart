// lib/core/providers/camera_provider.dart

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'camera_provider.g.dart';

// *** RENAME THE PROVIDER FUNCTION ***
@riverpod
Future<List<CameraDescription>> fetchAvailableCameras(
    FetchAvailableCamerasRef ref // <<< UPDATED Ref type to match
    ) async {
  print("DEBUG: fetchAvailableCamerasProvider fetching cameras..."); // Update log
  try {
    WidgetsFlutterBinding.ensureInitialized();
    // Call the ORIGINAL camera package function here
    final cameras = await availableCameras(); // This is the function from 'package:camera'
    print("DEBUG: fetchAvailableCamerasProvider found ${cameras.length} cameras.");
    return cameras;
  } catch (e) {
    print("DEBUG: fetchAvailableCamerasProvider ERROR fetching cameras: $e");
    rethrow;
  }
}