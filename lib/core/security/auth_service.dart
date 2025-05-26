// lib/core/security/auth_service.dart

import '../database/daos/user_dao.dart';
import '../database/entities/user.dart'; // Make sure this import path is correct
import 'crypto_service.dart';

// Simple class to represent the result of an authentication attempt
class AuthResult {
  final bool success;
  final String? message;
  final User? user; // Include user on success (especially registration)

  AuthResult({required this.success, this.message, this.user});
}


class AuthService {
  final UserDao _userDao;
  final CryptoService _cryptoService;

  User? _currentUser;

  // Dummy user for initial state bypass during development
  final User _dummyUser = User(
    userId: 999, authMethod: AuthMethod.NONE, salt: "dummy_salt_123",
    firstName: "Dev", lastName: "Tester", gender: Gender.Prefer_not_to_say, age: 33,
    skinType: SkinType.IV, riskProfile: RiskProfile.Low,
  );

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  AuthService({required UserDao userDao, required CryptoService cryptoService})
      : _userDao = userDao,
        _cryptoService = cryptoService {
    // Initialize with dummy user FOR DEVELOPMENT ONLY
    _currentUser = _dummyUser;
    print("AuthService initialized with DUMMY user: ${_currentUser?.displayName}");
  }

  /// Fetches a user by ID (proxy to the DAO)
  Future<User?> getUserById(int userId) async {
    try { return await _userDao.getUserById(userId); }
    catch (e) { print("Error in AuthService.getUserById($userId): $e"); return null; }
  }

  Future<bool> updateUserProfile(User updatedUser) async {
    // Ensure the user has an ID for updating
    if (updatedUser.userId == null) {
      print("AuthService Error: Cannot update user with null ID.");
      return false;
    }
    print("AuthService: Attempting to update profile for user ${updatedUser.userId}");
    try {
      final count = await _userDao.updateUser(updatedUser);
      if (count > 0) {
        print("AuthService: User ${updatedUser.userId} profile updated successfully in DB.");
        // If the updated user is the currently active one, update internal state
        if (_currentUser?.userId == updatedUser.userId) {
          _currentUser = updatedUser;
          print("AuthService: Updated internal _currentUser state.");
        }
        return true; // Success
      } else {
        print("AuthService: Failed to update user ${updatedUser.userId} in DB (record not found or no changes).");
        return false; // Update failed or didn't affect any rows
      }
    } catch (e) {
      print("AuthService: Error updating user profile ${updatedUser.userId}: $e");
      return false; // Failure due to exception
    }
  }

  /// Attempts to log in a user using their ID and password/PIN.
  Future<AuthResult> loginWithPassword({ required int userId, required String password, }) async {
    try {
      final User? user = await _userDao.getUserById(userId);
      if (user == null) return AuthResult(success: false, message: "User not found.");
      if (user.authMethod != AuthMethod.PASSWORD && user.authMethod != AuthMethod.PIN) {
        return AuthResult(success: false, message: "Incorrect authentication method for user.");
      }
      final bool passwordIsValid = _cryptoService.verifyPassword( plainPassword: password, storedHashBase64: user.authHash, storedSaltBase64: user.salt, );
      if (!passwordIsValid) return AuthResult(success: false, message: "Invalid password or PIN.");

      _currentUser = user; // Set as active user
      print("User ${user.userId} successfully authenticated.");
      return AuthResult(success: true, user: user, message: "Login successful.");
    } catch (e) {
      print("Error during login: $e");
      return AuthResult(success: false, message: "An unexpected error occurred during login.");
    }
  }

  /// Placeholder for Biometric Login
  Future<AuthResult> loginWithBiometrics(int userId) async {
    print("Biometric login placeholder for user $userId");
    final user = await getUserById(userId); // Use the public proxy method
    if (user != null && user.authMethod == AuthMethod.BIOMETRIC) {
      // TODO: Implement actual biometric prompt
      bool didAuthenticate = true; // Simulate success
      if (didAuthenticate) {
        _currentUser = user; // Set as active user
        return AuthResult(success: true, user: user, message: "Biometric login successful (Simulated).");
      }
    }
    return AuthResult(success: false, message: "Biometric login failed or not available (Simulated).");
  }

  /// Activates a user if their auth method is NONE.
  Future<AuthResult> setActiveUserWithoutAuth(int userId) async {
    final User? user = await getUserById(userId); // Use the public proxy method
    if (user == null) return AuthResult(success: false, message: "User not found.");
    if (user.authMethod != AuthMethod.NONE) return AuthResult(success: false, message: "User requires authentication.");

    _currentUser = user; // Set as active user
    print("Set active user (no auth): ${user.userId}");
    return AuthResult(success: true, user: user);
  }


