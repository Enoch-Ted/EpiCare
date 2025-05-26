// lib/core/security/crypto_service.dart

import 'dart:convert'; // For utf8 encoding
import 'dart:math'; // For Random
import 'dart:typed_data'; // For Uint8List

// Import pointycastle PBE and HMAC related classes
import 'package:pointycastle/export.dart';
// Note: We might need specific imports if export doesn't cover everything cleanly
// import 'package:pointycastle/key_derivators/api.dart';
// import 'package:pointycastle/key_derivators/pbkdf2.dart';
// import 'package:pointycastle/macs/hmac.dart';
// import 'package:pointycastle/digests/sha256.dart';

class CryptoService {
  // --- Configuration for PBKDF2 ---
  static const int _pbkdf2Iterations = 600000;
  static const int _saltLengthBytes = 16;
  static const int _keyLengthBytes = 32; // 256 bits

  // --- Salt Generation ---
  String generateSalt() {
    final random = Random.secure();
    final saltBytes = Uint8List(_saltLengthBytes);
    for (int i = 0; i < _saltLengthBytes; i++) {
      saltBytes[i] = random.nextInt(256);
    }
    return base64.encode(saltBytes);
  }

  // --- Password Hashing (using pointycastle) ---
  String? hashPassword(String password, String saltBase64) {
    try {
      // 1. Decode salt
      final Uint8List saltBytes = base64.decode(saltBase64);
      if (saltBytes.length != _saltLengthBytes) {
        print("Error: Invalid salt length for hashing.");
        return null;
      }

      // 2. Encode password
      final Uint8List passwordBytes = Uint8List.fromList(utf8.encode(password));

      // 3. Setup PBKDF2 with HMAC-SHA256 using pointycastle
      // Create the Key Derivator ('pbkdf2')
      final KeyDerivator keyDerivator = KeyDerivator('SHA-256/HMAC/PBKDF2');

      // Create parameters including salt, iteration count, and desired key length
      final Pbkdf2Parameters params = Pbkdf2Parameters(
          saltBytes, _pbkdf2Iterations, _keyLengthBytes);

      // Initialize the derivator
      keyDerivator.init(params);

      // Derive the key (hash) bytes from the password bytes
      // The process method takes the password bytes
      final Uint8List derivedKeyBytes = keyDerivator.process(passwordBytes);

      // 4. Encode derived key to Base64
      return base64.encode(derivedKeyBytes);
    } catch (e) {
      print("Error hashing password using pointycastle: $e");
      // print(StackTrace.current);
      return null;
    }
  }

  // --- Password Verification ---
  bool verifyPassword({
    required String plainPassword,
    required String? storedHashBase64,
    required String storedSaltBase64,
  }) {
    if (storedHashBase64 == null) {
      return false;
    }

    try {
      // 1. Hash the plain password attempt using the stored salt
      final String attemptedHashBase64 =
          hashPassword(plainPassword, storedSaltBase64) ?? '';

      // 2. Compare hashes (still okay to use standard string comparison here)
      return attemptedHashBase64 == storedHashBase64;
    } catch (e) {
      print("Error verifying password: $e");
      return false;
    }
  }
}