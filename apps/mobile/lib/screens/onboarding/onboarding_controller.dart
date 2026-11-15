import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showtime_mobile/core/eligibility/eligibility.dart';

/// Eligibility form result.
class OnboardingState {
  /// Creates the onboarding state.
  const OnboardingState({this.error, this.decision});

  /// Validation feedback.
  final String? error;

  /// Validated eligibility decision.
  final EligibilityDecision? decision;
}

/// Coordinates eligibility validation for the onboarding screen.
class OnboardingController extends StateNotifier<OnboardingState> {
  /// Creates the onboarding controller.
  OnboardingController() : super(const OnboardingState());

  /// Validates a date and returns a decision when eligible.
  EligibilityDecision? submit(String input) {
    try {
      final decision = evaluateEligibility(input.trim());
      state = OnboardingState(decision: decision);
      return decision;
    } on EligibilityValidationException catch (error) {
      state = OnboardingState(error: error.message);
      return null;
    }
  }
}

/// Owns the onboarding screen state.
final onboardingControllerProvider =
    StateNotifierProvider.autoDispose<OnboardingController, OnboardingState>(
      (ref) => OnboardingController(),
    );
