import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Local match coordination state.
class MatchHubState {
  /// Creates a match preview state.
  const MatchHubState({
    this.stage = 0,
    this.fusion = false,
    this.attendance = false,
    this.players = 0,
  });

  /// Current challenge lifecycle index.
  final int stage;

  /// Whether this is a Fusion game.
  final bool fusion;

  /// Whether attendance has been confirmed.
  final bool attendance;

  /// Number of approved local game players.
  final int players;

  /// Challenge lifecycle stages.
  static const stages = [
    'Draft',
    'Open',
    'Negotiation',
    'Agreed',
    'Scheduling',
    'Confirmed',
    'Completed',
  ];

  /// Current lifecycle label.
  String get status => stages[stage];

  /// Returns a copy with selected fields changed.
  MatchHubState copyWith({
    int? stage,
    bool? fusion,
    bool? attendance,
    int? players,
  }) => MatchHubState(
    stage: stage ?? this.stage,
    fusion: fusion ?? this.fusion,
    attendance: attendance ?? this.attendance,
    players: players ?? this.players,
  );
}

/// Coordinates local match actions.
class MatchHubController extends StateNotifier<MatchHubState> {
  /// Creates the match controller.
  MatchHubController() : super(const MatchHubState());

  /// Advances the preview lifecycle when another stage exists.
  void advance() {
    if (state.stage < MatchHubState.stages.length - 1) {
      state = state.copyWith(stage: state.stage + 1);
    }
  }

  /// Sets the Fusion game flag.
  void setFusion(bool value) => state = state.copyWith(fusion: value);

  /// Sets attendance confirmation.
  void setAttendance(bool value) => state = state.copyWith(attendance: value);

  /// Applies for an available preview slot.
  void apply() {
    if (state.players < 5) state = state.copyWith(players: state.players + 1);
  }
}

/// Owns the match screen's state.
final matchHubControllerProvider =
    StateNotifierProvider.autoDispose<MatchHubController, MatchHubState>(
      (ref) => MatchHubController(),
    );
