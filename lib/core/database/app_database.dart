// lib/core/database/app_database.dart

import 'dart:async'; // For Future
import 'dart:io'; // For Directory
import 'package:path/path.dart'; // For join()
import 'package:path_provider/path_provider.dart'; // To find documents directory
import 'package:sqflite/sqflite.dart'; // The sqflite plugin
import '../constants/app_constants.dart'; // For DB name and version

class AppDatabase {
  // --- Singleton Pattern ---
  // Static instance variable
  static AppDatabase? _instance;
  // Private constructor
  AppDatabase._internal();
  // Factory constructor to return the singleton instance
  factory AppDatabase() {
    _instance ??= AppDatabase._internal();
    return _instance!;
  }
  // --- End Singleton Pattern ---

  // Database object instance (nullable until initialized)
  static Database? _database;

  // Getter for the database instance, initializes if needed
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      // print("Returning existing database instance.");
      return _database!;
    }
    // print("Initializing new database instance.");
    _database = await _initDB();
    return _database!;
  }

  // Initializes the database connection and creates tables if necessary
  Future<Database> _initDB() async {
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      // Use constants for database name
      final String path = join(documentsDirectory.path, DbConfig.databaseName);
      // print("Database path: $path");

      return await openDatabase(
        path,
        version: DbConfig.databaseVersion, // Use constant for version
        onCreate: _onCreate, // Function to run when DB is first created
        // onUpgrade: _onUpgrade, // Function to run on version changes (add later if needed)
        // onDowngrade: onDatabaseDowngradeDelete, // Strategy for version decrease
        onConfigure: _onConfigure, // Run configuration steps like enabling foreign keys
      );
    } catch (e) {
      print("Error initializing database: $e");
      // Rethrow or handle appropriately depending on app requirements
      rethrow;
    }
  }

  // Configuration function called every time the database is opened
  Future<void> _onConfigure(Database db) async {
    // print("Configuring database...");
    // Enforce foreign key constraints (essential for data integrity)
    await db.execute('PRAGMA foreign_keys = ON');
    // print("Foreign keys enabled.");
  }

  // Function called only when the database file is created for the first time
  Future<void> _onCreate(Database db, int version) async {
    print("Creating database tables (version $version)...");
    // Use batch operations for efficiency when creating multiple tables
    final batch = db.batch();

    // --- Table Creation SQL ---
    // Use constants for table names from DbTableNames

    // 1. users Table
    batch.execute('''
    CREATE TABLE ${DbTableNames.users} (
      user_id INTEGER PRIMARY KEY AUTOINCREMENT,
      auth_method TEXT NOT NULL CHECK(auth_method IN ('${AuthMethodConstants.PIN}', '${AuthMethodConstants.PASSWORD}', '${AuthMethodConstants.BIOMETRIC}', '${AuthMethodConstants.NONE}')),
      auth_hash TEXT,
      salt TEXT NOT NULL,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      gender TEXT NOT NULL CHECK(gender IN ('${GenderConstants.Male}', '${GenderConstants.Female}', '${GenderConstants.Other}', '${GenderConstants.Prefer_not_to_say}')),
      age INTEGER NOT NULL CHECK(age >= 0 AND age <= 120),
      skin_type TEXT CHECK(skin_type IN ('${SkinTypeConstants.I}', '${SkinTypeConstants.II}', '${SkinTypeConstants.III}', '${SkinTypeConstants.IV}', '${SkinTypeConstants.V}', '${SkinTypeConstants.VI}')),
      risk_profile TEXT CHECK(risk_profile IN ('${RiskProfileConstants.Low}', '${RiskProfileConstants.Medium}', '${RiskProfileConstants.High}')),
      profile_pic TEXT
    )
    ''');
    print("Users table SQL prepared.");

    // 2. scans Table
    batch.execute('''
    CREATE TABLE ${DbTableNames.scans} (
      scan_id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      scan_name TEXT DEFAULT ('Scan_' || strftime('%Y%m%d_%H%M%S', 'now', 'localtime')),
      image_path TEXT NOT NULL,
      scan_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES ${DbTableNames.users}(user_id) ON DELETE CASCADE
    )
    ''');
    print("Scans table SQL prepared.");


    // 3. lesions Table (Corrected CHECK constraint with String Literals)
    batch.execute('''
    CREATE TABLE ${DbTableNames.lesions} (
      lesion_id INTEGER PRIMARY KEY AUTOINCREMENT,
      scan_id INTEGER NOT NULL,
      -- *** Use PLAIN STRINGS for CHECK constraint ***
      risk_level TEXT NOT NULL CHECK(risk_level IN ('Benign', 'Precursor', 'Malignant', 'Undetermined')),
      lesion_type TEXT NOT NULL,
      confidence_score REAL NOT NULL CHECK(confidence_score >= 0 AND confidence_score <= 1),
      body_map_x REAL NOT NULL CHECK(body_map_x >= 0 AND body_map_x <= 1),
      body_map_y REAL NOT NULL CHECK(body_map_y >= 0 AND body_map_y <= 1),
      body_side TEXT CHECK(body_side IN ('${BodySideConstants.Front}', '${BodySideConstants.Back}')),
      FOREIGN KEY (scan_id) REFERENCES ${DbTableNames.scans}(scan_id) ON DELETE CASCADE
    )
    ''');
    print("Lesions table SQL prepared.");

    // 4. user_settings Table
    batch.execute('''
    CREATE TABLE ${DbTableNames.userSettings} (
      user_id INTEGER PRIMARY KEY,
      scan_reminder_days INTEGER DEFAULT ${DefaultSettings.scanReminderDays},
      dark_mode INTEGER DEFAULT ${DefaultSettings.darkMode ? 1 : 0}, -- Store BOOLEAN as 0 or 1
      notifications_enabled INTEGER DEFAULT ${DefaultSettings.notificationsEnabled ? 1 : 0}, -- Store BOOLEAN as 0 or 1
      FOREIGN KEY (user_id) REFERENCES ${DbTableNames.users}(user_id) ON DELETE CASCADE
    )
    ''');
    print("User settings table SQL prepared.");

    // --- Index Creation ---
    // Add indexes for columns frequently used in WHERE clauses or JOINs

    // Index on foreign key in scans table
    batch.execute('CREATE INDEX idx_scan_user ON ${DbTableNames.scans} (user_id)');
    // Index on foreign key in lesions table
    batch.execute('CREATE INDEX idx_lesion_scan ON ${DbTableNames.lesions} (scan_id)');
    // Optional: Index on scan_date if frequently filtering/sorting by date
    batch.execute('CREATE INDEX idx_scan_date ON ${DbTableNames.scans} (scan_date)');

    print("Indexes SQL prepared.");

    // Commit all operations in the batch
    await batch.commit(noResult: true); // Use noResult: true for efficiency
    print("Database tables and indexes created successfully.");
  }

  // --- Database Migration (Placeholder) ---
  // Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  //   print("Upgrading database from version $oldVersion to $newVersion");
  //   // Implement migration logic using ALTER TABLE, etc. based on version changes
  //   // Example:
  //   // if (oldVersion < 2) {
  //   //   await db.execute("ALTER TABLE ${DbTableNames.users} ADD COLUMN email TEXT;");
  //   // }
  //   // if (oldVersion < 3) {
  //   //   // Add another change
  //   // }
  // }

  // --- Close Database ---
  // Optional: Method to explicitly close the database if needed (e.g., during testing or app exit)
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null; // Reset the static variable
      print("Database closed.");
    }
  }

// --- Optional: DAO Methods ---
// You can add CRUD methods directly here, or create separate DAO files
// Example (Illustrative - We might create separate DAO files later):
// Future<int> insertUser(User user) async {
//   final db = await database;
//   return await db.insert(DbTableNames.users, user.toMap(),
//       conflictAlgorithm: ConflictAlgorithm.replace); // Or .ignore, .fail
// }
//
// Future<User?> getUser(int id) async {
//    final db = await database;
//    final List<Map<String, dynamic>> maps = await db.query(
//      DbTableNames.users,
//      where: 'user_id = ?',
//      whereArgs: [id],
//    );
//    if (maps.isNotEmpty) {
//      return User.fromMap(maps.first);
//    } else {
//      return null;
//    }
// }
// ... other CRUD methods ...
}