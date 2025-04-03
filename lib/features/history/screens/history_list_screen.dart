// lib/features/history/screens/history_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date formatting

// Import providers and entities (Adjust paths/package name if needed)
import 'package:care/core/providers/database_providers.dart'; // Adjust package name
import 'package:care/core/database/entities/scan.dart'; // Adjust package name
import 'package:care/core/navigation/app_router.dart'; // Import AppRoutes
import 'package:go_router/go_router.dart'; // Import GoRouter

class HistoryListScreen extends ConsumerWidget {
  const HistoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Scan>> scansAsyncValue = ref.watch(userScansProvider());
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        // actions: [ ... ], // Placeholders
      ),
      body: scansAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center( /* ... Error display ... */ ),
        data: (scans) {
          if (scans.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'No scan history found.\nStart a new scan using the camera icon below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),

            );
          }

          // --- List View ---
          return ListView.builder(
            itemCount: scans.length,
            itemBuilder: (context, index) {
              final scan = scans[index];
              final formattedDate = DateFormat.yMMMd().add_jm().format(scan.scanDate.toLocal());

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                child: ListTile(
                  // leading: CircleAvatar(...), // Placeholder
                  title: Text(
                    scan.scanName ?? 'Scan on $formattedDate',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    formattedDate,
                    style: textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  // *** MODIFIED onTap ***
                  onTap: () {
                    print("Tapped on Scan ID: ${scan.scanId}");
                    if (scan.scanId != null) {
                      // Build the path by replacing the parameter placeholder
                      final detailPath = AppRoutes.scanDetail.replaceFirst(':scanId', scan.scanId.toString());
                      print("<<< NAVIGATING TO EXACT PATH: '$detailPath' >>>");
                      // Use context.push to navigate
                      context.push(detailPath);

                      // Or if using named routes (make sure name: 'scanDetail' is set in GoRoute):
                      // context.pushNamed('scanDetail', pathParameters: {'scanId': scan.scanId.toString()});
                    } else {
                      print("Error: Scan ID is null, cannot navigate.");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Cannot view details: Invalid Scan ID"), backgroundColor: Colors.red),
                      );
                    }
                  }, // *** End MODIFIED onTap ***
                ), // End ListTile
              ); // End Card
            }, // End itemBuilder
          ); // End ListView.builder
        }, // End data builder
      ), // End .when
    ); // End Scaffold
  } // End build
} // End class