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

// Remove the import for the assessment screen itself if providers are separate
// import 'skin_type_assessment_screen.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skin Type Result'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    boxShadow: [ /* ... shadow ... */ ]
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Skin Type Name ---
            Text( details.name, style: textTheme.headlineSmall?.copyWith(color: colors.primary), textAlign: TextAlign.center, ),
            const SizedBox(height: 24),

            // --- Description ---
            Expanded(
              child: SingleChildScrollView(
                child: Text( details.description, style: textTheme.bodyLarge, textAlign: TextAlign.center,),
              ),
            ),
            const SizedBox(height: 32),

            // --- Action Buttons ---
            ElevatedButton(
              onPressed: () { if (context.canPop()) context.pop(); },
              child: const Text('Done'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                print("Retake Assessment Tapped");
                // *** Use PUBLIC provider names from assessment_providers.dart ***
                ref.invalidate(assessmentAnswersProvider); // Use public name
                ref.invalidate(assessmentPageIndexProvider); // Use public name
                // *** End Use PUBLIC provider names ***

                // Navigate back to assessment start
                context.pushReplacement(AppRoutes.skinAssessment);
              },
              child: const Text('Retake Assessment'),
            ),
          ],
        ),
      ),
    );
  }
}