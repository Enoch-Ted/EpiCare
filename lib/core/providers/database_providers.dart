// lib/core/providers/database_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart'; // Keep if 'database' provider is used directly

// Corrected/verified paths
import '../database/app_database.dart';
import '../database/daos/user_dao.dart';
import '../database/daos/scan_dao.dart';
import '../database/daos/lesion_dao.dart';
import '../database/daos/user_settings_dao.dart';

// Import entities including BodySide from lesion.dart
import '../database/entities/lesion.dart' show Lesion, BodySide; // Import BodySide from here
import '../database/entities/scan.dart';
import '../database/entities/user.dart';
import '../database/entities/user_settings.dart';

// Import other providers
import '../../features/history/providers/history_filter_providers.dart';
import 'security_providers.dart';
// import 'package:care/core/navigation/app_router.dart'; // app_router.dart typically shouldn't be in database_providers

part 'database_providers.g.dart'; // Ensure this matches the filename

@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) {
  return AppDatabase();
}

@Riverpod(keepAlive: true)
Future<Database> database(DatabaseRef ref) async {
  final appDb = ref.watch(appDatabaseProvider);
  return appDb.database;
}

@Riverpod(keepAlive: true)
UserDao userDao(UserDaoRef ref) {
  // Assuming UserDao constructor doesn't require AppDatabase instance.
  // If it does, you'd get it from ref.watch(appDatabaseProvider)
  // return UserDao(ref.watch(appDatabaseProvider));
  return UserDao(); // If it has a default constructor or handles DB internally
}

@Riverpod(keepAlive: true)
ScanDao scanDao(ScanDaoRef ref) {
  // Similar to UserDao, pass AppDatabase if needed by constructor
  // return ScanDao(ref.watch(appDatabaseProvider));
  return ScanDao();
}

@Riverpod(keepAlive: true)
LesionDao lesionDao(LesionDaoRef ref) {
  // Similar to UserDao, pass AppDatabase if needed by constructor
  // return LesionDao(ref.watch(appDatabaseProvider));
  return LesionDao();
}

@Riverpod(keepAlive: true)
UserSettingsDao userSettingsDao(UserSettingsDaoRef ref) {
  // Similar to UserDao, pass AppDatabase if needed by constructor
  // return UserSettingsDao(ref.watch(appDatabaseProvider));
  return UserSettingsDao();
}

// Returns a Map like {'front': count, 'back': count}
@riverpod
Future<Map<String, int>> userLesionCounts(UserLesionCountsRef ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final lesionDao = ref.watch(lesionDaoProvider);

  if (currentUser == null || currentUser.userId == null) {
    return {'front': 0, 'back': 0};
  }

  final allLesions = await lesionDao.getAllLesionsByUserId(currentUser.userId!);

  int frontCount = 0;
  int backCount = 0;
  for (final lesion in allLesions) {
    // Use the imported BodySide enum from lesion.dart
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
Future<List<Scan>> userScans(UserScansRef ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final scanDao = ref.watch(scanDaoProvider);

  final searchQuery = ref.watch(historySearchQueryProvider);
  final sortOrder = ref.watch(historySortOrderProvider);
  // print("DEBUG: userScansProvider rebuilding. Query: '$searchQuery', Sort: $sortOrder");

  if (currentUser == null || currentUser.userId == null) return [];

  List<Scan> allScans = await scanDao.getScansByUserId(currentUser.userId!, newestFirst: true);

  if (searchQuery.trim().isNotEmpty) {
    final lowerQuery = searchQuery.trim().toLowerCase();
    allScans = allScans.where((scan) {
      final scanName = scan.scanName?.toLowerCase() ?? '';
      return scanName.contains(lowerQuery);
    }).toList();
  }

  allScans.sort((a, b) {
    switch (sortOrder) {
      case HistorySortOption.dateAsc:
        return a.scanDate.compareTo(b.scanDate);
      case HistorySortOption.nameAsc:
        return (a.scanName ?? '').toLowerCase().compareTo((b.scanName ?? '').toLowerCase());
      case HistorySortOption.nameDesc:
        return (b.scanName ?? '').toLowerCase().compareTo((a.scanName ?? '').toLowerCase());
      case HistorySortOption.dateDesc:
      default:
        return b.scanDate.compareTo(a.scanDate);
    }
  });

  // print("DEBUG: userScansProvider returning ${allScans.length} filtered/sorted scans.");
  return allScans;
}

@riverpod
Future<List<User>> allUsers(AllUsersRef ref) async {
  final userDao = ref.watch(userDaoProvider);
  return userDao.getAllUsers();
}

@riverpod
Future<UserSettings?> currentUserSettings(CurrentUserSettingsRef ref) async {
  final user = ref.watch(currentUserProvider);
  final settingsDao = ref.watch(userSettingsDaoProvider);

  if (user == null || user.userId == null) {
    return null;
  }
  final settings = await settingsDao.getSettingsByUserId(user.userId!);
  return settings ?? UserSettings(userId: user.userId!);
}

@riverpod
Future<Scan?> scanById(ScanByIdRef ref, int scanId) async {
  if (scanId <= 0) return null;
  final scanDao = ref.watch(scanDaoProvider);
  // print("DEBUG: scanByIdProvider fetching scan $scanId");
  return scanDao.getScanById(scanId);
}

// Provider to fetch Lesions for a specific Scan ID
@riverpod
Future<List<Lesion>> lesionsByScanId(LesionsByScanIdRef ref, int scanId) async {
  if (scanId <= 0) return [];
  final lesionDao = ref.watch(lesionDaoProvider);
  // print("DEBUG: lesionsByScanIdProvider fetching lesions for scan $scanId");
  return lesionDao.getLesionsByScanId(scanId);
}

// Provider to fetch ALL lesions for the current user
@riverpod
Future<List<Lesion>> allUserLesions(AllUserLesionsRef ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final lesionDao = ref.watch(lesionDaoProvider);

  if (currentUser == null || currentUser.userId == null) {
    return [];
  }
  // print("DEBUG: allUserLesionsProvider fetching lesions for user ${currentUser.userId}");
  final lesions = await lesionDao.getAllLesionsByUserId(currentUser.userId!);
  // print("DEBUG: allUserLesionsProvider found ${lesions.length} total lesions.");
  return lesions;
}

// ADDED: lesionByIdProvider (Family provider to fetch a single lesion by its ID)
@riverpod
Future<Lesion?> lesionById(LesionByIdRef ref, int lesionId) async {
  if (lesionId <= 0) return null;
  final lesionDao = ref.watch(lesionDaoProvider);
  print("DEBUG: lesionByIdProvider fetching lesion $lesionId");
  return lesionDao.getLesionById(lesionId); // Assuming your LesionDao has this method
}