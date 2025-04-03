// lib/features/profile/screens/account_details_screen.dart

import 'package:care/core/providers/database_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import providers and entities (Adjust paths/package name)
import 'package:care/core/constants/app_constants.dart';
import 'package:care/core/providers/security_providers.dart';
import 'package:care/core/database/entities/user.dart';
// Import DAO/Notifier later for saving

class AccountDetailsScreen extends ConsumerStatefulWidget {
  const AccountDetailsScreen({super.key});

  @override
  ConsumerState<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends ConsumerState<AccountDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for editable fields
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _ageController;

  // State for selected gender
  Gender? _selectedGender;

  bool _isLoading = false; // For save button state

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current user data from provider
    // Use ref.read here as initState runs before build
    final currentUser = ref.read(currentUserProvider);

    _firstNameController = TextEditingController(text: currentUser?.firstName ?? '');
    _lastNameController = TextEditingController(text: currentUser?.lastName ?? '');
    _ageController = TextEditingController(text: currentUser?.age?.toString() ?? '');
    _selectedGender = currentUser?.gender; // Initialize dropdown state
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // --- Save Function (Placeholder) ---
  Future<void> _saveAccountDetails() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    final currentUser = ref.read(currentUserProvider); // Get current user data for copyWith
    if (currentUser == null || currentUser.userId == null) {
      // Handle error: No user to update (shouldn't happen if screen loaded)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Active user not found!"), backgroundColor: Colors.red));
      setState(() => _isLoading = false);
      return;
    }

    // --- Create updated User object ---
    final User updatedUser = currentUser.copyWith(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      // Ensure age parsing is safe (form validation should handle it)
      age: int.tryParse(_ageController.text) ?? currentUser.age, // Keep old age if parse fails
      gender: _selectedGender ?? currentUser.gender, // Use selected or keep old
      // Note: We are NOT updating authMethod, password, skinType, riskProfile here
    );
    // --- End Create User ---


    // --- Call Update Logic via Notifier ---
    final success = await ref.read(authNotifierProvider.notifier).updateUserProfile(updatedUser);
    // --- End Call ---


    // Check if mounted before updating UI
    if (!mounted) return;

    setState(() => _isLoading = false); // Stop loading indicator

    // --- Handle Result ---
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
      );
      // Invalidate providers to ensure data refreshes everywhere
      ref.invalidate(currentUserProvider);
      ref.invalidate(allUsersProvider); // Refresh profile list too
      // Optionally invalidate settings/scan providers if they display user info

      context.pop(); // Go back to the previous screen (Settings)
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Error updating profile. Please try again.'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current user for initial values (read is fine after initState)
    final currentUser = ref.read(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Details'),
        actions: [
          // Save Button
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save Changes',
            // Disable if loading or no user (though should always be a user here)
            onPressed: _isLoading || currentUser == null ? null : _saveAccountDetails,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: currentUser == null
          ? const Center(child: Text("Error: No user data found.")) // Fallback
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- Profile Picture Area (Placeholder) ---
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: const AssetImage(AssetPaths.defaultProfilePic),
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: IconButton(
                        icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                        onPressed: () {
                          print("TODO: Implement profile picture change");
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("TODO: Change profile picture"))
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Form Fields ---
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
              textInputAction: TextInputAction.next,
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name'),
              textInputAction: TextInputAction.next,
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(labelText: 'Age'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                final age = int.tryParse(value);
                if (age == null || age < 0 || age > 120) return 'Invalid age';
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Gender Dropdown
            DropdownButtonFormField<Gender>(
              value: _selectedGender, // Use state variable
              decoration: const InputDecoration(labelText: 'Gender'),
              items: Gender.values.map((Gender gender) {
                String displayName = gender.name.replaceAll('_', ' ');
                return DropdownMenuItem<Gender>(value: gender, child: Text(displayName));
              }).toList(),
              onChanged: (Gender? newValue) {
                // Update local state when dropdown changes
                setState(() { _selectedGender = newValue; });
              },
              validator: (value) => value == null ? 'Required' : null,
            ),
            const SizedBox(height: 32),

            // --- Display Non-Editable Info (Example) ---
            ListTile(
              leading: const Icon(Icons.security_outlined),
              title: const Text("Authentication Method"),
              subtitle: Text(currentUser.authMethod.name),
              dense: true,
            ),
            // Could add Skin Type / Risk Profile here too if desired (read-only)

          ], // End ListView children
        ), // End ListView
      ), // End Form
    ); // End Scaffold
  } // End build
} // End State class