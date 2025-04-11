// lib/features/assessment/screens/skin_type_result_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import routes, providers, constants, entities (Adjust package name if needed)
import 'package:care/core/navigation/app_router.dart'; // Adjust package name
import 'package:care/core/providers/security_providers.dart';
import 'package:care/core/database/entities/user.dart';
import 'package:care/core/constants/app_constants.dart';
// *** Import the NEW provider file ***
import 'package:care/features/assessment/providers/assessment_providers.dart'; // Adjust package name

class SkinTypeResultScreen extends ConsumerWidget {
  const SkinTypeResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the current user to get their updated skin type
    final User? currentUser = ref.watch(currentUserProvider);
    final SkinType? userSkinType = currentUser?.skinType;

    // Get the corresponding details from the map, provide fallback
    final SkinTypeInfo details = skinTypeDetails[userSkinType] ??
        const SkinTypeInfo(
            name: "Unknown",
            description: "Could not determine skin type or user not found.",
            color: Colors.grey
        );

    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;

    // --- Define a consistent border radius ---
    // Use the same value as in RiskProfileResultScreen for consistency
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
        title: const Text('Skin Type Result'),
        automaticallyImplyLeading: false, // No back button if coming from assessment flow
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch buttons
          children: [
            // --- Color Palette Visualization ---
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    color: details.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.outlineVariant, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ]
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Skin Type Name ---
            Text(
              details.name,
              style: textTheme.headlineSmall?.copyWith(color: colors.primary), // Use primary theme color for title
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // --- Description ---
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  details.description,
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // --- Action Buttons ---
            ElevatedButton(
              onPressed: () {
                // Safer navigation
                if (context.canPop()) context.pop(); else context.go(AppRoutes.settings);
              },
              style: elevatedButtonStyle, // Apply consistent style
              child: const Text('Done'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                print("Retake Skin Type Assessment Tapped");
                // Invalidate skin type assessment providers
                ref.invalidate(assessmentAnswersProvider);
                ref.invalidate(assessmentPageIndexProvider);
                // Navigate back to skin assessment start
                context.pushReplacement(AppRoutes.skinAssessment);
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