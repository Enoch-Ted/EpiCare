// lib/core/providers/security_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import local_auth and services (might need Platform check)
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart'; // For PlatformException
import 'dart:io';

// Adjust package name if needed (using epiccare)
import 'package:care/core/database/entities/user.dart';
import 'package:care/core/security/crypto_service.dart';
import 'package:care/core/security/auth_service.dart';
import 'package:care/core/providers/database_providers.dart'; // Needs userDaoProvider

// --- Manual Provider Definitions ---

/// Provides an instance of [CryptoService].
final cryptoServiceProvider = Provider<CryptoService>((ref) {
  return CryptoService();
});

/// Provides an instance of [AuthService], injecting dependencies.
final authServiceProvider = Provider<AuthService>((ref) {
  final userDao = ref.watch(userDaoProvider);
  final cryptoSvc = ref.watch(cryptoServiceProvider);
  return AuthService(userDao: userDao, cryptoService: cryptoSvc);
});

// --- Authentication State Management ---

/// Type definition for the authentication state (a nullable User).
typedef AuthState = User?;

/// Manages the authentication state ([AuthState]) using [StateNotifier].
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(_authService.currentUser);

  /// Attempts Password/PIN login and updates state.
  Future<AuthResult> login(int userId, String password) async {
    final result = await _authService.loginWithPassword(userId: userId, password: password);
    if (result.success) {
      state = result.user;
    } else {
      state = null;
    }
    return result;
  }

  /// Placeholder for biometric login - needs implementation using local_auth.
  Future<AuthResult> loginWithBiometrics(int userId) async {
    print("AuthNotifier: Attempting biometric login for $userId");
    final LocalAuthentication localAuth = LocalAuthentication();
    bool canCheckBiometrics = false;
    bool isAuthenticated = false;
    String errorMessage = "Biometric login failed or not available."; // Default error

    try {
      // 1. Check if biometrics are available on device
      canCheckBiometrics = await localAuth.canCheckBiometrics;
      // Optional: Check specific types like fingerprint/face
      // final List<BiometricType> availableBiometrics = await localAuth.getAvailableBiometrics();

      if (canCheckBiometrics) {
        print("Biometrics available. Prompting user...");
        // 2. Trigger authentication prompt
        isAuthenticated = await localAuth.authenticate(
          localizedReason: 'Please authenticate to activate your EpiCare profile',
          options: const AuthenticationOptions(
            stickyAuth: true, // Keep prompt open after failed attempt
            biometricOnly: true, // IMPORTANT: Only allow biometrics, not device PIN/password
          ),
        );
        print("Biometric authentication result: $isAuthenticated");
      } else {
        print("Biometrics not available on this device.");
        errorMessage = "Biometrics not available on this device.";
      }
    } on PlatformException catch (e) {
      print("Biometric PlatformException: ${e.code} - ${e.message}");
      // Handle specific errors (e.g., PasscodeNotSet, NotEnrolled, LockedOut)
      if (e.code == 'NotEnrolled') {
        errorMessage = 'Biometrics not set up on this device.';
      } else if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        errorMessage = 'Biometric authentication locked out. Please use another method or wait.';
      } else {
        errorMessage = 'Biometric error: ${e.message ?? "Unknown platform error"}';
      }
      isAuthenticated = false;
    } catch (e) {
      print("Generic error during biometric auth: $e");
      isAuthenticated = false;
      errorMessage = "An unexpected error occurred during biometric authentication.";
    }

    // 3. Update state and return result
    if (isAuthenticated) {
      // Fetch user details AFTER successful authentication
      final user = await _authService.getUserById(userId);
      if (user != null && user.authMethod == AuthMethod.BIOMETRIC) {
        state = user; // Update state
        return AuthResult(success: true, user: user, message: "Biometric login successful.");
      } else {
        // Should not happen if called correctly, but handle case
        return AuthResult(success: false, message: "User data not found or auth method mismatch after biometric success.");
      }
    } else {
      // Ensure state is null if auth failed
      // Only set to null if the failed attempt was for the *currently active* user?
      // Or maybe don't change state on failure here? Let's not change it for now.
      // state = null;
      return AuthResult(success: false, message: errorMessage);
    }
  }

  /// Activates a user (sets them as current) if their auth method is NONE.
  Future<void> setActiveUser(int userId) async {
    final result = await _authService.setActiveUserWithoutAuth(userId);
    if (result.success) {
      state = result.user;
      print("AuthNotifier: Set active user to ${result.user?.displayName}");
    } else {
      print("AuthNotifier: Error setting active user: ${result.message}");
    }
  }

  // *** ADDED REGISTER METHOD ***
  /// Attempts to register a new user via AuthService.
  /// Returns AuthResult. Does NOT automatically log in the new user.
  Future<AuthResult> register({
    required String firstName,
    required String lastName,
    required Gender gender,
    required int age,
    required AuthMethod authMethod,
    String? password,
    SkinType? skinType,
    RiskProfile? riskProfile,
    String? profilePic,
  }) async {
    print("AuthNotifier: Attempting registration...");
    // Directly call the AuthService method
    final result = await _authService.registerUser(
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      age: age,
      authMethod: authMethod,
      password: password,
      skinType: skinType,
      riskProfile: riskProfile,
      profilePic: profilePic,
    );
    // We don't change the 'state' here, user needs to activate/login separately
    print("AuthNotifier: Registration result: ${result.success}, Msg: ${result.message}");
    return result;
  }
  // *** END REGISTER METHOD ***

  Future<bool> deleteCurrentUserAccount() async {
    final currentUserToDelete = state; // Get the user from current state
    if (currentUserToDelete == null || currentUserToDelete.userId == null) {
      print("AuthNotifier: No active user to delete.");
      return false; // No user is active
    }

    print("AuthNotifier: Attempting delete for user ${currentUserToDelete.userId}");
    final success = await _authService.deleteUserAccount(currentUserToDelete.userId!);

    if (success) {
      print("AuthNotifier: User deletion successful, logging out.");
      logout(); // Call existing logout method to clear state
      return true;
    } else {
      print("AuthNotifier: User deletion failed.");
      // Optionally provide error feedback via another state/provider
      return false;
    }
  }

  Future<bool> updateUserProfile(User updatedUser) async {
    if (updatedUser.userId == null) {
      print("AuthNotifier Error: Cannot update user with null ID.");
      return false;
    }
    print("AuthNotifier: Attempting profile update for user ${updatedUser.userId}");
    final success = await _authService.updateUserProfile(updatedUser);

    if (success) {
      print("AuthNotifier: Profile update successful via service.");
      // Check if the updated user is the one currently in the state
      if (state?.userId == updatedUser.userId) {
        print("AuthNotifier: Updating state with new profile data.");
        state = updatedUser; // Update the state directly
      }
      // Even if not the current user, the DB update succeeded
      return true;
    } else {
      print("AuthNotifier: Profile update failed via service.");
      return false;
    }
  }



  /// Returns AuthResult indicating success/failure.
  Future<AuthResult> changePassword(int userId, String oldPassword, String newPassword) async {
    print("AuthNotifier: Attempting password change for user $userId");
    // Call the service method
    final result = await _authService.changePassword(
      userId: userId,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );

    // If the password change was for the currently logged-in user AND successful,
    // update the state with the potentially modified user object from the result
    // (though only salt/hash changed, it's good practice).
    if (result.success && state?.userId == userId && result.user != null) {
      // Note: AuthService.changePassword doesn't currently return the updated user in AuthResult
      // We might need to adjust AuthService or re-fetch the user if we need the updated object here.
      // For now, just return the result. The hash/salt change doesn't affect displayed UI state.
      print("AuthNotifier: Password change successful for active user.");
    } else if (!result.success) {
      print("AuthNotifier: Password change failed: ${result.message}");
    }
    return result;
  }

  /// Logs out the current user by clearing the state.
  void logout() {
    _authService.logout();
    state = null;
    print("AuthNotifier: User logged out.");
  }
}


/// Provides the [AuthNotifier] instance and its state ([AuthState]).
/// Manually defined using [StateNotifierProvider].
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});


/// Provides the current logged-in [User] object (nullable).
/// Derived from the state of [authNotifierProvider].
final currentUserProvider = Provider<User?>((ref) {
  // Watch the state managed by the AuthNotifier
  return ref.watch(authNotifierProvider);
});


/// Provides a boolean indicating if a user is currently authenticated.
/// Derived from [currentUserProvider].
final isAuthenticatedProvider = Provider<bool>((ref) {
  // Check if the currentUser state is not null
  return ref.watch(currentUserProvider) != null;
});

// No extension method needed