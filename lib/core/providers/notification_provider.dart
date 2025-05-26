// lib/core/providers/notification_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/notification_service.dart';

part 'notification_provider.g.dart';

// Provides the singleton NotificationService instance
// KeepAlive is good here so init() and permission requests aren't repeated constantly
@Riverpod(keepAlive: true)
NotificationService notificationService(NotificationServiceRef ref) {
  // Return the singleton instance and trigger initialization
  // Initialization is async but we don't await it here.
  // Methods inside the service should call init() if needed or check _initialized flag.
  final service = NotificationService();
  service.init(); // Start initialization, don't await
  return service;
}