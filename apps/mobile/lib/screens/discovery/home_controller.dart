import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showtime_mobile/core/discovery/local_fixtures.dart';
import 'package:showtime_mobile/core/discovery/local_models.dart';

/// Local preview discovery state.
class HomeState {
  /// Creates the immutable discovery state.
  const HomeState({
    required this.snapshot,
    this.sentChallengeIds = const {},
    this.joinedGameId,
    this.refreshMessage,
    this.loading = false,
    this.formatFilter,
  });

  /// Current local presentation snapshot.
  final LocalPresentationData snapshot;

  /// Challenges sent during this preview session.
  final Set<String> sentChallengeIds;

  /// Most recently joined preview game.
  final String? joinedGameId;

  /// Feedback for the last local refresh.
  final String? refreshMessage;

  /// Whether a local refresh is in progress.
  final bool loading;

  /// Selected preview game format.
  final FootballFormat? formatFilter;

  /// Games matching the selected format.
  List<OpenGame> get filteredGames => snapshot.openGames
      .where((game) => formatFilter == null || game.format == formatFilter)
      .toList();
}

/// Coordinates the local discovery preview.
class HomeController extends StateNotifier<HomeState> {
  /// Creates the controller using an injected preview repository.
  HomeController(LocalPresentationRepository repository)
    : super(HomeState(snapshot: repository.snapshot));

  /// Joins a game in the preview session.
  void join(OpenGame game) => _update(joinedGameId: game.id);

  /// Saves a challenge in the preview session.
  void sendChallenge(TeamChallenge challenge) =>
      _update(sentChallengeIds: {...state.sentChallengeIds, challenge.id});

  /// Changes the format used to filter games.
  void selectFormat(FootballFormat? format) =>
      _update(formatFilter: format, replaceFormat: true);

  /// Simulates refresh without claiming the cached data is live.
  Future<void> refresh() async {
    _update(loading: true, clearMessage: true);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    _update(
      loading: false,
      refreshMessage: 'Local refresh complete · cached results retained.',
    );
  }

  void _update({
    Set<String>? sentChallengeIds,
    String? joinedGameId,
    String? refreshMessage,
    bool? loading,
    bool clearMessage = false,
    FootballFormat? formatFilter,
    bool replaceFormat = false,
  }) {
    state = HomeState(
      snapshot: state.snapshot,
      sentChallengeIds: Set.unmodifiable(
        sentChallengeIds ?? state.sentChallengeIds,
      ),
      joinedGameId: joinedGameId ?? state.joinedGameId,
      refreshMessage: clearMessage
          ? null
          : refreshMessage ?? state.refreshMessage,
      loading: loading ?? state.loading,
      formatFilter: replaceFormat ? formatFilter : state.formatFilter,
    );
  }
}

/// Owns the screen-scoped local discovery controller.
final homeControllerProvider =
    StateNotifierProvider.autoDispose<HomeController, HomeState>(
      (ref) => HomeController(LocalPresentationRepository()),
    );
