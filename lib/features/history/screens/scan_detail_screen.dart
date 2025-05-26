//lib/features/history/screens/scan_detail_screen.dart
import 'dart:io';
import 'dart:typed_data';

// Import necessary constants and aliases
import 'package:care/core/constants/app_constants.dart' as app_const;
// Import specific enums/classes/functions using show with the alias for clarity and to avoid ambiguity
// This ensures we use app_const.RiskLevel, app_const.BodySide etc.
import 'package:care/core/constants/app_constants.dart' show BodySide, RiskLevel, LesionRiskInfo, lesionRiskDetails, getRiskLevelFromLesionType;

// Import database entities and providers
import 'package:care/core/database/entities/scan.dart';
import 'package:care/core/database/entities/lesion.dart'; // Keep Lesion entity import
import 'package:care/core/providers/database_providers.dart';

// Import navigation
import 'package:care/core/navigation/app_router.dart';

// Flutter and Riverpod/Hooks imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

// Date formatting
import 'package:intl/intl.dart';

// For PDF generation and sharing
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// Import other providers if needed (e.g., security)
// import '../../../core/providers/security_providers.dart'; // Uncomment if needed elsewhere


// --- State Provider for Rename Dialog ---
// This is local to the file and used for the rename dialog text field state.
final _renameScanTextProvider = StateProvider<String>((ref) => '');


class ScanDetailScreen extends ConsumerWidget { // Use ConsumerWidget
  final int scanId;

  const ScanDetailScreen({required this.scanId, super.key});

