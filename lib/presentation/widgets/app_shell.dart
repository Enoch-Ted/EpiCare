// lib/presentation/widgets/app_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/app_router.dart'; // Import route constants

class AppShell extends ConsumerWidget {
  final Widget child; // The content for the current tab

  const AppShell({required this.child, super.key});

  // Helper method to determine the current index based on route location
  // Needs to handle 5 items now
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRoutes.history)) return 1;
    // Index 2 is Scan, which might not have its own persistent route in the shell
    // Or if it does, it would be index 2. Let's assume it doesn't persist here.
    if (location.startsWith(AppRoutes.profile)) return 3;
    if (location.startsWith(AppRoutes.settings)) return 4;
    // Default to Body Scan
    return 0;
  }

  // Helper method to navigate when a tab is tapped
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: // Body
        context.go(AppRoutes.bodyScan);
        break;
      case 1: // History
        context.go(AppRoutes.history);
        break;
      case 2: // Scan Button
        print("Scan button tapped - Navigating to Scan Screen");
        context.push(AppRoutes.scanScreen);
        break;
      case 3: // Profile
        context.go(AppRoutes.profile);
        break;
      case 4: // Settings
        context.go(AppRoutes.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bottomNavTheme = Theme.of(context).bottomNavigationBarTheme;

    // Define icon sizes from your previous code example or theme
    const double iconSize = 30.0; // Example size
    const double cameraIconSize = 35.0;

    return Scaffold(
      body: child, // Display the screen for the current route

      // Use standard BottomNavigationBar
      bottomNavigationBar: BottomNavigationBar(
        // Use theme settings
        type: bottomNavTheme.type ?? BottomNavigationBarType.fixed,
        backgroundColor: bottomNavTheme.backgroundColor ?? colors.surface,
        selectedItemColor: bottomNavTheme.selectedItemColor ?? colors.primary,
        unselectedItemColor: bottomNavTheme.unselectedItemColor ?? Colors.grey,
        selectedLabelStyle: bottomNavTheme.selectedLabelStyle,
        unselectedLabelStyle: bottomNavTheme.unselectedLabelStyle,
        showSelectedLabels: bottomNavTheme.showSelectedLabels,
        showUnselectedLabels: bottomNavTheme.showUnselectedLabels,
        elevation: bottomNavTheme.elevation ?? 8.0,

        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),

        // Define your 5 navigation items
        items: <BottomNavigationBarItem>[
          // Item 1: Body
          BottomNavigationBarItem(
            icon: Icon(Icons.accessibility_new, size: iconSize),
            label: 'Body',
          ),
          // Item 2: History
          BottomNavigationBarItem(
            icon: Icon(Icons.history, size: iconSize),
            label: 'History',
          ),
          // Item 3: Scan (Custom Look)
          BottomNavigationBarItem(
            icon: Container( // Use Container for custom styling
              // Add padding/margin if needed to adjust position/size
              padding: const EdgeInsets.only(bottom: 5), // Push icon up slightly maybe
              child: Container( // Inner container for circle/shadow
                decoration: BoxDecoration(
                  color: colors.primary, // Use theme primary color
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2)
                    )
                  ],
                ),
                padding: const EdgeInsets.all(8), // Padding inside circle
                child: Icon(Icons.camera_alt, color: colors.onPrimary, size: cameraIconSize),
              ),
            ),
            label: '', // No label for the center button
          ),
          // Item 4: Profile
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: iconSize),
            label: 'Profile',
          ),
          // Item 5: Settings
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined, size: iconSize),
            label: 'Settings',
          ),
        ],
      ),
    ); // End Scaffold
  } // End build
} // End AppShell