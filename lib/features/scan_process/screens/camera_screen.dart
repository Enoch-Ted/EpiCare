// lib/features/camera/screens/camera_screen.dart

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// path_provider and path are not strictly needed if just using XFile.path
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as p; // For path joining

// Import BodySide enum from your entity file
import 'package:care/core/database/entities/lesion.dart' show BodySide;

class CameraScreen extends StatefulWidget {
  final double normX;
  final double normY;
  final BodySide bodySide; // Expecting the enum now, non-nullable

  const CameraScreen({
    super.key,
    required this.normX,
    required this.normY,
    required this.bodySide,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isTakingPicture = false;
  // bool _isFlashOn = false; // Optional: if you want a toggle button later

  @override
  void initState() {
    super.initState();
    _initializeCameraAndSetFlash(); // Renamed for clarity
  }

  Future<void> _initializeCameraAndSetFlash() async { // Renamed
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        print("No cameras available");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No cameras available on this device.")),
          );
          context.pop();
        }
        return;
      }

      final firstCamera = _cameras!.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        firstCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      // --- ADDED: Set Flash Mode to Torch (Always On) ---
      try {
        // Check if the camera supports torch mode
        // (Some devices might not, or it might be tied to specific cameras)
        // For simplicity, we'll try to set it. If it fails, it will throw an error.
        await _cameraController!.setFlashMode(FlashMode.torch);
        print("Flash mode set to TORCH (always on).");
        // _isFlashOn = true; // Optional state update
      } catch (e) {
        print("Error setting flash mode to torch: $e");
        // You might want to inform the user if flash couldn't be turned on
        // Or try FlashMode.auto if torch fails and auto is supported
        // For now, we just log the error.
      }
      // -------------------------------------------------

      setState(() {
        _isCameraInitialized = true;
      });
      print("Camera initialized successfully.");

    } catch (e) {
      print("Error initializing camera or setting flash: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error initializing camera: ${e.toString()}")),
        );
        context.pop();
      }
    }
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _cameraController == null || _cameraController!.value.isTakingPicture) {
      return;
    }

    setState(() {
      _isTakingPicture = true;
    });

    try {
      // --- Important: Turn off torch mode just before taking picture if it was on ---
      // Taking a picture with torch mode ON might result in an overexposed image
      // as the capture flash might also fire. It's usually better to use FlashMode.auto
      // or FlashMode.always (for capture flash) when taking the picture.
      // For simplicity in this "always on flash" request, we'll keep torch on.
      // However, for better picture quality, consider:
      // FlashMode currentFlashMode = _cameraController!.value.flashMode;
      // if (currentFlashMode == FlashMode.torch) {
      //   await _cameraController!.setFlashMode(FlashMode.off); // Turn off torch
      //   // Optionally, set FlashMode.auto or .always for the capture itself if desired
      // }
      // -----------------------------------------------------------------------------

      final XFile imageFile = await _cameraController!.takePicture();

      // --- Restore torch mode AFTER taking picture if it was on ---
      // (Only if you turned it off before taking picture)
      // if (currentFlashMode == FlashMode.torch) {
      //   try {
      //     await _cameraController!.setFlashMode(FlashMode.torch);
      //   } catch (e) {
      //     print("Error re-enabling torch mode: $e");
      //   }
      // }
      // -----------------------------------------------------------

      print("Picture taken: ${imageFile.path}");

      if (mounted) {
        context.pop<Map<String, dynamic>>({
          'filePath': imageFile.path,
        });
      }
    } catch (e) {
      print("Error taking picture: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error taking picture: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }


  @override
  void dispose() {
    // --- ADDED: Turn off flash when disposing if it was on ---
    // Important to release the flash resource
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      // Check current flash mode to avoid errors if it's already off or not supported
      if (_cameraController!.value.flashMode == FlashMode.torch) {
        _cameraController!.setFlashMode(FlashMode.off).catchError((e) {
          print("Error turning off flash in dispose: $e");
        });
      }
    }
    // ---------------------------------------------------------
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _cameraController == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Capture Lesion Image")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Capture Lesion Image"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(_cameraController!),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton.large(
                onPressed: _isTakingPicture ? null : _takePicture,
                backgroundColor: Colors.white54,
                child: _isTakingPicture
                    ? const CircularProgressIndicator(color: Colors.blue)
                    : const Icon(Icons.camera_alt, size: 40, color: Colors.black87),
              ),
            ),
          ),
          // Optional: Add a button to toggle flash if you want user control
          // Positioned(
          //   top: 20,
          //   right: 20,
          //   child: IconButton(
          //     icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
          //     onPressed: () async {
          //       if (_cameraController != null && _cameraController!.value.isInitialized) {
          //         try {
          //           if (_isFlashOn) {
          //             await _cameraController!.setFlashMode(FlashMode.off);
          //             setState(() => _isFlashOn = false);
          //           } else {
          //             await _cameraController!.setFlashMode(FlashMode.torch);
          //             setState(() => _isFlashOn = true);
          //           }
          //         } catch (e) {
          //           print("Error toggling flash: $e");
          //         }
          //       }
          //     },
          //   ),
          // ),
        ],
      ),
    );
  }
}