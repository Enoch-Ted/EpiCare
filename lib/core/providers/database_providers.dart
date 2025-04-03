// lib/core/providers/database_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
// Ensure Database is imported if the databaseProvider is kept
// If you only provide DAOs, you might not need this specific import here.
import 'package:sqflite/sqflite.dart';

// Ensure all these paths are EXACTLY correct relative to this file
import '../database/app_database.dart';
import '../database/daos/user_dao.dart';
import '../database/daos/scan_dao.dart';
import '../database/daos/lesion_dao.dart';
import '../database/daos/user_settings_dao.dart';
import '../database/entities/lesion.dart';
import '../database/entities/scan.dart';
import '../database/entities/user.dart';
import '../database/entities/user_settings.dart';


import 'security_providers.dart';
 // Need Scan entity
import 'package:care/core/navigation/app_router.dart';
// Ensure this matches the filename EXACTLY and is present
part 'database_providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) { // <<< Check Ref type spelling
  return AppDatabase();
}

@Riverpod(keepAlive: true)
Future<Database> database(DatabaseRef ref) async { // <<< Check Ref type spelling
  final appDb = ref.watch(appDatabaseProvider); // <<< Check Provider name spelling
  return appDb.database;
}

@Riverpod(keepAlive: true)
UserDao userDao(UserDaoRef ref) { // <<< Check Ref type spelling
  return UserDao();
}

@Riverpod(keepAlive: true)
ScanDao scanDao(ScanDaoRef ref) { // <<< Check Ref type spelling
  return ScanDao();
}

@Riverpod(keepAlive: true)
LesionDao lesionDao(LesionDaoRef ref) { // <<< Check Ref type spelling
  return LesionDao();
}

@Riverpod(keepAlive: true)
UserSettingsDao userSettingsDao(UserSettingsDaoRef ref) { // <<< Check Ref type spelling
  return UserSettingsDao();
}

// Returns a Map like {'front': count, 'back': count}
@riverpod
// *** CORRECT THE REF TYPE HERE ***
Future<Map<String, int>> userLesionCounts(UserLesionCountsRef ref) async {// Changed from UserLesionCountsRef
  final currentUser = ref.watch(currentUserProvider);
  final lesionDao = ref.watch(lesionDaoProvider);

  if (currentUser == null || currentUser.userId == null) {
    return {'front': 0, 'back': 0};
  }

  final allLesions = await lesionDao.getAllLesionsByUserId(currentUser.userId!);

  int frontCount = 0;
  int backCount = 0;
  for (final lesion in allLesions) {
    if (lesion.bodySide == BodySide.Front) {
      frontCount++;
    } else if (lesion.bodySide == BodySide.Back) {
      backCount++;
    }
  }
  return {'front': frontCount, 'back': backCount};
}

@riverpod
// *** CORRECT THE REF TYPE HERE ***
Future<List<Scan>> userScans(UserScansRef ref, {bool newestFirst = true}) async { // Should be UserScansRef
  print("DEBUG: userScansProvider called.");
  // Depend on the current user state
  final currentUser = ref.watch(currentUserProvider);
  // Depend on the ScanDao
  final scanDao = ref.watch(scanDaoProvider);

  if (currentUser == null || currentUser.userId == null) {
    print("DEBUG: userScansProvider - No current user.");
    return [];
  }
  try { // Add try-catch
    print("DEBUG: userScansProvider - Fetching scans for user ${currentUser.userId}");
    final scans = await scanDao.getScansByUserId(currentUser.userId!, newestFirst: newestFirst);
    print("DEBUG: userScansProvider - Found ${scans.length} scans.");
    return scans;
  } catch (e) {
    print("DEBUG: userScansProvider - Error fetching scans: $e");
    rethrow; // Rethrow error so .when can catch it
  }
}


@riverpod
Future<List<User>> allUsers(AllUsersRef ref) async { // Changed Ref name
  final userDao = ref.watch(userDaoProvider);
  return userDao.getAllUsers();
}

@riverpod
Future<UserSettings?> currentUserSettings(CurrentUserSettingsRef ref) async {
  // Depend on current user and settings DAO
  final user = ref.watch(currentUserProvider);
  final settingsDao = ref.watch(userSettingsDaoProvider);

  if (user == null || user.userId == null) {
    // No logged-in user, return null or default settings for a non-existent user?
    // Returning null might be safer to indicate settings aren't applicable.
    return null;
  }

  // Fetch settings for the current user's ID
  final settings = await settingsDao.getSettingsByUserId(user.userId!);

  // If settings don't exist in DB yet for this user, return default settings
  // associated with their ID.
  return settings ?? UserSettings(userId: user.userId!);
}

@riverpod
Future<Scan?> scanById(ScanByIdRef ref, int scanId) async {
  if (scanId <= 0) return null; // Handle invalid ID
  final scanDao = ref.watch(scanDaoProvider);
  print("DEBUG: scanByIdProvider fetching scan $scanId");
  return scanDao.getScanById(scanId);
}

// Provider to fetch Lesions for a specific Scan ID
// Takes scanId as an argument
@riverpod
Future<List<Lesion>> lesionsByScanId(LesionsByScanIdRef ref, int scanId) async {
  if (scanId <= 0) return []; // Handle invalid ID
  final lesionDao = ref.watch(lesionDaoProvider);
  print("DEBUG: lesionsByScanIdProvider fetching lesions for scan $scanId");
  return lesionDao.getLesionsByScanId(scanId);
}