  // Helper to build detail items consistently
  Widget _buildDetailRow(String label, String value, BuildContext context, {TextStyle? valueStyle}) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // Consistent width for labels
            child: Text(
              '$label:', // Added colon for consistency
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: valueStyle ?? textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  // --- Rename Scan Dialog & Logic ---
  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref, Scan currentScan) async {
    // Initialize dialog controller with current name
    final renameController = TextEditingController(text: currentScan.scanName ?? '');
    // Initialize provider with current name for dialog state management
    ref.read(_renameScanTextProvider.notifier).state = currentScan.scanName ?? '';

    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) {
        // AlertDialog for renaming
        return AlertDialog(
          title: const Text("Rename Scan"),
          content: Consumer( // Use Consumer to watch the provider inside the dialog
              builder: (context, ref, child) {
                return TextFormField(
                  controller: renameController,
                  autofocus: true, // Automatically focus the text field
                  decoration: const InputDecoration(hintText: "Enter new scan name"),
                  // Update the provider whenever the text changes
                  onChanged: (value) => ref.read(_renameScanTextProvider.notifier).state = value,
                );
              }
          ),
          actions: [
            // Cancel Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(null), // Pop with null to indicate cancellation
              child: const Text("Cancel"),
            ),
            // Save Button
            TextButton(
              onPressed: () {
                // Get the final value from the provider when save is pressed
                final nameToSave = ref.read(_renameScanTextProvider);
                if (nameToSave.trim().isNotEmpty) {
                  Navigator.of(context).pop(nameToSave.trim()); // Pop with the new name
                } else {
                  // Optional: Show validation message within the dialog
                  if (context.mounted) { // Check context is still valid
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Name cannot be empty."), backgroundColor: Colors.orange)
                    );
                  }
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    // --- Handle Result from Dialog ---
    if (newName != null && newName.isNotEmpty && context.mounted) { // Check context is still valid
      print("Attempting to rename scan $scanId to '$newName'");
      final scanDao = ref.read(scanDaoProvider); // Get the Scan DAO
      final updatedScan = currentScan.copyWith(scanName: newName);
      try {
        final count = await scanDao.updateScan(updatedScan);
        if (count > 0) {
          print("Scan renamed successfully.");
          ref.invalidate(scanByIdProvider(scanId));
          ref.invalidate(userScansProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Scan renamed."), backgroundColor: Colors.green)
            );
          }
        } else {
          throw Exception("Update returned 0 rows affected. Scan might not exist.");
        }
      } catch (e) {
        print("Error renaming scan: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error renaming scan: ${e.toString()}"), backgroundColor: Theme.of(context).colorScheme.error)
          );
        }
      }
    } else {
      print("Scan rename cancelled or empty name provided.");
    }
  } // End _showRenameDialog


  // --- Delete Confirmation Helper ---
  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final Scan? currentScan = ref.read(scanByIdProvider(scanId)).asData?.value;
    final String scanNameToDelete = currentScan?.scanName ?? "this scan (ID: $scanId)";

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Scan?'),
          content: Text('Are you sure you want to permanently delete "$scanNameToDelete" and its associated lesions? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      print("User confirmed deletion for scan $scanId");
      try {
        final scanDao = ref.read(scanDaoProvider);
        final deletedCount = await scanDao.deleteScanById(scanId);

        if (deletedCount > 0 && context.mounted) {
          print("Scan $scanId deleted successfully.");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Scan deleted successfully"), backgroundColor: Colors.green),
          );
          ref.invalidate(userScansProvider);
          ref.invalidate(scanByIdProvider(scanId));
          ref.invalidate(lesionsByScanIdProvider(scanId));
          GoRouter.of(context).pop();
        } else if (context.mounted){
          print("Scan $scanId not found in DB during delete or delete failed (deletedCount: $deletedCount).");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text("Could not delete scan (already deleted or error)."), backgroundColor: Theme.of(context).colorScheme.error),
          );
          if (context.canPop()) context.pop();
        }
      } catch (e) {
        print("Error during deletion process: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error deleting scan: ${e.toString()}"), backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      }
    } else {
      print("Deletion cancelled for scan $scanId");
    }
  }


  // --- PDF Generation and Sharing Logic ---
  Future<void> _generateAndShareReport(BuildContext context, Scan scan, Lesion analyzedLesion, app_const.RiskLevel lesionRiskLevel) async {
    if (scan.scanId == null || analyzedLesion.lesionId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Report cannot be generated without analysis data."), backgroundColor: Colors.orangeAccent),
        );
      }
      return;
    }

    if (analyzedLesion.lesionType == "Pending Analysis" ||
        analyzedLesion.lesionType == "Unknown" ||
        analyzedLesion.lesionType == "Analysis Failed" ||
        analyzedLesion.lesionType == "Cropping Failed" ||
        analyzedLesion.lesionType == "Classification Failed" ||
        analyzedLesion.lesionType == "No Lesion Detected" ||
        analyzedLesion.lesionType == "Analysis Pipeline Failed"
    )
    {
      print("Attempted to generate report for incomplete/failed analysis status: ${analyzedLesion.lesionType}");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Analysis status is '${analyzedLesion.lesionType}'. Cannot generate a complete report."), backgroundColor: Colors.orangeAccent),
        );
      }
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Generating Report..."), duration: Duration(seconds: 2)),
      );
    }

    final pdf = pw.Document();
    final formattedDate = DateFormat.yMMMMd('en_US').add_jm().format(scan.scanDate.toLocal());
    final app_const.LesionRiskInfo? riskInfo = app_const.lesionRiskDetails[lesionRiskLevel];

    Uint8List? imageBytes;
    try {
      if (File(scan.imagePath).existsSync()) {
        imageBytes = await File(scan.imagePath).readAsBytes();
      }
    } catch (e) {
      print("Error loading image for PDF: $e");
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context pdfContext) {
          List<pw.Widget> pdfWidgets = [];

          pdfWidgets.add(pw.Center(child: pw.Text(scan.scanName ?? 'EpiCare Scan Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))));
          pdfWidgets.add(pw.SizedBox(height: 20));
          pdfWidgets.add(pw.Text('Scan Details', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)));
          pdfWidgets.add(pw.Divider());
          pdfWidgets.add(_buildPdfDetailRow('Scan Date', formattedDate, pdfContext));
          pdfWidgets.add(_buildPdfDetailRow('Body Location', '${analyzedLesion.bodySide ?? 'N/A'} view (X: ${analyzedLesion.bodyMapX?.toStringAsFixed(2) ?? 'N/A'}, Y: ${analyzedLesion.bodyMapY?.toStringAsFixed(2) ?? 'N/A'})', pdfContext));
          pdfWidgets.add(pw.SizedBox(height: 20));

          if (imageBytes != null) {
            pdfWidgets.add(pw.Text('Scanned Image', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)));
            pdfWidgets.add(pw.SizedBox(height: 8));
            pdfWidgets.add(pw.Center(child: pw.Image(pw.MemoryImage(imageBytes), height: 300)));
            pdfWidgets.add(pw.SizedBox(height: 20));
          }

          pdfWidgets.add(pw.Text('AI Analysis Results', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)));
          pdfWidgets.add(pw.Divider());
          pdfWidgets.add(_buildPdfDetailRow('Overall Prediction', lesionRiskLevel.name, pdfContext));

          // ADDED: Confidence Score to PDF report
          if (analyzedLesion.confidenceScore != null && analyzedLesion.confidenceScore! > 0) {
            pdfWidgets.add(_buildPdfDetailRow('Confidence', '${(analyzedLesion.confidenceScore! * 100).toStringAsFixed(1)}%', pdfContext));
          }

          pdfWidgets.add(pw.SizedBox(height: 20));
          pdfWidgets.add(pw.Text('Guidance:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)));
          pdfWidgets.add(pw.Divider());
          pdfWidgets.add(pw.Text(
            riskInfo?.description ?? "No specific guidance available based on current data.",
            style: const pw.TextStyle(fontSize: 12),
          ));
          pdfWidgets.add(pw.SizedBox(height: 24));
          pdfWidgets.add(pw.Spacer());
          pdfWidgets.add(pw.Center(
            child: pw.Text(
              'Generated by EpiCare App. This report is based on AI analysis and should not replace professional medical advice.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
              textAlign: pw.TextAlign.center,
            ),
          ));

          return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: pdfWidgets);
        },
      ),
    );

    try {
      final output = await getTemporaryDirectory();
      final safeScanName = scan.scanName?.replaceAll(RegExp(r'[^\w\s-]'), '') ?? 'scan';
      final fileName = '${safeScanName.replaceAll(' ', '_')}_report_${scan.scanDate.millisecondsSinceEpoch}.pdf';
      final file = File("${output.path}/$fileName");
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) {
        await Share.shareXFiles([XFile(file.path)], text: 'EpiCare Scan Report');
      }
    } catch (e, stackTrace) {
      print('Error generating or sharing PDF: $e');
      print(stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating/sharing report: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Helper for PDF detail row
  pw.Row _buildPdfDetailRow(String label, String value, pw.Context context) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(width: 120, child: pw.Text('$label:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(width: 8),
        pw.Expanded(child: pw.Text(value)),
      ],
    );
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Scan?> scanAsyncValue = ref.watch(scanByIdProvider(scanId));
    final AsyncValue<List<Lesion>> lesionsAsyncValue = ref.watch(lesionsByScanIdProvider(scanId));

    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;

    final Scan? currentScanData = scanAsyncValue.asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentScanData?.scanName ?? 'Scan Details'),
        actions: [
          if (currentScanData != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Rename Scan',
              onPressed: () => _showRenameDialog(context, ref, currentScanData),
            ),

          // --- Share button logic using collection if ---
          // CORRECTED: AppBar actions conditional logic
          if (currentScanData != null &&
              lesionsAsyncValue.asData?.value != null &&
              lesionsAsyncValue.asData!.value.isNotEmpty)
            Builder( // Use Builder to ensure conditions are evaluated correctly within list context
              builder: (context) {
                final Lesion potentialAnalyzedLesion = lesionsAsyncValue.asData!.value.first;
                final bool isAnalysisCompleteAndSuccessful =
                    potentialAnalyzedLesion.lesionType != "Pending Analysis" &&
                        potentialAnalyzedLesion.lesionType != "Unknown" &&
                        potentialAnalyzedLesion.lesionType != "Analysis Failed" &&
                        potentialAnalyzedLesion.lesionType != "Cropping Failed" &&
                        potentialAnalyzedLesion.lesionType != "Classification Failed" &&
                        potentialAnalyzedLesion.lesionType != "No Lesion Detected" &&
                        potentialAnalyzedLesion.lesionType != "Analysis Pipeline Failed";

                if (isAnalysisCompleteAndSuccessful) {
                  final app_const.RiskLevel lesionRiskLevel = app_const.getRiskLevelFromLesionType(potentialAnalyzedLesion.lesionType ?? "Unknown");
                  return IconButton(
                    icon: const Icon(Icons.share),
                    tooltip: 'Share Report',
                    onPressed: () {
                      _generateAndShareReport(context, currentScanData!, potentialAnalyzedLesion, lesionRiskLevel);
                    },
                  );
                }
                return const SizedBox.shrink(); // Return an empty widget if conditions not met
              },
            ),

          if (currentScanData != null)
            IconButton(
              icon: Icon(Icons.delete_outline, color: colors.error),
              tooltip: 'Delete Scan',
              onPressed: () => _confirmAndDelete(context, ref),
            ),
          const SizedBox(width: 8),
        ].whereType<Widget>().toList(), // Filter out SizedBox.shrink or other non-widgets
      ),
      body: scanAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error loading scan details: ${err.toString()}', textAlign: TextAlign.center, style: TextStyle(color: colors.error)),
        )),
        data: (scan) {
          if (scan == null) {
            return const Center(child: Text('Scan not found. It may have been deleted.'));
          }

          final Lesion? analyzedLesion = (lesionsAsyncValue.asData?.value != null && lesionsAsyncValue.asData!.value.isNotEmpty)
              ? lesionsAsyncValue.asData!.value.first
              : null;

          final formattedDate = DateFormat.yMMMMd('en_US').add_jm().format(scan.scanDate.toLocal());

          String overallPredictionDisplay = "Analysis Pending / Unknown";
          String confidenceDisplay = "N/A";
          String locationDisplay = "N/A";
          String adviceText = "Loading AI analysis results or no data available...";
          Color predictionColor = colors.onSurfaceVariant;
          FontWeight predictionFontWeight = FontWeight.normal;
          app_const.RiskLevel lesionRiskLevelEnum = app_const.RiskLevel.Undetermined;

          if (analyzedLesion != null) {
            lesionRiskLevelEnum = app_const.getRiskLevelFromLesionType(analyzedLesion.lesionType ?? "Unknown");
            final app_const.LesionRiskInfo? riskInfo = app_const.lesionRiskDetails[lesionRiskLevelEnum];

            if (lesionRiskLevelEnum == app_const.RiskLevel.Malignant) {
              overallPredictionDisplay = lesionRiskLevelEnum.name;
              predictionColor = colors.error;
              predictionFontWeight = FontWeight.bold;
            } else if (lesionRiskLevelEnum == app_const.RiskLevel.Benign) {
              overallPredictionDisplay = lesionRiskLevelEnum.name; // This was the typo
              predictionColor = Colors.green.shade700;
              predictionFontWeight = FontWeight.bold;
            } else {
              overallPredictionDisplay = analyzedLesion.lesionType ?? "Analysis Status Unknown";
            }

            // Display confidence if analysis was Benign or Malignant and score is valid
            if ((lesionRiskLevelEnum == app_const.RiskLevel.Benign || lesionRiskLevelEnum == app_const.RiskLevel.Malignant) &&
                analyzedLesion.confidenceScore != null && analyzedLesion.confidenceScore! > 0) {
              confidenceDisplay = "${(analyzedLesion.confidenceScore! * 100).toStringAsFixed(1)}%";
            } else {
              confidenceDisplay = "N/A"; // Set to N/A if not Benign/Malignant or no score
            }


            if (riskInfo != null) {
              adviceText = riskInfo.description;
            } else {
              adviceText = "No specific guidance available for this analysis result. Please consult a healthcare professional.";
            }

            if (analyzedLesion.bodyMapX != null && analyzedLesion.bodyMapY != null) {
              locationDisplay = "${analyzedLesion.bodySide ?? 'N/A'} view "
                  "(X: ${analyzedLesion.bodyMapX!.toStringAsFixed(2)}, "
                  "Y: ${analyzedLesion.bodyMapY!.toStringAsFixed(2)})";
            }
          } else {
            overallPredictionDisplay = "No Analysis Data";
            adviceText = "No AI analysis data found for this scan.";
          }


          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scan.scanName ?? "Scan Details", style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text("Captured on: $formattedDate", style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(height: 20),

                Text("Scanned Image:", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11.0),
                    child: File(scan.imagePath).existsSync()
                        ? Image.file(File(scan.imagePath), fit: BoxFit.contain)
                        : Center(child: Icon(Icons.broken_image_outlined, size: 60, color: colors.onSurfaceVariant)),
                  ),
                ),
                const SizedBox(height: 24),

                Text("AI Analysis:", style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),

                _buildDetailRow(
                  "Prediction",
                  overallPredictionDisplay,
                  context,
                  valueStyle: textTheme.titleLarge?.copyWith(
                    color: predictionColor,
                    fontWeight: predictionFontWeight,
                  ),
                ),

                // --- ADDED BACK: Confidence Score Row (conditionally) ---
                if (analyzedLesion != null &&
                    analyzedLesion.confidenceScore != null && analyzedLesion.confidenceScore! > 0 &&
                    (lesionRiskLevelEnum == app_const.RiskLevel.Benign || lesionRiskLevelEnum == app_const.RiskLevel.Malignant)
                )
                  _buildDetailRow("Confidence", confidenceDisplay, context, valueStyle: textTheme.titleMedium),

                _buildDetailRow("Location", locationDisplay, context),

                // Message for other statuses
                if (analyzedLesion != null &&
                    lesionRiskLevelEnum == app_const.RiskLevel.Undetermined && // Simpler check
                    analyzedLesion.lesionType != null && // Ensure lesionType is not null
                    (analyzedLesion.lesionType != app_const.RiskLevel.Benign.name && analyzedLesion.lesionType != app_const.RiskLevel.Malignant.name) // Not Benign or Malignant
                )
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Center(child: Text(
                      "Analysis status: ${analyzedLesion.lesionType}", // Show the actual status string
                      style: textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: colors.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    )),
                  ),


                const SizedBox(height: 24),

                Text("Guidance:", style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
                  ),
                  child: Text(
                    adviceText,
                    style: textTheme.bodyLarge?.copyWith(height: 1.5, color: colors.onSurface),
                  ),
                ),
                const SizedBox(height: 24),

                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text("Generate Report (PDF)"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: textTheme.titleMedium,
                    ),
                    onPressed: currentScanData != null &&
                        analyzedLesion != null &&
                        analyzedLesion.lesionType != "Pending Analysis" &&
                        analyzedLesion.lesionType != "Unknown" &&
                        analyzedLesion.lesionType != "Analysis Failed" &&
                        analyzedLesion.lesionType != "Cropping Failed" &&
                        analyzedLesion.lesionType != "Classification Failed" &&
                        analyzedLesion.lesionType != "No Lesion Detected" &&
                        analyzedLesion.lesionType != "Analysis Pipeline Failed"
                        ? () {
                      _generateAndShareReport(context, currentScanData, analyzedLesion, lesionRiskLevelEnum); // Pass the derived enum
                    }
                        : null,
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}