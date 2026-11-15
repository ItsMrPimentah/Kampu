import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:showtime_mobile/core/discovery/local_fixtures.dart';
import 'package:showtime_mobile/core/discovery/local_models.dart';
import 'package:showtime_mobile/screens/auth/login_controller.dart';
import 'package:showtime_mobile/screens/auth/verify_phone_controller.dart';
import 'package:showtime_mobile/screens/discovery/home_controller.dart';
import 'package:showtime_mobile/screens/pitches/pitches_controller.dart';
import 'package:showtime_mobile/screens/registration/registration_controller.dart';
import 'package:showtime_mobile/core/registration/registration_models.dart';
import 'package:showtime_mobile/core/community/community_repository.dart';
import 'package:showtime_mobile/screens/community/community_controllers.dart';
import 'package:showtime_mobile/screens/community/community_create_controller.dart';
import 'package:showtime_mobile/screens/community/community_detail_controller.dart';

import 'mocks/community_fake.dart';

void main() {
  test('login validates and reports authentication failures', () async {
    var calls = 0;
    final controller = LoginController((identifier, password) async {
      calls++;
      expect(identifier, 'name');
      return false;
    });
    addTearDown(controller.dispose);
    await controller.submit(' ', 'password');
    expect(controller.state.error, 'Enter your phone or email and password.');
    expect(calls, 0);
    await controller.submit(' name ', 'password');
    expect(
      controller.state.error,
      'Unable to sign in. Check your details and connection.',
    );
    expect(controller.state.loading, isFalse);
    expect(calls, 1);
  });

  test(
    'verification prevents concurrent actions and reports success',
    () async {
      final controller = VerifyPhoneController();
      addTearDown(controller.dispose);
      final action = Completer<bool>();
      var calls = 0;
      final pending = controller.resend(() {
        calls++;
        return action.future;
      });
      await controller.signOut(() async {
        calls++;
        return false;
      });
      expect(controller.state.loading, isTrue);
      expect(calls, 1);
      action.complete(true);
      await pending;
      expect(controller.state.message, 'A new code has been requested.');
      expect(controller.state.loading, isFalse);
    },
  );

  test('home filters and tracks preview actions', () {
    final controller = HomeController(LocalPresentationRepository());
    addTearDown(controller.dispose);
    controller.selectFormat(FootballFormat.sevenAside);
    expect(controller.state.filteredGames, hasLength(1));
    controller.selectFormat(null);
    expect(controller.state.filteredGames, hasLength(3));
    final game = controller.state.snapshot.openGames.first;
    final challenge = controller.state.snapshot.challenges.first;
    controller.join(game);
    controller.sendChallenge(challenge);
    expect(controller.state.joinedGameId, game.id);
    expect(controller.state.sentChallengeIds, contains(challenge.id));
  });

  test(
    'pitch reservation respects native availability and external authority',
    () {
      final controller = PitchesController(LocalFixtures.load());
      addTearDown(controller.dispose);
      final native = controller.state.data.venues.firstWhere(
        (v) => v.source == VenueSource.native,
      );
      final external = controller.state.data.venues.firstWhere(
        (v) => v.source == VenueSource.external,
      );
      final slot = native.slots.firstWhere(
        (slot) => slot.state == SlotState.available,
      );
      expect(controller.reserve(external, external.slots.first), isFalse);
      expect(controller.reserve(native, slot), isTrue);
      expect(controller.state.stateFor(slot), SlotState.confirmed);
      expect(controller.reserve(native, slot), isFalse);
      controller.selectFormat(FootballFormat.futsal);
      expect(
        controller.state.venues.every(
          (venue) => venue.format == FootballFormat.futsal,
        ),
        isTrue,
      );
    },
  );

  test('disposed login controller ignores a late result', () async {
    final result = Completer<bool>();
    final controller = LoginController((_, _) => result.future);
    final pending = controller.submit('name', 'password');
    controller.dispose();
    result.complete(false);
    await pending;
  });

  test('registration reports failure, permits retry, and prevents duplicate submissions', () async {
    final controller = RegistrationController();
    addTearDown(controller.dispose);
    const input = RegistrationInput(
      fullName: 'Player Name',
      dateOfBirth: '01 / 01 / 2000',
      phone: '912345678',
      countryCode: '+351',
      email: 'player@example.com',
      password: 'StrongPass1!',
      acceptedTerms: true,
    );
    final pendingResult = Completer<bool>();
    var calls = 0;
    final pending = controller.submit(input, (_) {
      calls++;
      return pendingResult.future;
    });
    await controller.submit(input, (_) async {
      calls++;
      return true;
    });
    expect(controller.state.submitting, isTrue);
    expect(calls, 1);
    pendingResult.complete(false);
    await pending;
    expect(controller.state.error, 'We could not continue. Please try again.');
    expect(controller.state.submitted, isFalse);
    await controller.submit(input, (submission) async {
      expect(submission.role, RegistrationRole.player);
      expect(submission.dateOfBirth, '2000-01-01');
      return true;
    });
    expect(controller.state.submitted, isTrue);
    expect(controller.state.error, isNull);
  });

  test('community list reports failures and recovers on refresh', () async {
    final repository = CommunityFake()..failList = true;
    final controller = CommunityListController(repository, 'games');
    addTearDown(controller.dispose);
    await controller.refresh();
    expect(controller.state.failure, CommunityFailure.unavailable);
    repository.failList = false;
    await controller.refresh();
    expect(controller.state.data?.single['id'], 'game-1');
    expect(controller.state.failure, isNull);
    final invalid = await controller.acceptInvite('../teams');
    expect(
      invalid.when(val: (_) => null, err: (error) => error),
      CommunityFailure.invalidResponse,
    );
    expect(
      repository.calls,
      isNot(contains('POST game-invites/../teams/accept')),
    );
  });

  test(
    'community creation validates and reports repository failures',
    () async {
      final repository = CommunityFake()..failPost = true;
      final controller = CommunityCreateController(repository, 'teams');
      addTearDown(controller.dispose);
      const invalid = CommunityCreateInput(
        name: '',
        region: 'Lisbon',
        location: '',
        capacity: '14',
        positions: '',
        description: '',
        format: '7v7',
        approval: true,
        private: false,
        kickoff: null,
        teamId: null,
      );
      expect(
        await controller.submit(invalid),
        'Complete the required fields and choose a future kickoff.',
      );
      const valid = CommunityCreateInput(
        name: 'Team',
        region: 'Lisbon',
        location: '',
        capacity: '14',
        positions: '',
        description: '',
        format: '7v7',
        approval: true,
        private: false,
        kickoff: null,
        teamId: null,
      );
      expect(
        await controller.submit(valid),
        'Unable to save. Check the details and try again.',
      );
      repository.failPost = false;
      expect(await controller.submit(valid), isNull);
      expect(controller.state.busy, isFalse);
    },
  );

  test('community detail preserves content after a failed action', () async {
    final repository = CommunityFake()..failPost = true;
    final controller = CommunityDetailController(repository, 'games', 'game-1');
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.state.requests, hasLength(2));
    final result = await controller.post(
      'games/game-1/applications/a2/approve',
    );
    expect(
      result.when(val: (_) => null, err: (error) => error),
      CommunityFailure.unavailable,
    );
    expect(controller.state.detail?['title'], 'Friday Football');
    expect(controller.state.busy, isFalse);
  });
}
