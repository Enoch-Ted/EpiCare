// lib/core/database/daos/lesion_dao.dart

import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../entities/lesion.dart'; // The Lesion entity
import '../../constants/app_constants.dart'; // For table name

class LesionDao {
  final AppDatabase _appDatabase = AppDatabase();

  // --- Create ---

  /// Inserts a new lesion record, typically associated with a scan.
  /// Returns the lesion_id of the newly inserted lesion.
  Future<int> insertLesion(Lesion lesion) async {
    final db = await _appDatabase.database;
    try {
      final map = lesion.toMap();
      map.remove('lesion_id'); // Let DB auto-increment

      final id = await db.insert(
        DbTableNames.lesions,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print("Inserted lesion with id: $id for scan: ${lesion.scanId}");
      return id;
    } catch (e) {
      print("Error inserting lesion for scan ${lesion.scanId}: $e");
      return -1;
    }
  }

  /// Inserts multiple lesions efficiently using a batch operation.
  /// Useful after processing a scan image that identifies multiple lesions.
  /// Returns a list of the new lesion_ids, or an empty list on error.
  Future<List<int>> insertMultipleLesions(List<Lesion> lesions) async {
    if (lesions.isEmpty) return [];
    final db = await _appDatabase.database;
    final batch = db.batch();
    List<int> generatedIds = []; // To potentially store IDs if needed, though batch doesn't return them directly

    try {
      for (final lesion in lesions) {
        final map = lesion.toMap();
        map.remove('lesion_id');
        batch.insert(
          DbTableNames.lesions,
          map,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        // Note: Batch insert doesn't easily return individual IDs.
        // If IDs are needed immediately, insert one by one or query afterwards.
      }
      await batch.commit(noResult: true); // Commit the batch
      print("Inserted ${lesions.length} lesions for scan: ${lesions.first.scanId}");
      // Querying back might be needed if you require the exact IDs right after batch insert
      return []; // Placeholder - batch commit doesn't return IDs
    } catch (e) {
      print("Error inserting multiple lesions for scan ${lesions.first.scanId}: $e");
      return [];
    }
  }

  // --- Read ---

  /// Retrieves a specific lesion by its lesion_id.
  Future<Lesion?> getLesionById(int lesionId) async {
    final db = await _appDatabase.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DbTableNames.lesions,
        where: 'lesion_id = ?',
        whereArgs: [lesionId],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return Lesion.fromMap(maps.first);
      } else {
        return null; // Lesion not found
      }
    } catch (e) {
      print("Error getting lesion by id $lesionId: $e");
      return null;
    }
  }

  /// Retrieves all lesions associated with a specific scan_id.
  /// Returns a list of Lesion objects.
  Future<List<Lesion>> getLesionsByScanId(int scanId) async {
    final db = await _appDatabase.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DbTableNames.lesions,
        where: 'scan_id = ?',
        whereArgs: [scanId],
        orderBy: 'lesion_id ASC', // Or order by coordinates, confidence etc.
      );

      if (maps.isNotEmpty) {
        return List.generate(maps.length, (i) => Lesion.fromMap(maps[i]));
      } else {
        return []; // No lesions found for this scan
      }
    } catch (e) {
      print("Error getting lesions for scan $scanId: $e");
      return [];
    }
  }

  /// Retrieves all lesions for a specific user by joining scans and lesions tables.
  /// Returns a list of Lesion objects.
  Future<List<Lesion>> getAllLesionsByUserId(int userId) async {
    final db = await _appDatabase.database;
    // Correct JOIN syntax
    final String query = '''
       SELECT l.* FROM ${DbTableNames.lesions} l
       INNER JOIN ${DbTableNames.scans} s ON l.scan_id = s.scan_id
       WHERE s.user_id = ?
       ORDER BY s.scan_date DESC, l.lesion_id ASC
     ''';
    try {
      final List<Map<String, dynamic>> maps = await db.rawQuery(query, [userId]);

      if (maps.isNotEmpty) {
        return List.generate(maps.length, (i) => Lesion.fromMap(maps[i]));
      } else {
        return []; // No lesions found for this user
      }
    } catch (e) {
      print("Error getting all lesions for user $userId: $e");
      return [];
    }
  }


  // --- Update ---

  /// Updates an existing lesion record.
  /// Uses lesion.lesionId to identify the record.
  Future<int> updateLesion(Lesion lesion) async {
    if (lesion.lesionId == null) {
      print("Error: Cannot update lesion with null lesionId.");
      return 0;
    }
    final db = await _appDatabase.database;
    try {
      final count = await db.update(
        DbTableNames.lesions,
        lesion.toMap(), // includes lesionId
        where: 'lesion_id = ?',
        whereArgs: [lesion.lesionId],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print("Updated $count lesion(s) with id: ${lesion.lesionId}");
      return count;
    } catch (e) {
      print("Error updating lesion ${lesion.lesionId}: $e");
      return 0;
    }
  }

  // --- Delete ---

  /// Deletes a specific lesion by its lesion_id.
  Future<int> deleteLesionById(int lesionId) async {
    final db = await _appDatabase.database;
    try {
      final count = await db.delete(
        DbTableNames.lesions,
        where: 'lesion_id = ?',
        whereArgs: [lesionId],
      );
      print("Deleted $count lesion(s) with id: $lesionId");
      return count;
    } catch (e) {
      print("Error deleting lesion $lesionId: $e");
      return 0;
    }
  }

  /// Deletes all lesions associated with a specific scan_id.
  /// Useful when deleting a scan if cascade delete wasn't used or failed.
  Future<int> deleteLesionsByScanId(int scanId) async {
    final db = await _appDatabase.database;
    try {
      final count = await db.delete(
        DbTableNames.lesions,
        where: 'scan_id = ?',
        whereArgs: [scanId],
      );
      print("Deleted $count lesion(s) for scan id: $scanId");
      return count;
    } catch (e) {
      print("Error deleting lesions for scan $scanId: $e");
      return 0;
    }
  }
}