// lib/core/database/entities/lesion.dart
import 'package:equatable/equatable.dart';
// No need for app_constants here as enums/types defined locally

// Enum for the side of the body map where the lesion is marked
enum BodySide { Front, Back }

class Lesion extends Equatable {
  final int? lesionId; // Nullable for new lesions before insertion (auto-increment)
  final int scanId; // Foreign key linking to the Scan table
  final String riskLevel; // General risk category ('Benign', 'Precursor', 'Malignant') - Mapped from prediction
  final String lesionType; // Specific predicted type from the model (e.g., 'Melanoma')
  final double confidenceScore; // Confidence of the 'lesionType' prediction (0.0 to 1.0)
  final double bodyMapX; // Normalized X coordinate on the body map (0.0 to 1.0)
  final double bodyMapY; // Normalized Y coordinate on the body map (0.0 to 1.0)
  final BodySide? bodySide; // Which body map view (Front/Back), nullable if not specified

  const Lesion({
    this.lesionId,
    required this.scanId,
    required this.riskLevel, // General category for DB
    required this.lesionType, // Specific model output class name
    required this.confidenceScore,
    required this.bodyMapX,
    required this.bodyMapY,
    this.bodySide, // Optional side information
  });

  // --- Database Mapping ---

  /// Factory constructor to create a Lesion instance from a database map.
  factory Lesion.fromMap(Map<String, dynamic> map) {
    // Helper function to safely convert string to BodySide enum
    BodySide? _bodySideFromStringSafe(String? value) {
      if (value == null) return null;
      try {
        return BodySide.values.firstWhere((side) => side.name == value);
      } catch (e) {
        print("Warning: Failed to convert string '$value' to BodySide enum. Returning null.");
        return null;
      }
    }

    return Lesion(
      lesionId: map['lesion_id'] as int?,
      scanId: map['scan_id'] as int? ?? 0, // Default if somehow null
      riskLevel: map['risk_level'] as String? ?? 'Undetermined', // Default if null
      lesionType: map['lesion_type'] as String? ?? 'Unknown', // Default if null
      // Ensure conversion from num (which SQLite might return) to double
      confidenceScore: (map['confidence_score'] as num?)?.toDouble() ?? 0.0,
      bodyMapX: (map['body_map_x'] as num?)?.toDouble() ?? 0.0,
      bodyMapY: (map['body_map_y'] as num?)?.toDouble() ?? 0.0,
      bodySide: _bodySideFromStringSafe(map['body_side'] as String?),
    );
  }

  /// Converts the Lesion object into a map suitable for database insertion or update.
  /// Excludes `lesionId` if null (for insertion).
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      // lesion_id handled by DB on insert
      'scan_id': scanId,
      'risk_level': riskLevel,
      'lesion_type': lesionType,
      'confidence_score': confidenceScore,
      'body_map_x': bodyMapX,
      'body_map_y': bodyMapY,
      'body_side': bodySide?.name, // Store enum name as string or null
    };
    if (lesionId != null) {
      map['lesion_id'] = lesionId; // Include for updates
    }
    return map;
  }

  // --- Utility Methods ---

  /// Creates a copy of this Lesion instance with potentially updated fields.
  Lesion copyWith({
    int? lesionId,
    int? scanId,
    String? riskLevel,
    String? lesionType,
    double? confidenceScore,
    double? bodyMapX,
    double? bodyMapY,
    BodySide? bodySide,
    bool clearBodySide = false, // Flag to explicitly set bodySide to null
  }) {
    return Lesion(
      lesionId: lesionId ?? this.lesionId,
      scanId: scanId ?? this.scanId,
      riskLevel: riskLevel ?? this.riskLevel,
      lesionType: lesionType ?? this.lesionType,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      bodyMapX: bodyMapX ?? this.bodyMapX,
      bodyMapY: bodyMapY ?? this.bodyMapY,
      bodySide: clearBodySide ? null : (bodySide ?? this.bodySide),
    );
  }

  // --- Equatable Implementation ---

  @override
  List<Object?> get props => [
    lesionId,
    scanId,
    riskLevel,
    lesionType,
    confidenceScore,
    bodyMapX,
    bodyMapY,
    bodySide,
  ];

  // Optional: toString for debugging
  @override
  String toString() {
    return 'Lesion(lesionId: $lesionId, scanId: $scanId, type: $lesionType, risk: $riskLevel, score: ${confidenceScore.toStringAsFixed(3)}, side: $bodySide)';
  }
}