// lib/core/database/entities/user.dart
import 'package:equatable/equatable.dart';
// No need to import app_constants here as enums are defined locally

// Enums defined directly for type safety within Dart code
// These correspond to the CHECK constraints in the database schema
enum AuthMethod { PIN, PASSWORD, BIOMETRIC, NONE }
enum Gender { Male, Female, Other, Prefer_not_to_say }
enum SkinType { I, II, III, IV, V, VI }
enum RiskProfile { Low, Medium, High }

class User extends Equatable {
  final int? userId; // Nullable for new users before insertion (auto-increment)
  final AuthMethod authMethod;
  final String? authHash; // Hashed PIN/Password (null if NONE or BIOMETRIC)
  final String salt; // Salt used for hashing (should always be present)
  final String firstName;
  final String lastName;
  final Gender gender;
  final int age;
  final SkinType? skinType; // Nullable if not assessed yet
  final RiskProfile? riskProfile; // Nullable if not assessed yet
  final String? profilePic; // Path or identifier (e.g., local file path)

  const User({
    this.userId,
    required this.authMethod,
    this.authHash,
    required this.salt,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.age,
    this.skinType,
    this.riskProfile,
    this.profilePic,
  });

  // --- Database Mapping ---

  /// Factory constructor to create a User instance from a database map.
  /// Handles potential type mismatches and enum conversions.
  factory User.fromMap(Map<String, dynamic> map) {
    // Helper function to safely convert string to enum T from a list of values.
    T? _enumFromStringSafe<T>(Iterable<T> values, String? value, {T? defaultValue}) {
      if (value == null) return defaultValue;
      try {
        // Compare against the string representation (enumName)
        return values.firstWhere((type) => type.toString().split('.').last == value);
      } catch (e) {
        print("Warning: Failed to convert string '$value' to enum $T. Using default: $defaultValue");
        return defaultValue;
      }
    }

    return User(
      userId: map['user_id'] as int?, // Allow null from DB query if not present
      authMethod: _enumFromStringSafe(AuthMethod.values, map['auth_method'] as String?, defaultValue: AuthMethod.NONE)!, // Assume NONE if invalid/null
      authHash: map['auth_hash'] as String?,
      salt: map['salt'] as String? ?? '', // Provide default empty salt if somehow null in DB
      firstName: map['first_name'] as String? ?? '', // Default if null
      lastName: map['last_name'] as String? ?? '', // Default if null
      gender: _enumFromStringSafe(Gender.values, map['gender'] as String?, defaultValue: Gender.Prefer_not_to_say)!, // Assume Prefer_not_to_say if invalid/null
      age: map['age'] as int? ?? 0, // Default if null
      skinType: _enumFromStringSafe(SkinType.values, map['skin_type'] as String?), // Null if invalid/null
      riskProfile: _enumFromStringSafe(RiskProfile.values, map['risk_profile'] as String?), // Null if invalid/null
      profilePic: map['profile_pic'] as String?,
    );
  }

  /// Converts the User object into a map suitable for database insertion or update.
  /// Excludes `userId` if it's null (for auto-increment insertion).
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      // user_id is handled by the database on insert
      'auth_method': authMethod.name, // Store enum name as string
      'auth_hash': authHash,
      'salt': salt,
      'first_name': firstName,
      'last_name': lastName,
      'gender': gender.name,
      'age': age,
      'skin_type': skinType?.name, // Store enum name or null
      'risk_profile': riskProfile?.name, // Store enum name or null
      'profile_pic': profilePic,
    };
    // Include user_id only if it's not null (for updates)
    if (userId != null) {
      map['user_id'] = userId;
    }
    return map;
  }

  // --- Utility Methods ---

  /// Creates a copy of this User instance with potentially updated fields.
  /// Allows setting fields to null explicitly using `clear` flags.
  User copyWith({
    int? userId,
    AuthMethod? authMethod,
    String? authHash,
    bool clearAuthHash = false,
    String? salt,
    String? firstName,
    String? lastName,
    Gender? gender,
    int? age,
    SkinType? skinType,
    bool clearSkinType = false,
    RiskProfile? riskProfile,
    bool clearRiskProfile = false,
    String? profilePic,
    bool clearProfilePic = false,
  }) {
    return User(
      userId: userId ?? this.userId,
      authMethod: authMethod ?? this.authMethod,
      authHash: clearAuthHash ? null : (authHash ?? this.authHash),
      salt: salt ?? this.salt,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      skinType: clearSkinType ? null : (skinType ?? this.skinType),
      riskProfile: clearRiskProfile ? null : (riskProfile ?? this.riskProfile),
      profilePic: clearProfilePic ? null : (profilePic ?? this.profilePic),
    );
  }

  /// Returns a display name combining first and last name.
  String get displayName => '$firstName $lastName'.trim();

  // --- Equatable Implementation ---

  @override
  List<Object?> get props => [
    userId,
    authMethod,
    authHash,
    salt,
    firstName,
    lastName,
    gender,
    age,
    skinType,
    riskProfile,
    profilePic,
  ];

  // Optional: toString for easier debugging
  @override
  String toString() {
    return 'User(userId: $userId, name: $displayName, auth: $authMethod, age: $age, skin: $skinType, risk: $riskProfile)';
  }
}