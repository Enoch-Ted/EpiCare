// lib/presentation/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // --- Define ALL colors as static const ---
  static const Color primaryColor = Color(0xFF0052CC); // Main blue
  static const Color lightBlueBackground = Color(0xFFE3F2FD); // Your light blue
  static const Color accentColor = Color(0xFF651FFF); // Example accent
  static const Color lightGreyBackground = Color(0xFFF5F5F5); // Very light grey
  static const Color mediumGreyText = Color(0xFF616161); // For subtitles etc.
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color black87 = Colors.black87;
  static const Color black54 = Colors.black54;
  static const Color grey = Colors.grey; // Base grey
  static const Color grey300 = Color(0xFFE0E0E0); // Specific grey shade
  static const Color grey400 = Color(0xFFBDBDBD); // Specific grey shade
  static const Color redAccent = Colors.redAccent;
  static const Color shadowColor = Color(0x1A000000); // Black with low opacity for shadow

  // Define the light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor, // Core primary color reference
      scaffoldBackgroundColor: white, // White background for scaffolds

      // *** Use const ColorScheme.light and reference const colors ***
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        primaryContainer: lightBlueBackground,
        onPrimaryContainer: primaryColor, // Text on light blue
        surface: white,
        onSurface: black87,
        background: white,
        onBackground: black87,
        error: redAccent,
        onError: white,
        onPrimary: white,
        onSecondary: white,
        surfaceVariant: lightGreyBackground, // Use defined light grey
        onSurfaceVariant: black54, // Use defined text color for light grey
        outline: grey,
        outlineVariant: grey300, // Use defined grey shade
        shadow: shadowColor, // Use defined shadow color
        // You can add the other optional M3 colors here if needed,
        // ensuring they reference static const Color values.
        // surfaceTint: primaryColor,
        // ... etc
      ),

      // Define Text Theme (Can be const)
      textTheme: const TextTheme(
        titleMedium: TextStyle(fontWeight: FontWeight.bold, color: black87, fontSize: 16),
        bodyMedium: TextStyle(color: black87, fontSize: 14),
        bodySmall: TextStyle(color: mediumGreyText, fontSize: 12),
        labelLarge: TextStyle(color: white, fontWeight: FontWeight.bold),
        // Define labelMedium if needed for toggle buttons
        labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),

      // Define AppBar Theme (Can be const)
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: white,
        elevation: 1.0,
        iconTheme: IconThemeData(color: white),
        titleTextStyle: TextStyle(color: white, fontSize: 18, fontWeight: FontWeight.w600),
      ),

      // Define BottomNavigationBar Theme (Can be const)
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primaryColor,
        unselectedItemColor: mediumGreyText,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 4.0,
      ),

      // Define Card Theme (Shape needs to be const)
      cardTheme: CardTheme(
        elevation: 1.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        // Color comes from scheme (surface) or overridden in widget
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
      ),

      // Define Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          )
      ),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
          )
      ),

      // Define Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: grey), // Use const grey
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: grey400), // Use const grey shade
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: lightGreyBackground, // Use const light grey
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),

      // Define Icon Theme (Can be const)
      iconTheme: const IconThemeData(
        color: primaryColor,
        size: 24,
      ),

      // Define ListTile Theme (Can be const)
      listTileTheme: ListTileThemeData(
        iconColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        // dense: true,
      ),
    );
  }

// static ThemeData get darkTheme { ... } // Keep placeholder
}