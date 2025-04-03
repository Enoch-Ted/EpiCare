// lib/core/navigation/app_router.dart


import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Import providers and screens (Adjust paths as necessary)
import '../../features/auth/screens/login_screen.dart';
import '../../features/body_scan/screens/body_scan_screen.dart';
import '../../features/history/screens/history_list_screen.dart';
import '../../features/profile/screens/add_profile_screen.dart';
import '../../features/profile/screens/profile_list_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../presentation/widgets/app_shell.dart'; // Our BottomNavBar shell
import '../providers/security_providers.dart'; // To check authentication state
import'../../features/scan/screens/scan_screen_placeholder.dart';
import 'package:care/features/history/screens/scan_detail_screen.dart';
import 'package:care/features/auth/screens/auth_prompt_screen.dart';
import 'package:care/features/profile/screens/account_details_screen.dart';
import 'package:care/features/auth/screens/change_password_screen.dart';
import 'package:care/features/assessment/screens/skin_type_assessment_screen.dart';
import 'package:care/features/assessment/screens/skin_type_result_screen.dart';
import 'package:care/features/assessment/screens/risk_profile_assessment_screen.dart';
import 'package:care/features/assessment/screens/risk_profile_result_screen.dart';
import 'package:care/features/settings/screens/reminder_settings_screen.dart';
part 'app_router.g.dart'; // Riverpod generator file

// --- Route Paths ---
// It's good practice to define route paths as constants
// Use root-relative paths (starting with '/')
class AppRoutes {
  static const login = '/login';
  static const bodyScan = '/body'; // Main tab routes relative to root for simplicity here
  static const history = '/history';
  static const profile = '/profile';
  static const settings = '/settings';
  static const scanScreen = '/scan';

  static const settingsReminders = '/settings/reminders';
  static const settingsInfo = '/settings/info';

  static const settingsContact = '/settings/contact';
  static const settingsPrivacy = '/settings/privacy';
  static const settingsFaq = '/settings/faq';
  static const settingsTerms = '/settings/terms';
  static const settingsInstructions = '/settings/instructions';
  static const settingsDisclaimer = '/settings/disclaimer';

  static const scanDetail = '/history/scan/:scanId';
  static const addProfile = '/profile/add';
  static const authPrompt = '/auth-prompt/:userId';
  static const accountDetails = '/account/details';
  static const changePassword = '/account/change-password';
  static const skinAssessment = '/assessment/skin';
  static const skinResult = '/result/skin';

  static const riskAssessment = '/assessment/risk';
  static const riskResult = '/result/risk'; //
// Add other paths later, e.g., '/scan-detail/:scanId'
}

// --- Navigator Keys ---
// Use GlobalKeys for navigator states, especially for ShellRoute
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shellNav');


