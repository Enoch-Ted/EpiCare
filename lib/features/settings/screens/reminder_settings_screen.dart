// lib/features/settings/screens/reminder_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import providers and entities (Adjust package name)
import 'package:care/core/providers/database_providers.dart';
import 'package:care/core/providers/security_providers.dart';
import 'package:care/core/database/entities/user_settings.dart';

// State for the selected reminder frequency in the UI
// Initialize it by reading the current setting when the screen loads
final _selectedReminderDaysProvider = StateProvider<int?>((ref) {
  // Read synchronously, will update when async provider resolves
  return ref.watch(currentUserSettingsProvider).asData?.value?.scanReminderDays;
});

class ReminderSettingsScreen extends ConsumerWidget {
  const ReminderSettingsScreen({super.key});

  // Map frequency options to days (0 means off)
  final Map<String, int> _reminderOptions = const {
    'Off': 0,
    'Monthly': 30,
    'Every 2 Months': 60,
    'Every 3 Months': 90,
    'Every 6 Months': 180,
    'Yearly': 365,
  };

  Future<void> _saveReminderSetting(WidgetRef ref, BuildContext context, int? currentUserId) async {
    final selectedDays = ref.read(_selectedReminderDaysProvider);
    final currentSettingsAsync = ref.read(currentUserSettingsProvider); // Read current async value

    if (selectedDays == null || currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not save setting."), backgroundColor: Colors.red));
      return;
    }

    // Get existing settings or create default if needed
    final existingSettings = currentSettingsAsync.asData?.value ?? UserSettings(userId: currentUserId);
    if (existingSettings.scanReminderDays == selectedDays) {
      print("Reminder setting unchanged.");
      context.pop(); // Just go back if no change
      return;
    }
    final updatedSettings = existingSettings.copyWith(scanReminderDays: selectedDays);
    print("Saving reminder setting: ${updatedSettings.scanReminderDays} days for user $currentUserId");

    try {
      final success = await ref.read(userSettingsDaoProvider).upsertSettings(updatedSettings);
      if (success >= 0 && context.mounted) {
        ref.invalidate(currentUserSettingsProvider); // Refresh settings provider
        print("Reminder setting saved.");
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Reminder settings saved."), backgroundColor: Colors.green)
        );
        // *** Call Notification Service ***
        //final notificationService = ref.read(notificationServiceProvider);
        //if (selectedDays > 0) {
          //print("Attempting to schedule notifications for every $selectedDays days");
          //notificationService.scheduleRepeatingReminder(selectedDays);
        //} else {
          //print("Attempting to cancel scheduled notifications");
          //notificationService.cancelAllReminders();
        //}

        context.pop(); // Go back
      } else if (context.mounted) {
        throw Exception("Database update failed.");
      }
    } catch (e) {
      print("Error saving reminder settings: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error saving settings: $e"), backgroundColor: Colors.red)
        );
      }
    }
  } // End _saveReminderSetting


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the async settings provider to get initial value
    final settingsAsync = ref.watch(currentUserSettingsProvider);
    // Watch the local state provider for UI selection
    final selectedDaysUI = ref.watch(_selectedReminderDaysProvider);
    // Get user ID for saving
    final currentUserId = ref.watch(currentUserProvider)?.userId;

    // Update local UI state provider when async settings load
    ref.listen(currentUserSettingsProvider, (_, next) {
      if (next is AsyncData<UserSettings?> && next.value != null) {
        // Check if the local state differs from loaded state before updating
        if (ref.read(_selectedReminderDaysProvider) != next.value!.scanReminderDays) {
          ref.read(_selectedReminderDaysProvider.notifier).state = next.value!.scanReminderDays;
        }
      }
    });


    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder Settings'),
        actions: [
          // Save button - enabled only if a selection has been made
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save Settings',
            onPressed: selectedDaysUI == null ? null : () => _saveReminderSetting(ref, context, currentUserId),
          )
        ],
      ),
      body: settingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text("Error loading settings: $err")),
          data: (settings) {
            // The selectedDaysUI should reflect the loaded settings due to the ref.listen
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  "Select how often you want to be reminded to perform a skin check.",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                // Generate RadioListTiles from options map
                ..._reminderOptions.entries.map((entry) {
                  final String label = entry.key;
                  final int days = entry.value;
                  return RadioListTile<int>(
                    title: Text(label),
                    value: days,
                    groupValue: selectedDaysUI, // Use local UI state provider
                    onChanged: (int? newValue) {
                      // Update the local UI state provider
                      ref.read(_selectedReminderDaysProvider.notifier).state = newValue;
                    },
                  );
                }).toList(),
              ],
            );
          }
      ),
    );
  }
}