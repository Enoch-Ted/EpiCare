// lib/features/assessment/screens/skin_type_assessment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart'; // Import flutter_hooks
import 'package:hooks_riverpod/hooks_riverpod.dart'; // Use hooks_riverpod
import 'package:go_router/go_router.dart';

// Import entities/providers (Adjust package name if needed)
import 'package:care/core/database/entities/user.dart';
import 'package:care/core/providers/security_providers.dart';
import 'package:care/core/providers/database_providers.dart'; // For DAOs and invalidation
import 'package:care/core/navigation/app_router.dart'; // For result route

// --- State Management for Assessment ---
final _assessmentPageIndexProvider = StateProvider<int>((ref) => 0);
final _assessmentAnswersProvider = StateProvider<Map<int, int>>((ref) => {});


class SkinTypeAssessmentScreen extends HookConsumerWidget { // Changed to HookConsumerWidget
  const SkinTypeAssessmentScreen({super.key});

  // --- Define Assessment Questions ---
  final List<Map<String, dynamic>> _questions = const [
    // ... (Your questions list remains unchanged) ...
    {
      'question': 'What is your natural eye color?',
      'options': [ 'Light blue, light gray or light green', 'Blue, gray or green', 'Hazel or light brown', 'Dark brown', 'Brownish black', ],
      'points': [0, 3, 6, 9, 12],
    },
    {
      'question': 'What is your natural hair color?',
      'options': [ 'Sandy red', 'Blond', 'Chestnut or dark blond', 'Dark brown', 'Black', ],
      'points': [0, 3, 6, 9, 12],
    },
    {
      'question': 'What is your natural skin color (before sun exposure)?',
      'options': [ 'Reddish', 'Very pale', 'Pale with beige tint', 'Light brown', 'Dark brown', ],
      'points': [0, 3, 6, 9, 12],
    },
    {
      'question': 'How many freckles do you have on unexposed areas?',
      'options': [ 'Many', 'Several', 'Few', 'Very few', 'None', ],
      'points': [0, 3, 6, 9, 12],
    },
    {
      'question': 'How does your skin respond to the sun?',
      'options': [ 'Always burns, never tans', 'Usually burns, tans minimally', 'Sometimes burns mildly, tans uniformly', 'Rarely burns, tans easily', 'Never burns, tans profusely', 'Never burns, deeply pigmented', ],
      'points': [0,4,8,12,16,20],
    },
  ];

