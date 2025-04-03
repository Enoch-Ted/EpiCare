// lib/core/providers/security_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    print("AuthNotifier: Attempting biometric login (Simulated) for $userId");
    final user = await _authService.getUserById(userId);
    if (user != null && user.authMethod == AuthMethod.BIOMETRIC) {
      // TODO: Implement actual biometric prompt
      bool didAuthenticate = true; // Simulate success
      if (didAuthenticate) {
        state = user;
        return AuthResult(success: true, user: user, message: "Biometric login successful (Simulated).");
      }
    }
    return AuthResult(success: false, message: "Biometric login failed or not available (Simulated).");
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