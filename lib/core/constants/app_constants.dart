// lib/core/constants/app_constants.dart
import 'package:flutter/material.dart';  // Import material for Color
import 'package:care/core/database/entities/user.dart';// Import SkinType enum
/// Contains constant values used throughout the EpiCare application.

// Enum string values (primarily for database storage where TEXT is used)
// Using these constants helps prevent typos when interacting with the database.
class AuthMethodConstants {
  static const String PIN = 'PIN';
  static const String PASSWORD = 'PASSWORD';
  static const String BIOMETRIC = 'BIOMETRIC';
  static const String NONE = 'NONE';
}

class GenderConstants {
  static const String Male = 'Male';
  static const String Female = 'Female';
  static const String Other = 'Other';
  static const String Prefer_not_to_say = 'Prefer_not_to_say';
}

class SkinTypeConstants {
  static const String I = 'I';
  static const String II = 'II';
  static const String III = 'III';
  static const String IV = 'IV';
  static const String V = 'V';
  static const String VI = 'VI';
}

class RiskProfileConstants {
  static const String Low = 'Low';
  static const String Medium = 'Medium';
  static const String High = 'High';
}

// Constants for Lesion.riskLevel (adapt if your 7 classes have different names)
// Specific Lesion Type Constants (from the 7-class model output)
// General Risk Level Constants (for the lesions.risk_level column)


// Constants for Lesion.bodySide
class BodySideConstants {
  static const String Front = 'Front'; // Matches BodySide.Front.name from lesion.dart
  static const String Back = 'Back';   // Matches BodySide.Back.name from lesion.dart
}


// Database Related Constants
class DbConfig {
  static const String databaseName = 'epiccare.db';
  static const int databaseVersion = 1; // Increment this for schema migrations
}

class DbTableNames {
  static const String users = 'users';
  static const String scans = 'scans';
  static const String lesions = 'lesions';
  static const String userSettings = 'user_settings';
}

// Default User Settings Values
class DefaultSettings {
  static const int scanReminderDays = 30;
  static const bool darkMode = false;
  static const bool notificationsEnabled = true; // As defined in UserSettings entity
}

// Asset Paths (Optional but helpful)
class AssetPaths {
  static const String bodyMapFront = 'assets/images/body_map_front.png';
  static const String bodyMapBack = 'assets/images/body_map_back.png';
  static const String defaultProfilePic = 'assets/images/default_profile_pic.png';
  static const String binaryClassifierModel = 'models/ccn_vit_binary_fp16_final.tflite';
  static const String binaryClassifierLabels = 'assets/labels.txt';
  static const String yoloModel = 'models/best_float16.tflite';

// Add paths to models if needed elsewhere, though services often encapsulate this
// static const String classifierModel = 'models/your_classifier_model.tflite';
}


// --- Skin Type Information ---
class SkinTypeInfo {
  final String name;
  final String description;
  final Color color; // Representative color

  const SkinTypeInfo({required this.name, required this.description, required this.color});
}

// Map SkinType enum to detailed information
const Map<SkinType, SkinTypeInfo> skinTypeDetails = {
  SkinType.I: SkinTypeInfo(
    name: "Type I (Very Light / Pale)",
    description: "Always burns, never tans. Highly sensitive to sun exposure. Increased risk for skin cancers.",
    color: Color(0xFFFFF5E1), // Very pale cream
  ),
  SkinType.II: SkinTypeInfo(
    name: "Type II (Light / Fair)",
    description: "Usually burns, tans minimally with difficulty. High sensitivity to sun exposure.",
    color: Color(0xFFF3CFB3), // Pale beige
  ),
  SkinType.III: SkinTypeInfo(
    name: "Type III (Light Intermediate / Beige)",
    description: "Sometimes burns mildly, tans uniformly and gradually. Moderate sensitivity.",
    color: Color(0xFFE0B094), // Light beige/tan
  ),
  SkinType.IV: SkinTypeInfo(
    name: "Type IV (Dark Intermediate / Olive)",
    description: "Rarely burns, tans easily and well. Minimal sensitivity.",
    color: Color(0xFFC78E6A), // Olive/light brown
  ),
  SkinType.V: SkinTypeInfo(
    name: "Type V (Dark / Brown)",
    description: "Very rarely burns, tans profusely and easily. Low sensitivity.",
    color: Color(0xFF8C4E2A), // Medium brown
  ),
  SkinType.VI: SkinTypeInfo(
    name: "Type VI (Very Dark / Black)",
    description: "Never burns, deeply pigmented skin. Very low sensitivity to UV radiation, but still at risk for certain skin cancers.",
    color: Color(0xFF3A2118), // Dark brown
  ),
};

class RiskProfileInfo {
  final String name;
  final String description;
  final IconData icon;
  final Color color; // Color associated with the risk level

