// lib/features/history/screens/scan_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import providers and entities later when needed
import 'package:care/core/providers/database_providers.dart';
import 'package:care/core/database/entities/scan.dart';
import 'package:care/core/database/entities/lesion.dart';

class ScanDetailScreen extends ConsumerWidget {
  final int scanId; // Receive scanId from router

  const ScanDetailScreen({required this.scanId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Fetch Scan details and Lesion details based on scanId using providers
    // Example: final scanAsync = ref.watch(scanByIdProvider(scanId));
    // Example: final lesionsAsync = ref.watch(lesionsByScanIdProvider(scanId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Details (ID: $scanId)'), // Show the ID for now
        // Optionally add actions like Delete, Rename, etc.
      ),
      body: SingleChildScrollView( // Allow scrolling for details
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Displaying details for Scan ID: $scanId", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            const Text("Placeholder for Scan Image"),
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
              alignment: Alignment.center,
              child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Text("Placeholder for Scan Date/Name"),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text("Scan Date: Loading..."),
            ),
            ListTile(
              leading: Icon(Icons.label),
              title: Text("Scan Name: Loading..."),
            ),
            const SizedBox(height: 20),
            const Text("Placeholder for Associated Lesions"),
            // TODO: Use .when on lesion provider to show loading/error/list
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: Text("Lesion list area..."),
            ),
            const SizedBox(height: 20),
            const Text("Placeholder for AI Results Summary"),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: Text("AI results area..."),
            ),
          ],
        ),
      ),
    );
  }
}