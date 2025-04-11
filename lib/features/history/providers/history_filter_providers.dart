// lib/features/history/providers/history_filter_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_filter_providers.g.dart';

// Enum for Sort Options
enum HistorySortOption { dateDesc, dateAsc, nameAsc, nameDesc }

// Provider for the search query string
@riverpod
class HistorySearchQuery extends _$HistorySearchQuery {
  @override
  String build() => ''; // Initial state is empty string

  void setQuery(String query) {
    state = query;
  }
}

// Provider for the sort order selection
@riverpod
class HistorySortOrder extends _$HistorySortOrder {
  @override
  HistorySortOption build() => HistorySortOption.dateDesc; // Default sort

  void setSortOrder(HistorySortOption sortOption) {
    state = sortOption;
  }
}