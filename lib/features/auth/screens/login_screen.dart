// lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import providers, entities, routes (Adjust paths/package name)
import 'package:care/core/providers/database_providers.dart';
import 'package:care/core/providers/security_providers.dart';
import 'package:care/core/database/entities/user.dart';
import 'package:care/core/security/auth_service.dart'; // For AuthResult
import 'package:care/core/navigation/app_router.dart'; // For AppRoutes

// --- State Management for Login Screen ---

// Holds the currently selected user in the dropdown
final _selectedLoginUserProvider = StateProvider<User?>((ref) => null);

// Manages loading state and error messages for the login form
final _loginFormStateProvider = StateProvider<({bool isLoading, String? error})>(
        (ref) => (isLoading: false, error: null));

// Password visibility
final _loginPasswordVisibleProvider = StateProvider<bool>((ref) => false);


class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  // --- Login Function ---
// lib/features/auth/screens/login_screen.dart -> _submitLogin function

  Future<void> _submitLogin() async {
    ref.read(_loginFormStateProvider.notifier).update((state) => (isLoading: state.isLoading, error: null));
    final selectedUser = ref.read(_selectedLoginUserProvider);

    if (selectedUser == null || selectedUser.userId == null) {
      ref.read(_loginFormStateProvider.notifier).update((state) => (isLoading: false, error: "Please select a profile."));
      return;
    }

    // *** DETERMINE ACTION BASED ON AUTH METHOD ***
    AuthResult? result; // Make result nullable initially

    if (selectedUser.authMethod == AuthMethod.NONE) {
      // --- Activate User with NONE ---
      print("Attempting to activate user ${selectedUser.userId} (AuthMethod.NONE)");
      // Call setActiveUser directly on the notifier
      // Note: setActiveUser returns Future<void>, so we wrap result manually
      await ref.read(authNotifierProvider.notifier).setActiveUser(selectedUser.userId!);
      // Check the state AFTER the call to confirm success
      final success = ref.read(currentUserProvider)?.userId == selectedUser.userId;
      result = AuthResult(success: success, message: success ? "Profile activated." : "Failed to activate profile.");

    } else if (selectedUser.authMethod == AuthMethod.PASSWORD || selectedUser.authMethod == AuthMethod.PIN) {
      // --- Login with Password/PIN ---
      bool passwordRequired = true; // Already determined it's PW/PIN
      if (passwordRequired && _passwordController.text.isEmpty) {
        ref.read(_loginFormStateProvider.notifier).update((state) => (isLoading: false, error: "Password/PIN is required for this profile."));
        return;
      }
      if (passwordRequired && !_formKey.currentState!.validate()) {
        return;
      }

      ref.read(_loginFormStateProvider.notifier).update((state) => (isLoading: true, error: null));
      final password = _passwordController.text;
      result = await ref.read(authNotifierProvider.notifier).login(selectedUser.userId!, password);

    } else if (selectedUser.authMethod == AuthMethod.BIOMETRIC) {
      // --- Handle Biometric (Placeholder) ---
      print("Biometric required for user ${selectedUser.userId}. Triggering prompt from Login Screen...");
      // TODO: Trigger biometric prompt here
      // result = await ref.read(authNotifierProvider.notifier).loginWithBiometrics(selectedUser.userId!);
      result = AuthResult(success: false, message: "Biometric login not yet implemented from login screen."); // Placeholder result
    } else {
      // Should not happen
      result = AuthResult(success: false, message: "Unsupported authentication method.");
    }

    // --- Handle Result ---
    if (!mounted) return;
    ref.read(_loginFormStateProvider.notifier).update((state) => (isLoading: false, error: result?.message)); // Use result message

    if (result != null && result.success) {
      print("Login/Activation successful for ${selectedUser.displayName}");
      // GoRouter redirect handles navigation
    } else {
      print("Login/Activation failed: ${result?.message}");
      // Error message is set in the state provider
    }
  } // End _submitLogin

  @override
  Widget build(BuildContext context) {
    // Watch providers needed for the UI
    final allUsersAsync = ref.watch(allUsersProvider);
    final selectedUser = ref.watch(_selectedLoginUserProvider);
    final formState = ref.watch(_loginFormStateProvider);
    final passwordVisible = ref.watch(_loginPasswordVisibleProvider);

    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    // Determine if password field should be shown based on selected user
    final bool showPasswordField = selectedUser != null &&
        (selectedUser.authMethod == AuthMethod.PASSWORD || selectedUser.authMethod == AuthMethod.PIN);

    return Scaffold(
      body: Center( // Center content vertically and horizontally
        child: SingleChildScrollView( // Allow scrolling if content overflows
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch buttons etc.
              children: [
                // App Title or Logo (Optional)
                Text(
                  'EpiCare Login',
                  style: textTheme.headlineMedium?.copyWith(color: colors.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // --- Profile Selection Dropdown ---
                allUsersAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Text("Error loading profiles: $err", style: TextStyle(color: colors.error)),
                    data: (users) {
                      // Set initial selection if null and users exist
                      // Note: This might cause issues if called during build. Better to handle initial selection outside build.
                      // WidgetsBinding.instance.addPostFrameCallback((_) {
                      //    if (ref.read(_selectedLoginUserProvider) == null && users.isNotEmpty) {
                      //       ref.read(_selectedLoginUserProvider.notifier).state = users.first;
                      //    }
                      // });

                      if (users.isEmpty) {
                        return const Text("No profiles found. Please add a profile.", textAlign: TextAlign.center);
                      }

                      return DropdownButtonFormField<User>(
                        value: selectedUser,
                        hint: const Text('Select Profile'),
                        isExpanded: true,
                        decoration: const InputDecoration(
                          // labelText: 'Profile', // Can use label or hint
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: users.map((User user) {
                          return DropdownMenuItem<User>(
                            value: user,
                            child: Text(user.displayName),
                          );
                        }).toList(),
                        onChanged: (User? newValue) {
                          // Update selected user state
                          ref.read(_selectedLoginUserProvider.notifier).state = newValue;
                          // Clear password field when user changes
                          _passwordController.clear();
                          // Clear previous errors
                          ref.read(_loginFormStateProvider.notifier).update((s) => (isLoading: s.isLoading, error: null));
                        },
                        validator: (value) => value == null ? 'Please select a profile' : null,
                      );
                    }
                ),
                const SizedBox(height: 16),

                // --- Conditional Password/PIN Field ---
                // Use AnimatedSize/Visibility for smoother transition if desired
                if (showPasswordField)
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !passwordVisible,
                    decoration: InputDecoration(
                      labelText: selectedUser?.authMethod == AuthMethod.PIN ? 'PIN' : 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(passwordVisible ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => ref.read(_loginPasswordVisibleProvider.notifier).state = !passwordVisible,
                      ),
                    ),
                    keyboardType: selectedUser?.authMethod == AuthMethod.PIN ? TextInputType.number : TextInputType.visiblePassword,
                    inputFormatters: selectedUser?.authMethod == AuthMethod.PIN ? [FilteringTextInputFormatter.digitsOnly] : [],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter ${selectedUser?.authMethod == AuthMethod.PIN ? 'PIN' : 'Password'}';
                      }
                      // Add specific PIN/Password validation if needed
                      return null;
                    },
                    onFieldSubmitted: (_) => _submitLogin(), // Allow submitting from keyboard
                    textInputAction: TextInputAction.done,
                  ),

                // Add space only if password field is shown
                if (showPasswordField) const SizedBox(height: 16),

                // --- Error Message Display ---
                if (formState.error != null && !formState.isLoading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      formState.error!,
                      style: TextStyle(color: colors.error),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // --- Login Button ---
                ElevatedButton(
                  // Disable if no user selected OR if loading
                  onPressed: selectedUser == null || formState.isLoading ? null : _submitLogin,
                  child: formState.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                      : const Text('Login / Activate'),
                ),
                const SizedBox(height: 24),

                // --- Link to Add Profile ---
                TextButton(
                  onPressed: formState.isLoading ? null : () { // Disable if loading
                    context.push(AppRoutes.addProfile);
                  },
                  child: const Text('Create a New Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}