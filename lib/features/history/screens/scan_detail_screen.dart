// lib/features/history/screens/scan_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';

// Import providers and entities (Adjust paths/package name)
import 'package:care/core/providers/database_providers.dart';
import 'package:care/core/database/entities/scan.dart';
import 'package:care/core/database/entities/lesion.dart';
import 'package:care/core/constants/app_constants.dart';

// Simple provider to hold the text being edited in the rename dialog
final _renameScanTextProvider = StateProvider<String>((ref) => '');

class ScanDetailScreen extends ConsumerWidget {
  final int scanId;

  const ScanDetailScreen({required this.scanId, super.key});

  // --- Rename Scan Dialog & Logic ---
  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref, Scan currentScan) async {
    // Initialize dialog controller with current name
    final renameController = TextEditingController(text: currentScan.scanName ?? '');
    ref.read(_renameScanTextProvider.notifier).state = currentScan.scanName ?? ''; // Init provider too

    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Rename Scan"),
          content: Consumer( // Use consumer to rebuild on text change if needed later
              builder: (context, ref, child) {
                return TextFormField(
                  controller: renameController,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: "Enter new scan name"),
                  onChanged: (value) => ref.read(_renameScanTextProvider.notifier).state = value, // Update provider on change
                );
              }
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null), // Cancel
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final nameToSave = ref.read(_renameScanTextProvider); // Get final value from provider
                if (nameToSave.trim().isNotEmpty) {
                  Navigator.of(context).pop(nameToSave.trim()); // Return new name
                } else {
                  // Optional: Show validation within dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Name cannot be empty."), backgroundColor: Colors.orange)
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    // If a new name was entered and saved
    if (newName != null && newName.isNotEmpty && context.mounted) {
      print("Attempting to rename scan $scanId to '$newName'");
      final scanDao = ref.read(scanDaoProvider);
      final updatedScan = currentScan.copyWith(scanName: newName); // Create updated object
      try {
        final count = await scanDao.updateScan(updatedScan);
        if (count > 0) {
          print("Scan renamed successfully.");
          // Invalidate providers to refresh data
          ref.invalidate(scanByIdProvider(scanId));
          ref.invalidate(userScansProvider); // Refresh history list
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Scan renamed."), backgroundColor: Colors.green)
          );
        } else {
          throw Exception("Update returned 0 rows affected.");
        }
      } catch (e) {
        print("Error renaming scan: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error renaming scan: $e"), backgroundColor: Theme.of(context).colorScheme.error)
          );
        }
      }
    }
  } // End _showRenameDialog

  // --- Delete Confirmation Helper (Keep as is) ---
  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    // Get current scan data for context, though ID is passed via widget.scanId
    final Scan? currentScan = ref.read(scanByIdProvider(scanId)).asData?.value;
    final String scanNameToDelete = currentScan?.scanName ?? "this scan (ID: $scanId)";

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Scan?'),
          // Use scan name in confirmation message
          content: Text('Are you sure you want to permanently delete "$scanNameToDelete" and its associated lesions? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false); // Return false
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true); // Return true
              },
            ),
          ],
        );
      },
    );

    // If user confirmed deletion
    if (confirmed == true && context.mounted) { // Check context is still valid
      print("User confirmed deletion for scan $scanId");
      try {
        // Call DAO method via provider using the screen's scanId
        final scanDao = ref.read(scanDaoProvider);
        final deletedCount = await scanDao.deleteScanById(scanId); // Use scanId from widget

        if (deletedCount > 0 && context.mounted) {
          print("Scan $scanId deleted successfully.");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Scan deleted successfully"), backgroundColor: Colors.green),
          );
          // Invalidate providers that depend on scan list to refresh History screen
          ref.invalidate(userScansProvider);
          // Invalidate this specific scan provider too (though we are popping)
          ref.invalidate(scanByIdProvider(scanId));
          ref.invalidate(lesionsByScanIdProvider(scanId)); // Invalidate lesions too
          // Navigate back to the previous screen (HistoryListScreen)
          context.pop();
        } else if (context.mounted){
          // This might happen if the scan was deleted by another process
          // between loading the screen and confirming delete
          print("Scan $scanId not found in DB during delete or delete failed.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text("Could not delete scan (already deleted or error)."), backgroundColor: Theme.of(context).colorScheme.error),
          );
          // Optionally pop anyway? Or stay on screen? Popping is usually fine.
          if (context.canPop()) context.pop();

        }
      } catch (e) {
        print("Error during deletion process: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error deleting scan: $e"), backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      }
    } else {
      print("Deletion cancelled for scan $scanId");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Scan?> scanAsyncValue = ref.watch(scanByIdProvider(scanId));
    final AsyncValue<List<Lesion>> lesionsAsyncValue = ref.watch(lesionsByScanIdProvider(scanId));
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;

    // Get the current scan data (if loaded) to pass to dialogs
    final Scan? currentScanData = scanAsyncValue.asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentScanData?.scanName ?? 'Scan Details'), // Show current name or default
        actions: [
          // --- Add Rename Button ---
          if (currentScanData != null) // Only show if scan data is loaded
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Rename Scan',
              onPressed: () => _showRenameDialog(context, ref, currentScanData),
            ),
          // --- End Rename Button ---
          IconButton(
            icon: Icon(Icons.delete_outline, color: colors.error),
            tooltip: 'Delete Scan',
            // Disable delete if scan data isn't loaded yet? Optional.
              onPressed: () => _confirmAndDelete(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Display Scan Info ---
          scanAsyncValue.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())),
              error: (err, stack) => Text('Error loading scan: $err', style: TextStyle(color: colors.error)),
              data: (scan) {
                if (scan == null) {
                  return const Center(child: Text('Scan not found.'));
                }
                final formattedDate = DateFormat.yMMMd().add_jm().format(scan.scanDate.toLocal());
                // Use local variable 'scan' here
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Scan from $formattedDate", style: textTheme.headlineSmall),
                    // Don't show name here if it's in AppBar title
                    // if (scan.scanName != null) Padding(...)
                    const SizedBox(height: 16),
                    // --- Improved Image Display ---
                    Container(
                      height: 250, width: double.infinity,
                      decoration: BoxDecoration(color: colors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: scan.imagePath.startsWith('/placeholder/') // Check for placeholder
                            ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.image_search, size: 50, color: Colors.grey), SizedBox(height: 8), Text("Placeholder Image", style: TextStyle(color: Colors.grey))]))
                            : Image.file( // Attempt to load real file
                          File(scan.imagePath),
                          fit: BoxFit.cover,



                          errorBuilder: (context, error, stackTrace) {
                            print("Error loading image ${scan.imagePath}: $error");
                            return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.broken_image_outlined, size: 50, color: Colors.grey), SizedBox(height: 8), Text("Image not found", style: TextStyle(color: Colors.grey))]));
                          },
                        ),
                      ),
                    ),
                    // --- End Improved Image Display ---
                    const SizedBox(height: 20),
                  ],
                );
              }
          ), // End scanAsyncValue.when

          // --- Display Lesions ---
          Text("Detected Lesions:", style: textTheme.titleLarge),
          const SizedBox(height: 8),
          lesionsAsyncValue.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())),
              error: (err, stack) => Text('Error loading lesions: $err', style: TextStyle(color: colors.error)),
              data: (lesions) {
                if (lesions.isEmpty) { /* ... No lesions text ... */ }
                return Column(
                  children: lesions.map((lesion) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        title: Text(lesion.lesionType, style: textTheme.titleMedium),
                        subtitle: Column( /* ... Lesion details ... */ ),
                        // *** Add Lesion onTap Placeholder ***
                        onTap: () {
                          print("Tapped Lesion ID: ${lesion.lesionId}, Type: ${lesion.lesionType}");
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("TODO: Show more details or highlight lesion ${lesion.lesionId}"))
                          );
                          // TODO: Navigate to dedicated lesion detail or trigger highlight later
                        },
                        // *** End Lesion onTap ***
                      ),
                    );
                  }).toList(),
                );
              }
          ), // End lesionsAsyncValue.when
        ], // End Main ListView Children
      ), // End ListView
    ); // End Scaffold
  } // End build
} // End class