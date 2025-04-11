// lib/features/camera/screens/camera_screen.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p; // Use prefix for join
import 'package:care/core/providers/camera_provider.dart';

// Import needed entities/providers (Adjust package name)
import 'package:care/core/database/entities/lesion.dart'; // For BodySide

// Provider to hold available cameras (usually fetched once)

class CameraScreen extends ConsumerStatefulWidget {
  final double normX;
  final double normY;
  final BodySide bodySide;

  const CameraScreen({
    required this.normX,
    required this.normY,
    required this.bodySide,
    super.key,
  });

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    print("DEBUG: _initializeCamera called.");
    // Read the provider itself to access its .future
    final camerasProviderInstance = fetchAvailableCamerasProvider; // Get the provider instance

    try {
      // *** Await the .future property of the provider via ref.read ***
      final cameras = await ref.read(camerasProviderInstance.future);
      print("DEBUG: Cameras loaded in _initializeCamera.");

      if (cameras.isEmpty)
      {print("Error: No cameras available."); }
      final firstCamera = cameras.first;
      print("DEBUG: Using camera: ${firstCamera.name}");

      if (_controller != null) await _controller!.dispose();

      _controller = CameraController( firstCamera, ResolutionPreset.high, enableAudio: false, );

      // Assign the future for the FutureBuilder
      // Use setState to ensure the FutureBuilder gets the future assigned
      setState(() {
        _initializeControllerFuture = _controller!.initialize().then((_) {
          if (!mounted) return;
          print("DEBUG: Camera controller initialized successfully.");
          setState(() {}); // Trigger rebuild AFTER controller is initialized
        }).catchError((error) {
          print("DEBUG: Camera controller initialization ERROR: $error");
          if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error initializing camera: $error"), backgroundColor: Colors.red));
          context.pop(); }
        });
      });

    } catch (e) {
      print("DEBUG: Error awaiting availableCamerasProvider.future: $e");
      if (mounted) { /* ... show snackbar and pop ... */ }
    }
  } // End _initializeCamera

  @override
  void dispose() {
    _controller?.dispose(); // Dispose controller when widget is removed
    print("Camera controller disposed.");
    super.dispose();
  }

  // --- Capture and Save Logic ---
  Future<void> _captureAndProceed() async {
    if (_controller == null || !_controller!.value.isInitialized || _isTakingPicture) {
      print("DEBUG: Capture button pressed but controller not ready or already taking picture.");
      return;
    }
    print("DEBUG: Setting _isTakingPicture = true");
    // Use mounted check BEFORE async gap if possible
    if (!mounted) return;
    setState(() => _isTakingPicture = true);

    try {
      final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
      final String scansDirPath = p.join(appDocumentsDir.path, 'scans');
      final Directory scansDir = Directory(scansDirPath);
      if (!await scansDir.exists()) { await scansDir.create(recursive: true); }
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = p.join(scansDirPath, 'scan_$timestamp.jpg');

      print("DEBUG: Attempting to take picture...");
      final XFile imageFile = await _controller!.takePicture(); // <<< Potential Hang Point 1
      print("DEBUG: Picture taken: ${imageFile.path}");

      print("DEBUG: Attempting to save picture to: $filePath");
      await imageFile.saveTo(filePath); // <<< Potential Hang Point 2
      print("DEBUG: Picture saved successfully.");

      if (mounted) {
        print("DEBUG: Popping camera screen with result.");
        context.pop({ // <<< Potential Hang Point 3 (Less Likely)
          'filePath': filePath,
          'normX': widget.normX,
          'normY': widget.normY,
          'bodySide': widget.bodySide,
        });
      }

    } catch (e) {
      print("DEBUG: Error during capture/save: $e"); // Log the specific error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text("Error capturing image: $e"), backgroundColor: Colors.red) );
      }
    } finally {
      // Ensure this always runs
      print("DEBUG: Setting _isTakingPicture = false in finally block.");
      if (mounted) {
        setState(() => _isTakingPicture = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use FutureBuilder to display loading/preview/error
    return Scaffold(
      backgroundColor: Colors.black, // Black background for camera view
      // Optional AppBar if needed
      // appBar: AppBar(title: Text("Capture Lesion")),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && _controller != null && _controller!.value.isInitialized) {
            // If the Future is complete, display the preview.
            return Stack( // Use Stack to overlay button
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller!), // Display camera feed
                // Capture Button Overlay
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton(
                      onPressed: _isTakingPicture ? null : _captureAndProceed,
                      backgroundColor: Colors.white.withOpacity(0.8),
                      child: _isTakingPicture
                          ? const CircularProgressIndicator()
                          : const Icon(Icons.camera_alt, color: Colors.black),
                    ),
                  ),
                )
              ],
            );
          } else if (snapshot.hasError) {
            // If there was an error initializing
            return Center(child: Text("Error initializing camera: ${snapshot.error}", style: TextStyle(color: Colors.white)));
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}