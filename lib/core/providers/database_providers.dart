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
import '../../features/history/providers/history_filter_providers.dart';

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

// Provider to fetch AND FILTER/SORT scans for the current user
@riverpod
Future<List<Scan>> userScans(UserScansRef ref) async { // Removed newestFirst argument
  final currentUser = ref.watch(currentUserProvider);
  final scanDao = ref.watch(scanDaoProvider);

  // *** Watch filter states ***
  final searchQuery = ref.watch(historySearchQueryProvider);
  final sortOrder = ref.watch(historySortOrderProvider);
  print("DEBUG: userScansProvider rebuilding. Query: '$searchQuery', Sort: $sortOrder"); // Debug log

  if (currentUser == null || currentUser.userId == null) return [];

  // 1. Fetch ALL scans for the user initially (DAO sorts by date desc by default now)
  // We'll handle sorting and filtering in Dart now.
  // Alternatively, modify DAO method to accept search/sort parameters.
  // Fetching all and filtering here is simpler for moderate amounts of data.
  List<Scan> allScans = await scanDao.getScansByUserId(currentUser.userId!, newestFirst: true); // Fetch newest first initially

  // 2. Apply Search Filter (Case-insensitive)
  if (searchQuery.trim().isNotEmpty) {
    final lowerQuery = searchQuery.trim().toLowerCase();
    allScans = allScans.where((scan) {
      final scanName = scan.scanName?.toLowerCase() ?? '';
      // Add other fields to search if needed (e.g., formatted date?)
      return scanName.contains(lowerQuery);
    }).toList();
  }

  // 3. Apply Sorting
  allScans.sort((a, b) {
    switch (sortOrder) {
      case HistorySortOption.dateAsc:
        return a.scanDate.compareTo(b.scanDate);
      case HistorySortOption.nameAsc:
      // Handle null names gracefully
        return (a.scanName ?? '').toLowerCase().compareTo((b.scanName ?? '').toLowerCase());
      case HistorySortOption.nameDesc:
        return (b.scanName ?? '').toLowerCase().compareTo((a.scanName ?? '').toLowerCase());
      case HistorySortOption.dateDesc: // Default, already fetched like this, but good to be explicit
      default:
        return b.scanDate.compareTo(a.scanDate);
    }
  });

  print("DEBUG: userScansProvider returning ${allScans.length} filtered/sorted scans.");
  return allScans;
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

// Provider to fetch ALL lesions for the current user
// This is needed so we can filter by bodySide in the UI provider
@riverpod
Future<List<Lesion>> allUserLesions(AllUserLesionsRef ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final lesionDao = ref.watch(lesionDaoProvider);

  if (currentUser == null || currentUser.userId == null) {
    return []; // No user, no lesions
  }
  print("DEBUG: allUserLesionsProvider fetching lesions for user ${currentUser.userId}");
  final lesions = await lesionDao.getAllLesionsByUserId(currentUser.userId!);
  print("DEBUG: allUserLesionsProvider found ${lesions.length} total lesions.");
  return lesions;
}