  const RiskProfileInfo({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// Map RiskProfile enum to detailed information
// TODO: Refine descriptions and choose appropriate icons/colors
final Map<RiskProfile, RiskProfileInfo> riskProfileDetails = {
  RiskProfile.Low: RiskProfileInfo(
    name: "Low Risk",
    description: "Based on your answers, you have a lower risk of developing Skin Cancer. However, all of us are exposed to UV and sunlight on a daily basis, the main contributor to 90% of Skin Cancer.\n\nRecommendations:\n- Apply SPF30 or higher sunscreen daily\n- When outdoors (between 11-4pm) wear a hat, long sleeves and sunglasses\n- Avoid sunburns\n- Avoid sun beds (high UV radiation)\n- Monitor your skin regularly using EpiCare.",
    icon: Icons.check_circle_outline,
    color: Colors.green.shade600,
  ),
  RiskProfile.Medium: RiskProfileInfo(
    name: "Medium Risk",
    description: "Based on your answers, you have a medium risk of developing Skin Cancer. It's important to be vigilant with sun protection and skin monitoring.\n\nRecommendations:\n- Strictly follow sun safety guidelines (SPF, clothing, shade)\n- Perform monthly skin self-examinations\n- Consider annual check-ups with a dermatologist.",
    icon: Icons.warning_amber_rounded,
    color: Colors.orange.shade700,
  ),
  RiskProfile.High: RiskProfileInfo(
    name: "High Risk",
    description: "Based on your answers, you have an elevated risk of developing Skin Cancer. Consistent sun protection and regular professional checks are crucial.\n\nRecommendations:\n- Maximize sun protection daily (high SPF, protective clothing, seek shade)\n- Perform thorough monthly skin self-examinations, noting any changes\n- Schedule regular dermatologist appointments (e.g., every 6-12 months or as advised).",
    icon: Icons.dangerous_outlined,
    color: Colors.red.shade700,
  ),
};

/// *** Use final instead of const, explicitly type values ***


// Helper to get RiskLevel from Lesion Type string safely
RiskLevel getRiskLevelFromLesionType(String label) {
  // Ensure the label strings exactly match your binary_labels.txt content.
  // Convert to lowercase for case-insensitive matching.
  switch (label.toLowerCase().trim()) {
    case "benign": // <-- VERIFY THIS STRING matches your binary_labels.txt (labels.txt)
      return RiskLevel.Benign;
    case "malignant": // <-- VERIFY THIS STRING matches your binary_labels.txt (labels.txt)
      return RiskLevel.Malignant;
  // Handle other statuses that might be saved in lesion.lesionType
    case "pending analysis":
    case "analysis failed":
    case "cropping failed":
    case "classification failed":
    case "no lesion detected":
    case "analysis pipeline failed":
    case "unknown":
    default:
      return RiskLevel.Undetermined;
  }
}


// YOLO Constants (Based on your model)
//const int YOLO_INPUT_SIZE = 640; // Model expects 640x640 input
//const int YOLO_ATTRIBUTES_COUNT = 5; // cx, cy, w, h, score (Based on your output shape [1, 5, 8400])
//const int YOLO_SCORE_INDEX = 4; // Index of the confidence score within the 5 attributes

//const double YOLO_DETECTION_THRESHOLD = 0.1; // Min confidence to consider a YOLO detection *before* NMS
//const double YOLO_NMS_IOU_THRESHOLD = 0.5;    // IoU threshold for Non-Maximum Suppression
//const int YOLO_MAX_DETECTIONS_NMS = 100;     // Max detections to keep after NMS

// Classification Constants (Based on your model)
// You got input shape [1, 224, 224, 3], dtype float32
const int BINARY_CLASSIFICATION_INPUT_SIZE = 224; // Model expects 224x224 input
const String BINARY_CLASSIFIER_NORMALIZATION_TYPE = 'ZERO_TO_ONE';
/// The risk buckets used for AI lesion classification.
enum RiskLevel {
  Benign,
  Malignant,
  Undetermined,
}

/// Detailed info (name + description + optional icon/color) for each RiskLevel.
class LesionRiskInfo {
  final String name;
  final String description;
  const LesionRiskInfo({required this.name, required this.description});
}

/// Guidance and labels *for* lesion‐based risk levels.
const Map<RiskLevel, LesionRiskInfo> lesionRiskDetails = {
  RiskLevel.Benign: LesionRiskInfo(
      name: "Benign",
      description: "These lesions are low risk. You can monitor them; no urgent action is typically needed."
  ),
  RiskLevel.Malignant: LesionRiskInfo(
      name: "Malignant",
      description: "These lesions are potentially cancerous. Please seek professional medical advice immediately."
  ),
  RiskLevel.Undetermined: LesionRiskInfo(
      name: "Undetermined",
      description: "The AI could not assign a risk level. Please consult a professional for an accurate diagnosis."
  ),
};

