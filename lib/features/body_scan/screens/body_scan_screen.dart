// lib/features/body_scan/screens/body_scan_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io'; // For FileImage if needed later
import 'package:go_router/go_router.dart';
import 'dart:math';

// Import core project files (adjust package name 'epiccare' if different)
import 'package:care/core/database/entities/user.dart';
import 'package:care/core/database/entities/lesion.dart'; // For BodySide enum
import 'package:care/core/providers/security_providers.dart';
import 'package:care/core/constants/app_constants.dart';
import 'package:care/presentation/theme/app_theme.dart'; // For direct theme constants if needed
import 'package:care/core/providers/database_providers.dart';
import 'package:care/core/navigation/app_router.dart';
import 'package:care/features/profile/widgets/profile_bio_modal.dart';
import 'package:care/features/body_scan/providers/body_map_providers.dart';

// State provider for managing the front/back view toggle
final isBodyFrontProvider = StateProvider<bool>((ref) => true); // Default to front view

class BodyScanScreen extends ConsumerWidget {
  const BodyScanScreen({super.key});

  // Helper to build Skin Type / Risk Profile text row
  Widget _buildUserInfoSubtitle(User? user, BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color subtitleColor = textTheme.bodySmall!.color ?? Colors.grey[700]!;

    String skinTypeDisplay = "Find skin type";
    TextStyle skinTypeStyle = textTheme.bodySmall!.copyWith(color: colors.primary);
    VoidCallback? skinTypeTap = () {
      print("Navigate to Skin Type Assessment");
      context.push(AppRoutes.skinAssessment);
    };

    if (user?.skinType != null) {
      skinTypeDisplay = "Skin Type ${user!.skinType!.name}";
      skinTypeStyle = textTheme.bodySmall!.copyWith(color: subtitleColor);
      skinTypeTap = () {
        print("Navigate to Skin Type Result Screen");
        context.push(AppRoutes.skinResult);  // Go to result screen
      };
    }else {
      skinTypeTap = () {
        print("Navigate to Skin Type Assessment");
        context.push(AppRoutes.skinAssessment); // Go to assessment screen
      };
    }

    String riskProfileDisplay = "Find risk profile";
    TextStyle riskProfileStyle = textTheme.bodySmall!.copyWith(color: colors.primary);
    VoidCallback? riskProfileTap = () {
      print("Navigate to Risk Profile Assessment");
      context.push(AppRoutes.riskAssessment);
    };

    if (user?.riskProfile != null) {
      riskProfileDisplay = "Risk: ${user!.riskProfile!.name}";
      riskProfileStyle = textTheme.bodySmall!.copyWith(color: subtitleColor);
      riskProfileTap = () {
        print("Navigate to Risk Profile Details");
        context.push(AppRoutes.riskResult);
      };
    }

    return Row(
      children: [
        // TODO: Add color palette icon for skin type if needed
        // Placeholder: Container(width: 16, height: 16, color: Colors.orange[100], margin: const EdgeInsets.only(right: 4)),
        InkWell(onTap: skinTypeTap, child: Text(skinTypeDisplay, style: skinTypeStyle)),
        Text(" | ", style: textTheme.bodySmall!.copyWith(color: subtitleColor)),
        InkWell(onTap: riskProfileTap, child: Text(riskProfileDisplay, style: riskProfileStyle)),
      ],
    );
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch states from providers
    final User? currentUser = ref.watch(currentUserProvider);
    final bool isFront = ref.watch(isBodyFrontProvider);
    final isBodyFrontNotifier = ref.read(isBodyFrontProvider.notifier);
    final lesionCountsAsyncValue = ref.watch(userLesionCountsProvider);
    // *** Watch provider for visible lesions ***
    final List<Lesion> visibleLesions = ref.watch(visibleBodyMapLesionsProvider);

    // Theme variables for convenience
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    // --- Loading State ---
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: colors.primary)),
      );
    }

    // --- Define Aspect Ratios ---
    const double frontAspectRatio = 631 / 1500;
    const double backAspectRatio = 630 / 1494;
    final double currentAspectRatio = isFront ? frontAspectRatio : backAspectRatio;

    // --- Main UI ---
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column( // Main layout column
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- User Info Row ---
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      print("Tapped Profile Pic/Name - Showing Modal");
                      // *** Show Modal Bottom Sheet ***
                      showModalBottomSheet(
                        context: context,
                        // Optional: Make it scrollable if content might exceed height
                        isScrollControlled: true,
                        // Optional: Customize shape
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
                        ),
                        builder: (modalContext) {
                          // Pass the current user data to the modal widget
                          return ProfileBioModal(user: currentUser);
                        },
                      );
                      // TODO: Implement Modal/BottomSheet display for user bio
                    },
                    child: CircleAvatar(
                      radius: 25,
                      backgroundImage: const AssetImage(AssetPaths.defaultProfilePic),
                      backgroundColor: colors.secondaryContainer, // Use theme color
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector( // Allow tapping name too
                          onTap: () {
                            print("Tapped Profile Pic/Name");
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("TODO: Show Bio Data Modal")));
                            // TODO: Implement Modal/BottomSheet display for user bio
                          },
                          child: Text(
                            currentUser.displayName,
                            style: textTheme.titleMedium?.copyWith(color: colors.onBackground),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 2),
                        _buildUserInfoSubtitle(currentUser, context), // Subtitle helper
                      ],
                    ),
                  ),
                ],
              ), // End User Info Row
              const SizedBox(height: 12),

              // --- Buttons Row ---
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Learn More Item (Wider)
                    Expanded(
                      flex: 7, // Adjust ratio as needed
                      child: Card(
                        color: AppTheme.lightBlueBackground, // Or colors.primaryContainer
                        shape: Theme.of(context).cardTheme.shape,
                        elevation: Theme.of(context).cardTheme.elevation,
                        margin: const EdgeInsets.only(right: 4.0),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            print("Tapped Learn More");
                            context.push(AppRoutes.settingsInfo); // Navigate
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.help_outline, color: colors.primary, size: 24),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: RichText(
                                    text: TextSpan(
                                      style: textTheme.bodySmall?.copyWith(color: colors.primary, height: 1.3), // Or onPrimaryContainer
                                      children: const [
                                        TextSpan(text: 'Interested in learning more about skin cancer? '),
                                        TextSpan(
                                          text: 'Read articles',
                                          style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ), // End Expanded Learn More

                    // Set Reminder Item (Narrower)
                    Expanded(
                      flex: 3, // Adjust ratio as needed
                      child: Card(
                        color: colors.surfaceVariant, // Use theme light grey
                        shape: Theme.of(context).cardTheme.shape,
                        elevation: Theme.of(context).cardTheme.elevation,
                        margin: const EdgeInsets.only(left: 4.0),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            print("Tapped Set Reminder");
                            context.push(AppRoutes.settingsReminders); // Navigate
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Set Skin Check Reminder', // Corrected Text
                                    style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios, size: 16, color: colors.onSurfaceVariant.withOpacity(0.8)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ), // End Expanded Set Reminder
                  ],
                ), // End Row
              ), // End IntrinsicHeight
              const SizedBox(height: 12),

              // --- Body Image Area with Markers ---
              Expanded(
                child: LayoutBuilder( // Use LayoutBuilder to get constraints
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final availableHeight = constraints.maxHeight;

                    // Calculate the actual render size based on aspect ratio and BoxFit.contain
                    double renderWidth;
                    double renderHeight;
                    double offsetX = 0; // Horizontal padding if image is shorter than available width
                    double offsetY = 0; // Vertical padding if image is narrower than available height

                    // Determine if the width or height is the limiting constraint
                    if (availableWidth / availableHeight > currentAspectRatio) {
                      // Height is limiting, width will have padding
                      renderHeight = availableHeight;
                      renderWidth = availableHeight * currentAspectRatio;
                      offsetX = (availableWidth - renderWidth) / 2; // Centered padding
                    } else {
                      // Width is limiting, height will have padding
                      renderWidth = availableWidth;
                      renderHeight = availableWidth / currentAspectRatio;
                      offsetY = (availableHeight - renderHeight) / 2; // Centered padding
                    }

                    // Prevent negative offsets if calculation is slightly off
                    offsetX = max(0, offsetX);
                    offsetY = max(0, offsetY);

                    print("Layout: Available($availableWidth x $availableHeight), Render($renderWidth x $renderHeight), Offset($offsetX, $offsetY)");

                    return Stack(
                      children: [
                        // --- Body Image ---
                        // Position the image within the Stack based on calculated offsets
                        Positioned(
                          left: offsetX,
                          top: offsetY,
                          width: renderWidth,
                          height: renderHeight,
                          child: Image.asset(
                            isFront ? AssetPaths.bodyMapFront : AssetPaths.bodyMapBack,
                            // No fit needed here as size is explicitly set
                          ),
                        ),

                        // --- Lesion Markers ---
                        // Layer markers on top, using calculated offsets and render size
                        if (visibleLesions.isNotEmpty)
                          ...visibleLesions.map((lesion) {
                            const double markerSize = 24.0;
                            // Calculate position relative to the RENDERED image box
                            final double markerLeft = offsetX + (lesion.bodyMapX * renderWidth) - (markerSize / 2);
                            final double markerTop = offsetY + (lesion.bodyMapY * renderHeight) - (markerSize / 2);

                            // Basic boundary check (optional)
                            // if (markerLeft < offsetX || markerTop < offsetY || ...)

                            return Positioned(
                              left: markerLeft,
                              top: markerTop,
                              child: GestureDetector(
                                onTap: () {
                                  print("Tapped marker for Lesion ID: ${lesion.lesionId}, navigating to Scan ID: ${lesion.scanId}");
                                  final detailPath = AppRoutes.scanDetail.replaceFirst(':scanId', lesion.scanId.toString());
                                  context.push(detailPath);
                                },
                                child: Tooltip(
                                  message: "${lesion.lesionType}\n(${lesion.riskLevel})", // Show type/risk
                                  child: Icon(
                                    Icons.location_on,
                                    color: Colors.redAccent.withOpacity(0.9), // Slightly more opaque
                                    size: markerSize,
                                    shadows: const [Shadow(blurRadius: 1.0, color: Colors.black54)], // Add shadow
                                  ),
                                ),
                              ),
                            );
                          }).toList(), // End map and convert to list
                      ], // End Stack children
                    ); // End Stack
                  }, // End LayoutBuilder builder
                ), // End LayoutBuilder
              ), // End Expanded for Body Area
              const SizedBox(height: 8),

              // --- Front/Back Toggle (with Lesion Count) ---
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.primary),
                  ),
                  child: lesionCountsAsyncValue.when( // Use .when for AsyncValue
                    data: (counts) {
                      final frontCount = counts['front'] ?? 0;
                      final backCount = counts['back'] ?? 0;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () { isBodyFrontNotifier.state = true; },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: isFront ? colors.primary : colors.surface,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(7),
                                  bottomLeft: Radius.circular(7),
                                ),
                              ),
                              child: Text(
                                'Front ($frontCount)', // Display count
                                style: textTheme.labelMedium?.copyWith(
                                  color: isFront ? colors.onPrimary : colors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () { isBodyFrontNotifier.state = false; },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: !isFront ? colors.primary : colors.surface,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(7),
                                  bottomRight: Radius.circular(7),
                                ),
                              ),
                              child: Text(
                                'Back ($backCount)', // Display count
                                style: textTheme.labelMedium?.copyWith(
                                  color: !isFront ? colors.onPrimary : colors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                      child: const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    error: (error, stackTrace) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Tooltip( // Add tooltip for error
                          message: error.toString(),
                          child: Icon(Icons.error_outline, color: colors.error, size: 18),
                        )
                    ),
                  ), // End .when
                ), // End Container
              ), // End Center
              const SizedBox(height: 8), // Spacing at the bottom
            ],
          ), // End Main Column
        ), // End Padding
      ), // End SafeArea
    ); // End Scaffold
  } // End build
} // End BodyScanScreen