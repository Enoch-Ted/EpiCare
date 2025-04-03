// lib/features/assessment/screens/risk_profile_result_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import routes, providers, constants, entities (Adjust package name)
import 'package:care/core/navigation/app_router.dart';
import 'package:care/core/constants/app_constants.dart';
import 'package:care/core/providers/security_providers.dart';
import 'package:care/core/database/entities/user.dart'; // For RiskProfile enum
// *** Import NEW providers ***
import 'package:care/features/assessment/providers/assessment_providers.dart';
// TODO: Add constants for risk profile details later

// *** RENAME CLASS ***
class RiskProfileResultScreen extends ConsumerWidget {
  const RiskProfileResultScreen({super.key});

  // --- TODO: Create Risk Profile Details Map/Helper ---
  // Similar to skinTypeDetails, create a map for RiskProfile
  String _getRiskDescription(RiskProfile? profile) {
    switch (profile) {
      case RiskProfile.Low: return "Based on your answers, you have a lower risk...\n- Apply SPF30+\n- Wear protective clothing\n- Avoid sunbeds\n- Monitor your skin";
      case RiskProfile.Medium: return "Based on your answers, you have a medium risk...\n- Be extra vigilant with sun protection\n- Perform regular self-checks\n- Consider annual dermatologist visits";
      case RiskProfile.High: return "Based on your answers, you have a higher risk...\n- Strict sun protection is crucial\n- Perform monthly self-checks\n- Schedule regular dermatologist appointments (e.g., every 6 months)";
      default: return "Could not determine risk profile.";
    }
  }
  String _getRiskName(RiskProfile? profile) {
    switch (profile) {
      case RiskProfile.Low: return "Low Risk";
      case RiskProfile.Medium: return "Medium Risk";
      case RiskProfile.High: return "High Risk";
      default: return "Unknown Risk";
    }
  }
  IconData _getRiskIcon(RiskProfile? profile) {
    switch (profile) {
      case RiskProfile.Low: return Icons.check_circle_outline; // Green?
      case RiskProfile.Medium: return Icons.warning_amber_outlined; // Yellow?
      case RiskProfile.High: return Icons.dangerous_outlined; // Red?
      default: return Icons.help_outline;
    }
  }
  Color _getRiskColor(RiskProfile? profile, ColorScheme colors) {
    switch (profile) {
      case RiskProfile.Low: return Colors.green;
      case RiskProfile.Medium: return Colors.orange;
      case RiskProfile.High: return colors.error;
      default: return Colors.grey;
    }
  }
  // --- End TODO ---


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch current user for risk profile
    final User? currentUser = ref.watch(currentUserProvider);
    final RiskProfile? userRiskProfile = currentUser?.riskProfile;

    // Get details using helper methods
    final String riskName = _getRiskName(userRiskProfile);
    final String riskDescription = _getRiskDescription(userRiskProfile);
    final IconData riskIcon = _getRiskIcon(userRiskProfile);
    final Color riskColor = _getRiskColor(userRiskProfile, Theme.of(context).colorScheme);

    final RiskProfileInfo details = riskProfileDetails[userRiskProfile] ??
        RiskProfileInfo( // Fallback
            name: "Unknown Risk",
            description: "Could not determine risk profile.",
            icon: Icons.help_outline,
            color: Colors.grey
        );


    final TextTheme textTheme = Theme.of(context).textTheme;
    // final ColorScheme colors = Theme.of(context).colorScheme; // Already got color via helper

    return Scaffold(
      appBar: AppBar(
        // *** Update Title ***
        title: const Text('Risk Profile Result'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Risk Icon Visualization ---
            Center(
              child: Icon(riskIcon, size: 80, color: riskColor), // Use themed color
            ),
            const SizedBox(height: 16),

            // --- Risk Profile Name ---
            Text(
              riskName, // Use name from helper
              style: textTheme.headlineSmall?.copyWith(color: riskColor), // Use risk color
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // --- Description ---
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  riskDescription, // Use description from helper
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center, // Or start
                ),
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
                print("Retake Risk Assessment Tapped");
                // *** Reset RISK assessment providers ***
                ref.invalidate(riskAssessmentAnswersProvider);
                ref.invalidate(riskAssessmentPageIndexProvider);
                // *** Navigate to RISK assessment start ***
                context.pushReplacement(AppRoutes.riskAssessment);
              },
              child: const Text('Retake Assessment'),
            ),
          ],
        ),
      ),
    );
  }
}