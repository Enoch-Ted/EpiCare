// lib/features/scan/screens/scan_screen.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:care/core/constants/app_constants.dart';
import 'package:care/core/database/entities/scan.dart';
import 'package:care/core/navigation/app_router.dart';
import 'package:care/core/providers/database_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:care/core/ai/model_handler.dart';
import 'dart:math';
import 'package:image/image.dart' as img;

import 'package:care/core/database/entities/lesion.dart';
import '../../../core/providers/ai_providers.dart';
import '../../../core/providers/security_providers.dart';

// --- State Providers ---
@immutable
class MarkerData {
  final double? normX;
  final double? normY;
  const MarkerData({this.normX, this.normY});
  static const MarkerData empty = MarkerData();
  MarkerData copyWith({double? normX, double? normY}) {
    return MarkerData(
      normX: normX ?? this.normX,
      normY: normY ?? this.normY,
    );
  }
}

final _isScanViewFrontProvider = StateProvider<bool>((ref) => true);
final _markersStateProvider = StateProvider<Map<BodySide, MarkerData>>(
        (ref) => { BodySide.Front: MarkerData.empty, BodySide.Back: MarkerData.empty });

// --- Image Data Provider ---
final _bodyImageDataProvider = FutureProvider.autoDispose<Map<BodySide, img.Image?>>((ref) async {
  print("Loading body map image data for boundary check...");
  try {
    final frontBytes = await rootBundle.load(AssetPaths.bodyMapFront);
    final backBytes = await rootBundle.load(AssetPaths.bodyMapBack);
    // Using compute might be slightly better if decoding is slow, but Future is often sufficient
    final frontImage = await Future(() => img.decodePng(frontBytes.buffer.asUint8List()));
    final backImage = await Future(() => img.decodePng(backBytes.buffer.asUint8List()));
    print("Body map image data loaded successfully.");
    return { BodySide.Front: frontImage, BodySide.Back: backImage };
  } catch (e) {
    print("Error loading body map image data: $e");
    return { BodySide.Front: null, BodySide.Back: null }; // Return nulls on error
  }
});


// --- Screen Widget ---
class ScanScreen extends HookConsumerWidget {
  const ScanScreen({super.key});

  // --- Boundary Check Helper ---
  bool _isTapInsideBodyOutline(img.Image? bodyImageData, double normX, double normY) {
    if (bodyImageData == null) {
      print("Boundary check skipped: Image data not loaded.");
      return false; // Cannot check if data isn't loaded
    }
    // Check basic normalized bounds first
    if (normX < 0.0 || normX > 1.0 || normY < 0.0 || normY > 1.0) {
      return false;
    }

    final imgWidth = bodyImageData.width;
    final imgHeight = bodyImageData.height;
    final pixelX = (normX * imgWidth).floor().clamp(0, imgWidth - 1);
    final pixelY = (normY * imgHeight).floor().clamp(0, imgHeight - 1);

    try {
      final pixel = bodyImageData.getPixel(pixelX, pixelY);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();

      // Define the pure white background color (assuming RGB 255,255,255)
      const int whiteR = 255, whiteG = 255, whiteB = 255;
      // Define a tolerance if needed (e.g., if background isn't perfectly white)
      // const int tolerance = 5;
      // bool isBackground = (r >= whiteR - tolerance && r <= whiteR + tolerance) &&
      //                     (g >= whiteG - tolerance && g <= whiteG + tolerance) &&
      //                     (b >= whiteB - tolerance && b <= whiteB + tolerance);

      // Check if the pixel IS the pure white background
      bool isBackground = (r == whiteR && g == whiteG && b == whiteB);

      // Return true if it's NOT the background
      return !isBackground;

    } catch (e) {
      print("Error checking pixel at ($pixelX, $pixelY): $e");
      return false;
    }
  }

