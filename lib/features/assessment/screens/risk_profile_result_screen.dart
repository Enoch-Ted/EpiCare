// lib/features/assessment/screens/risk_profile_result_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import routes, providers, constants, entities (Adjust package name)
import 'package:care/core/navigation/app_router.dart';
import 'package:care/core/constants/app_constants.dart';
import 'package:care/core/providers/security_providers.dart';
import 'package:care/core/database/entities/user.dart'; // For RiskProfile enum
import 'package:care/features/assessment/providers/assessment_providers.dart';

// *** Risk Profile Details Map (Example - Adapt as needed) ***
// It's generally better practice to define this structure outside the build method
class RiskProfileInfo {
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const RiskProfileInfo({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// Define the map (can be placed outside the class or in a constants file)
final Map<RiskProfile?, RiskProfileInfo> riskProfileDetails = {
  RiskProfile.Low: RiskProfileInfo(
    name: "Low Risk",
    description: "Based on your answers, you have a lower risk profile for developing skin cancer. However, everyone should practice sun safety.\n\nRecommendations:\n• Apply broad-spectrum SPF 30+ daily.\n• Wear protective clothing, hats, and sunglasses.\n• Avoid tanning beds.\n• Perform monthly skin self-checks.",
    icon: Icons.check_circle_outline,
    color: Colors.green.shade600, // Specific shade
  ),
  RiskProfile.Medium: RiskProfileInfo(
    name: "Medium Risk",
    description: "Based on your answers, you have a medium risk profile. Increased vigilance with sun protection and skin monitoring is recommended.\n\nRecommendations:\n• Be extra diligent with daily SPF 30+ application.\n• Always wear protective clothing in strong sun.\n• Perform monthly skin self-checks carefully.\n• Consider annual skin checks by a dermatologist.",
    icon: Icons.warning_amber_outlined,
    color: Colors.orange.shade700, // Specific shade
  ),
  RiskProfile.High: RiskProfileInfo(
    name: "High Risk",
    description: "Based on your answers, you have a higher risk profile. Strict sun protection and regular professional skin checks are crucial.\n\nRecommendations:\n• Use broad-spectrum SPF 50+ daily and reapply often.\n• Maximize use of protective clothing, hats, and sunglasses.\n• Seek shade during peak sun hours (10 AM - 4 PM).\n• Perform thorough monthly skin self-checks.\n• Schedule regular dermatologist appointments (e.g., every 6-12 months).",
    icon: Icons.dangerous_outlined,
    color: Colors.red.shade700, // Specific shade
  ),
  // Add a default/null case if needed
  null: RiskProfileInfo(
    name: "Unknown Risk",
    description: "Could not determine risk profile. Please retake the assessment.",
    icon: Icons.help_outline,
    color: Colors.grey.shade600,
  ),
};
// --- End Risk Profile Details ---


class RiskProfileResultScreen extends ConsumerWidget {
  const RiskProfileResultScreen({super.key});

  // REMOVED helper methods, using the map above now

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final User? currentUser = ref.watch(currentUserProvider);
    // Use the map to get details, providing a fallback for null
    final RiskProfileInfo details = riskProfileDetails[currentUser?.riskProfile] ?? riskProfileDetails[null]!;

    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme; // Get theme colors

    // --- Define a consistent border radius ---
    // You can adjust this value (e.g., 8.0, 12.0, 16.0)
    final BorderRadius buttonBorderRadius = BorderRadius.circular(12.0);

    // --- Define consistent ButtonStyle for reuse ---
    final ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: buttonBorderRadius, // Apply consistent radius
      ),
      backgroundColor: colors.primary, // Use theme color
      foregroundColor: colors.onPrimary, // Use theme color
      padding: const EdgeInsets.symmetric(vertical: 14), // Consistent padding
      textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold), // Consistent text style
    );

    final ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: buttonBorderRadius, // Apply consistent radius
      ),
      side: BorderSide(color: colors.primary), // Use theme color for border
      foregroundColor: colors.primary, // Use theme color for text
      padding: const EdgeInsets.symmetric(vertical: 14), // Consistent padding
      textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold), // Consistent text style
    );
    // --- End ButtonStyle definitions ---


    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Profile Result'),
        automaticallyImplyLeading: false, // No back button if coming from assessment flow
        elevation: 1, // Add slight elevation if desired
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch buttons horizontally
          children: [
            // --- Risk Icon Visualization ---
            Center(
              child: Icon(details.icon, size: 80, color: details.color), // Use color from details map
            ),
            const SizedBox(height: 16),

            // --- Risk Profile Name ---
            Text(
              details.name, // Use name from details map
              style: textTheme.headlineSmall?.copyWith(color: details.color), // Use color from details map
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // --- Description ---
            Expanded(
              child: SingleChildScrollView( // Ensure description scrolls if long
                child: Text(
                  details.description, // Use description from details map
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // --- Action Buttons ---
            ElevatedButton(
              onPressed: () {
                // Navigate back to where the user came from, or a specific screen like home
                // If always coming from assessment, pop might be okay.
                // If potentially reachable otherwise, consider context.go(AppRoutes.home);
                if (context.canPop()) context.pop(); else context.go(AppRoutes.settings); // Safer navigation
              },
              style: elevatedButtonStyle, // Apply consistent style
              child: const Text('Done'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                print("Retake Risk Assessment Tapped");
                ref.invalidate(riskAssessmentAnswersProvider);
                ref.invalidate(riskAssessmentPageIndexProvider);
                // Replace current route with assessment start
                context.pushReplacement(AppRoutes.riskAssessment);
              },
              style: outlinedButtonStyle, // Apply consistent style
              child: const Text('Retake Assessment'),
            ),
          ],
        ),
      ),
    );
  }
}