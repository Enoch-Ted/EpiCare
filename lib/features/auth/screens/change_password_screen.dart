// lib/features/auth/screens/change_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import providers (Adjust paths/package name)
import 'package:care/core/providers/security_providers.dart';

// --- State Management for this screen ---
final _changePasswordStateProvider = StateProvider<({bool isLoading, String? error})>(
        (ref) => (isLoading: false, error: null));

// Visibility toggles
final _currentPasswordVisibleProvider = StateProvider<bool>((ref) => false);
final _newPasswordVisibleProvider = StateProvider<bool>((ref) => false);


class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Submit Function (Placeholder for Logic) ---
  Future<void> _submitChangePassword() async {
    ref.read(_changePasswordStateProvider.notifier).update((state) => (isLoading: state.isLoading, error: null));
    if (!_formKey.currentState!.validate()) return;

    setState(() => ref.read(_changePasswordStateProvider.notifier).update((state) => (isLoading: true, error: null)));

    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;

    // --- Call Change Password Logic ---
    // Get current user ID (should not be null if user got to this screen)
    final userId = ref.read(currentUserProvider)?.userId;
    if (userId == null) {
      ref.read(_changePasswordStateProvider.notifier).update((state) => (isLoading: false, error: "Cannot identify current user."));
      return;
    }

    // Call method in Notifier
    final result = await ref.read(authNotifierProvider.notifier).changePassword(
        userId,
        currentPassword,
        newPassword
    );
    // --- End Call ---

    if (!mounted) return; // Check if widget is still mounted

    // Update loading state and error message
    ref.read(_changePasswordStateProvider.notifier).update((state) => (isLoading: false, error: result.message));

    // Handle result
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.green),
      );
      context.pop(); // Go back to settings screen
    } else {
      // Error message is shown via the state provider update above
      print("Change password failed: ${result.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(_changePasswordStateProvider);
    final currentPasswordVisible = ref.watch(_currentPasswordVisibleProvider);
    final newPasswordVisible = ref.watch(_newPasswordVisibleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password/PIN'),
      ),
      body: Form(
        key: _formKey,
        child: ListView( // Use ListView for scrolling
          padding: const EdgeInsets.all(16.0),
          children: [
            Text(
              'Please change your password or PIN to keep your account safe.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // --- Current Password ---
            TextFormField(
              controller: _currentPasswordController,
              obscureText: !currentPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Current Password/PIN',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(currentPasswordVisible ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => ref.read(_currentPasswordVisibleProvider.notifier).state = !currentPasswordVisible,
                ),
              ),
              validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // --- New Password ---
            TextFormField(
              controller: _newPasswordController,
              obscureText: !newPasswordVisible,
              decoration: InputDecoration(
                labelText: 'New Password/PIN',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(newPasswordVisible ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => ref.read(_newPasswordVisibleProvider.notifier).state = !newPasswordVisible,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                // TODO: Add complexity rules if desired (length, characters etc.)
                // Example: if (value.length < 6) return 'Must be at least 6 characters';
                if (value == _currentPasswordController.text) return 'New password must be different';
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // --- Confirm New Password ---
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !newPasswordVisible, // Use same visibility as new password
              decoration: const InputDecoration(
                labelText: 'Confirm New Password/PIN',
                prefixIcon: Icon(Icons.lock_outline),
                // No visibility toggle here, relies on the one above
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (value != _newPasswordController.text) return 'Passwords do not match';
                return null;
              },
              onFieldSubmitted: (_) => _submitChangePassword(), // Submit on action key
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),

            // --- Error Message Display ---
            if (formState.error != null && !formState.isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  formState.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),

            // --- Submit Button ---
            ElevatedButton(
              onPressed: formState.isLoading ? null : _submitChangePassword,
              child: formState.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                  : const Text('Change My Password'),
            ),

          ], // End ListView Children
        ), // End ListView
      ), // End Form
    ); // End Scaffold
  } // End Build
} // End State