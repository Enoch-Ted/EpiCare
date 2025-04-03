// lib/features/settings/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import providers and entities (Adjust paths/package name)
import 'package:care/core/providers/database_providers.dart';
import 'package:care/core/providers/security_providers.dart'; // For User & AuthNotifier
import 'package:care/core/database/entities/user.dart'; // For User and Enums
import 'package:care/core/database/entities/user_settings.dart';
import 'package:care/core/navigation/app_router.dart';// For AppRoutes
import 'package:care/core/providers/app_info_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // Helper to build section headers
  Widget _buildSectionHeader(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 16.0, right: 16.0), // More top padding
      child: Text(
        title.toUpperCase(), // Uppercase for section titles
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary, // Use primary color
          letterSpacing: 0.8, // Add letter spacing
        ),
      ),
    );
  }

  // --- ADD Delete Confirmation Helper ---
  Future<void> _confirmAndDeleteAccount(BuildContext context, WidgetRef ref) async {
    // Get current user BEFORE showing dialog, in case state changes while dialog is open
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No active user to delete."), backgroundColor: Colors.orange),
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Profile?'),
          content: Text('Are you sure you want to permanently delete the profile for ${currentUser.displayName}? This will also delete all associated scan data. This action cannot be undone.'), // Personalized message
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('DELETE PERMANENTLY'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    // Check if mounted AFTER the dialog is dismissed
    if (confirmed == true && context.mounted) {
      print("User confirmed account deletion for user ${currentUser.userId}.");
      // Call the notifier method
      final success = await ref.read(authNotifierProvider.notifier).deleteCurrentUserAccount();

      // Feedback is handled by logout/redirect triggered by state change in notifier
      if (!success && context.mounted) {
        // Show error only if deletion itself failed before logout
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text("Failed to delete profile."), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } else {
      print("Account deletion cancelled.");
    }
  } // --- End Delete Helper ---



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch necessary providers
    final settingsAsyncValue = ref.watch(currentUserSettingsProvider);
    final currentUser = ref.watch(currentUserProvider); // Get the full User object

    // Determine if password change option should be shown
    final bool canChangePassword = currentUser?.authMethod == AuthMethod.PASSWORD ||
        currentUser?.authMethod == AuthMethod.PIN;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView( // Use ListView for scrolling sections
        children: [
          // --- My Account Section ---
          _buildSectionHeader("My Account", context),
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text("My Account Details"),
            subtitle: Text(currentUser?.displayName ?? "View/Edit Profile"), // Show name if available
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              print("Navigate to Account Details");
              // TODO: Define AppRoutes.accountDetails and push
              context.push(AppRoutes.accountDetails);
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined), // Example icon
            title: const Text("Skin Type"),
            // Display current skin type or prompt
            trailing: Text(
              currentUser?.skinType != null ? "Type ${currentUser!.skinType!.name}" : "Assess",
              style: TextStyle(color: Theme.of(context).colorScheme.secondary), // Use accent color
            ),
            onTap: () {
              // Navigate to assessment or result screen
              if (currentUser?.skinType != null) {
                print("Navigate to Skin Type Result Screen");
                context.push(AppRoutes.skinResult);
              } else {
                print("Navigate to Skin Type Assessment");
                context.push(AppRoutes.skinAssessment);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined), // Example icon
            title: const Text("Risk Profile"),
            // Display current risk profile or prompt
            trailing: Text(
              currentUser?.riskProfile != null ? "${currentUser!.riskProfile!.name} Risk" : "Assess",
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
            onTap: () {
              // Navigate to assessment or result screen
              if (currentUser?.riskProfile != null) {
                print("Navigate to Risk Profile Result");
                context.push(AppRoutes.riskResult);
              } else {
                print("Navigate to Risk Profile Assessment");
                context.push(AppRoutes.riskAssessment);
              }
            },
          ),
          // Notification Toggle (Keep from previous version)
          settingsAsyncValue.when(
            loading: () => const ListTile(title: Text("Loading settings..."), /* ... */),
            error: (err, stack) => ListTile(title: Text("Error loading settings"), /* ... */),
            data: (settings) {
              bool initialValue = settings?.notificationsEnabled ?? false;
              return SwitchListTile(
                title: const Text("Notifications"),
                subtitle: const Text("Receive scan reminders"),
                value: initialValue,
                onChanged: (currentUser?.userId == null) ? null : (bool newValue) async {
                  // ... (Existing onChanged logic remains the same) ...
                  final existingSettings = settings ?? UserSettings(userId: currentUser!.userId!);
                  final updatedSettings = existingSettings.copyWith(notificationsEnabled: newValue);
                  final success = await ref.read(userSettingsDaoProvider).upsertSettings(updatedSettings);
                  if (success >= 0) {
                    print("Settings updated successfully.");
                    ref.invalidate(currentUserSettingsProvider);
                    // *** Call Notification Service ***

                    //if (newValue) {
                      // Use the SAVED reminder days value
                      //final days = updatedSettings.scanReminderDays; // From DB/object
                      //print("Attempting to schedule notifications for every $days days");
                      //if (days > 0) {
                       // notificationService.scheduleRepeatingReminder(days);
                      //} else {
                        //print("Reminder days set to 0 or less, cancelling notifications.");
                       // notificationService.cancelAllReminders();
                      //}
                    //} else {
                      //print("Attempting to cancel scheduled notifications");
                      //notificationService.cancelAllReminders();
                    //}/
                    // *** End Call ***
                  } else { /* Show error */ }
                },
                secondary: Icon(initialValue ? Icons.notifications_active_outlined : Icons.notifications_off_outlined),
                activeColor: Theme.of(context).colorScheme.primary,
              );
            },
          ),
          // *** ADD ListTile for Reminder Settings ***
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text("Reminder Frequency"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              context.push(AppRoutes.settingsReminders);
            },
          ),

          // --- Help & Support Section ---
          _buildSectionHeader("Help & Support", context),
          ListTile( leading: const Icon(Icons.contact_mail_outlined), title: const Text("Contact Us"), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: () => context.push(AppRoutes.settingsContact)),
          // Conditionally show Change Password
          if (canChangePassword)
            ListTile(
              leading: const Icon(Icons.password_outlined),
              title: const Text("Change My Password/PIN"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                print("Navigate to Change Password");
                // TODO: Define AppRoutes.changePassword and push
                // context.push(AppRoutes.changePassword);
                context.push(AppRoutes.changePassword);
              },
            ),
          ListTile( leading: const Icon(Icons.info_outline), title: const Text("Skin Cancer Information"), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: () => context.push(AppRoutes.settingsInfo)),
          ListTile( leading: const Icon(Icons.quiz_outlined), title: const Text("FAQ"), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: () => context.push(AppRoutes.settingsFaq)),
          ListTile( leading: const Icon(Icons.integration_instructions_outlined), title: const Text("Instructions for Use"), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: () => context.push(AppRoutes.settingsInstructions)),
          ListTile( leading: const Icon(Icons.privacy_tip_outlined), title: const Text("Privacy Policy"), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: () => context.push(AppRoutes.settingsPrivacy)),
          ListTile( leading: const Icon(Icons.description_outlined), title: const Text("Terms and Conditions"), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: () => context.push(AppRoutes.settingsTerms)),
          ListTile( leading: const Icon(Icons.gavel_outlined), title: const Text("Disclaimer"), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: () => context.push(AppRoutes.settingsDisclaimer)),

          // --- Account Actions Section ---
          _buildSectionHeader("Account Actions", context),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
            title: Text("Delete My Profile", style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () => _confirmAndDeleteAccount(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Sign Out"),
            onTap: () {
              print("Signing out...");
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),

          // --- App Info ---
          const Divider(height: 32),
          Consumer( // Use Consumer to watch the provider inline
              builder: (context, ref, child) {
                final pkgInfoAsync = ref.watch(packageInfoProvider);
                return pkgInfoAsync.when(
                  data: (info) => ListTile(
                    title: const Text("App Version"),
                    subtitle: Text("${info.version} (Build ${info.buildNumber})"),
                    dense: true,
                    visualDensity: VisualDensity.compact,
                  ),
                  loading: () => const ListTile(
                    title: Text("App Version"),
                    subtitle: Text("Loading..."),
                    dense: true,
                    visualDensity: VisualDensity.compact,
                  ),
                  error: (e, s) => ListTile(
                    title: const Text("App Version"),
                    subtitle: const Text("Error loading version"),
                    dense: true,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }
          ),
          const SizedBox(height: 16),// Padding at bottom
        ],
      ), // End ListView
    ); // End Scaffold
  } // End build
} // End class