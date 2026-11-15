import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showtime_mobile/core/community/community_repository.dart';
import 'package:showtime_mobile/shared/external/utils/result.dart';

/// Identifies a community detail screen and its repository.
class CommunityDetailArgs {
  /// Creates detail arguments.
  const CommunityDetailArgs(this.repository, this.section, this.id);

  /// Repository providing data.
  final CommunityRepository repository;

  /// Item type.
  final String section;

  /// Item identifier.
  final String id;
  @override
  bool operator ==(Object other) =>
      other is CommunityDetailArgs &&
      identical(repository, other.repository) &&
      section == other.section &&
      id == other.id;
  @override
  int get hashCode => Object.hash(identityHashCode(repository), section, id);
}

/// Detail data and request status.
class CommunityDetailState {
  /// Creates detail state.
  const CommunityDetailState({
    this.detail,
    this.teams = const [],
    this.requests = const [],
    this.loading = true,
    this.busy = false,
  });

  /// Loaded item details.
  final CommunityJson? detail;

  /// Captain teams for challenge actions.
  final List<CommunityJson> teams;

  /// Join requests or applications.
  final List<CommunityJson> requests;

  /// Whether detail loading is in progress.
  final bool loading;

  /// Whether an action is in progress.
  final bool busy;
}

/// Coordinates loading and actions for a community detail screen.
class CommunityDetailController extends StateNotifier<CommunityDetailState> {
  /// Creates a controller with an injected repository and item identity.
  CommunityDetailController(this._repository, this._section, this._id)
    : super(const CommunityDetailState());
  final CommunityRepository _repository;
  final String _section, _id;
  int _version = 0;

  /// Reloads the detail and its related data.
  Future<void> load() async {
    if (!mounted) return;
    final version = ++_version;
    state = CommunityDetailState(busy: state.busy);
    final result = await _repository.get('$_section/$_id');
    final loaded = await result.when(val: _loadRelated, err: (_) async => null);
    if (!mounted || version != _version) return;
    state = CommunityDetailState(
      detail: loaded?.detail,
      teams: loaded?.teams ?? [],
      requests: loaded?.requests ?? [],
      loading: false,
      busy: state.busy,
    );
  }

  Future<CommunityDetailState?> _loadRelated(CommunityJson detail) async {
    final path = switch (_section) {
      'teams' when detail['myRole'] == 'captain' => 'teams/$_id/requests',
      'challenges' => 'teams',
      'games' when detail['is_organizer'] == true => 'games/$_id/applications',
      _ => null,
    };
    if (path == null) {
      return CommunityDetailState(detail: detail, loading: false);
    }
    final result = await _repository.list(path);
    return result.when(
      val: (items) => CommunityDetailState(
        detail: detail,
        loading: false,
        teams: _section == 'challenges'
            ? items.where((v) => v['my_role'] == 'captain').toList()
            : [],
        requests: _section == 'challenges' ? [] : items,
      ),
      err: (_) => null,
    );
  }

  /// Performs an action and refreshes the detail on success.
  Future<CommunityResult<CommunityJson>> post(
    String path, [
    CommunityJson body = const {},
    bool reload = true,
  ]) async {
    if (state.busy) return const Result.err(CommunityFailure.unavailable);
    _setBusy(true);
    final result = await _repository.post(path, body);
    if (!mounted) return result;
    if (reload && result is Success<CommunityJson, CommunityFailure>) {
      await load();
    }
    if (mounted) _setBusy(false);
    return result;
  }

  /// Updates a detail and refreshes it on success.
  Future<CommunityResult<CommunityJson>> patch(
    String path,
    CommunityJson body,
  ) async {
    if (state.busy) return const Result.err(CommunityFailure.unavailable);
    _setBusy(true);
    final result = await _repository.patch(path, body);
    if (!mounted) return result;
    if (result is Success<CommunityJson, CommunityFailure>) await load();
    if (mounted) _setBusy(false);
    return result;
  }

  void _setBusy(bool busy) => state = CommunityDetailState(
    detail: state.detail,
    teams: state.teams,
    requests: state.requests,
    loading: state.loading,
    busy: busy,
  );

  /// Captain teams eligible for an action.
  List<CommunityJson> eligibleTeams(String action) {
    final detail = state.detail;
    if (detail == null) return [];
    final match = detail['match'] as Map;
    final proposals = detail['proposals'] as List;
    final votes = detail['votes'] as List;
    return state.teams.where((team) {
      if (action == 'join') {
        final formats = team['supported_formats'];
        return team['id'] != match['host_team_id'] &&
            formats is List &&
            formats.contains(match['format']);
      }
      if (![
        match['host_team_id'],
        match['opponent_team_id'],
      ].contains(team['id'])) {
        return false;
      }
      if (action == 'accept' && proposals.isNotEmpty) {
        return team['id'] != proposals.last['proposed_by_team_id'];
      }
      if (action == 'field-approve' && votes.isNotEmpty) {
        return team['id'] != votes.first['proposed_by_team_id'];
      }
      return true;
    }).toList();
  }
}

/// Provides a detail controller per repository and item.
final communityDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<
      CommunityDetailController,
      CommunityDetailState,
      CommunityDetailArgs
    >(
      (ref, args) =>
          CommunityDetailController(args.repository, args.section, args.id),
    );
