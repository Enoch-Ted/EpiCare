//lib/features/scan/screens/scan_screen.dart
import 'dart:io';
// Import constants and aliases
import 'package:care/core/constants/app_constants.dart' as app_const;

// Import database entities and providers
import 'package:care/core/database/entities/scan.dart';
// MODIFIED: Import BodySide enum FROM lesion.dart, and Lesion entity
import 'package:care/core/database/entities/lesion.dart' show Lesion, BodySide; // BodySide from lesion.dart
import 'package:care/core/providers/database_providers.dart'; // Ensure this exports lesionByIdProvider
import 'package:care/core/ai/model_handler.dart' show  AiPipelineResult;
// Import navigation
import 'package:care/core/navigation/app_router.dart';

// Flutter and Riverpod/Hooks imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
// AI related imports
import 'package:care/core/ai/model_handler.dart'; // Import ModelHandler and AiPipelineResult
import '../../../core/providers/ai_providers.dart'; // Provides ModelHandler

// Utility/Helper imports
import 'dart:math' as math; // Use math alias
import 'package:image/image.dart' as img; // Alias img for image processing

// Import other providers if needed (e.g., security)
import '../../../core/providers/security_providers.dart';


// --- State Providers (Use BodySide from lesion.dart) ---

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

// MODIFIED: Use BodySide (imported from lesion.dart) for map keys
final _isScanViewFrontProvider = StateProvider<bool>((ref) => true);
final _markersStateProvider = StateProvider<Map<BodySide, MarkerData>>(
        (ref) => { BodySide.Front: MarkerData.empty, BodySide.Back: MarkerData.empty });

// --- Image Data Provider (Use BodySide from lesion.dart) ---
final _bodyImageDataProvider = FutureProvider.autoDispose<Map<BodySide, img.Image?>>((ref) async {
  print("Loading body map image data for boundary check...");
  try {
    final frontBytes = await rootBundle.load(app_const.AssetPaths.bodyMapFront);
    final backBytes = await rootBundle.load(app_const.AssetPaths.bodyMapBack);
    final frontImage = await Future(() => img.decodePng(frontBytes.buffer.asUint8List()));
    final backImage = await Future(() => img.decodePng(backBytes.buffer.asUint8List()));
    print("Body map image data loaded successfully.");
    return { BodySide.Front: frontImage, BodySide.Back: backImage };
  } catch (e) {
    print("Error loading body map image data: $e");
    return { BodySide.Front: null, BodySide.Back: null };
  }
});


// --- Screen Widget ---
class ScanScreen extends HookConsumerWidget {
  const ScanScreen({super.key});

  bool _isTapInsideBodyOutline(img.Image? bodyImageData, double normX, double normY) { /* ... no change ... */
    if (bodyImageData == null || normX < 0.0 || normX > 1.0 || normY < 0.0 || normY > 1.0) return false;
    final imgWidth = bodyImageData.width; final imgHeight = bodyImageData.height;
    final pixelX = (normX * imgWidth).floor().clamp(0, imgWidth - 1);
    final pixelY = (normY * imgHeight).floor().clamp(0, imgHeight - 1);
    try {
      final pixel = bodyImageData.getPixel(pixelX, pixelY);
      final r = pixel.r.toInt(); final g = pixel.g.toInt(); final b = pixel.b.toInt(); final a = pixel.a.toInt();
      const int whiteR = 255, whiteG = 255, whiteB = 255, opaqueA = 255;
      bool isBackground = (r == whiteR && g == whiteG && b == whiteB && a == opaqueA);
      return !isBackground;
    } catch (e) { print("Error checking pixel at ($pixelX, $pixelY): $e"); return false; }
  }

