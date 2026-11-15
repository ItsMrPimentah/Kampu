import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showtime_mobile/core/community/community_repository.dart';

import 'community_controllers.dart';

/// Input values used to create a community item.
class CommunityCreateInput {
  /// Creates a form snapshot.
  const CommunityCreateInput({
    required this.name,
    required this.region,
    required this.location,
    required this.capacity,
    required this.positions,
    required this.description,
    required this.format,
    required this.approval,
    required this.private,
    required this.kickoff,
    required this.teamId,
  });

  /// Name or title.
  final String name;

  /// Region.
  final String region;

  /// Field or location.
  final String location;

  /// Player capacity.
  final String capacity;

  /// Comma-separated positions.
  final String positions;

  /// Team description.
  final String description;

  /// Match format.
  final String format;

  /// Whether approval is required.
  final bool approval;

  /// Whether the item is private.
  final bool private;

  /// Selected kickoff.
  final DateTime? kickoff;

  /// Selected captain team.
  final String? teamId;
}

/// Creation screen data and submission state.
class CommunityCreateState {
  /// Creates creation state.
  const CommunityCreateState({this.teams = const [], this.busy = false});

  /// Eligible captain teams.
  final List<CommunityJson> teams;

  /// Whether submission is running.
  final bool busy;
}

/// Coordinates creation validation and repository requests.
class CommunityCreateController extends StateNotifier<CommunityCreateState> {
  /// Creates a controller with injected dependencies.
  CommunityCreateController(this._repository, this._section)
    : super(const CommunityCreateState());
  final CommunityRepository _repository;
  final String _section;

  /// Loads teams eligible to create challenges.
  Future<CommunityResult<List<CommunityJson>>> loadTeams() async {
    final result = await _repository.list('teams');
    if (mounted) {
      result.when(
        val: (items) => state = CommunityCreateState(
          teams: items.where((item) => item['my_role'] == 'captain').toList(),
          busy: state.busy,
        ),
        err: (_) {},
      );
    }
    return result;
  }

  /// Validates and submits, returning an error message or null on success.
  Future<String?> submit(CommunityCreateInput input) async {
    if (state.busy) return 'A request is already in progress.';
    final capacity = int.tryParse(input.capacity);
    final kickoff = input.kickoff;
    if (input.region.trim().isEmpty ||
        (_section != 'challenges' && input.name.trim().isEmpty) ||
        (_section != 'teams' &&
            (kickoff == null || !kickoff.isAfter(DateTime.now()))) ||
        (_section == 'challenges' && input.teamId == null) ||
        (_section == 'games' &&
            (input.location.trim().isEmpty || capacity == null))) {
      return 'Complete the required fields and choose a future kickoff.';
    }
    if (_section == 'challenges') {
      final selected = state.teams.where((team) => team['id'] == input.teamId);
      final supported = selected.isEmpty
          ? null
          : selected.first['supported_formats'];
      if (supported is! List || !supported.contains(input.format)) {
        return 'Choose a format supported by your team.';
      }
    }
    state = CommunityCreateState(teams: state.teams, busy: true);
    final result = await _repository.post(_section, _body(input, capacity));
    if (mounted) state = CommunityCreateState(teams: state.teams);
    return result.when(
      val: (_) => null,
      err: (_) => 'Unable to save. Check the details and try again.',
    );
  }

  CommunityJson _body(CommunityCreateInput input, int? capacity) =>
      switch (_section) {
        'teams' => {
          'name': input.name,
          'region': input.region,
          'formats': [input.format],
          'visibility': input.private ? 'private' : 'public',
          'description': input.description,
        },
        'challenges' => {
          'teamId': input.teamId,
          'format': input.format,
          'scheduledAt': input.kickoff?.toUtc().toIso8601String(),
          'region': input.region,
          'field': input.location,
        },
        _ => {
          'title': input.name,
          'region': input.region,
          'location': input.location,
          'format': input.format,
          'scheduledAt': input.kickoff?.toUtc().toIso8601String(),
          'capacity': capacity,
          'approvalRequired': input.approval,
          'visibility': input.private ? 'private' : 'public',
          'requiredPositions': input.positions
              .split(',')
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList(),
        },
      };
}

/// Provides a creation controller for a repository and section.
final communityCreateControllerProvider = StateNotifierProvider.autoDispose
    .family<CommunityCreateController, CommunityCreateState, CommunityListArgs>(
      (ref, args) => CommunityCreateController(args.repository, args.section),
    );