// --- GoRouter Provider ---
@Riverpod(keepAlive: true) // Keep router state alive
GoRouter goRouter(GoRouterRef ref) {

  // Listen to authentication state for redirection
  final authStateListenable = ValueNotifier<bool>(ref.watch(isAuthenticatedProvider));
  ref.listen(isAuthenticatedProvider, (_, next) {
    authStateListenable.value = next;
    print("Auth state changed: $next"); // Debugging
  });


  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.bodyScan, // Start at the body screen (adjust if login needed first)
    debugLogDiagnostics: true, // Log routing events in debug console
    refreshListenable: authStateListenable, // Re-evaluate routes on auth change

    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = ref.read(isAuthenticatedProvider);
      final String currentLocation = state.matchedLocation;
      final bool isLoginScreen = currentLocation == AppRoutes.login;
      // *** ADD CHECK FOR ALLOWED UNAUTHENTICATED ROUTES ***
      final bool isPublicRoute = currentLocation == AppRoutes.login ||
          currentLocation == AppRoutes.addProfile; // Allow access to add profile when logged out

      print("Redirect check: loggedIn=$loggedIn, location=$currentLocation, isPublic=$isPublicRoute");

      // Scenario 1: User is NOT logged in
      if (!loggedIn) {
        // If NOT logged in and trying to access a route that is NOT public, redirect to login.
        if (!isPublicRoute) {
          print("Redirecting non-logged-in user to login screen from $currentLocation.");
          return AppRoutes.login;
        }
        // Otherwise, allow access to the public route (Login or AddProfile)
        print("User not logged in, accessing public route $currentLocation. No redirect.");
        return null;
      }
      // Scenario 2: User IS logged in
      else { // loggedIn is true
        // If logged in but on the login screen, redirect away.
        if (isLoginScreen) {
          print("Redirecting logged-in user away from login screen.");
          return AppRoutes.bodyScan;
        }
        // Otherwise, allow navigation.
        print("User logged in, not on login screen. No redirect needed.");
        return null;
      }
    }, // End redirect
    // --- Routes ---
    routes: <RouteBase>[
      // Login Route (Outside the shell)
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // Main application routes with BottomNavigationBar (ShellRoute)
      ShellRoute(
        navigatorKey: _shellNavigatorKey, // Key for the shell's navigator
        // Builder provides the AppShell widget which contains the BottomNavBar
        builder: (context, state, child)
        {
          // 'child' is the widget for the currently active sub-route (e.g., BodyScanScreen)
          return AppShell(child: child);
        },
        // Sub-routes managed by the ShellRoute
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.bodyScan, // e.g., /body
            // Use NoTransitionPage to prevent slide animations between tabs
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BodyScanScreen(),
            ),
          ),

          GoRoute(
              path: AppRoutes.history, // Parent path /history
              pageBuilder: (c,s) => const NoTransitionPage(child: HistoryListScreen()),
              // *** NESTED ROUTES for /history/***
              routes: <RouteBase>[ // <<< Add nested routes list here
                GoRoute(
                  // *** Path RELATIVE to parent ***
                  path: 'scan/:scanId', // Relative path 'scan/:scanId'
                  name: 'scanDetail',
                  // No parentNavigatorKey needed when nested like this
                  builder: (context, state) {
                    final String? scanIdStr = state.pathParameters['scanId'];
                    final int scanId = int.tryParse(scanIdStr ?? '') ?? -1;
                    if (scanId == -1) {
                      return Scaffold(body: Center(child: Text("Invalid Scan ID: $scanIdStr")));
                    }
                    return ScanDetailScreen(scanId: scanId);
                  },
                ),
              ] // <<< End nested routes list
          ),
          GoRoute(
            path: AppRoutes.profile, // e.g., /profile
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings, // e.g., /settings
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),




          // --- Temporarily Comment Out Placeholder Routes ---
          // GoRoute(path: AppRoutes.skinAssessment, parentNavigatorKey: _rootNavigatorKey, builder: (c,s) => Scaffold(appBar: AppBar(title: Text("Skin Assess")), body: Center(child: Text("Skin Type Assess")))),
          // GoRoute(path: AppRoutes.skinDetails, parentNavigatorKey: _rootNavigatorKey, builder: (c,s) => Scaffold(appBar: AppBar(title: Text("Skin Details")), body: Center(child: Text("Skin Type Details")))),
          // GoRoute(path: AppRoutes.settingsReminders, parentNavigatorKey: _rootNavigatorKey, builder: (c,s) => Scaffold(appBar: AppBar(title: Text("Reminders")), body: Center(child: Text("Reminder Settings")))),
          // GoRoute(path: AppRoutes.settingsInfo, parentNavigatorKey: _rootNavigatorKey, builder: (c,s) => Scaffold(appBar: AppBar(title: Text("Info")), body: Center(child: Text("Skin Cancer Info")))),
          // --- End Comment Out ---

          //GoRoute(path: AppRoutes.settingsContact, parentNavigatorKey: _rootNavigatorKey, builder: (c,s) => Scaffold(appBar: AppBar(title: Text("Contact Us")), body: Center(child: Text("Contact Info")))),
         // GoRoute(path: AppRoutes.settingsPrivacy, parentNavigatorKey: _rootNavigatorKey, builder: (c,s) => Scaffold(appBar: AppBar(title: Text("Privacy Policy")), body: Center(child: Text("Privacy Details")))),
          //GoRoute(path: AppRoutes.settingsFaq, parentNavigatorKey: _rootNavigatorKey, builder: (c,s) => Scaffold(appBar: AppBar(title: Text("FAQ")), body: Center(child: Text("Frequently Asked Questions")))),
          //GoRoute(path: AppRoutes.settingsTerms, parentNavigatorKey: _rootNavigatorKey, builder: (c,s) => Scaffold(appBar: AppBar(title: Text("Terms")), body: Center(child: Text("Terms and Conditions")))),
          //GoRoute(path: AppRoutes.settingsInstructions, parentNavigatorKey: _rootNavigatorKey, builder: (c,s) => Scaffold(appBar: AppBar(title: Text("Instructions")), body: Center(child: Text("Instructions for Use")))),
          //GoRoute(path: AppRoutes.settingsDisclaimer, parentNavigatorKey: _rootNavigatorKey, builder: (c,s) => Scaffold(appBar: AppBar(title: Text("Disclaimer")), body: Center(child: Text("Disclaimer Text")))),
          // --- End Placeholder Settings ---


        ],
      ),
      GoRoute(
        path: AppRoutes.scanScreen,
        // *** ADD parentNavigatorKey HERE ***
        parentNavigatorKey: _rootNavigatorKey, // Specify root key
        builder: (context, state) => const ScanScreenPlaceholder(),
      ),

      GoRoute(
        path: AppRoutes.addProfile,
        name: 'addProfile',
        // Use root key so it appears over the bottom bar
        parentNavigatorKey: _rootNavigatorKey,
        // Use builder or pageBuilder
        builder: (context, state) => const AddProfileScreen(), // We'll create this screen
      ),

      GoRoute(
        path: AppRoutes.authPrompt, // '/auth-prompt/:userId'
        name: 'authPrompt',
        parentNavigatorKey: _rootNavigatorKey, // Show over bottom bar
        builder: (context, state) {
          // Extract userId parameter
          final String? userIdStr = state.pathParameters['userId'];
          final int userId = int.tryParse(userIdStr ?? '') ?? -1;
          // Optional: Extract user name if passed via extra
          String? userName; // Initialize userName as null
          if (state.extra != null && state.extra is Map<String, dynamic>) {
            // Cast extra to the correct Map type after checking
            final extraMap = state.extra as Map<String, dynamic>;
            // Safely access the 'userName' key
            userName = extraMap['userName'] as String?;
          }

          if (userId == -1) {
            // Handle invalid ID - maybe navigate back or show error
            return const Scaffold(body: Center(child: Text("Invalid User ID for Auth Prompt")));
          }
          // Return the actual screen widget, passing the ID and optional name
          return AuthPromptScreen(userId: userId, userName: userName);
        },
      ),

      GoRoute(
        path: AppRoutes.accountDetails,
        name: 'accountDetails',
        parentNavigatorKey: _rootNavigatorKey, // Show over bottom bar
        builder: (context, state) => const AccountDetailsScreen(), // Create this screen
      ),

      GoRoute(
        path: AppRoutes.changePassword,
        name: 'changePassword',
        parentNavigatorKey: _rootNavigatorKey, // Show over bottom bar
        builder: (context, state) => const ChangePasswordScreen(), // Create this screen
      ),

      GoRoute(
        path: AppRoutes.skinAssessment,
        name: 'skinAssessment',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (c,s) => const SkinTypeAssessmentScreen(), // Create this screen
      ),
      GoRoute(
        path: AppRoutes.skinResult,
        name: 'skinResult',
        parentNavigatorKey: _rootNavigatorKey,
        // Result screen might take the calculated type as an argument later
        builder: (c,s) => const SkinTypeResultScreen(), // Create this screen
      ),

      GoRoute(
          path: AppRoutes.riskAssessment,
          parentNavigatorKey: _rootNavigatorKey,
          builder: (c,s) => const RiskProfileAssessmentScreen()
      ),


       GoRoute(path: AppRoutes.riskResult,
           parentNavigatorKey: _rootNavigatorKey,
           builder: (c,s) => const RiskProfileResultScreen()
       ),


      GoRoute(
        path: AppRoutes.settingsReminders,
        name: 'settingsReminders',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (c,s) => const ReminderSettingsScreen(), // Create this screen
      ),









      // --- Other Top-Level Routes (Example) ---
      // Add routes here that should appear *over* the bottom nav bar
      // GoRoute(
      //   path: '/scan-detail/:scanId',
      //   parentNavigatorKey: _rootNavigatorKey, // Use root key
      //   builder: (context, state) {
      //     final scanId = state.pathParameters['scanId']!;
      //     // return ScanDetailScreen(scanId: scanId); // Your detail screen
      //   },
      // ),
    ],
  );
}