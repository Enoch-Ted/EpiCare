// lib/core/database/entities/scan.dart
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart'; // For parsing/formatting dates

class Scan extends Equatable {
  final int? scanId; // Nullable for new scans before insertion (auto-increment)
  final int userId; // Foreign key linking to the User table
  final String? scanName; // Name of the scan (nullable, DB might provide default)
  final String imagePath; // Path to the associated full scan image file
  final DateTime scanDate; // Date and time the scan was performed

  const Scan({
    this.scanId,
    required this.userId,
    this.scanName,
    required this.imagePath,
    required this.scanDate,
  });

  // --- Database Mapping ---

  /// Factory constructor to create a Scan instance from a database map.
  factory Scan.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    try {
      // Attempt to parse the timestamp string from SQLite (usually ISO8601 format)
      // CURRENT_TIMESTAMP in SQLite often returns 'YYYY-MM-DD HH:MM:SS'
      final dateString = map['scan_date'] as String?;
      if (dateString != null) {
        // Handle potential timezone issues if stored without Z or offset
        parsedDate = DateTime.parse(dateString).toLocal(); // Convert to local time
      } else {
        // Fallback if somehow null in DB, though default should prevent this
        print("Warning: scan_date was null in database for scan_id ${map['scan_id']}. Using current time.");
        parsedDate = DateTime.now();
      }
    } catch (e) {
      print("Error parsing scan_date '${map['scan_date']}' for scan_id ${map['scan_id']}: $e. Using current time.");
      parsedDate = DateTime.now(); // Fallback on parsing error
    }

    return Scan(
      scanId: map['scan_id'] as int?,
      userId: map['user_id'] as int? ?? 0, // Default user 0 if somehow null (shouldn't happen with NOT NULL)
      scanName: map['scan_name'] as String?, // Can be null if DB default was used
      imagePath: map['image_path'] as String? ?? '', // Default if null
      scanDate: parsedDate,
    );
  }

  /// Converts the Scan object into a map suitable for database insertion or update.
  /// Excludes `scanId` if null (for insertion).
  /// Excludes `scanName` if null (to let DB default apply on insert).
  /// Formats `scanDate` to a standard SQLite-compatible string format.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      // scan_id handled by DB on insert
      'user_id': userId,
      'image_path': imagePath,
      // Store DateTime as ISO8601 string in UTC for consistency
      // Or use 'YYYY-MM-DD HH:MM:SS' format which SQLite understands well
      'scan_date': DateFormat("yyyy-MM-dd HH:mm:ss").format(scanDate.toUtc()), // Store in UTC
    };
    if (scanId != null) {
      map['scan_id'] = scanId; // Include for updates
    }
    if (scanName != null) {
      map['scan_name'] = scanName; // Include if provided, else let DB default work
    }
    return map;
  }

  // --- Utility Methods ---

  /// Creates a copy of this Scan instance with potentially updated fields.
  Scan copyWith({
    int? scanId,
    int? userId,
    String? scanName, // Allows setting or updating the name
    bool clearScanName = false, // Allows explicitly clearing the name
    String? imagePath,
    DateTime? scanDate,
  }) {
    return Scan(
      scanId: scanId ?? this.scanId,
      userId: userId ?? this.userId,
      scanName: clearScanName ? null : (scanName ?? this.scanName),
      imagePath: imagePath ?? this.imagePath,
      scanDate: scanDate ?? this.scanDate,
    );
  }

  // --- Equatable Implementation ---

  @override
  List<Object?> get props => [scanId, userId, scanName, imagePath, scanDate];

  // Optional: toString for debugging
  @override
  String toString() {
    return 'Scan(scanId: $scanId, userId: $userId, name: $scanName, date: ${DateFormat.yMd().add_jms().format(scanDate)})';
  }
}