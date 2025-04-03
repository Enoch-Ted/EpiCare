// lib/features/profile/screens/add_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatters
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import entities and providers (Adjust paths/package name)
import 'package:care/core/database/entities/user.dart';
import 'package:care/core/providers/security_providers.dart'; // For AuthNotifier later
import 'package:care/core/providers/database_providers.dart';
// Import GoRouter for navigation later
import 'package:go_router/go_router.dart';

// Simple state provider to manage selected auth method in the form
final _selectedAuthMethodProvider = StateProvider<AuthMethod>((ref) => AuthMethod.NONE);
// State provider for showing/hiding password field
final _passwordVisibleProvider = StateProvider<bool>((ref) => false);


class AddProfileScreen extends ConsumerStatefulWidget {
  const AddProfileScreen({super.key});

  @override
  ConsumerState<AddProfileScreen> createState() => _AddProfileScreenState();
}

class _AddProfileScreenState extends ConsumerState<AddProfileScreen> {
  // Form Key
  final _formKey = GlobalKey<FormState>();

  // Text Editing Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _passwordController = TextEditingController(); // For Password/PIN

  // Selected values for dropdowns (can be nullable)
  Gender? _selectedGender;
  // SkinType? _selectedSkinType; // Add later if assessing during registration
  // RiskProfile? _selectedRiskProfile; // Add later

  bool _isLoading = false; // To show loading indicator on save

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final selectedAuthMethod = ref.read(_selectedAuthMethodProvider);
    if ((selectedAuthMethod == AuthMethod.PASSWORD || selectedAuthMethod == AuthMethod.PIN) &&
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password/PIN cannot be empty for selected auth method.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    // *** UNCOMMENT AND USE THIS BLOCK ***
    // Call AuthNotifier register method
    final result = await ref.read(authNotifierProvider.notifier).register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      age: int.parse(_ageController.text), // Already validated as int
      gender: _selectedGender!, // Validated by form
      authMethod: selectedAuthMethod,
      password: (selectedAuthMethod == AuthMethod.PASSWORD || selectedAuthMethod == AuthMethod.PIN)
          ? _passwordController.text
          : null,
      // Pass other optional fields if collected here
      // skinType: _selectedSkinType,
      // riskProfile: _selectedRiskProfile,
    );
    // *** END UNCOMMENT ***


    // Check if the widget is still mounted before updating UI
    if (!mounted) return;

    // --- REMOVE OR COMMENT OUT PLACEHOLDER CODE ---
    // print("Form Validated. TODO: Call registration logic."); // Remove
    // print("Data: ${_firstNameController.text}, ${_lastNameController.text}, ${_ageController.text}, $_selectedGender, $selectedAuthMethod, PW: ${_passwordController.text}"); // Remove
    // await Future.delayed(const Duration(seconds: 1)); // Remove
    // setState(() => _isLoading = false); // Handled below
    // ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('TODO: Registration logic not implemented yet.'), backgroundColor: Colors.orange),
    // ); // Remove
    // --- END REMOVE PLACEHOLDER ---


