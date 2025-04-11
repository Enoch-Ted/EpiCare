// lib/features/profile/widgets/profile_bio_modal.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For potential date formatting if needed

// Import User entity (Adjust package name)
import 'package:care/core/database/entities/user.dart';
import 'package:care/core/constants/app_constants.dart'; // For default pic

class ProfileBioModal extends StatelessWidget {
  final User user;

  const ProfileBioModal({required this.user, super.key});

  // Helper for consistent list tile appearance
  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Text("$label:", style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: textTheme.bodyMedium)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    // Format data for display
    final String genderDisplay = user.gender.name.replaceAll('_', ' ');
    final String skinTypeDisplay = user.skinType?.name ?? "Not Assessed";
    final String riskProfileDisplay = user.riskProfile?.name ?? "Not Assessed";

    return Container(
      // Add padding within the modal
      padding: const EdgeInsets.all(20.0),
      // Optional: Set background color and rounded corners for the sheet itself
      decoration: BoxDecoration(
        color: colors.surface, // Use theme surface color
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Take only needed vertical space
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Pic and Name
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: const AssetImage(AssetPaths.defaultProfilePic), // Placeholder
                // TODO: Load actual image user.profilePic
                backgroundColor: colors.secondaryContainer,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  user.displayName,
                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              // Optional: Close button for modal
              // IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(height: 32, thickness: 1),

          // Detail Rows
          _buildDetailRow(context, Icons.cake_outlined, "Age", user.age.toString()),
          _buildDetailRow(context, Icons.wc_outlined, "Gender", genderDisplay),
          _buildDetailRow(context, Icons.palette_outlined, "Skin Type", skinTypeDisplay),
          _buildDetailRow(context, Icons.shield_outlined, "Risk Profile", riskProfileDisplay),

          const SizedBox(height: 20), // Spacing before potential actions

          // Optional: Add Edit button here?
          // Center(
          //    child: ElevatedButton.icon(
          //       icon: Icon(Icons.edit_outlined, size: 18),
          //       label: Text("Edit Profile"),
          //       onPressed: () {
          //          Navigator.pop(context); // Close modal first
          //          context.push(AppRoutes.accountDetails); // Navigate to edit screen
          //       },
          //    ),
          // )

        ],
      ),
    );
  }
}