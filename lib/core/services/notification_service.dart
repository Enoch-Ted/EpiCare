// lib/core/services/notification_service.dart
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io'; // For Platform check

// Needed for background tap handling isolate entry point
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // handle action (limited capabilities in background isolate)
  print('Background notification tapped (payload: ${notificationResponse.payload})');
  // IMPORTANT: Avoid heavy async work, UI updates, or complex logic here.
  // You might store the payload or trigger a simpler background task if needed.
}

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;
  bool _permissionsRequested = false; // Track if permissions were asked

  Future<void> init() async {
    // Prevent multiple initializations
    if (_initialized) {
      print("NotificationService already initialized.");
      // Still request permissions if not done yet
      if (!_permissionsRequested) await _requestPermissions();
      return;
    }
    print("Initializing NotificationService...");

    // Initialize timezone database
    try {
      tz.initializeTimeZones();
      // Optional: Set local timezone if needed for scheduling accuracy
      // final String currentTimeZone = await FlutterNativeTimezone.getLocalTimezone();
      // tz.setLocalLocation(tz.getLocation(currentTimeZone));
      print("Timezones initialized.");
    } catch (e) {
      print("Error initializing timezones: $e");
      // Continue initialization even if timezone fails? Or throw?
    }

    // Android Initialization Settings
    // Use a relevant drawable/mipmap name for the small icon
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // Or '@drawable/notification_icon'

    // iOS Initialization Settings
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          // onDidReceiveLocalNotification handled by plugin now for newer iOS
          // requestAlertPermission: false, // Default false
          // requestBadgePermission: false,
          // requestSoundPermission: false,
        );

    // Combined Initialization Settings
    final InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin, // Use Darwin for iOS
      macOS: initializationSettingsDarwin, // Use Darwin for macOS too
    );
    // *** END UPDATED ***

    try {
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        // *** Use onDidReceiveNotificationResponse for ALL platforms when tapped ***
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
      _initialized = true;
      print("NotificationService Initialized Successfully.");
      await _requestPermissions(); // Request permissions AFTER init
    } catch (e) { print("Error initializing FLN Plugin: $e"); _initialized = false; }
  }
  Future<bool> _requestPermissions() async {
    // --- Request iOS Permissions ---
    if (Platform.isIOS || Platform.isMacOS) {
      try {
        // Request permissions explicitly for iOS/macOS
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true,);
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true,);
        print("iOS/macOS permissions requested.");
        // Assume granted for now, plugin handles denial internally mostly
      } catch(e) { print("Error requesting iOS/macOS permissions: $e"); }
    }
    // --- Request Android Permissions ---
    else if (Platform.isAndroid) {
      try {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidImplementation != null) {
          final bool? grantedNotifications = await androidImplementation.requestNotificationsPermission();
          print("Android Notification Permission Granted: $grantedNotifications");
          _permissionsRequested = true;
          return grantedNotifications ?? false;
        } // else: handle missing implementation
      } catch(e) { print("Error requesting Android permissions: $e"); }
    }
    _permissionsRequested = true; // Mark as requested even on error/other platforms
    return true; // Assume success/not needed for non-Android for now
  }

  // --- Scheduling Methods ---

  /// Schedules a repeating notification based on the interval in days.
  /// Note: True repeating for arbitrary intervals (like monthly) is complex.
  /// This implementation schedules ONE notification 'days' from now.
  /// Proper repeating requires rescheduling or background tasks.
  Future<void> scheduleRepeatingReminder(int days) async {
    if (days <= 0) {
      print("Reminder interval is 0 or less. Cancelling any existing reminders.");
      await cancelAllReminders();
      return;
    }
    // Ensure initialized and permissions potentially requested
    await init();
    if (!_initialized) {
      print("Cannot schedule reminder: NotificationService not initialized.");
      return;
    }
    // Optional: Re-check/request permissions here if needed, although init should handle it.
    // bool permissionsGranted = await _requestPermissions();
    // if (!permissionsGranted && Platform.isAndroid) { // Example check
    //    print("Cannot schedule reminder: Notification permissions not granted.");
    //    // Optionally inform the user they need to grant permissions in settings
    //    return;
    // }


    // Cancel existing reminders before scheduling new ones
    await cancelAllReminders();

    // Define platform-specific details
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'scan_reminder_channel_id', // Unique ID
      'Scan Reminders', // Channel Name visible in settings
      channelDescription: 'Reminders to perform a skin check using EpiCare.',
      importance: Importance.max, // High importance for visibility
      priority: Priority.high,
      ticker: 'EpiCare Reminder', // Ticker text for accessibility
      // Optional: Add sound, vibration pattern, LED color etc.
    );

    const DarwinNotificationDetails iosDetails =
    DarwinNotificationDetails(presentSound: true, presentBadge: true, presentAlert: true);
    const NotificationDetails platformDetails =
    NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Calculate next notification time (e.g., 'days' from now at 10:00 AM)
    final tz.TZDateTime scheduledTime = _nextInstanceOfReminderTime(days);
    print("Scheduling ONE reminder for: $scheduledTime (Timezone: ${tz.local.name})");

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
          0, // ID
          'EpiCare Skin Check Reminder', // Title
          'Time for your periodic skin check!', // Body
          scheduledTime,
          platformDetails,
          // *** Use androidAllowWhileIdle for newer parameter name ***
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Keep if API supports
          // androidAllowWhileIdle: true, // Use this if androidScheduleMode is deprecated
          // *** uiLocalNotificationDateInterpretation is for iOS only ***
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, // Keep for iOS
          //matchDateTimeComponents: DateTimeComponents.time, // REMOVE - Not for arbitrary intervals
          payload: 'reminder_payload'
      );
      print("Reminder scheduled successfully for $scheduledTime.");
    } catch (e) { print("Error scheduling reminder: $e"); }
  }
  tz.TZDateTime _nextInstanceOfReminderTime(int intervalDays) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    // Schedule for 10 AM on the target day
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 10);

    // Add the interval days
    scheduledDate = scheduledDate.add(Duration(days: intervalDays));

    // If the calculated time is somehow in the past (e.g., intervalDays was negative, though we check > 0),
    // push it forward. This shouldn't happen with days > 0 check.
    // if (scheduledDate.isBefore(now)) {
    //    scheduledDate = scheduledDate.add(Duration(days: intervalDays)); // Add again? Or handle differently?
    // }

    return scheduledDate;
  }


  Future<void> cancelAllReminders() async {
    // No need to call init() here usually, cancelAll works without full init
    await flutterLocalNotificationsPlugin.cancelAll();
    print("Cancelled all scheduled notifications.");
  }

  // --- Notification Handlers ---
  // Called when notification is received while app is in foreground (iOS only < 10)
  void onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) async {
    print("iOS foreground notification received: $id");
    // Optionally show an in-app message/dialog
  }

  // Called when user taps notification (app running or terminated)
  void onDidReceiveNotificationResponse(NotificationResponse response) async {
    print('Notification tapped: Payload=${response.payload}, ActionID=${response.actionId}, Input=${response.input}');
    // TODO: Handle payload - e.g., navigate to a specific screen
    // Example: Check payload and navigate using GoRouter (needs navigator key)
    // if (response.payload == 'reminder_payload' && navigatorKey.currentState != null) {
    //    navigatorKey.currentState!.pushNamed(AppRoutes.bodyScan); // Example navigation
    // }
  }

} // End NotificationService