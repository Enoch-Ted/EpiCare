// lib/core/constants/app_constants.dart
import 'package:flutter/material.dart';  // Import material for Color
import 'package:care/core/database/entities/user.dart';  // Import SkinType enum
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
class LesionTypeConstants {
  static const String ActinicKeratosis = 'Actinic Keratosis / Intraepithelial Carcinoma';
  static const String BasalCellCarcinoma = 'Basal Cell Carcinoma';
  static const String BenignKeratosis = 'Benign Keratosis';
  static const String Dermatofibroma = 'Dermatofibroma';
  static const String Melanoma = 'Melanoma';
  static const String MelanocyticNevus = 'Melanocytic Nevus';
  static const String VascularLesion = 'Vascular Lesion';
}

// General Risk Level Constants (for the lesions.risk_level column)
class RiskLevel {
  static const String Benign = 'Benign';
  static const String Precursor = 'Precursor';
  static const String Malignant = 'Malignant';
  static const String Undetermined = 'Undetermined'; // Good to have a fallback
}

// Constants for Lesion.bodySide
class BodySideConstants {
  static const String Front = 'Front';
  static const String Back = 'Back';
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
//Other App-wide Constants (e.g., API Keys if you had online features)
// class ApiKeys {
//   static const String googleMaps = 'YOUR_API_KEY_HERE';
// }