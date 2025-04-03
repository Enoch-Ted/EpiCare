// lib/features/profile/screens/profile_list_screen.dart

import 'package:care/core/navigation/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


// Import providers and entities (Adjust paths/package name)
import 'package:care/core/providers/database_providers.dart';
import 'package:care/core/providers/security_providers.dart';
import 'package:care/core/database/entities/user.dart';
import 'package:care/core/constants/app_constants.dart';
import 'package:go_router/go_router.dart';// For AssetPaths
// Import navigation routes later for add/auth screens

class ProfileListScreen extends ConsumerWidget {
  const ProfileListScreen({super.key});

  // --- Helper Function for onTap ---
  void _onProfileTap(User tappedUser, User? currentUser, BuildContext context, WidgetRef ref) {
    print("Tapped profile: ${tappedUser.displayName}, ID: ${tappedUser.userId}");
    print("Auth method: ${tappedUser.authMethod}");

    if (currentUser?.userId == tappedUser.userId) {
      print("Tapped user is already active.");
      // Optionally navigate to their detail view? Or do nothing?
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${tappedUser.displayName} is already active."))
      );
      return;
    }

    // Handle activation based on auth method
    switch (tappedUser.authMethod) {
      case AuthMethod.NONE:
        print("Activating user ${tappedUser.userId} without auth...");
        // Directly call auth service logic via notifier
        ref.read(authNotifierProvider.notifier).setActiveUser(tappedUser.userId!); // We'll add this method
        break;
      case AuthMethod.PIN:
      case AuthMethod.PASSWORD:
        print("Password/PIN required for user ${tappedUser.userId}. Navigating to auth prompt...");
        context.pushNamed(
            'authPrompt', // Use route name
            pathParameters: {'userId': tappedUser.userId!.toString()}, // Pass userId in path
            extra: {'userName': tappedUser.displayName} // Pass name via extra for display
        );
        // TODO: Navigate to an auth prompt screen, passing tappedUser.userId
        // Example: context.push('/auth-prompt/${tappedUser.userId}');
        break;
      case AuthMethod.BIOMETRIC:
        print("Biometric required for user ${tappedUser.userId}. Triggering prompt...");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("TODO: Trigger Biometric prompt for ${tappedUser.displayName}"))
        );
        // TODO: Call biometric login logic via notifier/service
        // ref.read(authNotifierProvider.notifier).loginWithBiometrics(tappedUser.userId!);
        break;
    }
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the list of all users
    final AsyncValue<List<User>> allUsersAsyncValue = ref.watch(allUsersProvider);
    // Watch the currently active user to highlight them
    final User? activeUser = ref.watch(currentUserProvider);

    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles'),
        // Optionally add subtitle showing active user?
        // title: Column(
        //   crossAxisAlignment: CrossAxisAlignment.start,
        //   children: [
        //      const Text('Profiles'),
        //      if (activeUser != null) Text(
        //         'Active: ${activeUser.displayName}',
        //          style: textTheme.bodySmall?.copyWith(color: colors.onPrimary.withOpacity(0.8)),
        //       )
        //   ],
        // )
      ),
      body: allUsersAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading profiles: $error')),
        data: (users) {
          if (users.isEmpty) {
            // Should ideally not happen if we always ensure at least one user,
            // but good to handle.
            return const Center(
              child: Text(
                'No profiles found.\nTap the + button to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // --- User List ---
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final bool isActive = user.userId == activeUser?.userId;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                // Add visual indication if active
                color: isActive ? colors.primaryContainer.withOpacity(0.5) : null, // Example highlight
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: const AssetImage(AssetPaths.defaultProfilePic), // Placeholder
                    // TODO: Load actual user.profilePic later
                    backgroundColor: isActive ? colors.primary : colors.secondaryContainer,
                  ),
                  title: Text(
                    user.displayName,
                    style: textTheme.titleMedium,
                  ),
                  // Optionally show auth method icon
                  subtitle: Text(
                    'Auth: ${user.authMethod.name}',
                    style: textTheme.bodySmall,
                  ),
                  // Show checkmark or indicator if active
                  trailing: isActive
                      ? Icon(Icons.check_circle, color: colors.primary)
                      : const Icon(Icons.person_outline, size: 24), // Placeholder or null
                  onTap: () => _onProfileTap(user, activeUser, context, ref),
                ),
              );
            },
          );
        },
      ),
      // --- Floating Action Button ---
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("Navigate to Add Profile Screen");
          // *** Use context.push to navigate ***
          context.push(AppRoutes.addProfile);
        },
        tooltip: 'Add Profile',
        child: const Icon(Icons.add),
      ),
    ); // End Scaffold
  } // End build
} // End class