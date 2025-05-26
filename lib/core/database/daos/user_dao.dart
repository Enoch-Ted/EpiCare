// lib/core/database/daos/user_dao.dart

import 'package:sqflite/sqflite.dart';
import '../app_database.dart'; // To get the database instance
import '../entities/user.dart'; // The User entity
import '../../constants/app_constants.dart'; // For table name

class UserDao {
  // Get the singleton instance of AppDatabase
  final AppDatabase _appDatabase = AppDatabase();

  // --- Create ---

  /// Inserts a new user into the database.
  /// Returns the user_id of the newly inserted user.
  /// Handles potential conflicts by replacing existing record with the same primary key (if any).
  Future<int> insertUser(User user) async {
    final db = await _appDatabase.database;
    try {
      // Use toMap() ensuring userId is null for auto-increment
      final map = user.toMap();
      map.remove('user_id'); // Ensure userId isn't in the map for insert

      final id = await db.insert(
        DbTableNames.users,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace, // Or .fail, .ignore
      );
      print("Inserted user with id: $id");
      return id;
    } catch (e) {
      print("Error inserting user: $e");
      // Return -1 or throw exception based on desired error handling
      return -1;
    }
  }

  // --- Read ---

  /// Retrieves a user by their user_id.
  /// Returns the User object or null if not found.
  Future<User?> getUserById(int userId) async {
    final db = await _appDatabase.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DbTableNames.users,
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1, // We only expect one user
      );

      if (maps.isNotEmpty) {
        return User.fromMap(maps.first);
      } else {
        return null; // User not found
      }
    } catch (e) {
      print("Error getting user by id $userId: $e");
      return null;
    }
  }

  /// Retrieves all users from the database.
  /// Useful for profile switching screen.
  /// Returns a list of User objects.
  Future<List<User>> getAllUsers() async {
    final db = await _appDatabase.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DbTableNames.users,
        orderBy: 'first_name ASC, last_name ASC', // Example ordering
      );

      if (maps.isNotEmpty) {
        // Convert each map to a User object
        return List.generate(maps.length, (i) {
          return User.fromMap(maps[i]);
        });
      } else {
        return []; // Return empty list if no users found
      }
    } catch (e) {
      print("Error getting all users: $e");
      return []; // Return empty list on error
    }
  }

  // --- Update ---

  /// Updates an existing user in the database.
  /// Uses the user.userId to find the record to update.
  /// Returns the number of rows affected (should be 1 if successful, 0 if user not found).
  Future<int> updateUser(User user) async {
    if (user.userId == null) {
      print("Error: Cannot update user with null userId.");
      return 0; // Or throw error
    }
    final db = await _appDatabase.database;
    try {
      final count = await db.update(
        DbTableNames.users,
        user.toMap(), // toMap includes userId if it's not null
        where: 'user_id = ?',
        whereArgs: [user.userId],
        conflictAlgorithm: ConflictAlgorithm.replace, // Or .fail
      );
      print("Updated $count user(s) with id: ${user.userId}");
      return count;
    } catch (e) {
      print("Error updating user ${user.userId}: $e");
      return 0;
    }
  }

  // --- Delete ---

  /// Deletes a user from the database by their user_id.
  /// Note: ON DELETE CASCADE should handle related scans, lesions, settings.
  /// Returns the number of rows affected (should be 1 if successful, 0 if user not found).
  Future<int> deleteUserById(int userId) async {
    final db = await _appDatabase.database;
    try {
      final count = await db.delete(
        DbTableNames.users,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      print("Deleted $count user(s) with id: $userId");
      // Consider adding deletion logic for associated image files (profile pic) if stored locally
      return count;
    } catch (e) {
      print("Error deleting user $userId: $e");
      return 0;
    }
  }

// --- Other Potential Methods ---
// Future<User?> getUserByCredentials(String identifier, String password) async { ... }
// Future<int> countUsers() async { ... }

}