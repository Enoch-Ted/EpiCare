// lib/features/assessment/providers/assessment_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'assessment_providers.g.dart'; // Add part directive

// Provider to hold the current page index for assessments
@Riverpod(keepAlive: false) // KeepAlive likely not needed, reset on invalidate
class AssessmentPageIndex extends _$AssessmentPageIndex { // Use Class-based syntax
  @override
  int build() => 0; // Initial state is 0
}

// Provider to hold the answers (Map<QuestionIndex, AnswerValue>)
@Riverpod(keepAlive: false) // KeepAlive likely not needed
class AssessmentAnswers extends _$AssessmentAnswers { // Use Class-based syntax
  @override
  Map<int, int> build() => {}; // Initial state is empty map
}

// --- Risk Profile Assessment State ---
@Riverpod(keepAlive: false)
class RiskAssessmentPageIndex extends _$RiskAssessmentPageIndex { @override int build() => 0; }

@Riverpod(keepAlive: false)
class RiskAssessmentAnswers extends _$RiskAssessmentAnswers {
  @override
  Map<int, int> build() => {}; // Initial state is empty map

  // Method to update an answer
  void setAnswer(int questionIndex, int answerIndex) {
    // To update the immutable state, create a new map based on the old one
    // Use the spread operator for conciseness
    // *** CORRECT way to update state ***
    state = {
      ...state, // Copy existing key-value pairs
      questionIndex: answerIndex, // Add or overwrite the specific answer
    };
    // No need for final newState variable or Map.from()
  }

  // Method to reset answers
  void resetAnswers() {
    // Assign a new empty map to state
    // *** CORRECT way to reset state ***
    state = {};
  }
} // *** Ensure closing brace is here ***
//