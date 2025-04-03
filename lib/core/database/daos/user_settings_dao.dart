// lib/core/database/daos/user_settings_dao.dart

import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../entities/user_settings.dart'; // The UserSettings entity
import '../../constants/app_constants.dart'; // For table name and defaults

class UserSettingsDao {
  final AppDatabase _appDatabase = AppDatabase();

  // --- Create/Update (Upsert) ---

  /// Inserts or replaces the settings for a given user_id.
  /// Since user_id is the primary key, inserting with the same user_id
  /// will replace the existing record if ConflictAlgorithm.replace is used.
  /// Returns the row ID of the inserted/replaced record, or -1 on error.
  Future<int> upsertSettings(UserSettings settings) async {
    final db = await _appDatabase.database;
    try {
      // Use toMap() which includes the userId (PK)
      final map = settings.toMap();

      final id = await db.insert(
        DbTableNames.userSettings,
        map,
        // Replace existing settings if user_id already exists
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print("Upserted settings for user id: ${settings.userId}");
      return id; // Returns rowId, which is typically userId for this table
    } catch (e) {
      print("Error upserting settings for user ${settings.userId}: $e");
      return -1; // Indicate error
    }
  }

  // --- Read ---

  /// Retrieves the settings for a specific user_id.
  /// Returns the UserSettings object or null if not found (e.g., new user).
  Future<UserSettings?> getSettingsByUserId(int userId) async {
    final db = await _appDatabase.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DbTableNames.userSettings,
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return UserSettings.fromMap(maps.first);
      } else {
        // If no settings found for the user, return null
        // Or alternatively, return default settings:
        // return UserSettings(userId: userId); // Returns settings with default values
        return null;
      }
    } catch (e) {
      print("Error getting settings for user $userId: $e");
      return null;
    }
  }

  // --- Update ---
  // (Often covered by upsertSettings, but specific update methods can be added if needed)

  /// Updates only specific fields for a user's settings.
  /// More efficient than upsert if only changing one value.
  /// Example: Update only the dark mode setting.
  Future<int> updateDarkMode(int userId, bool isDarkMode) async {
    final db = await _appDatabase.database;
    try {
      final count = await db.update(
        DbTableNames.userSettings,
        {'dark_mode': isDarkMode ? 1 : 0}, // Map with only the field to update
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      print("Updated dark mode for user $userId: $count row(s)");
      return count;
    } catch (e) {
      print("Error updating dark mode for user $userId: $e");
      return 0;
    }
  }

  /// Example: Update only the reminder days setting.
  Future<int> updateReminderDays(int userId, int days) async {
    final db = await _appDatabase.database;
    try {
      final count = await db.update(
        DbTableNames.userSettings,
        {'scan_reminder_days': days},
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      print("Updated reminder days for user $userId: $count row(s)");
      return count;
    } catch (e) {
      print("Error updating reminder days for user $userId: $e");
      return 0;
    }
  }

  /// Example: Update only the notifications enabled setting.
  Future<int> updateNotificationsEnabled(int userId, bool isEnabled) async {
    final db = await _appDatabase.database;
    try {
      final count = await db.update(
        DbTableNames.userSettings,
        {'notifications_enabled': isEnabled ? 1 : 0},
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      print("Updated notifications enabled for user $userId: $count row(s)");
      return count;
    } catch (e) {
      print("Error updating notifications enabled for user $userId: $e");
      return 0;
    }
  }


  // --- Delete ---

  /// Deletes the settings record for a specific user_id.
  /// Usually handled by ON DELETE CASCADE when the user is deleted,
  /// but provided for completeness or specific cleanup scenarios.
  Future<int> deleteSettingsByUserId(int userId) async {
    final db = await _appDatabase.database;
    try {
      final count = await db.delete(
        DbTableNames.userSettings,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      print("Deleted $count settings record(s) for user id: $userId");
      return count;
    } catch (e) {
      print("Error deleting settings for user $userId: $e");
      return 0;
    }
  }
}