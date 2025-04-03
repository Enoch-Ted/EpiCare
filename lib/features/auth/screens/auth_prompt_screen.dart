// lib/features/auth/screens/auth_prompt_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import providers (Adjust paths/package name)
import 'package:care/core/providers/security_providers.dart';
import 'package:care/core/security/auth_service.dart'; // For AuthResult

// State for managing loading and error message
final _authPromptStateProvider = StateProvider<({bool isLoading, String? error})>(
        (ref) => (isLoading: false, error: null));
// State for password visibility
final _passwordVisibleProvider = StateProvider<bool>((ref) => false);


class AuthPromptScreen extends ConsumerStatefulWidget {
  final int userId;
  final String? userName; // Optional name for display

  const AuthPromptScreen({
    required this.userId,
    this.userName,
    super.key,
  });

  @override
  ConsumerState<AuthPromptScreen> createState() => _AuthPromptScreenState();
}

class _AuthPromptScreenState extends ConsumerState<AuthPromptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitAuth() async {
    // Clear previous errors
    ref.read(_authPromptStateProvider.notifier).update((state) => (isLoading: state.isLoading, error: null));

    if (!_formKey.currentState!.validate()) {
      return; // Don't proceed if validation fails
    }

    // Set loading state
    ref.read(_authPromptStateProvider.notifier).update((state) => (isLoading: true, error: null));

    final password = _passwordController.text;

    // Call the login method on the notifier
    final AuthResult result = await ref.read(authNotifierProvider.notifier).login(
      widget.userId, // Use userId passed to the widget
      password,
    );

    // Check if mounted before updating state/navigating
    if (!mounted) return;

    // Update loading state
    ref.read(_authPromptStateProvider.notifier).update((state) => (isLoading: false, error: result.message)); // Store error message if any

    if (result.success) {
      print("Auth prompt successful for user ${widget.userId}");
      context.pop(); // Go back to the previous screen (ProfileListScreen)
    } else {
      // Error message is already set in the state provider, UI will rebuild
      print("Auth prompt failed: ${result.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(_authPromptStateProvider);
    final passwordVisible = ref.watch(_passwordVisibleProvider);
    final String displayName = widget.userName ?? 'User ID: ${widget.userId}';

    return Scaffold(
      appBar: AppBar(
        title: Text('Unlock Profile'),
        // Automatically includes back button due to push navigation
      ),
      body: Center( // Center the content
        child: SingleChildScrollView( // Allow scrolling on small screens
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter Password/PIN for',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                Text(
                  displayName, // Show user name/ID
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !passwordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password or PIN',
                    // Determine keyboard type based on assumption or user data if available
                    // For now, assume visible password might be needed
                    // keyboardType: TextInputType.number, // Use if definitely PIN
                    suffixIcon: IconButton(
                      icon: Icon(passwordVisible ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => ref.read(_passwordVisibleProvider.notifier).state = !passwordVisible,
                    ),
                  ),
                  // inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Use if definitely PIN
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter Password or PIN';
                    }
                    return null;
                  },
                  // Submit form on action key press
                  onFieldSubmitted: (_) => _submitAuth(),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 16),
                // Display error message if present
                if (authState.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      authState.error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                // Login Button
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _submitAuth,
                  child: authState.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                      : const Text('Unlock Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}