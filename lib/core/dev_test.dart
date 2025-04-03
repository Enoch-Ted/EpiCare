// lib/core/dev_test.dart

import 'dart:typed_data';
import 'package:care/core/security/auth_service.dart';
import 'package:care/core/security/crypto_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Adjust package name 'epiccare' if yours is different
import 'package:care/core/constants/app_constants.dart';
import 'package:care/core/providers/database_providers.dart';
import 'package:care/core/providers/ai_providers.dart';
import 'package:care/core/providers/security_providers.dart';
import 'package:care/core/database/entities/user.dart';
import 'package:care/core/database/entities/scan.dart';
import 'package:care/core/database/entities/lesion.dart';
import 'package:care/core/database/entities/user_settings.dart';
import 'package:care/core/ai/model_handler.dart';
import 'package:care/core/database/daos/user_dao.dart';
import 'package:care/core/database/daos/scan_dao.dart';
import 'package:care/core/database/daos/lesion_dao.dart';
import 'package:care/core/database/daos/user_settings_dao.dart';

// --- Test Runner Function ---
Future<void> runCoreSanityChecks(ProviderContainer container, {bool insertOnly = false}) async {
  print("--- Running Core Sanity Checks ---");
  bool dbOk = false;
  bool aiOk = false;

  print("\n--- Database Checks ---");
  dbOk = await _testDatabaseOperations(container, insertOnly: insertOnly);

  // Skip AI check if only inserting data
  if (!insertOnly) {
    print("\n--- AI Model Checks ---");
    aiOk = await _testClassifier(container);
    print("\n--- Core Sanity Checks Complete (DB: ${dbOk ? 'OK' : 'FAIL'}, AI: ${aiOk ? 'OK' : 'FAIL'}) ---");
  } else {
    print("\n--- Database Insertion Complete (DB: ${dbOk ? 'OK' : 'FAIL'}) ---");
  }

}


// --- Database Test Function ---
// Added insertOnly flag to skip deletion for populating DB
/// lib/core/dev_test.dart -> _testDatabaseOperations function

Future<bool> _testDatabaseOperations(ProviderContainer container, {bool insertOnly = false}) async {
  // ... dao/service setup ...
  // *** ADD EXPLICIT TYPES ***
  final UserDao userDao = container.read(userDaoProvider);
  final ScanDao scanDao = container.read(scanDaoProvider);
  final LesionDao lesionDao = container.read(lesionDaoProvider);
  final UserSettingsDao userSettingsDao = container.read(userSettingsDaoProvider);
  final CryptoService cryptoService = container.read(cryptoServiceProvider);
  final AuthService authService = container.read(authServiceProvider);
  // *** END EXPLICIT TYPES ***

  int? actualUserIdInDb = null; // Use nullable int for the actual ID
  int? testScanId = null;
  bool success = true;

  final User? dummyUserFromAuth = authService.currentUser;

  if (dummyUserFromAuth == null) {
    print("DATABASE CHECK FAILED: Dummy user not found in AuthService.");
    return false;
  }
  print("AuthService has dummy user: ${dummyUserFromAuth.displayName} (intended ID: ${dummyUserFromAuth.userId})");

  try {
    // --- STEP 1: ENSURE User is IN THE DATABASE & GET ACTUAL ID ---
    // Use the intended ID for checking first
    final int intendedUserId = dummyUserFromAuth.userId ?? -1; // Use dummy ID or -1 if null
    print("Checking for user with intended ID: $intendedUserId in database...");

    User? userInDb = (intendedUserId > 0) ? await userDao.getUserById(intendedUserId) : null;

    if (userInDb == null) {
      print("User $intendedUserId not found in DB, attempting to insert dummy user...");
      // Insert the user data *without* specifying an ID (let DB assign it)
      final User userToInsert = dummyUserFromAuth.copyWith(userId: null); // Force null ID for insert
      actualUserIdInDb = await userDao.insertUser(userToInsert); // Get the ACTUAL ID assigned by DB

      if (actualUserIdInDb <= 0) {
        throw Exception("Dummy user insertion failed.");
      }
      print("SUCCESS: Inserted dummy user data with ACTUAL DB ID: $actualUserIdInDb.");
    } else {
      print("User $intendedUserId already exists in database.");
      actualUserIdInDb = userInDb.userId; // Use the existing ID
    }

    // --- From now on, use actualUserIdInDb ---
    if (actualUserIdInDb == null) {
      throw Exception("Could not obtain a valid user ID from the database.");
    }


    // --- STEP 2: Upsert User Settings ---
    print("\nTesting UserSettings Upsert for user $actualUserIdInDb...");
    // *** Use the ACTUAL ID from the database ***
    final settings = UserSettings(userId: actualUserIdInDb, darkMode: false, scanReminderDays: 21, notificationsEnabled: true);
    int settingsResultId = await userSettingsDao.upsertSettings(settings);
    if (settingsResultId < 0) throw Exception("Settings upsert failed.");
    print("Upsert operation returned ID/RowID: $settingsResultId");

    final fetchedSettings = await userSettingsDao.getSettingsByUserId(actualUserIdInDb);
    if (fetchedSettings == null || fetchedSettings.scanReminderDays != 21) {
      throw Exception("Failed to upsert or verify settings.");
    }
    print("SUCCESS: Upserted and fetched Settings: $fetchedSettings");


    // --- STEP 3: Insert Scan Data ---
    print("\nTesting Scan Insert for user $actualUserIdInDb...");
    // *** Use the ACTUAL ID from the database ***
    final testScan = Scan(
        userId: actualUserIdInDb, // Use actual ID
        imagePath: "/placeholder/scan_image_1.jpg",
        scanDate: DateTime.now().subtract(const Duration(days: 5)),
        scanName: "First Test Scan"
    );
    testScanId = await scanDao.insertScan(testScan); // Store the scan ID
    if (testScanId == null || testScanId <= 0) throw Exception("Scan insertion failed."); // Check null and value
    print("SUCCESS: Inserted Scan ID: $testScanId");


    // --- STEP 4: Insert Lesion Data ---
    print("\nTesting Lesion Insert for scan $testScanId...");
    // *** Use the scan ID obtained above ***
    // Lesion 1
    final testLesion1 = Lesion(
        scanId: testScanId, // Use actual scan ID
        riskLevel: RiskLevel.Benign, lesionType: LesionTypeConstants.MelanocyticNevus,
        confidenceScore: 0.92, bodyMapX: 0.25, bodyMapY: 0.30, bodySide: BodySide.Front
    );
    int lesionId1 = await lesionDao.insertLesion(testLesion1);
    if (lesionId1 <= 0) throw Exception("Lesion 1 insertion failed.");
    print("SUCCESS: Inserted Lesion ID: $lesionId1");

    // Lesion 2
    final testLesion2 = Lesion(
        scanId: testScanId, // Use actual scan ID
        riskLevel: RiskLevel.Undetermined, lesionType: LesionTypeConstants.Dermatofibroma,
        confidenceScore: 0.65, bodyMapX: 0.70, bodyMapY: 0.45, bodySide: BodySide.Back
    );
    int lesionId2 = await lesionDao.insertLesion(testLesion2);
    if (lesionId2 <= 0) throw Exception("Lesion 2 insertion failed.");
    print("SUCCESS: Inserted Lesion ID: $lesionId2");


    // --- STEP 5: Verify Insertion ---
    print("\nVerifying Lesion Read for scan $testScanId...");
    final lesionsForScan = await lesionDao.getLesionsByScanId(testScanId);
    if (lesionsForScan.length != 2) {
      throw Exception("Failed to fetch correct number of lesions.");
    }
    print("SUCCESS: Fetched ${lesionsForScan.length} lesion(s).");

    print("\nSUCCESS: Database operations for test data seem OK.");

  } catch (e) {
    print("DATABASE CHECK FAILED: $e");
    success = false;
  } finally {
    // --- Cleanup ---
    if (!insertOnly) { /* ... cleanup logic ... */ }
    else { print("\nSkipping data cleanup (insertOnly mode). Data for user $actualUserIdInDb remains."); }
  }
  return success;
}

