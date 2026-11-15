import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showtime_mobile/core/discovery/local_fixtures.dart';
import 'package:showtime_mobile/core/discovery/local_models.dart';

/// Owns the local challenges list for its screen.
class ChallengesController extends StateNotifier<List<TeamChallenge>> {
  /// Creates a controller from injected preview data.
  ChallengesController(LocalPresentationData data)
    : super(List.unmodifiable(data.challenges));
}

/// Coordinates a local challenge detail.
class ChallengeDetailController extends StateNotifier<TeamChallenge> {
  /// Creates a controller for the selected preview challenge.
  ChallengeDetailController(super.challenge);

  /// Updates the local challenge decision.
  void update(ChallengeAction action) => state = state.copyWith(status: action);
}

/// Provides the local challenge list.
final challengesControllerProvider =
    StateNotifierProvider.autoDispose<
      ChallengesController,
      List<TeamChallenge>
    >((ref) => ChallengesController(LocalFixtures.load()));

/// Provides a controller for a specific local challenge.
final challengeDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<ChallengeDetailController, TeamChallenge, String>((ref, id) {
      final challenges = LocalFixtures.load().challenges;
      return ChallengeDetailController(
        challenges.firstWhere(
          (challenge) => challenge.id == id,
          orElse: () => challenges.first,
        ),
      );
    });