  // --- Build Question Page ---
  Widget _buildQuestionPage(BuildContext context, WidgetRef ref, int pageIndex) {
    // ... (This function remains unchanged) ...
    final questionData = _questions[pageIndex];
    final String questionText = questionData['question'];
    final List<String> options = questionData['options'];
    final currentAnswers = ref.watch(_assessmentAnswersProvider);
    final int? selectedOptionIndex = currentAnswers[pageIndex];

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text( 'Question ${pageIndex + 1} of ${_questions.length}', style: Theme.of(context).textTheme.bodySmall, ),
        const SizedBox(height: 8),
        Text( questionText, style: Theme.of(context).textTheme.titleLarge, ),
        const SizedBox(height: 24),
        for (int i = 0; i < options.length; i++)
          RadioListTile<int>(
            title: Text(options[i]),
            value: i,
            groupValue: selectedOptionIndex,
            onChanged: (int? value) {
              if (value != null) {
                ref.read(_assessmentAnswersProvider.notifier).update((state) {
                  final newState = Map<int, int>.from(state);
                  newState[pageIndex] = value;
                  return newState;
                });
              }
            },
          ),
      ],
    );
  }

  // --- MODIFIED Finish Assessment Logic ---
  Future<void> _finishAssessment(BuildContext context, WidgetRef ref) async {
    final answers = ref.read(_assessmentAnswersProvider);
    // Validation is handled by the button already, but double check is ok
    if (answers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all questions.'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    print("Assessment finished. Answers: $answers");

    // --- Calculate Skin Type ---
    int totalScore = 0;
    answers.forEach((questionIndex, answerIndex) {
      if (_questions[questionIndex].containsKey('points') &&
          _questions[questionIndex]['points'].length > answerIndex) {
        totalScore += _questions[questionIndex]['points'][answerIndex] as int;
      } else { print("Warning: Missing points for question $questionIndex or answer $answerIndex"); }
    });
    print("Total Score: $totalScore");

    SkinType calculatedType;
    // Example Fitzpatrick Scale Mapping (ADJUST BASED ON OFFICIAL SCALE AND YOUR POINTS)
    if (totalScore >= 0 && totalScore <=10) calculatedType = SkinType.I;
    else if (totalScore >= 11 && totalScore <= 20) calculatedType = SkinType.II;
    else if (totalScore >= 21 && totalScore <= 30) calculatedType = SkinType.III;
    else if (totalScore >= 31 && totalScore <= 40) calculatedType = SkinType.IV;
    else if (totalScore >= 41 && totalScore <= 50) calculatedType = SkinType.V;
    else calculatedType = SkinType.VI; // Score 50+
    print("Calculated Skin Type: ${calculatedType.name}");
    // --- End Calculate ---


    // --- Save Result to User Profile ---
    final currentUser = ref.read(currentUserProvider); // Get current user state
    bool saveSuccess = false; // Flag for save status

    if (currentUser != null && currentUser.userId != null) {
      print("Attempting to save skin type ${calculatedType.name} for user ${currentUser.userId}");
      // Create updated user object using copyWith
      final updatedUser = currentUser.copyWith(skinType: calculatedType);
      // Call update method via notifier
      saveSuccess = await ref.read(authNotifierProvider.notifier).updateUserProfile(updatedUser);

      if (saveSuccess) {
        print("Skin type saved successfully.");
        // Invalidate providers to ensure UI updates elsewhere
        ref.invalidate(currentUserProvider);
        ref.invalidate(allUsersProvider); // Profile list might show type
        // Invalidate settings provider if it displays skin type
        ref.invalidate(currentUserSettingsProvider); // Or specific parts if possible
      } else {
        print("Failed to save skin type.");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Could not save skin type. Please try again.'), backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
        return; // Stop if saving failed
      }
    } else {
      print("Error: Cannot save skin type - no active user found.");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Error: Could not find active user to save settings.'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
      return; // Stop if no user
    }
    // --- End Save ---


    // --- Navigate to Result Screen ---
    if (context.mounted) {
      // Reset answers and page index for next time
      ref.read(_assessmentAnswersProvider.notifier).state = {};
      ref.read(_assessmentPageIndexProvider.notifier).state = 0;

      // Navigate, replacing assessment screen
      // TODO: Pass calculatedType to result screen if needed
      context.pushReplacement(AppRoutes.skinResult);
    }
  } // --- End _finishAssessment ---


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPageIndex = ref.watch(_assessmentPageIndexProvider);
    final pageController = usePageController(initialPage: currentPageIndex);

    ref.listen(_assessmentPageIndexProvider, (_, next) {
      if (pageController.hasClients && pageController.page?.round() != next) {
        pageController.animateToPage(next, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skin Type Assessment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () { if (context.canPop()) context.pop(); },
        ),
      ),
      body: PageView.builder(
        controller: pageController,
        itemCount: _questions.length,
        itemBuilder: (context, index) => _buildQuestionPage(context, ref, index),
        onPageChanged: (index) => ref.read(_assessmentPageIndexProvider.notifier).state = index,
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: currentPageIndex == 0 ? null : () {
                  ref.read(_assessmentPageIndexProvider.notifier).state--;
                },
                child: const Text('Back'),
              ),
              _buildPageIndicator(context, _questions.length, currentPageIndex),
              ElevatedButton(
                onPressed: () {
                  // *** Validation logic moved here ***
                  final currentAnswers = ref.read(_assessmentAnswersProvider);
                  if (currentAnswers[currentPageIndex] == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select an option to continue.'), backgroundColor: Colors.orangeAccent)
                    );
                    return;
                  }
                  // *** End Validation ***

                  if (currentPageIndex < _questions.length - 1) {
                    ref.read(_assessmentPageIndexProvider.notifier).state++;
                  } else {
                    _finishAssessment(context, ref); // Call the updated finish method
                  }
                },
                child: Text(currentPageIndex < _questions.length - 1 ? 'Next' : 'Finish'),
              ),
            ],
          ),
        ),
      ),
    );
  } // End build

  // Helper to build page indicator dots
  Widget _buildPageIndicator(BuildContext context, int pageCount, int currentPage) {
    // ... (This function remains unchanged) ...
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        return Container(
          width: 8.0, height: 8.0,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentPage == index ? Theme.of(context).colorScheme.primary : Colors.grey[400],
          ),
        );
      }),
    );
  }

} // End class

// Hook to use PageController
PageController usePageController({int initialPage = 0}) {
  return useMemoized(() => PageController(initialPage: initialPage), [initialPage]);
}