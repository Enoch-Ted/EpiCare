// lib/core/utils/list_extensions.dart

/// Extension methods for List<double>.
extension DoubleListSum on List<double> {
  /// Calculates the sum of all elements in the list.
  double get sum => fold(0.0, (prev, element) => prev + element);
}