import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Consent selections displayed on the safety screen.
class SafetyState {
  /// Creates consent state.
  const SafetyState({required this.advertising, required this.analytics});

  /// Personalized advertising preference.
  final bool advertising;

  /// Optional analytics preference.
  final bool analytics;
}

/// Coordinates local consent changes and forwards them to injected consumers.
class NotificationSafetyController extends StateNotifier<SafetyState> {
  /// Creates a controller with the initial choices and change callbacks.
  NotificationSafetyController({
    required bool advertising,
    required bool analytics,
    this.onAdvertisingChanged,
    this.onAnalyticsChanged,
  }) : super(SafetyState(advertising: advertising, analytics: analytics));

  /// Consumer of advertising preference changes.
  final void Function(bool)? onAdvertisingChanged;

  /// Consumer of analytics preference changes.
  final void Function(bool)? onAnalyticsChanged;

  /// Updates the advertising preference.
  void setAdvertising(bool value) {
    state = SafetyState(advertising: value, analytics: state.analytics);
    onAdvertisingChanged?.call(value);
  }

  /// Updates the analytics preference.
  void setAnalytics(bool value) {
    state = SafetyState(advertising: state.advertising, analytics: value);
    onAnalyticsChanged?.call(value);
  }
}

/// Immutable arguments for a safety screen controller instance.
class SafetyControllerArgs {
  /// Creates controller arguments.
  const SafetyControllerArgs({
    required this.advertising,
    required this.analytics,
    this.onAdvertisingChanged,
    this.onAnalyticsChanged,
  });

  /// Initial advertising preference.
  final bool advertising;

  /// Initial analytics preference.
  final bool analytics;

  /// Consumer of advertising preference changes.
  final void Function(bool)? onAdvertisingChanged;

  /// Consumer of analytics preference changes.
  final void Function(bool)? onAnalyticsChanged;
}

/// Owns the safety screen's consent state.
final notificationSafetyControllerProvider = StateNotifierProvider.autoDispose
    .family<NotificationSafetyController, SafetyState, SafetyControllerArgs>(
      (ref, args) => NotificationSafetyController(
        advertising: args.advertising,
        analytics: args.analytics,
        onAdvertisingChanged: args.onAdvertisingChanged,
        onAnalyticsChanged: args.onAnalyticsChanged,
      ),
    );