  // --- _saveScanAndLesion Method (SIMPLIFIED for Binary Classification on FULL IMAGE ONLY) ---
  Future<void> _saveScanAndLesion(WidgetRef ref, BuildContext context, String originalImagePath, double normX, double normY, BodySide bodySide) async {
    final currentUser = ref.read(currentUserProvider);
    final scanDao = ref.read(scanDaoProvider);
    final lesionDao = ref.read(lesionDaoProvider);
    final modelHandler = ref.read(modelHandlerProvider);

    if (currentUser == null || currentUser.userId == null) { /* ... error handling ... */ return; }
    if (!modelHandler.isLoaded) { /* ... error handling ... */ return; } // isLoaded now reflects binary classifier

    if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saving scan and analyzing image..."), duration: Duration(seconds: 6))); }

    int? newScanId;
    Lesion? initialLesion;
    // imagePathForDb will remain originalImagePath as we are not cropping
    // String imagePathForDb = originalImagePath; // Not needed if not saving cropped

    try {
      final newScan = Scan( userId: currentUser.userId!, imagePath: originalImagePath, scanDate: DateTime.now());
      newScanId = await scanDao.insertScan(newScan);
      if (newScanId == null || newScanId <= 0) throw Exception("Failed to insert Scan record.");
      print("Saved Scan with ID: $newScanId (image path: $originalImagePath)");

      initialLesion = Lesion(
          scanId: newScanId,
          riskLevel: app_const.RiskLevel.Undetermined.name,
          lesionType: "Pending Analysis",
          confidenceScore: 0.0,
          bodyMapX: normX, bodyMapY: normY,
          bodySide: bodySide
      );
      int? initialLesionId = await lesionDao.insertLesion(initialLesion);
      if (initialLesionId == null || initialLesionId <= 0) throw Exception("Failed to insert initial Lesion record.");
      initialLesion = initialLesion.copyWith(lesionId: initialLesionId);
      print("Saved initial Lesion with ID: $initialLesionId (Status: Pending Analysis)");

      Uint8List fullImageBytes = await File(originalImagePath).readAsBytes();
      print(">>> Starting AI Analysis (Binary Classification on Full Image) for: $originalImagePath");

      // ModelHandler.detectAndClassifyLesion now effectively just classifies the full image
      final AiPipelineResult aiResult = await modelHandler.detectAndClassifyLesion(fullImageBytes);

      Lesion? finalLesionUpdate;
      String finalMessage;
      Color feedbackColor;

      if (aiResult.classificationResults != null && aiResult.classificationResults!.isNotEmpty) {
        final topClassification = aiResult.classificationResults!.first;
        final mappedRisk = app_const.getRiskLevelFromLesionType(topClassification.label);

        print("AI Pipeline: Classified FULL image as ${topClassification.label} (Conf: ${topClassification.confidence.toStringAsFixed(4)})");
        finalMessage = "Scan saved. Image classified: ${topClassification.label}";
        feedbackColor = Colors.green; // Successful classification

        finalLesionUpdate = initialLesion.copyWith(
          lesionType: topClassification.label,
          confidenceScore: topClassification.confidence,
          riskLevel: mappedRisk.name,
        );
      } else {
        // Classification itself failed
        print("AI Pipeline: Binary classification on full image failed.");
        finalMessage = "Scan saved. AI analysis encountered an error.";
        feedbackColor = Colors.red;
        finalLesionUpdate = initialLesion.copyWith(lesionType: "Classification Failed", riskLevel: app_const.RiskLevel.Undetermined.name);
      }

      // Update Lesion Record
      if (initialLesion.lesionId != null && finalLesionUpdate != null) {
        await lesionDao.updateLesion(finalLesionUpdate);
        print("Lesion record ${initialLesion.lesionId} updated with: ${finalLesionUpdate.lesionType}");
      } else {
        print("Failed to prepare final lesion update or initial lesion ID was null.");
        if (initialLesion.lesionId != null && initialLesion.lesionType == "Pending Analysis") {
          await lesionDao.updateLesion(initialLesion.copyWith(lesionType: "Analysis Failed", riskLevel: app_const.RiskLevel.Undetermined.name));
        }
      }

      // UI Feedback & Navigation
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(finalMessage), backgroundColor: feedbackColor, duration: const Duration(seconds: 5)));
        ref.invalidate(userScansProvider); ref.invalidate(allUserLesionsProvider); ref.invalidate(userLesionCountsProvider);
        if (newScanId != null) { ref.invalidate(scanByIdProvider(newScanId)); ref.invalidate(lesionsByScanIdProvider(newScanId)); }
        if (initialLesion.lesionId != null) { ref.invalidate(lesionByIdProvider(initialLesion.lesionId!)); }
        if (newScanId != null) { context.go(AppRoutes.scanDetail.replaceFirst(':scanId', newScanId.toString())); }
        else { context.go(AppRoutes.history); }
      }
    } catch (e, stackTrace) {
      // ... (existing critical error handling) ...
      print("Critical Error during AI pipeline or saving: $e"); print(stackTrace);
      if (newScanId != null && initialLesion?.lesionId != null && initialLesion?.lesionType == "Pending Analysis") {
        try { await lesionDao.updateLesion(initialLesion!.copyWith(lesionType: "Analysis Pipeline Failed", riskLevel: app_const.RiskLevel.Undetermined.name, confidenceScore: 0.0));
        } catch (updateError) { print("Error updating initial lesion after critical failure: $updateError"); }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text("Critical error during analysis: ${e.toString()}. Scan saved with failure status."), backgroundColor: Colors.red) );
          context.go(AppRoutes.scanDetail.replaceFirst(':scanId', newScanId.toString()));
        }
      } else {
        if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text("Failed to save scan: ${e.toString()}"), backgroundColor: Colors.red) ); }
        context.go(AppRoutes.history);
      }
    }
  }

  // ... (useTransformationController and build method remain the same as your last working version) ...
  TransformationController useTransformationController([Matrix4? initialValue]) {
    final controller = useMemoized(() => TransformationController(initialValue), [initialValue]);
    useEffect(() { return controller.dispose; }, [controller]);
    return controller;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFront = ref.watch(_isScanViewFrontProvider);
    final isScanViewFrontNotifier = ref.read(_isScanViewFrontProvider.notifier);
    final allMarkersData = ref.watch(_markersStateProvider);
    final currentSide = isFront ? BodySide.Front : BodySide.Back; // Uses BodySide from lesion.dart
    final currentMarkerData = allMarkersData[currentSide] ?? MarkerData.empty;

    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bodyImageDataAsync = ref.watch(_bodyImageDataProvider);

    final innerStackKey = useMemoized(() => GlobalKey(), const []);
    final frontTransformationController = useTransformationController();
    final backTransformationController = useTransformationController();
    final activeTransformationController = isFront ? frontTransformationController : backTransformationController;

    const double frontAspectRatio = 631 / 1500;
    const double backAspectRatio = 630 / 1494;
    final double currentAspectRatio = isFront ? frontAspectRatio : backAspectRatio;

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        if (isFront) { if (backTransformationController.value != Matrix4.identity()) { backTransformationController.value = Matrix4.identity(); } }
        else { if (frontTransformationController.value != Matrix4.identity()) { frontTransformationController.value = Matrix4.identity(); } }
      });
      return null;
    }, [isFront, frontTransformationController, backTransformationController]);

    final bool isMarkerPlaced = currentMarkerData.normX != null && currentMarkerData.normY != null;
    final bool aiModelsLoaded = ref.watch(modelHandlerProvider).isLoaded; // This now reflects binary classifier readiness

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 1,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () { if (context.canPop()) context.pop(); }),
        title: const Text('Mark New Spot', style: TextStyle(color: Colors.black, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth; final availableHeight = constraints.maxHeight;
                      double renderWidth, renderHeight, initialOffsetX = 0, initialOffsetY = 0;
                      if (availableWidth <= 0 || availableHeight <= 0) { return const Center(child: Text("Calculating layout...")); }
                      if (availableWidth / availableHeight > currentAspectRatio) { renderHeight = availableHeight; renderWidth = availableHeight * currentAspectRatio; initialOffsetX = (availableWidth - renderWidth) / 2; initialOffsetY = 0; }
                      else { renderWidth = availableWidth; renderHeight = availableWidth / currentAspectRatio; initialOffsetX = 0; initialOffsetY = (availableHeight - renderHeight) / 2; }
                      initialOffsetX = math.max(0, initialOffsetX); initialOffsetY = math.max(0, initialOffsetY);
                      final Size imageSize = Size(renderWidth, renderHeight);
                      final Offset imageOffset = Offset(initialOffsetX, initialOffsetY);
                      final currentBodyImageData = bodyImageDataAsync.when( data: (dataMap) => dataMap[currentSide], loading: () => null, error: (err, stack) => null );

                      return Stack(
                        key: innerStackKey, alignment: Alignment.topLeft, clipBehavior: Clip.none,
                        children: [
                          InteractiveViewer(
                            transformationController: activeTransformationController,
                            minScale: 1.0, maxScale: 5.0, clipBehavior: Clip.none,
                            child: GestureDetector(
                              onTapUp: (details) {
                                final RenderBox? ivRenderBox = context.findRenderObject() as RenderBox?;
                                if (ivRenderBox == null || !ivRenderBox.hasSize || imageSize.isEmpty) { print("Skipping tap: IV RenderBox info not ready."); return; }
                                final Offset localTapPosition = ivRenderBox.globalToLocal(details.globalPosition);
                                final Matrix4 invertedMatrix = activeTransformationController.value.clone()..invert();
                                final Offset transformedTapPosition = MatrixUtils.transformPoint(invertedMatrix, localTapPosition);
                                final Offset tapRelativeToImageOrigin = transformedTapPosition - imageOffset;
                                final double normX = (tapRelativeToImageOrigin.dx / imageSize.width);
                                final double normY = (tapRelativeToImageOrigin.dy / imageSize.height);

                                bool isInside = _isTapInsideBodyOutline(currentBodyImageData, normX, normY);
                                if (isInside) {
                                  final newMarkerData = MarkerData(normX: normX.clamp(0.0, 1.0), normY: normY.clamp(0.0, 1.0));
                                  ref.read(_markersStateProvider.notifier).update((state) {
                                    final newState = Map<BodySide, MarkerData>.from(state);
                                    newState[currentSide] = newMarkerData;
                                    return newState;
                                  });
                                  print("Marker data updated: Norm(${normX.toStringAsFixed(4)}, ${normY.toStringAsFixed(4)}), Side: $currentSide");
                                } else {
                                  if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please tap inside the body outline."), duration: Duration(seconds: 1), backgroundColor: Colors.orangeAccent)); }
                                }
                              },
                              child: Stack(
                                alignment: Alignment.topLeft, clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    left: imageOffset.dx, top: imageOffset.dy, width: imageSize.width, height: imageSize.height,
                                    child: Image.asset(isFront ? app_const.AssetPaths.bodyMapFront : app_const.AssetPaths.bodyMapBack, fit: BoxFit.contain, gaplessPlayback: true),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isMarkerPlaced)
                            ValueListenableBuilder<Matrix4>(
                              valueListenable: activeTransformationController,
                              builder: (context, matrix, child) {
                                final currentNormX = currentMarkerData.normX; final currentNormY = currentMarkerData.normY;
                                if (currentNormX == null || currentNormY == null || imageSize.isEmpty) return const SizedBox.shrink();
                                final Offset pointOnImage = Offset(currentNormX * imageSize.width, currentNormY * imageSize.height);
                                final Offset pointInInnerStack = pointOnImage + imageOffset;
                                final Offset pointOnScreen = MatrixUtils.transformPoint(matrix, pointInInnerStack);
                                const double markerSize = 24.0;
                                final double markerLeft = pointOnScreen.dx - (markerSize / 2);
                                final double markerTop = pointOnScreen.dy - markerSize;
                                return Positioned(left: markerLeft, top: markerTop, child: IgnorePointer(child: Icon(Icons.location_on, color: Colors.red.withOpacity(0.9), size: markerSize, shadows: const [Shadow(blurRadius: 1.0, color: Colors.black54)])));
                              },
                            ),
                          Positioned.fill(
                            child: bodyImageDataAsync.when(
                              data: (dataMap) => (dataMap[currentSide] == null && bodyImageDataAsync.hasValue) ? Center(child: Text('Error loading map data.', style: TextStyle(color: Colors.red[700]))) : const SizedBox.shrink(),
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (err, stack) => Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Error loading map data: ${err.toString()}', style: TextStyle(color: Colors.red[700]), textAlign: TextAlign.center))),
                            ),
                          ),
                          if (!aiModelsLoaded && bodyImageDataAsync.isLoading == false)
                            Positioned.fill(
                                child: Container(
                                    color: Colors.black54,
                                    child: const Center(
                                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text("Loading AI models...", style: TextStyle(color: Colors.white))])))),
                        ],
                      );
                    }
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Add a new spot by tapping on the body", style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700]), textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search, color: Colors.grey[600], size: 18), const SizedBox(width: 4), Text("Pinch to zoom in", style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]))]),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(onTap: () { if (!isFront) { isScanViewFrontNotifier.state = true; } }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: isFront ? Colors.lightBlue[100] : Colors.transparent, borderRadius: const BorderRadius.only(topLeft: Radius.circular(7), bottomLeft: Radius.circular(7))), child: Text('Front', style: textTheme.labelMedium?.copyWith(color: isFront ? Colors.blue[700] : Colors.grey[700], fontWeight: FontWeight.w500)))),
                        Container(width: 1, height: 30, color: Colors.grey[350]),
                        InkWell(onTap: () { if (isFront) { isScanViewFrontNotifier.state = false; } }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: !isFront ? Colors.lightBlue[100] : Colors.transparent, borderRadius: const BorderRadius.only(topRight: Radius.circular(7), bottomRight: Radius.circular(7))), child: Text('Back', style: textTheme.labelMedium?.copyWith(color: !isFront ? Colors.blue[700] : Colors.grey[700], fontWeight: FontWeight.w500)))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            child: ElevatedButton(
              onPressed: isMarkerPlaced && aiModelsLoaded ? () async {
                final coords = ref.read(_markersStateProvider)[currentSide] ?? MarkerData.empty;
                final BodySide sideForPipeline = isFront ? BodySide.Front : BodySide.Back;

                if (coords.normX != null && coords.normY != null) {
                  print("Proceeding to camera. Coords: (${coords.normX}, ${coords.normY}), Side: ${sideForPipeline.name}");
                  final result = await context.push<Map<String, dynamic>>(AppRoutes.cameraScreen, extra: { 'x': coords.normX, 'y': coords.normY, 'side': sideForPipeline.name });
                  if (result != null && context.mounted) {
                    final String? filePath = result['filePath'] as String?;
                    if (filePath != null) {
                      print("Received image path from Camera: $filePath");
                      await _saveScanAndLesion(ref, context, filePath, coords.normX!, coords.normY!, sideForPipeline);
                    } else {
                      if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to capture image."), backgroundColor: Colors.red)); }
                    }
                  } else if (context.mounted) {
                    print("Camera screen popped without returning data.");
                  }
                } else {
                  if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Internal Error: Marker location data missing."), backgroundColor: Colors.red)); }
                }
              } : null,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: (isMarkerPlaced && aiModelsLoaded) ? colors.primary : colors.primaryContainer,
                  foregroundColor: (isMarkerPlaced && aiModelsLoaded) ? colors.onPrimary : colors.onPrimaryContainer.withOpacity(0.8),
                  disabledBackgroundColor: colors.primaryContainer,
                  disabledForegroundColor: colors.onPrimaryContainer.withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
              ).copyWith(elevation: MaterialStateProperty.resolveWith<double>((Set<MaterialState> states) => states.contains(MaterialState.disabled) ? 0 : 2)),
              child: aiModelsLoaded ? const Text('Add spot') : const Text('Loading AI...'),
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
  return controller;}