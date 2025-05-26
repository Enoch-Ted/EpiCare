// lib/core/database/entities/user_settings.dart
import 'package:equatable/equatable.dart';
// *** CORRECTED IMPORT PATH ***
import '../../constants/app_constants.dart'; // Use relative path

class UserSettings extends Equatable {
  final int userId; // Primary key, also foreign key to User table
  final int scanReminderDays;
  final bool darkMode;
  final bool notificationsEnabled; // Added based on earlier discussion

  const UserSettings({
    required this.userId, // Must be associated with a user
    // Use default values from constants if not provided
    this.scanReminderDays = DefaultSettings.scanReminderDays, // Should resolve now
    this.darkMode = DefaultSettings.darkMode, // Should resolve now
    this.notificationsEnabled = DefaultSettings.notificationsEnabled, // Should resolve now
  });

  // --- Database Mapping ---

  /// Factory constructor to create a UserSettings instance from a database map.
  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      // userId should always be present as it's the PK
      userId: map['user_id'] as int? ?? 0, // Default to 0 if somehow null (indicates error)
      scanReminderDays: map['scan_reminder_days'] as int? ?? DefaultSettings.scanReminderDays, // Should resolve now
      // SQLite stores BOOLEAN as 0 (false) or 1 (true)
      darkMode: (map['dark_mode'] as int? ?? (DefaultSettings.darkMode ? 1 : 0)) == 1, // Should resolve now
      notificationsEnabled: (map['notifications_enabled'] as int? ?? (DefaultSettings.notificationsEnabled ? 1 : 0)) == 1, // Should resolve now
    );
  }

  /// Converts the UserSettings object into a map suitable for database insertion or update.
  /// The `userId` is always included as it's the primary key.
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'scan_reminder_days': scanReminderDays,
      'dark_mode': darkMode ? 1 : 0, // Store boolean as integer 0 or 1
      'notifications_enabled': notificationsEnabled ? 1 : 0, // Store boolean as integer
    };
  }

  // --- Utility Methods ---

  /// Creates a copy of this UserSettings instance with potentially updated fields.
  UserSettings copyWith({
    int? userId, // Primary key usually doesn't change via copyWith
    int? scanReminderDays,
    bool? darkMode,
    bool? notificationsEnabled,
  }) {
    return UserSettings(
      userId: userId ?? this.userId, // Keep original userId by default
      scanReminderDays: scanReminderDays ?? this.scanReminderDays,
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  // --- Equatable Implementation ---

  @override
  List<Object?> get props => [userId, scanReminderDays, darkMode, notificationsEnabled];

  // Optional: toString for debugging
  @override
  String toString() {
    return 'UserSettings(userId: $userId, reminderDays: $scanReminderDays, darkMode: $darkMode, notifications: $notificationsEnabled)';
  }
}