    // --- Handle Actual Result ---
    setState(() => _isLoading = false); // Stop loading indicator AFTER async call

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile created successfully!'), backgroundColor: Colors.green),
      );
      // Invalidate allUsersProvider so profile list refreshes
      ref.invalidate(allUsersProvider); // Make sure allUsersProvider is imported
      context.pop(); // Go back to profile list screen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating profile: ${result.message ?? "Unknown error"}'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  } // End _saveProfile

  @override
  Widget build(BuildContext context) {
    // Watch state providers for auth method and password visibility
    final selectedAuthMethod = ref.watch(_selectedAuthMethodProvider);
    final passwordVisible = ref.watch(_passwordVisibleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Profile'),
      ),
      // Use Form and ListView for scrolling fields
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- Basic Info ---
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a first name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name'),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a last name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(labelText: 'Age'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Only allow numbers
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter age';
                }
                final age = int.tryParse(value);
                if (age == null || age < 0 || age > 120) {
                  return 'Please enter a valid age (0-120)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Gender Dropdown
            DropdownButtonFormField<Gender>(
              value: _selectedGender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: Gender.values.map((Gender gender) {
                // Use helper to get display name if needed, or just enum name
                String displayName = gender.name.replaceAll('_', ' ');
                return DropdownMenuItem<Gender>(
                  value: gender,
                  child: Text(displayName),
                );
              }).toList(),
              onChanged: (Gender? newValue) {
                setState(() {
                  _selectedGender = newValue;
                });
              },
              validator: (value) => value == null ? 'Please select a gender' : null,
            ),
            const SizedBox(height: 24),

            // --- Authentication Method ---
            Text('Authentication Method', style: Theme.of(context).textTheme.titleMedium),
            // Use RadioListTiles for selection
            RadioListTile<AuthMethod>(
              title: const Text('None'),
              subtitle: const Text('No lock required to activate profile'),
              value: AuthMethod.NONE,
              groupValue: selectedAuthMethod,
              onChanged: (AuthMethod? value) {
                if (value != null) ref.read(_selectedAuthMethodProvider.notifier).state = value;
              },
            ),
            RadioListTile<AuthMethod>(
              title: const Text('Password'),
              value: AuthMethod.PASSWORD,
              groupValue: selectedAuthMethod,
              onChanged: (AuthMethod? value) {
                if (value != null) ref.read(_selectedAuthMethodProvider.notifier).state = value;
              },
            ),
            RadioListTile<AuthMethod>(
              title: const Text('PIN (Numeric)'),
              value: AuthMethod.PIN,
              groupValue: selectedAuthMethod,
              onChanged: (AuthMethod? value) {
                if (value != null) ref.read(_selectedAuthMethodProvider.notifier).state = value;
              },
            ),
            // TODO: Add Biometric option later if implementing
            // RadioListTile<AuthMethod>(
            //    title: const Text('Biometric (Fingerprint/Face)'),
            //    value: AuthMethod.BIOMETRIC,
            //    groupValue: selectedAuthMethod,
            //     onChanged: (AuthMethod? value) { ... },
            // ),

            // --- Conditional Password/PIN Field ---
            if (selectedAuthMethod == AuthMethod.PASSWORD || selectedAuthMethod == AuthMethod.PIN)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: !passwordVisible, // Use state for visibility
                  decoration: InputDecoration(
                    labelText: selectedAuthMethod == AuthMethod.PIN ? 'PIN' : 'Password',
                    // Add visibility toggle icon
                    suffixIcon: IconButton(
                      icon: Icon(
                        passwordVisible ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        // Toggle visibility state
                        ref.read(_passwordVisibleProvider.notifier).state = !passwordVisible;
                      },
                    ),
                  ),
                  keyboardType: selectedAuthMethod == AuthMethod.PIN
                      ? TextInputType.number // Use number pad for PIN
                      : TextInputType.visiblePassword,
                  inputFormatters: selectedAuthMethod == AuthMethod.PIN
                      ? [FilteringTextInputFormatter.digitsOnly] // PIN digits only
                      : [],
                  validator: (value) {
                    // Validation is checked in _saveProfile, but basic check here is ok too
                    if (value == null || value.isEmpty) {
                      return 'Please enter a ${selectedAuthMethod == AuthMethod.PIN ? 'PIN' : 'Password'}';
                    }
                    if (selectedAuthMethod == AuthMethod.PIN && value.length < 4) {
                      return 'PIN must be at least 4 digits'; // Example PIN length
                    }
                    // Add other password complexity rules if desired
                    return null;
                  },
                ),
              ),

            const SizedBox(height: 32),

            // --- Save Button ---
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile, // Disable button while loading
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                  : const Text('Create Profile'),
            ),
          ],
        ),
      ),
    );
  }
}