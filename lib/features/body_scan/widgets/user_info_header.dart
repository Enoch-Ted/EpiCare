// lib/features/body_scan/widgets/user_info_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import User entity and providers (Adjust paths)
import 'package:care/core/database/entities/user.dart';
import 'package:care/core/providers/security_providers.dart'; // Provides currentUserProvider

class UserInfoHeader extends ConsumerWidget {
  const UserInfoHeader({super.key});

  // Helper to display skin type or placeholder
  Widget _buildSkinTypeWidget(User? user, BuildContext context) {
    if (user?.skinType != null) {
      // TODO: Add actual color palette widget later
      return GestureDetector(
        onTap: () {
          // TODO: Navigate to Skin Type Result/Retake screen
          print("Tapped Skin Type: ${user!.skinType!.name}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Navigate to Skin Type Details for ${user.skinType!.name}")),
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Placeholder for color palette
            Container(width: 16, height: 16, color: Colors.orange[100], margin: const EdgeInsets.only(right: 4)),
            Text("Skin Type ${user!.skinType!.name}", style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    } else {
      return GestureDetector(
        onTap: () {
          // TODO: Navigate to Skin Type Assessment screen
          print("Tapped Find Skin Type");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Navigate to Skin Type Assessment")),
          );
        },
        child: Text(
          "Find skin type",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).primaryColor),
        ),
      );
    }
  }

  // Helper to display risk profile or placeholder
  Widget _buildRiskProfileWidget(User? user, BuildContext context) {
    if (user?.riskProfile != null) {
      return GestureDetector(
        onTap: () {
          // TODO: Navigate to Risk Profile Result/Retake screen
          print("Tapped Risk Profile: ${user!.riskProfile!.name}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Navigate to Risk Profile Details for ${user.riskProfile!.name}")),
          );
        },
        // Added '| ' separator for consistency if both are present
        child: Text("| Find risk profile", style: Theme.of(context).textTheme.bodyMedium), // Text differs slightly from image, adjust as needed
      );
    } else {
      return GestureDetector(
        onTap: () {
          // TODO: Navigate to Risk Profile Assessment screen
          print("Tapped Find Risk Profile");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Navigate to Risk Profile Assessment")),
          );
        },
        child: Text(
          "Find risk profile",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).primaryColor),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the current user state
    final User? currentUser = ref.watch(currentUserProvider);

    // Handle loading or unauthenticated state (though router should prevent unauth)
    if (currentUser == null) {
      // Show a loading state or minimal header if user data isn't available yet
      // This might happen briefly during app startup or if auth state is delayed
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(radius: 25, child: Icon(Icons.person)), // Placeholder icon
            SizedBox(width: 12),
            Text("Loading user..."),
          ],
        ),
      );
    }

    // Build UI with user data
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically
        children: [
          // Profile Picture (Clickable)
          GestureDetector(
            onTap: () {
              // TODO: Show Bio Data (Modal/BottomSheet)
              print("Tapped Profile Pic for ${currentUser.displayName}");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Show Bio Data for ${currentUser.displayName}")),
              );
            },
            child: CircleAvatar(
              radius: 25,
              // TODO: Load actual profile picture (currentUser.profilePic)
              // Use placeholder for now
              backgroundColor: Colors.grey[300], // Placeholder color
              child: const Icon(Icons.person, size: 30, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          // User Name and Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // User Name (Clickable, same action as pic)
                GestureDetector(
                  onTap: () {
                    // TODO: Show Bio Data (Modal/BottomSheet)
                    print("Tapped Profile Name for ${currentUser.displayName}");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Show Bio Data for ${currentUser.displayName}")),
                    );
                  },
                  child: Text(
                    currentUser.displayName, // Use displayName getter
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis, // Prevent long names overflowing
                  ),
                ),
                const SizedBox(height: 4),
                // Skin Type / Risk Profile Row
                Row(
                  children: [
                    _buildSkinTypeWidget(currentUser, context),
                    const SizedBox(width: 4),
                    // Only show risk profile text if skin type exists, or always show 'Find risk profile'?
                    // Based on image, it seems risk profile link is always shown after skin type area.
                    // Let's show it always for now.
                    _buildRiskProfileWidget(currentUser, context),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}