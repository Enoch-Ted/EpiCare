// lib/features/history/screens/scan_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';

import 'package:care/core/providers/database_providers.dart';
import 'package:care/core/database/entities/scan.dart';
import 'package:care/core/database/entities/lesion.dart';
// import 'package:care/core/database/entities/user.dart'; // Potentially unused
import 'package:care/core/constants/app_constants.dart';
import 'package:care/core/navigation/app_router.dart';
// import 'package:care/core/providers/security_providers.dart'; // Potentially unused
// import 'package:care/core/ai/model_handler.dart'; // Not directly used by this screen

// State provider for rename dialog
final _renameScanTextProvider = StateProvider<String>((ref) => '');
enum ScanAction { rename, /* share, */ delete } // Share commented out as per your code

class ScanDetailScreen extends ConsumerWidget {
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
              label,
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

  // --- Dialog/Action Methods (Rename, Delete - assuming they are correct from your code) ---
  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref, Scan currentScan) async {
    final renameController = TextEditingController(text: currentScan.scanName ?? '');
    ref.read(_renameScanTextProvider.notifier).state = currentScan.scanName ?? '';

    final String? newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) { // Use dialogContext inside
        return AlertDialog(
          title: const Text("Rename Scan"),
          content: Consumer(builder: (context, ref, child) {
            return TextFormField(
              controller: renameController,
              autofocus: true,
              decoration: const InputDecoration(hintText: "Enter new scan name"),
              onChanged: (value) => ref.read(_renameScanTextProvider.notifier).state = value,
            );
          }),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(null), child: const Text("Cancel")),
            TextButton(
              onPressed: () {
                final nameToSave = ref.read(_renameScanTextProvider);
                if (nameToSave.trim().isNotEmpty) {
                  Navigator.of(dialogContext).pop(nameToSave.trim());
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text("Name cannot be empty."), backgroundColor: Colors.orange));
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty && context.mounted) {
      final scanDao = ref.read(scanDaoProvider);
      final updatedScan = currentScan.copyWith(scanName: newName);
      try {
        final count = await scanDao.updateScan(updatedScan);
        if (count > 0) {
          ref.invalidate(scanByIdProvider(scanId));
          ref.invalidate(userScansProvider); // To update lists elsewhere
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Scan renamed."), backgroundColor: Colors.green));
          }
        } else if (context.mounted) {
          throw Exception("Update returned 0 rows affected.");
        }
      } catch (e) {
        print("Error renaming scan: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Error renaming scan: $e"), backgroundColor: Theme.of(context).colorScheme.error));
        }
      }
    }
  }

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final Scan? currentScan = ref.read(scanByIdProvider(scanId)).asData?.value;
    final String scanNameToDelete = currentScan?.scanName ?? "this scan (ID: $scanId)";

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Scan?'),
          content: Text(
              'Are you sure you want to permanently delete "$scanNameToDelete" and its associated lesions? This action cannot be undone.'),
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
      try {
        final scanDao = ref.read(scanDaoProvider);
        final deletedCount = await scanDao.deleteScanById(scanId); // This should also delete related lesions via CASCADE
        if (deletedCount > 0 && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Scan deleted successfully"), backgroundColor: Colors.green),
          );
          ref.invalidate(userScansProvider);
          // No need to invalidate scanByIdProvider for a deleted scan, it will return null
          // lesionsByScanIdProvider will also return empty or error if scan is gone
          if (context.canPop()) context.pop(); else context.go(AppRoutes.history); // Go to history if cannot pop
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not delete scan (already deleted or error)."), backgroundColor: Colors.red),
          );
          if (context.canPop()) context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error deleting scan: $e"), backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      }
    }
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Scan?> scanAsyncValue = ref.watch(scanByIdProvider(scanId));
    // For a binary model, we expect one primary lesion object per scan storing the AI result.
    final AsyncValue<List<Lesion>> lesionsAsyncValue = ref.watch(lesionsByScanIdProvider(scanId));

    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Consumer(builder: (context, ref, _) { // Consumer for dynamic title
          final scanData = ref.watch(scanByIdProvider(scanId)).asData?.value;
          return Text(scanData?.scanName ?? 'Scan Details');
        }),
        actions: [
          Consumer(builder: (context, ref, _) { // Consumer for actions
            final scanData = ref.watch(scanByIdProvider(scanId)).asData?.value;
            if (scanData != null) {
              return PopupMenuButton<ScanAction>(
                icon: const Icon(Icons.more_vert),
                tooltip: "Options",
                onSelected: (ScanAction action) {
                  switch (action) {
                    case ScanAction.rename: _showRenameDialog(context, ref, scanData); break;
                    case ScanAction.delete: _confirmAndDelete(context, ref); break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<ScanAction>>[
                  const PopupMenuItem<ScanAction>(value: ScanAction.rename, child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Rename Scan'))),
                  const PopupMenuDivider(),
                  PopupMenuItem<ScanAction>(value: ScanAction.delete, child: ListTile(leading: Icon(Icons.delete_outline, color: colors.error), title: Text('Delete Scan', style: TextStyle(color: colors.error)))),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: scanAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error loading scan details: $err', textAlign: TextAlign.center, style: TextStyle(color: colors.error)),
        )),
        data: (scan) {
          if (scan == null) {
            return const Center(child: Text('Scan not found. It may have been deleted.'));
          }

          // Get the primary lesion associated with this scan's AI result.
          // This assumes that the lesions list for a scan will contain the AI-analyzed lesion,
          // typically as the first or only item.
          final Lesion? analyzedLesion = (lesionsAsyncValue.asData?.value != null && lesionsAsyncValue.asData!.value.isNotEmpty)
              ? lesionsAsyncValue.asData!.value.firstWhere(
                (l) => l.lesionType == "Benign" || l.lesionType == "Malignant", // Find the AI classified one
            orElse: () => lesionsAsyncValue.asData!.value.first, // Fallback to first
          )
              : null;

          final formattedDate = DateFormat.yMMMMd('en_US').add_jm().format(scan.scanDate.toLocal());

          // Determine advice text and color based on AI prediction
          String adviceText = "The AI analysis is complete. Please consult a dermatologist for a professional diagnosis and guidance regarding this scan.";
          Color predictionColor = colors.onSurface; // Default text color
          FontWeight predictionFontWeight = FontWeight.normal;

          if (analyzedLesion != null && (analyzedLesion.lesionType == "Benign" || analyzedLesion.lesionType == "Malignant")) {
            if (analyzedLesion.lesionType == 'Malignant') {
              adviceText = "AI Prediction: MALIGNANT\n\nThis finding suggests a potential malignancy and requires URGENT attention. Please consult a dermatologist or healthcare professional IMMEDIATELY for further evaluation, diagnosis, and treatment options.";
              predictionColor = colors.error; // Red for malignant
              predictionFontWeight = FontWeight.bold;
            } else if (analyzedLesion.lesionType == 'Benign') {
              adviceText = "AI Prediction: BENIGN\n\nThis finding suggests the lesion is likely benign. Continue with your regular skin monitoring (e.g., monthly self-scans) and consult a dermatologist if you notice any changes, have concerns, or for routine check-ups.";
              predictionColor = Colors.green.shade700; // Green for benign
              predictionFontWeight = FontWeight.bold;
            }
          } else if (analyzedLesion != null && analyzedLesion.lesionType == "Pending Analysis") {
            adviceText = "AI analysis is still pending for this lesion. Please check back later or consult your dermatologist.";
          }


          return SingleChildScrollView( // Changed from ListView to SingleChildScrollView for better control
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Scan Name (if available, else date)
                Text(scan.scanName ?? "Scan Details", style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text("Captured on: $formattedDate", style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(height: 20),

                // --- Lesion Image ---
                Text("Lesion Image:", style: textTheme.titleMedium),
                const SizedBox(height: 8),
                Container(
                  height: 300, // Good height for image
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

                // --- AI Analysis Results Section ---
                Text("AI Analysis:", style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (analyzedLesion != null && (analyzedLesion.lesionType == "Benign" || analyzedLesion.lesionType == "Malignant")) ...[
                  _buildDetailRow(
                    "Prediction:",
                    analyzedLesion.lesionType!, // "Benign" or "Malignant"
                    context,
                    valueStyle: textTheme.titleLarge?.copyWith(
                      color: predictionColor,
                      fontWeight: predictionFontWeight,
                    ),
                  ),
                  _buildDetailRow(
                      "Confidence:",
                      "${(analyzedLesion.confidenceScore * 100).toStringAsFixed(1)}%",
                      context,
                      valueStyle: textTheme.titleMedium
                  ),
                  if (analyzedLesion.bodyMapX != null && analyzedLesion.bodyMapY != null) ...[
                    _buildDetailRow(
                      "Location:",
                      "${analyzedLesion.bodySide?.name ?? 'N/A'} view "
                          "(X: ${analyzedLesion.bodyMapX!.toStringAsFixed(2)}, "
                          "Y: ${analyzedLesion.bodyMapY!.toStringAsFixed(2)})",
                      context,
                    ),
                  ],
                ] else if (analyzedLesion != null && analyzedLesion.lesionType == "Pending Analysis") ...[
                  _buildDetailRow("Status:", "AI Analysis Pending", context, valueStyle: textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic)),
                ] else ...[
                  _buildDetailRow("Status:", "No AI analysis data found for this scan.", context, valueStyle: textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 24),

                // --- Advice Section ---
                Text("Guidance:", style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer, // Subtle background
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
                  ),
                  child: Text(
                    adviceText,
                    style: textTheme.bodyLarge?.copyWith(height: 1.5, color: colors.onSurface),
                  ),
                ),
                const SizedBox(height: 24),

                // --- Generate Report Button ---
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text("Generate Report (PDF)"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: textTheme.titleMedium,
                    ),
                    onPressed: () {
                      // TODO: Implement PDF generation and sharing logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("PDF Report generation: To be implemented.")),
                      );
                      print("Generate report button tapped for scan ID: ${scan.scanId}");
                    },
                  ),
                ),
                const SizedBox(height: 40), // Extra space at the bottom
              ],
            ),
          );
        },
      ),
    );
  }
}