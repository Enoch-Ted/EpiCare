// lib/features/history/screens/scan_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';

// Import project files (Adjust package name 'epiccare' if needed)
import 'package:care/core/providers/database_providers.dart';
import 'package:care/core/database/entities/scan.dart';
import 'package:care/core/database/entities/lesion.dart';
import 'package:care/core/database/entities/user.dart';
import 'package:care/core/constants/app_constants.dart';
import 'package:care/core/navigation/app_router.dart';
import 'package:care/core/providers/security_providers.dart';
import 'package:care/core/ai/model_handler.dart'; // For ClassificationResult

final _renameScanTextProvider = StateProvider<String>((ref) => '');
enum ScanAction { rename, share, delete }

class ScanDetailScreen extends ConsumerWidget {
  final int scanId;
  const ScanDetailScreen({required this.scanId, super.key});

  // --- Helper Functions (Ensure these are correct) ---
  RiskLevel _getRiskLevelEnumFromString(String? riskLevelString) {
    return RiskLevel.values.firstWhere((e) => e.name == riskLevelString, orElse: () => RiskLevel.Undetermined);
  }

  RiskProfileInfo _getRiskProfileInfo(RiskLevel riskEnum, BuildContext context) {
    RiskProfile profileEnum;
    switch (riskEnum) {
      case RiskLevel.Benign: profileEnum = RiskProfile.Low; break;
      case RiskLevel.Precursor: profileEnum = RiskProfile.Medium; break;
      case RiskLevel.Malignant: profileEnum = RiskProfile.High; break;
      case RiskLevel.Undetermined:
      default:
        return RiskProfileInfo( name: "Undetermined", description: "Risk level could not be determined.", icon: Icons.help_outline, color: Colors.grey );
    }
    return riskProfileDetails[profileEnum] ?? RiskProfileInfo( name: "Unknown", description: "Details not found.", icon: Icons.help_outline, color: Colors.grey );
  }

  Widget _buildDetailItem(String label, String value, BuildContext context, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        // *** ADD the 'text:' parameter ***
        text: TextSpan( // <<< Root TextSpan
            style: Theme.of(context).textTheme.bodyMedium, // Default style for all children
            children: [
              TextSpan(text: "$label ", style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: value, style: TextStyle(color: valueColor, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
            ]
        ),
        // *** END Add 'text:' ***
      ),
    );
  }
  // --- End Helper Functions ---


