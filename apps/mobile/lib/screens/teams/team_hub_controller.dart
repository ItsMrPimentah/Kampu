import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Local team preview state.
class TeamHubState {
  /// Creates team screen state.
  const TeamHubState({this.format = '5v5', this.players = 1, this.status});

  /// Selected football format.
  final String format;

  /// Eligible starting player count.
  final int players;

  /// Latest local action feedback.
  final String? status;

  /// Required player counts by format.
  static const formats = <String, int>{
    '5v5': 5,
    '7v7': 7,
    '11v11': 11,
    'Futsal': 5,
    'Futevoley 2v2': 2,
  };

  /// Number of players required for the selected format.
  int get requiredPlayers => formats[format] ?? 5;

  /// Creates a copy with selected values replaced.
  TeamHubState copyWith({String? format, int? players, String? status}) =>
      TeamHubState(
        format: format ?? this.format,
        players: players ?? this.players,
        status: status ?? this.status,
      );
}

/// Coordinates team preview actions and validation.
class TeamHubController extends StateNotifier<TeamHubState> {
  /// Creates the team controller.
  TeamHubController() : super(const TeamHubState());

  /// Selects a supported format.
  void selectFormat(String? format) {
    if (format != null && TeamHubState.formats.containsKey(format)) {
      state = state.copyWith(format: format);
    }
  }

  /// Sets the eligible player count.
  void setPlayers(int players) => state = state.copyWith(players: players);

  /// Validates and creates a local team preview.
  void createTeam(String name, String region) => state = state.copyWith(
    status: name.trim().isEmpty
        ? 'Team name is required.'
        : 'Team created as captain in ${region.trim()}.',
  );

  /// Creates a local invitation preview.
  void invite(String player) => state = state.copyWith(
    status: 'Invitation created for ${player.trim()}.',
  );
}

/// Owns the team screen's preview state.
final teamHubControllerProvider =
    StateNotifierProvider.autoDispose<TeamHubController, TeamHubState>(
      (ref) => TeamHubController(),
    );