  // --- _saveScanAndLesion Method ---
  Future<void> _saveScanAndLesion(WidgetRef ref, BuildContext context, String imagePath, double normX, double normY, BodySide bodySide) async {
    final currentUser = ref.read(currentUserProvider);
    final scanDao = ref.read(scanDaoProvider);
    final lesionDao = ref.read(lesionDaoProvider);
    final modelHandler = ref.read(modelHandlerProvider);

    if (currentUser == null || currentUser.userId == null) {
      print("Error: Cannot save scan - no active user.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: No active user found."), backgroundColor: Colors.red));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saving scan data...")));

    int? newScanId;
    int? newLesionId;
    Lesion? initialLesion;

    try {
      // 1. Create and Insert Scan
      final newScan = Scan( userId: currentUser.userId!, imagePath: imagePath, scanDate: DateTime.now());
      newScanId = await scanDao.insertScan(newScan);
      if (newScanId == null || newScanId <= 0) throw Exception("Failed to insert Scan record.");
      print("Saved Scan with ID: $newScanId");

      // 2. Create and Insert Initial Lesion
      initialLesion = Lesion(
          scanId: newScanId,
          riskLevel: RiskLevel.Undetermined.name, // Use .name
          lesionType: "Pending Analysis", confidenceScore: 0.0,
          bodyMapX: normX, bodyMapY: normY, bodySide: bodySide
      );
      newLesionId = await lesionDao.insertLesion(initialLesion);
      if (newLesionId == null || newLesionId <= 0) throw Exception("Failed to insert initial Lesion record.");
      print("Saved initial Lesion with ID: $newLesionId");
      initialLesion = initialLesion.copyWith(lesionId: newLesionId);

      // --- 3. Trigger AI Analysis ---
      print(">>> Starting AI Analysis for image: $imagePath"); // Log Start
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Analyzing image...")));
      Uint8List imageBytes;
      try { imageBytes = await File(imagePath).readAsBytes(); }
      catch (e) { throw Exception("Failed to read image file for AI: $e"); }

      final List<ClassificationResult>? classificationResults = await modelHandler.classifyLesion(imageBytes);
      print(">>> AI Analysis Complete. Results: ${classificationResults?.map((r) => '${r.label}:${r.confidence.toStringAsFixed(2)}').toList()}"); // Log Result

      // 4. Process Results & Update Lesion
      if (classificationResults != null && classificationResults.isNotEmpty) {
        final topPrediction = classificationResults.first;
        print("AI Result: ${topPrediction.label} (${topPrediction.confidence})");
        final RiskLevel? lookedUpRisk = lesionTypeToRiskLevel[topPrediction.label];
        final RiskLevel mappedRisk = lookedUpRisk ?? RiskLevel.Undetermined;
        print("Mapped Risk Level: ${mappedRisk.name}");

        if (initialLesion == null) throw Exception("Initial lesion object was null before update.");

        final Lesion updatedLesion = initialLesion.copyWith(
          lesionType: topPrediction.label,
          confidenceScore: topPrediction.confidence,
          riskLevel: mappedRisk.name, // Save the .name string
        );

        print("Updating lesion record $newLesionId with AI results...");
        final updateCount = await lesionDao.updateLesion(updatedLesion);
        if (updateCount <= 0) print("Warning: Failed to update lesion record with AI results.");
        else print("Lesion record updated successfully with AI results.");

      } else {
        print("Warning: AI classification returned null or empty results.");
        if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text("AI analysis could not determine lesion type."), backgroundColor: Colors.orangeAccent) ); }
      }

      // 5. Success Feedback & Navigation
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text("Scan saved and analyzed!"), backgroundColor: Colors.green) );
        ref.invalidate(userScansProvider);
        ref.invalidate(allUserLesionsProvider);
        ref.invalidate(userLesionCountsProvider);
        ref.invalidate(scanByIdProvider(newScanId));
        ref.invalidate(lesionsByScanIdProvider(newScanId));
        final detailPath = AppRoutes.scanDetail.replaceFirst(':scanId', newScanId.toString());
        context.go(detailPath);
      }

    } catch (e) {
      print("Error saving scan/lesion/processing AI: $e");
      if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text("Error saving scan data: $e"), backgroundColor: Colors.red) ); }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFront = ref.watch(_isScanViewFrontProvider);
    final isScanViewFrontNotifier = ref.read(_isScanViewFrontProvider.notifier);
    final allMarkersData = ref.watch(_markersStateProvider);
    final currentSide = isFront ? BodySide.Front : BodySide.Back;
    final currentMarkerData = allMarkersData[currentSide] ?? MarkerData.empty;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bodyImageDataAsync = ref.watch(_bodyImageDataProvider);

    // --- Hooks ---
    final innerStackKey = useMemoized(() => GlobalKey(), const []);
    final frontTransformationController = useTransformationController();
    final backTransformationController = useTransformationController();
    final activeTransformationController = isFront ? frontTransformationController : backTransformationController;

    const double frontAspectRatio = 631 / 1500;
    const double backAspectRatio = 630 / 1494;
    final double currentAspectRatio = isFront ? frontAspectRatio : backAspectRatio;

    // --- Reset Zoom/Pan on Side Change ---
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        if (isFront) {
          backTransformationController.value = Matrix4.identity();
        } else {
          frontTransformationController.value = Matrix4.identity();
        }
      });
      return null;
    }, [isFront]);

    final bool isMarkerPlaced = currentMarkerData.normX != null && currentMarkerData.normY != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () { if (context.canPop()) context.pop(); },
        ),
        title: const Text(
          'Mark New Spot',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column( // Main column
        children: [
          // --- Body Map Area (Takes maximum available space) ---
          Expanded(
            // REMOVED Padding wrapper
            child: Stack( // Stack holds Map and loading indicator
              children: [
                // --- Map Area (using LayoutBuilder) ---
                LayoutBuilder(
                    builder: (context, constraints) {
                      // --- Size/Offset Calculation ---
                      final availableWidth = constraints.maxWidth;
                      final availableHeight = constraints.maxHeight;
                      double renderWidth, renderHeight, initialOffsetX = 0, initialOffsetY = 0;
                      if (availableWidth <= 0 || availableHeight <= 0) { return const Center(child: Text("Calculating layout...")); }
                      if (availableWidth / availableHeight > currentAspectRatio) { renderHeight = availableHeight; renderWidth = availableHeight * currentAspectRatio; initialOffsetX = (availableWidth - renderWidth) / 2; }
                      else { renderWidth = availableWidth; renderHeight = availableWidth / currentAspectRatio; initialOffsetY = (availableHeight - renderHeight) / 2; }
                      initialOffsetX = max(0, initialOffsetX); initialOffsetY = max(0, initialOffsetY);
                      final Size imageSize = Size(renderWidth, renderHeight);
                      final Offset imageOffset = Offset(initialOffsetX, initialOffsetY);

                      // --- Get current image data for boundary check ---
                      final currentBodyImageData = bodyImageDataAsync.when( data: (dataMap) => dataMap[currentSide], loading: () => null, error: (err, stack) => null );

                      // --- Stack for InteractiveViewer + Marker ---
                      return Stack( // Stack holds IV + Marker
                        clipBehavior: Clip.none,
                        children: [
                          // --- Interactive Map Area ---
                          InteractiveViewer(
                            transformationController: activeTransformationController,
                            minScale: 1.0, maxScale: 5.0,
                            clipBehavior: Clip.none,
                            child: GestureDetector(
                              onTapUp: (details) {
                                // --- Tap Calculation Logic ---
                                final innerStackRenderBox = innerStackKey.currentContext?.findRenderObject() as RenderBox?;
                                if (innerStackRenderBox == null || imageSize.isEmpty) {
                                  print("Skipping tap: Render info not ready.");
                                  return;
                                }
                                final Offset tapPositionInInnerStack = innerStackRenderBox.globalToLocal(details.globalPosition);
                                final Offset tapRelativeToImageOrigin = tapPositionInInnerStack - imageOffset;
                                final double normX = (tapRelativeToImageOrigin.dx / imageSize.width);
                                final double normY = (tapRelativeToImageOrigin.dy / imageSize.height);

                                print("--- Tap Details ---");
                                print("Normalized Coords: ($normX, $normY)");

                                // --- INTEGRATE Boundary Check ---
                                bool isInside = _isTapInsideBodyOutline(currentBodyImageData, normX, normY);
                                print("Boundary Check Result: $isInside");

                                if (isInside) { // Check result of boundary function
                                  // --- Update State (Only normX/Y) ---
                                  final newMarkerData = MarkerData(
                                      normX: normX.clamp(0.0, 1.0),
                                      normY: normY.clamp(0.0, 1.0)
                                  );
                                  ref.read(_markersStateProvider.notifier).update((state) {
                                    final newState = Map<BodySide, MarkerData>.from(state);
                                    newState[currentSide] = newMarkerData;
                                    return newState;
                                  });
                                  print("Marker data updated: Norm($normX, $normY), Side: $currentSide");
                                } else {
                                  // Provide feedback if tap is outside
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Please tap inside the body outline."),
                                      duration: Duration(seconds: 1),
                                      backgroundColor: Colors.orangeAccent,
                                    ),
                                  );
                                  print("Tap ignored: Outside body outline.");
                                }
                              },
                              child: Stack( // <<<< INNER STACK (for image)
                                key: innerStackKey,
                                alignment: Alignment.topLeft,
                                clipBehavior: Clip.none,
                                children: [
                                  // --- Positioned Image ---
                                  Positioned(
                                    left: imageOffset.dx,
                                    top: imageOffset.dy,
                                    width: imageSize.width,
                                    height: imageSize.height,
                                    child: Image.asset(
                                      isFront ? AssetPaths.bodyMapFront : AssetPaths.bodyMapBack,
                                      fit: BoxFit.contain,
                                      gaplessPlayback: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ), // End InteractiveViewer

                          // --- Positioned Marker ---
                          if (isMarkerPlaced)
                            ValueListenableBuilder<Matrix4>(
                              valueListenable: activeTransformationController,
                              builder: (context, matrix, child) {
                                // --- Calculate marker screen position ---
                                final currentNormX = currentMarkerData.normX;
                                final currentNormY = currentMarkerData.normY;

                                if (currentNormX == null || currentNormY == null || imageSize.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                final Offset pointOnImage = Offset(currentNormX * imageSize.width, currentNormY * imageSize.height);
                                final Offset pointInInnerStack = pointOnImage + imageOffset;
                                final Offset pointOnScreen = MatrixUtils.transformPoint(matrix, pointInInnerStack);
                                const double markerSize = 24.0;
                                final double markerLeft = pointOnScreen.dx - (markerSize / 2);
                                final double markerTop = pointOnScreen.dy - markerSize;

                                return Positioned(
                                  left: markerLeft,
                                  top: markerTop,
                                  child: IgnorePointer(
                                    child: Icon(
                                      Icons.location_on,
                                      color: Colors.red.withOpacity(0.9),
                                      size: markerSize,
                                      shadows: const [Shadow(blurRadius: 1.0, color: Colors.black54)],
                                    ),
                                  ),
                                );
                              },
                            ),

                          // --- Loading/Error Indicator ---
                          Positioned.fill(
                            child: bodyImageDataAsync.when(
                              data: (dataMap) {
                                if (dataMap[currentSide] == null && bodyImageDataAsync.hasValue) {
                                  return Center(child: Text('Error loading map data.', style: TextStyle(color: Colors.red[700])));
                                }
                                return const SizedBox.shrink();
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (err, stack) => Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'Error loading map data: $err',
                                    style: TextStyle(color: Colors.red[700]),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ], // End Inner Stack children (IV + Marker + Loading)
                      ); // End Inner Stack
                    } // End LayoutBuilder builder
                ), // End LayoutBuilder
              ], // End Outer Stack children (Map Area + Loading)
            ), // End Outer Stack
          ), // End Expanded

          // --- Instructions and Toggle Buttons (Below Map) ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Combined padding
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Instructions ---
                Text(
                  "Add a new spot by tapping on the body",
                  style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Use the search icon from the reference image
                    Icon(Icons.search, color: Colors.grey[600], size: 18),
                    const SizedBox(width: 4),
                    Text(
                      "Pinch to zoom in",
                      style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 12), // Space before toggle

                // --- Front/Back Toggle ---
                Center(
                  child: Container(
                    // Style similar to reference image toggle
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200], // Light grey background for the toggle container
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Front Button
                        InkWell(
                          onTap: () { if (!isFront) { isScanViewFrontNotifier.state = true; } },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              // Light blue for selected, transparent for unselected
                              color: isFront ? Colors.lightBlue[100] : Colors.transparent, // Lighter blue
                              borderRadius: const BorderRadius.only( topLeft: Radius.circular(7), bottomLeft: Radius.circular(7),),
                            ),
                            child: Text(
                              'Front',
                              style: textTheme.labelMedium?.copyWith(
                                color: isFront ? Colors.blue[700] : Colors.grey[700], // Darker blue text for selected
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        // Divider
                        Container(width: 1, height: 30, color: Colors.grey[350]), // Vertical divider
                        // Back Button
                        InkWell(
                          onTap: () { if (isFront) { isScanViewFrontNotifier.state = false; } },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: !isFront ? Colors.lightBlue[100] : Colors.transparent, // Lighter blue
                              borderRadius: const BorderRadius.only( topRight: Radius.circular(7), bottomRight: Radius.circular(7),),
                            ),
                            child: Text(
                              'Back',
                              style: textTheme.labelMedium?.copyWith(
                                color: !isFront ? Colors.blue[700] : Colors.grey[700], // Darker blue text
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ), // End Instructions/Toggle Padding

          // --- Add Spot Button (Remains at very bottom) ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0), // Reduced top padding slightly
            child: ElevatedButton(
              child: const Text('Add spot'),
              onPressed: isMarkerPlaced ? () async {
                final coords = ref.read(_markersStateProvider)[currentSide] ?? MarkerData.empty;
                final side = currentSide;

                if (coords.normX != null && coords.normY != null) {
                  print("Proceeding to camera. Coords: (${coords.normX}, ${coords.normY}), Side: $side");
                  final result = await context.push<Map<String, dynamic>>(
                      AppRoutes.cameraScreen,
                      extra: { 'x': coords.normX, 'y': coords.normY, 'side': side, }
                  );

                  // Handle result
                  if (result != null && context.mounted) {
                    final String? filePath = result['filePath'] as String?;
                    final double? resultX = result['normX'] as double?;
                    final double? resultY = result['normY'] as double?;
                    final BodySide? resultSide = result['bodySide'] as BodySide?;

                    if (filePath != null && resultX != null && resultY != null && resultSide != null) {
                      print("Received from Camera: Path=$filePath, Coords=($resultX, $resultY), Side=$resultSide");
                      await _saveScanAndLesion(ref, context, filePath, resultX, resultY, resultSide);
                    } else {
                      print("Camera returned invalid data.");
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to get data from camera."), backgroundColor: Colors.red));
                    }
                  } else if (context.mounted) {
                    print("Camera screen popped without returning data.");
                  }

                } else {
                  print("Error: Marker data (normX/normY) is missing despite button being enabled.");
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Internal Error: Marker location data missing."), backgroundColor: Colors.red));
                }
              } : null, // Disable button if no marker placed
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  // Match button color from reference image (adjust if needed)
                  backgroundColor: isMarkerPlaced ? Colors.blue[600] : Colors.blue[300], // Example: Slightly lighter blue when disabled
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.blue[200], // Lighter blue when disabled
                  disabledForegroundColor: Colors.white.withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
              ).copyWith(
                elevation: MaterialStateProperty.resolveWith<double>(
                      (Set<MaterialState> states) {
                    if (states.contains(MaterialState.disabled)) { return 0; }
                    return 2; // Default elevation
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- useTransformationController Hook ---
TransformationController useTransformationController([Matrix4? initialValue]) {
  final controller = useMemoized(() => TransformationController(initialValue), [initialValue]);
  useEffect(() {
    return controller.dispose;
  }, [controller]);
  return controller;
}