  // --- Dialog/Action Methods (Now Methods of the Class) ---

  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref, Scan currentScan) async {
    final renameController = TextEditingController(text: currentScan.scanName ?? '');
    ref.read(_renameScanTextProvider.notifier).state = currentScan.scanName ?? '';

    final String? newName = await showDialog<String>(
      context: context, // <<< Pass context
      builder: (dialogContext) { // <<< Pass builder, use dialogContext inside
        return AlertDialog(
          title: const Text("Rename Scan"),
          content: Consumer(
              builder: (context, ref, child) { // Inner consumer uses its own context/ref
                return TextFormField(
                  controller: renameController,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: "Enter new scan name"),
                  onChanged: (value) => ref.read(_renameScanTextProvider.notifier).state = value,
                );
              }
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null), // Use dialogContext
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final nameToSave = ref.read(_renameScanTextProvider);
                if (nameToSave.trim().isNotEmpty) {
                  Navigator.of(dialogContext).pop(nameToSave.trim()); // Use dialogContext
                } else {
                  // *** Pass SnackBar to showSnackBar ***
                  ScaffoldMessenger.of(dialogContext).showSnackBar( // Use dialogContext or original context
                      const SnackBar(content: Text("Name cannot be empty."), backgroundColor: Colors.orange)
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      }, // <<< End builder
    );

    if (newName != null && newName.isNotEmpty && context.mounted) {
      final scanDao = ref.read(scanDaoProvider);
      final updatedScan = currentScan.copyWith(scanName: newName);
      try {
        final count = await scanDao.updateScan(updatedScan);
        if (count > 0) {
          ref.invalidate(scanByIdProvider(scanId));
          ref.invalidate(userScansProvider);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Scan renamed."), backgroundColor: Colors.green)
          );
        }  else if (context.mounted) { throw Exception("Update returned 0 rows affected."); }
      } catch (e) {
        print("Error renaming scan: $e");
        if (context.mounted) {
          // *** Pass SnackBar to showSnackBar ***
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error renaming scan: $e"), backgroundColor: Theme.of(context).colorScheme.error)
          );
        }
      }
    }
  }

  // --- CORRECTED Delete Confirmation Helper ---
  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final Scan? currentScan = ref.read(scanByIdProvider(scanId)).asData?.value;
    final String scanNameToDelete = currentScan?.scanName ?? "this scan (ID: $scanId)";

    // *** Pass context and builder ***
    final bool? confirmed = await showDialog<bool>(
      context: context, // <<< Pass context
      builder: (BuildContext dialogContext) { // <<< Pass builder
        return AlertDialog(
          title: const Text('Delete Scan?'),
          content: Text('Are you sure you want to permanently delete "$scanNameToDelete" and its associated lesions? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false), // Use dialogContext
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete'), // Simpler text
              onPressed: () => Navigator.of(dialogContext).pop(true), // Use dialogContext
            ),
          ],
        );
      }, // <<< End builder
    ); // *** End showDialog ***

    if (confirmed == true && context.mounted) {
      print("User confirmed deletion for scan $scanId");
      try {
        final scanDao = ref.read(scanDaoProvider);
        final deletedCount = await scanDao.deleteScanById(scanId);
        if (deletedCount > 0 && context.mounted) {
          print("Scan $scanId deleted successfully.");
          // *** Pass SnackBar to showSnackBar ***
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Scan deleted successfully"), backgroundColor: Colors.green),
          );
          ref.invalidate(userScansProvider);
          ref.invalidate(scanByIdProvider(scanId));
          ref.invalidate(lesionsByScanIdProvider(scanId));
          context.pop();
        } else if (context.mounted){
          print("Scan $scanId not found in DB during delete or delete failed.");
          // *** Pass SnackBar to showSnackBar ***
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not delete scan (already deleted or error)."), backgroundColor: Colors.red), // Use red
          );
          if (context.canPop()) context.pop();
        }
      } catch (e) {
        print("Error during deletion process: $e");
        if (context.mounted) {
          // *** Pass SnackBar to showSnackBar ***
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error deleting scan: $e"), backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      }
    } else { print("Deletion cancelled for scan $scanId"); }
  }

  // *** Ensure Lesion Details Dialog Shows ALL Info ***
  void _showLesionDetailsDialog(BuildContext context, Lesion lesion) {
    final RiskLevel riskEnum = _getRiskLevelEnumFromString(lesion.riskLevel);
    final RiskProfileInfo riskInfo = _getRiskProfileInfo(riskEnum, context);
    String lesionInfo = "Detailed information about ${lesion.lesionType} will be available here.";
    String recommendations = riskInfo.description; // Use description from map

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16), // Adjust padding
        title: Row( children: [ Icon(riskInfo.icon, color: riskInfo.color, size: 28), const SizedBox(width: 10), Expanded(child: Text(lesion.lesionType, style: Theme.of(context).textTheme.titleLarge)), ], ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem("Risk Assessment:", riskInfo.name, context, valueColor: riskInfo.color, isBold: true),
              _buildDetailItem("AI Confidence:", "${(lesion.confidenceScore * 100).toStringAsFixed(1)}%", context),
              const Divider(height: 16),
              _buildDetailItem("Location:", "${lesion.bodySide?.name ?? 'N/A'} (${lesion.bodyMapX.toStringAsFixed(2)}, ${lesion.bodyMapY.toStringAsFixed(2)})", context),
              const Divider(height: 16),
              Text("About ${lesion.lesionType}:", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4), Text(lesionInfo, style: Theme.of(context).textTheme.bodyMedium),
              const Divider(height: 16),
              Text("Recommendations:", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4), Text(recommendations, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        actions: [ TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("Close")) ],
      ),
    );
  }
  //

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Scan?> scanAsyncValue = ref.watch(scanByIdProvider(scanId));
    final AsyncValue<List<Lesion>> lesionsAsyncValue = ref.watch(lesionsByScanIdProvider(scanId));
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Scan? currentScanData = scanAsyncValue.asData?.value;
    final String appBarTitle = currentScanData?.scanName ??
        (currentScanData != null
            ? 'Scan_${DateFormat('yyyyMMdd_HHmmss').format(currentScanData.scanDate.toLocal())}'
            : 'Scan Details');

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          // *** Use PopupMenuButton for Actions ***
          if (currentScanData != null)
            PopupMenuButton<ScanAction>(
              icon: const Icon(Icons.more_vert), // Standard options icon
              tooltip: "Options",
              onSelected: (ScanAction action) {
                switch (action) {
                  case ScanAction.rename: _showRenameDialog(context, ref, currentScanData); break;
                  case ScanAction.share: print("TODO: Implement Share Scan Report"); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("TODO: Implement Share Scan Report"))); break;
                  case ScanAction.delete: _confirmAndDelete(context, ref); break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<ScanAction>>[
                const PopupMenuItem<ScanAction>( value: ScanAction.rename, child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Rename')), ),
                const PopupMenuItem<ScanAction>( value: ScanAction.share, child: ListTile(leading: Icon(Icons.share_outlined), title: Text('Share')), ),
                const PopupMenuDivider(),
                PopupMenuItem<ScanAction>( value: ScanAction.delete, child: ListTile( leading: Icon(Icons.delete_outline, color: colors.error), title: Text('Delete', style: TextStyle(color: colors.error)), ), ),
              ],
            )
          else const SizedBox(width: 48), // Placeholder if actions hidden
          const SizedBox(width: 8), // Padding after menu
        ],
        // *** End PopupMenuButton ***
      ),
      body: ListView( // Keep overall ListView
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Display Scan Info ---
          scanAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error loading scan: $err'),
              data: (scan) {
                if (scan == null) return const Center(child: Text('Scan not found.'));
                final formattedDate = DateFormat.yMMMd().add_jm().format(scan.scanDate.toLocal());
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Scan from $formattedDate", style: textTheme.titleMedium),
                    const SizedBox(height: 16),
                    Container( // Image Container
                      height: 250, width: double.infinity,
                      decoration: BoxDecoration(color: colors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: scan.imagePath.startsWith('/placeholder/')
                            ? const Center(/* Placeholder */)
                            : Image.file( File(scan.imagePath), fit: BoxFit.cover, errorBuilder: (c,e,s) => const Center(/* Error */) ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              }
          ), // End scanAsyncValue.when

          // --- Display Lesions ---
          Text("Detected Lesions:", style: textTheme.titleLarge),
          const SizedBox(height: 8),
          lesionsAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error loading lesions: $err'),
              data: (lesions) {
                if (lesions.isEmpty) { return const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Center(child: Text('No lesions were recorded for this scan.'))); }
                // *** Use ListTile with Risk Indicator ***
                return Column(
                  children: lesions.map((lesion) {
                    final RiskLevel riskEnum = _getRiskLevelEnumFromString(lesion.riskLevel);
                    final RiskProfileInfo riskInfo = _getRiskProfileInfo(riskEnum, context);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        leading: Icon(riskInfo.icon, color: riskInfo.color, size: 30), // Risk Indicator
                        title: Text(lesion.lesionType, style: textTheme.titleMedium), // Specific Type
                        subtitle: Text( riskInfo.name, style: TextStyle(color: riskInfo.color, fontWeight: FontWeight.w500), ), // Mapped Risk Name
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showLesionDetailsDialog(context, lesion), // Show DIALOG on tap
                      ),
                    );
                  }).toList(),
                );
                // *** End ListTile ***
              }
          ), // End lesionsAsyncValue.when
        ], // End Main ListView Children
      ), // End ListView
    ); // End Scaffold
  } // End build
} // End class