  /// Registers a new user. Handles password hashing and DB insertion.
  Future<AuthResult> registerUser({
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

    String salt = '';
    String? hashedPassword;

    // Basic Validation
    if ((authMethod == AuthMethod.PASSWORD || authMethod == AuthMethod.PIN) && (password == null || password.isEmpty)) {
      return AuthResult(success: false, message: "Password/PIN is required for this authentication method.");
    }

    // Hash Password if needed
    try {
      if (authMethod == AuthMethod.PASSWORD || authMethod == AuthMethod.PIN) {
        salt = _cryptoService.generateSalt();
        hashedPassword = _cryptoService.hashPassword(password!, salt);
        if (hashedPassword == null) {
          return AuthResult(success: false, message: "Failed to hash password.");
        }
      } else {
        salt = _cryptoService.generateSalt(); // Generate salt even if unused for hash
        hashedPassword = null;
      }
    } catch (e) {
      print("Error during crypto operations in registerUser: $e");
      return AuthResult(success: false, message: "Error processing security details.");
    }

    // Create User Entity (ID will be null)
    final newUser = User(
      authMethod: authMethod, authHash: hashedPassword, salt: salt,
      firstName: firstName.trim(), lastName: lastName.trim(),
      gender: gender, age: age, skinType: skinType,
      riskProfile: riskProfile, profilePic: profilePic,
    );

    // Insert into Database
    try {
      // insertUser expects a User object without an ID
      final newUserId = await _userDao.insertUser(newUser);

      if (newUserId > 0) {
        print("User registered successfully with DB ID: $newUserId");
        // Create user object with the assigned ID to return
        final createdUser = newUser.copyWith(userId: newUserId);
        // We DON'T automatically log in the new user here in the service
        return AuthResult(success: true, user: createdUser, message: "Registration successful.");
      } else {
        return AuthResult(success: false, message: "Failed to save user to database (DAO returned <= 0).");
      }
    } catch (e) {
      print("Error during database insertion in registerUser: $e");
      return AuthResult(success: false, message: "Database error during registration.");
    }
  } // End registerUser

  Future<AuthResult> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    print("AuthService: Attempting password change for user $userId");
    try {
      // 1. Fetch user
      final User? user = await _userDao.getUserById(userId);
      if (user == null) {
        return AuthResult(success: false, message: "User not found.");
      }

      // 2. Verify old password
      final bool oldPasswordIsValid = _cryptoService.verifyPassword(
        plainPassword: oldPassword,
        storedHashBase64: user.authHash,
        storedSaltBase64: user.salt,
      );
      if (!oldPasswordIsValid) {
        return AuthResult(success: false, message: "Incorrect current password/PIN.");
      }

      // 3. Generate new salt and hash new password
      final String newSalt = _cryptoService.generateSalt();
      final String? newHashedPassword = _cryptoService.hashPassword(newPassword, newSalt);
      if (newHashedPassword == null) {
        return AuthResult(success: false, message: "Failed to hash new password.");
      }

      // 4. Create updated user object
      final User updatedUser = user.copyWith(
        authHash: newHashedPassword,
        salt: newSalt,
        // Ensure authMethod is appropriate (should already be PASSWORD/PIN)
        authMethod: (user.authMethod == AuthMethod.PASSWORD || user.authMethod == AuthMethod.PIN)
            ? user.authMethod
            : AuthMethod.PASSWORD, // Default to PASSWORD if somehow NONE/BIOMETRIC
      );

      // 5. Update user in database
      final count = await _userDao.updateUser(updatedUser);
      if (count > 0) {
        print("AuthService: Password updated successfully for user $userId in DB.");
        // Update internal state if it's the current user
        if (_currentUser?.userId == userId) {
          _currentUser = updatedUser;
        }
        return AuthResult(success: true, message: "Password/PIN updated successfully.");
      } else {
        return AuthResult(success: false, message: "Failed to update password in database.");
      }

    } catch (e) {
      print("AuthService: Error changing password for user $userId: $e");
      return AuthResult(success: false, message: "An unexpected error occurred.");
    }
  } // End changePassword

  /// Deletes the user specified by userId from the database.
  /// Returns true on success, false on failure.
  Future<bool> deleteUserAccount(int userId) async {
    print("AuthService: Attempting to delete user $userId");
    try {
      // DAO handles DB record deletion and file deletion attempt
      final count = await _userDao.deleteUserById(userId);
      if (count > 0) {
        print("AuthService: User $userId deleted successfully from DB.");
        // If this was the current user, clear the internal state
        if (_currentUser?.userId == userId) {
          _currentUser = null;
          print("AuthService: Cleared active user state after deletion.");
        }
        return true;
      } else {
        print("AuthService: User $userId not found in DB or delete failed.");
        return false;
      }
    } catch (e) {
      print("AuthService: Error deleting user $userId: $e");
      return false;
    }
  }

  /// Logs out the current user.
  void logout() {
    print("Logging out user: ${_currentUser?.userId}");
    _currentUser = null;
  }

} // End AuthService class