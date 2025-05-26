// lib/core/database/daos/scan_dao.dart

import 'package:sqflite/sqflite.dart';
import '../app_database.dart'; // Path is correct relative to this file
import '../entities/scan.dart'; // The Scan entity
import '../../constants/app_constants.dart'; // For table name
import 'dart:io'; // *** Import dart:io for File operations ***

class ScanDao {
  final AppDatabase _appDatabase = AppDatabase();

  // --- Create ---
  Future<int> insertScan(Scan scan) async {
    final db = await _appDatabase.database;
    try {
      final map = scan.toMap();
      map.remove('scan_id');
      final id = await db.insert(
        DbTableNames.scans,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print("Inserted scan with id: $id for user: ${scan.userId}");
      return id;
    } catch (e) {
      print("Error inserting scan for user ${scan.userId}: $e");
      return -1;
    }
  }

  // --- Read ---
  Future<Scan?> getScanById(int scanId) async {
    final db = await _appDatabase.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DbTableNames.scans,
        where: 'scan_id = ?',
        whereArgs: [scanId],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return Scan.fromMap(maps.first);
      } else {
        return null;
      }
    } catch (e) {
      print("Error getting scan by id $scanId: $e");
      return null;
    }
  }

  Future<List<Scan>> getScansByUserId(int userId, {bool newestFirst = true}) async {
    final db = await _appDatabase.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DbTableNames.scans,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'scan_date ${newestFirst ? 'DESC' : 'ASC'}',
      );
      if (maps.isNotEmpty) {
        return List.generate(maps.length, (i) => Scan.fromMap(maps[i]));
      } else {
        return [];
      }
    } catch (e) {
      print("Error getting scans for user $userId: $e");
      return [];
    }
  }

  Future<List<Scan>> getAllScans({bool newestFirst = true}) async {
    // ... (implementation remains the same) ...
    final db = await _appDatabase.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DbTableNames.scans,
        orderBy: 'scan_date ${newestFirst ? 'DESC' : 'ASC'}',
      );
      if (maps.isNotEmpty) {
        return List.generate(maps.length, (i) => Scan.fromMap(maps[i]));
      } else { return []; }
    } catch (e) { print("Error getting all scans: $e"); return []; }
  }

  // --- Update ---
  Future<int> updateScan(Scan scan) async {
    // ... (implementation remains the same) ...
    if (scan.scanId == null) { print("Error: Cannot update scan with null scanId."); return 0; }
    final db = await _appDatabase.database;
    try {
      final count = await db.update( DbTableNames.scans, scan.toMap(), where: 'scan_id = ?', whereArgs: [scan.scanId], conflictAlgorithm: ConflictAlgorithm.replace, );
      print("Updated $count scan(s) with id: ${scan.scanId}"); return count;
    } catch (e) { print("Error updating scan ${scan.scanId}: $e"); return 0; }
  }

  // --- Delete ---

  /// Deletes a specific scan by its scan_id.
  /// Also attempts to delete the associated image file.
  /// Note: ON DELETE CASCADE should handle related lesions in the DB.
  /// Returns the number of rows affected in the DB.
  Future<int> deleteScanById(int scanId) async {
    final db = await _appDatabase.database;
    String imagePath = ''; // Store path for file deletion

    try {
      // --- Get image path BEFORE deleting DB record ---
      print("Attempting to get image path for scan $scanId before deletion.");
      final List<Map<String, dynamic>> maps = await db.query(
        DbTableNames.scans,
        columns: ['image_path'], // Only fetch the needed column
        where: 'scan_id = ?',
        whereArgs: [scanId],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        imagePath = maps.first['image_path'] as String? ?? '';
        print("Found image path: $imagePath");
      } else {
        print("No scan record found for ID $scanId to get image path.");
      }
      // --- End Get image path ---

      // --- Delete DB record ---
      print("Attempting to delete scan record $scanId from database.");
      final count = await db.delete(
        DbTableNames.scans,
        where: 'scan_id = ?',
        whereArgs: [scanId],
      );
      print("Deleted $count scan record(s) with id: $scanId from database.");
      // --- End Delete DB record ---

      // --- Delete Image File (only if DB delete was successful, count > 0?) ---
      // Consider only deleting file if DB record was actually deleted (count > 0)
      // and if path is valid and not a placeholder.
      if (count > 0 && imagePath.isNotEmpty && !imagePath.startsWith('/placeholder/')) { // Avoid deleting placeholder
        print("Attempting to delete image file: $imagePath");
        try {
          final imageFile = File(imagePath);
          // Check if file exists before attempting delete
          if (await imageFile.exists()) {
            await imageFile.delete();
            print("Successfully deleted image file: $imagePath");
          } else {
            print("Image file not found at path, skipping delete: $imagePath");
          }
        } catch (fileErr) {
          // Log file deletion error but don't fail the whole operation
          print("Error deleting image file $imagePath: $fileErr");
        }
      } else if (count > 0) {
        print("No valid image path found ('$imagePath') or placeholder path, skipping file delete.");
      }
      // --- End Delete Image File ---

      return count; // Return DB delete count
    } catch (e) {
      print("Error during deleteScanById for scan $scanId: $e");
      return 0; // Return 0 indicates DB error or record not found initially
    }
  } // End deleteScanById


  /// Deletes all scans associated with a specific user_id.
  /// Also attempts to delete associated image files.
  Future<int> deleteScansByUserId(int userId) async {
    final db = await _appDatabase.database;
    List<String> imagePathsToDelete = []; // Store paths before deleting records

    try {
      // --- Get all image paths for this user BEFORE deleting records ---
      print("Getting image paths for user $userId before deleting scans.");
      final List<Map<String, dynamic>> maps = await db.query(
        DbTableNames.scans,
        columns: ['image_path'],
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      if (maps.isNotEmpty) {
        imagePathsToDelete = maps
            .map((map) => map['image_path'] as String? ?? '')
            .where((path) => path.isNotEmpty && !path.startsWith('/placeholder/')) // Filter valid paths
            .toList();
        print("Found ${imagePathsToDelete.length} image paths to potentially delete for user $userId.");
      }
      // --- End Get image paths ---

      // --- Delete DB records ---
      print("Attempting to delete scan records for user $userId.");
      final count = await db.delete(
        DbTableNames.scans,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      print("Deleted $count scan record(s) for user id: $userId.");
      // --- End Delete DB records ---

      // --- Delete Image Files ---
      if (count > 0 && imagePathsToDelete.isNotEmpty) {
        print("Attempting to delete ${imagePathsToDelete.length} associated image files...");
        int deletedFiles = 0;
        for (String path in imagePathsToDelete) {
          try {
            final imageFile = File(path);
            if (await imageFile.exists()) {
              await imageFile.delete();
              deletedFiles++;
            }
          } catch (fileErr) {
            print("Error deleting image file $path: $fileErr");
            // Continue trying to delete others
          }
        }
        print("Deleted $deletedFiles out of ${imagePathsToDelete.length} image files.");
      } else if (count > 0) {
        print("No valid image paths found for user $userId, skipping file deletion.");
      }
      // --- End Delete Image Files ---

      return count; // Return count of deleted DB records
    } catch (e) {
      print("Error deleting scans for user $userId: $e");
      return 0;
    }
  } // End deleteScansByUserId

} // End ScanDao class