// ... _testClassifier function ....
// Changed to return bool
Future<bool> _testClassifier(ProviderContainer container) async {
  final tfliteService = container.read(tfliteServiceProvider);
  const String testImagePath = 'assets/test_images/test_lesion.jpg'; // Ensure this exists
  bool success = false;

  print("Loading test image: $testImagePath");
  try {
    final ByteData byteData = await rootBundle.load(testImagePath);
    final Uint8List imageBytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    print("Test image loaded successfully (${imageBytes.lengthInBytes} bytes).");

    print("Running classifier inference...");
    final List<double>? rawProbabilities = await tfliteService.runClassifierModel(imageBytes);

    if (rawProbabilities == null) throw Exception("Raw probabilities were null.");
    if (rawProbabilities.length != 7) throw Exception("Expected 7 probabilities, got ${rawProbabilities.length}.");

    print("Raw Probabilities from Service: $rawProbabilities");

    double maxConfidence = 0.0;
    int predictedClassIndex = -1;
    for (int i = 0; i < rawProbabilities.length; i++) {
      if (rawProbabilities[i] > maxConfidence) {
        maxConfidence = rawProbabilities[i];
        predictedClassIndex = i;
      }
    }

    if (predictedClassIndex != -1) {
      print("Predicted Class Index: $predictedClassIndex, Confidence: $maxConfidence");
      const List<String> classLabels = [ 'Actinic Keratosis / Intraepithelial Carcinoma', 'Basal Cell Carcinoma', 'Benign Keratosis', 'Dermatofibroma', 'Melanoma', 'Melanocytic Nevus', 'Vascular Lesion' ];
      if (predictedClassIndex >= 0 && predictedClassIndex < classLabels.length) {
        print("  (Mapped Name: ${classLabels[predictedClassIndex]})");
      }
      print("\nSUCCESS: AI classification test ran without crashing.");
      success = true;
    } else {
      throw Exception("Could not determine predicted class index.");
    }

  } catch(e) {
    print("AI CLASSIFIER CHECK FAILED: $e");
  }
  return success;
}