// lib/features/body_scan/providers/body_map_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Import necessary entities and other providers (Adjust paths/package name)
import 'package:care/core/database/entities/lesion.dart';
import 'package:care/core/providers/database_providers.dart';
import 'package:care/features/body_scan/screens/body_scan_screen.dart'; // For isBodyFrontProvider

part 'body_map_providers.g.dart';

// Provider that filters all user lesions based on the current front/back view
@riverpod
List<Lesion> visibleBodyMapLesions(VisibleBodyMapLesionsRef ref) {
  // Watch the state determining front or back view
  final bool isFrontView = ref.watch(isBodyFrontProvider);
  // Watch the async provider that fetches all lesions for the user
  final allLesionsAsync = ref.watch(allUserLesionsProvider);

  print("DEBUG: visibleBodyMapLesionsProvider rebuilding. isFront: $isFrontView");

  // Handle loading/error states of the allUserLesionsProvider
  return allLesionsAsync.when(
    // While loading or on error, return empty list (no markers to show)
      loading: () => [],
      error: (err, stack) {
        print("Error in allUserLesionsProvider: $err");
        return [];
      },
      // When data is available, filter it
      data: (allLesions) {
        final targetSide = isFrontView ? BodySide.Front : BodySide.Back;
        final visible = allLesions.where((lesion) => lesion.bodySide == targetSide).toList();
        print("DEBUG: Found ${visible.length} lesions for ${targetSide.name} view.");
        return visible;
      }
  );
}