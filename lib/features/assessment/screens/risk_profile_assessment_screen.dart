// lib/features/assessment/screens/risk_profile_assessment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart'; // Use hooks_riverpod
import 'package:go_router/go_router.dart';

// Import entities/providers (Adjust package name if needed)
import 'package:care/core/database/entities/user.dart'; // Adjust package name
import 'package:care/core/providers/security_providers.dart';
import 'package:care/core/providers/database_providers.dart';
import 'package:care/core/navigation/app_router.dart';
// Import NEW providers
import 'package:care/features/assessment/providers/assessment_providers.dart'; // Adjust package name

class RiskProfileAssessmentScreen extends HookConsumerWidget {
  const RiskProfileAssessmentScreen({super.key});

  // Define Risk Assessment Questions
  final List<Map<String, dynamic>> _questions = const [
    { 'question': 'How often did you experience severe sunburns during childhood/adolescence?', 'options': ['Never', 'Rarely (1-2 times)', 'Occasionally (Several times)', 'Frequently (Many times)'], 'points': [0, 1, 2, 3], },
    { 'question': 'Do you have a personal history of melanoma or non-melanoma skin cancer?', 'options': ['No', 'Yes, non-melanoma', 'Yes, melanoma'], 'points': [0, 2, 4], },
    { 'question': 'Do you have a close family member (parent, sibling, child) with a history of melanoma?', 'options': ['No', 'Yes'], 'points': [0, 3], },
    { 'question': 'How many moles (nevi) do you estimate you have on your body?', 'options': ['Less than 15', '15-50', 'More than 50', 'Many atypical moles'], 'points': [0, 1, 2, 3], },
  ];

  // Build Question Page
  Widget _buildQuestionPage(BuildContext context, WidgetRef ref, int pageIndex) {
    final questionData = _questions[pageIndex];
    final String questionText = questionData['question'];
    final List<String> options = questionData['options'];
    final currentAnswers = ref.watch(riskAssessmentAnswersProvider); // Use RISK provider
    final int? selectedOptionIndex = currentAnswers[pageIndex];

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text('Question ${pageIndex + 1} of ${_questions.length}', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Text(questionText, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        for (int i = 0; i < options.length; i++)
          RadioListTile<int>(
            title: Text(options[i]),
            value: i,
            groupValue: selectedOptionIndex,
            onChanged: (int? value) {
              if (value != null) {
                // *** CORRECTED state update ***
                ref.read(riskAssessmentAnswersProvider.notifier).setAnswer(pageIndex, value);
              }
            },
          ),
      ],
    );
  }

  // Finish Risk Assessment Logic
  Future<void> _finishRiskAssessment(BuildContext context, WidgetRef ref) async {
    final answers = ref.read(riskAssessmentAnswersProvider); // Use RISK provider
    if (answers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Please answer all questions.'), backgroundColor: Colors.orangeAccent), );
      return;
    }

    print("Risk Assessment finished. Answers: $answers");
    int totalRiskScore = 0;
    answers.forEach((questionIndex, answerIndex) {
      if (_questions[questionIndex].containsKey('points') && _questions[questionIndex]['points'].length > answerIndex) {
        totalRiskScore += _questions[questionIndex]['points'][answerIndex] as int;
      } else { print("Warning: Missing points for question $questionIndex or answer $answerIndex"); }
    });
    print("Total Risk Score: $totalRiskScore");

    RiskProfile calculatedRisk;
    if (totalRiskScore <= 3) calculatedRisk = RiskProfile.Low;
    else if (totalRiskScore <= 7) calculatedRisk = RiskProfile.Medium;
    else calculatedRisk = RiskProfile.High;
    print("Calculated Risk Profile: ${calculatedRisk.name}");

    final currentUser = ref.read(currentUserProvider);
    bool saveSuccess = false;
    if (currentUser != null && currentUser.userId != null) {
      print("Attempting to save risk profile for user ${currentUser.userId}");
      final updatedUser = currentUser.copyWith(riskProfile: calculatedRisk); // Save risk profile
      saveSuccess = await ref.read(authNotifierProvider.notifier).updateUserProfile(updatedUser);
      if (saveSuccess) {
        print("Risk profile saved successfully.");
        ref.invalidate(currentUserProvider);
        ref.invalidate(allUsersProvider);
        ref.invalidate(currentUserSettingsProvider);
      } else { /* Handle save failure */ return; }
    } else { /* Handle no user */ return; }

    if (context.mounted && saveSuccess) { // Check success before navigating
      ref.read(riskAssessmentAnswersProvider.notifier).state = {}; // Reset RISK provider
      ref.read(riskAssessmentPageIndexProvider.notifier).state = 0; // Reset RISK provider
      context.pushReplacement(AppRoutes.riskResult); // Navigate to RISK result
    } else if (context.mounted && !saveSuccess) {
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: const Text('Could not save risk profile. Please try again.'), backgroundColor: Theme.of(context).colorScheme.error), );
    }
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPageIndex = ref.watch(riskAssessmentPageIndexProvider); // Use RISK provider
    final pageController = usePageController(initialPage: currentPageIndex);

    ref.listen(riskAssessmentPageIndexProvider, (_, next) { // Use RISK provider
      if (pageController.hasClients && pageController.page?.round() != next) {
        pageController.animateToPage(
          next,
          // *** ADDED duration and curve ***
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Profile Assessment'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () { if (context.canPop()) context.pop(); }),
      ),
      body: PageView.builder(
        controller: pageController,
        itemCount: _questions.length,
        itemBuilder: (context, index) => _buildQuestionPage(context, ref, index),
        onPageChanged: (index) => ref.read(riskAssessmentPageIndexProvider.notifier).state = index, // Use RISK provider
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: currentPageIndex == 0 ? null : () => ref.read(riskAssessmentPageIndexProvider.notifier).state--, // Use RISK provider
                child: const Text('Back'),
              ),
              _buildPageIndicator(context, _questions.length, currentPageIndex),
              ElevatedButton(
                onPressed: () {
                  final currentAnswers = ref.read(riskAssessmentAnswersProvider); // Use RISK provider
                  if (currentAnswers[currentPageIndex] == null) {
                    ScaffoldMessenger.of(context).showSnackBar( const SnackBar( content: Text('Please select an option to continue.'), backgroundColor: Colors.orangeAccent, ) );
                    return;
                  }
                  if (currentPageIndex < _questions.length - 1) {
                    ref.read(riskAssessmentPageIndexProvider.notifier).state++; // Use RISK provider
                  } else {
                    _finishRiskAssessment(context, ref); // Call RISK finish method
                  }
                },
                child: Text(currentPageIndex < _questions.length - 1 ? 'Next' : 'Finish'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to build page indicator dots
  Widget _buildPageIndicator(BuildContext context, int pageCount, int currentPage) {
    // *** ADDED explicit return ***
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
  // *** ADDED explicit return ***
  return useMemoized(() => PageController(initialPage: initialPage), [initialPage]);
}