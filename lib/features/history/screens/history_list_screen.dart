// lib/features/history/screens/history_list_screen.dart
import 'dart:async'; // For Timer
import 'package:flutter/material.dart';
// *** Use flutter_riverpod ***
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

// Import providers and entities
import 'package:care/core/providers/database_providers.dart'; // Adjust package name
import 'package:care/core/database/entities/scan.dart';
import 'package:care/core/navigation/app_router.dart';
import 'package:care/features/history/providers/history_filter_providers.dart';

// *** Change to ConsumerStatefulWidget ***
class HistoryListScreen extends ConsumerStatefulWidget {
  const HistoryListScreen({super.key});

  @override
  ConsumerState<HistoryListScreen> createState() => _HistoryListScreenState();
}

// *** Create State Class ***
class _HistoryListScreenState extends ConsumerState<HistoryListScreen> {

  // --- State Variables ---
  late final TextEditingController _searchQueryController;
  Timer? _debounceTimer;
  // --- End State Variables ---

  @override
  void initState() {
    super.initState();
    // Initialize controller with current provider state
    _searchQueryController = TextEditingController(text: ref.read(historySearchQueryProvider));
  }

  @override
  void dispose() {
    // Dispose controller and timer
    _searchQueryController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // --- Debounce Logic ---
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel(); // Cancel existing timer
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      // Update provider state after delay
      print("Debounced Search: $query");
      // Use ref.read inside callbacks/logic outside build
      ref.read(historySearchQueryProvider.notifier).setQuery(query);
    });
  }

  // --- Sort Menu Logic (Keep as before) ---
  void _showSortMenu(BuildContext context) {
    final currentSort = ref.read(historySortOrderProvider);
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: HistorySortOption.values.map((option) {
          return ListTile(
            title: Text(_getSortOptionText(option)),
            selected: currentSort == option,
            selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
            onTap: () {
              ref.read(historySortOrderProvider.notifier).setSortOrder(option);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }
  String _getSortOptionText(HistorySortOption option) {
    switch (option) {
      case HistorySortOption.dateDesc: return 'Date (Newest First)';
      case HistorySortOption.dateAsc: return 'Date (Oldest First)';
      case HistorySortOption.nameAsc: return 'Name (A-Z)';
      case HistorySortOption.nameDesc: return 'Name (Z-A)';
    // *** ADD Default Case ***
      default:
      // This should technically never be reached with an enum
        print("Error: Unexpected sort option: $option");
        return 'Unknown Sort'; // Or throw an exception
    }
  }


  @override
  Widget build(BuildContext context) {
    // Watch providers needed for build
    final AsyncValue<List<Scan>> scansAsyncValue = ref.watch(userScansProvider);
    // We don't need to watch the search query provider directly for build anymore
    // final currentSearchQuery = ref.watch(historySearchQueryProvider); // Optional: if needed for UI state

    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;

    // Listen to search query provider ONLY if controller needs external updates
    // ref.listen(historySearchQueryProvider, (_, next) {
    //    if (_searchQueryController.text != next) {
    //       _searchQueryController.text = next; // Update controller if provider changes externally
    //    }
    // });

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort Scans',
            onPressed: () => _showSortMenu(context), // Call method without ref
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchQueryController, // Use state controller
              decoration: InputDecoration(
                hintText: 'Search by scan name...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                border: OutlineInputBorder( borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide.none,),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  tooltip: 'Clear Search',
                  onPressed: () {
                    _searchQueryController.clear();
                    // Update provider immediately and cancel timer
                    ref.read(historySearchQueryProvider.notifier).setQuery('');
                    _debounceTimer?.cancel();
                  },
                ),
              ),
              onChanged: _onSearchChanged, // Call debounce handler
            ),
          ),
        ),
      ),
      body: scansAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center( /* ... Error display ... */ ),

    data: (scans) {
    final bool isSearching = ref.read(historySearchQueryProvider).isNotEmpty;
    if (scans.isEmpty) {
    return Center( /* ... Empty state display ... */ );
    }
    // --- Restore ListView.builder ---
    return ListView.builder(
    itemCount: scans.length,
    // *** ADD itemBuilder back ***
    itemBuilder: (context, index) {
    final scan = scans[index];
    final formattedDate = DateFormat.yMMMd().add_jm().format(scan.scanDate.toLocal());

    return Card(
    margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
    child: ListTile(
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
    onTap: () { // Keep navigation logic
    if (scan.scanId != null) {
    final detailPath = AppRoutes.scanDetail.replaceFirst(':scanId', scan.scanId.toString());
    print("<<< NAVIGATING TO EXACT PATH: '$detailPath' >>>");
    context.push(detailPath);
    } else { /* ... error handling ... */ }
    },
    ),
    );
    }, // *** End itemBuilder ***
    ); // End ListView.builder
    },)); // End data builder
} }// End State clas}s