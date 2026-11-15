import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showtime_mobile/core/community/community_repository.dart';
import 'package:showtime_mobile/shared/external/utils/result.dart';

/// Loading, success, and failure state for a community request.
class CommunityLoadState<T> {
  /// Creates request state.
  const CommunityLoadState({this.loading = true, this.data, this.failure});

  /// Whether a request is running.
  final bool loading;

  /// Last successful value.
  final T? data;

  /// Expected request failure.
  final CommunityFailure? failure;
}

/// Data displayed by authenticated community discovery.
class CommunityDiscoveryData {
  /// Creates discovery data.
  const CommunityDiscoveryData({required this.challenges, required this.games});

  /// Available challenges.
  final List<CommunityJson> challenges;

  /// Available games.
  final List<CommunityJson> games;
}

/// Loads authenticated community discovery and notifications.
class CommunityDiscoveryController
    extends StateNotifier<CommunityLoadState<CommunityDiscoveryData>> {
  /// Creates a controller with the injected repository.
  CommunityDiscoveryController(this._repository)
    : super(const CommunityLoadState());
  final CommunityRepository _repository;
  int _version = 0;

  /// Refreshes both discovery collections.
  Future<void> refresh() async {
    if (!mounted) return;
    final version = ++_version;
    state = const CommunityLoadState();
    final results = await Future.wait([
      _repository.list('challenges'),
      _repository.list('games'),
    ]);
    if (!mounted || version != _version) return;
    state = results[0].when(
      val: (challenges) => results[1].when(
        val: (games) => CommunityLoadState(
          loading: false,
          data: CommunityDiscoveryData(challenges: challenges, games: games),
        ),
        err: (failure) => CommunityLoadState(loading: false, failure: failure),
      ),
      err: (failure) => CommunityLoadState(loading: false, failure: failure),
    );
  }

  /// Retrieves notifications for the sheet.
  Future<CommunityResult<List<CommunityJson>>> notifications() =>
      _repository.list('notifications');
}

/// Arguments identifying a community list screen.
class CommunityListArgs {
  /// Creates list controller arguments.
  const CommunityListArgs(this.repository, this.section);

  /// Data source.
  final CommunityRepository repository;

  /// Community section.
  final String section;

  @override
  bool operator ==(Object other) =>
      other is CommunityListArgs &&
      identical(repository, other.repository) &&
      section == other.section;
  @override
  int get hashCode => Object.hash(identityHashCode(repository), section);
}

/// Loads a community collection and accepts invitations.
class CommunityListController
    extends StateNotifier<CommunityLoadState<List<CommunityJson>>> {
  /// Creates a controller with injected dependencies.
  CommunityListController(this._repository, this._section)
    : super(const CommunityLoadState());
  final CommunityRepository _repository;
  final String _section;
  int _version = 0;

  /// Reloads the collection.
  Future<void> refresh() async {
    if (!mounted) return;
    final version = ++_version;
    state = const CommunityLoadState();
    final result = await _repository.list(_section);
    if (!mounted || version != _version) return;
    state = result.when(
      val: (items) => CommunityLoadState(loading: false, data: items),
      err: (error) => CommunityLoadState(loading: false, failure: error),
    );
  }

  /// Accepts the invitation and refreshes the collection on success.
  Future<CommunityResult<CommunityJson>> acceptInvite(String token) async {
    final trimmed = token.trim();
    if (!RegExp(r'^[A-Za-z0-9_-]{32}$').hasMatch(trimmed)) {
      return const Result.err(CommunityFailure.invalidResponse);
    }
    final path = _section == 'teams' ? 'invites' : 'game-invites';
    final result = await _repository.post('$path/$trimmed/accept');
    if (mounted && result is Success<CommunityJson, CommunityFailure>) {
      await refresh();
    }
    return result;
  }
}

/// Provides a discovery controller per repository.
final communityDiscoveryControllerProvider = StateNotifierProvider.autoDispose
    .family<
      CommunityDiscoveryController,
      CommunityLoadState<CommunityDiscoveryData>,
      CommunityRepository
    >((ref, repository) => CommunityDiscoveryController(repository));

/// Provides a collection controller per repository and section.
final communityListControllerProvider = StateNotifierProvider.autoDispose
    .family<
      CommunityListController,
      CommunityLoadState<List<CommunityJson>>,
      CommunityListArgs
    >((ref, args) => CommunityListController(args.repository, args.section));
