import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:showtime_mobile/app/auth/session_controller.dart';
import 'package:showtime_mobile/screens/auth/login_screen.dart';
import 'package:showtime_mobile/screens/auth/verify_phone_screen.dart';
import 'package:showtime_mobile/screens/community/community_screen.dart';
import 'package:showtime_mobile/core/community/community_repository.dart';
import 'package:showtime_mobile/screens/challenges/challenge_detail_screen.dart';
import 'package:showtime_mobile/screens/challenges/challenges_screen.dart';
import 'package:showtime_mobile/screens/discovery/home_screen.dart';
import 'package:showtime_mobile/screens/matches/match_hub_screen.dart';
import 'package:showtime_mobile/core/eligibility/eligibility.dart';
import 'package:showtime_mobile/core/registration/registration_models.dart';
import 'package:showtime_mobile/screens/onboarding/onboarding_screen.dart'
    show OnboardingScreen;
import 'package:showtime_mobile/screens/payments/payment_hub_screen.dart';
import 'package:showtime_mobile/screens/registration/registration_screen.dart';
import 'package:showtime_mobile/screens/pitches/pitches_screen.dart';
import 'package:showtime_mobile/screens/safety/notification_safety_screen.dart';
import 'package:showtime_mobile/screens/squad/squad_screen.dart';
import 'package:showtime_mobile/screens/teams/team_hub_screen.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';
import 'package:showtime_mobile/screens/venues/venue_hub_screen.dart';

import 'authenticated_shell.dart';
import 'navigation_controller.dart';

GoRouter createShowtimeRouter({
  required ValueNotifier<EligibilityDecision?> eligibility,
  SessionController? session,
  Listenable? sessionChanges,
  CommunityRepository? community,
  VoidCallback? onRegister,
}) {
  late final GoRouter router;
  late final NavigationController navigation;
  Future<bool> login(String identifier, String password) async =>
      (await session?.login(
        identifier,
        password,
      ))?.when(val: (_) => true, err: (_) => false) ??
      false;
  Future<bool> verify(String code) async =>
      (await session?.verify(code))
          ?.when(val: (_) => true, err: (_) => false) ??
      false;
  Future<bool> resend() async =>
      (await session?.resend())?.when(val: (_) => true, err: (_) => false) ??
      false;
  Future<bool> signOut() async =>
      (await session?.logout())?.when(val: (_) => true, err: (_) => false) ??
      false;
  Future<bool> register(RegistrationSubmission submission) async =>
      (await session?.register(submission))
          ?.when(val: (_) => true, err: (_) => false) ??
      false;
  final communityRepository = community;

  router = GoRouter(
    initialLocation: session == null ? '/onboarding' : '/login',
    refreshListenable: sessionChanges ?? eligibility,
    redirect: (context, state) {
      if (session != null) {
        final snapshot = session.snapshot;
        final path = state.matchedLocation;
        if (!snapshot.initialized) {
          return path == '/loading' ? null : '/loading';
        }
        if (snapshot.connectionFailed) {
          return path == '/loading' ? null : '/loading';
        }
        if (!snapshot.hasSession) {
          return path == '/login' || path == '/register' ? null : '/login';
        }
        if (!snapshot.verified) {
          return path == '/verify-phone' ? null : '/verify-phone';
        }
        if (path == '/login' ||
            path == '/register' ||
            path == '/verify-phone' ||
            path == '/loading' ||
            path == '/onboarding') {
          return '/home';
        }
        return null;
      }
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isRegister = state.matchedLocation == '/register';
      if (eligibility.value == null) {
        return isOnboarding || isRegister ? null : '/onboarding';
      }
      return isOnboarding || isRegister ? '/home' : null;
    },
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      if (session != null) ...[
        GoRoute(
          path: '/loading',
          builder: (context, state) => Scaffold(
            body: Center(
              child: session.snapshot.connectionFailed
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Unable to connect to ShowTime.'),
                        TextButton(
                          onPressed: session.restore,
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginScreen(
            onLogin: login,
            onRegister: () => context.push('/register'),
          ),
        ),
        GoRoute(
          path: '/verify-phone',
          builder: (context, state) => VerifyPhoneScreen(
            phone: session.snapshot.phone ?? '',
            smsSent: session.snapshot.smsSent,
            onVerify: verify,
            onResend: resend,
            onSignOut: signOut,
          ),
        ),
      ],
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => OnboardingScreen(
          onEligible: (decision) {
            eligibility.value = decision;
            router.go('/home');
          },
          onRegister: onRegister ?? () => router.push('/register'),
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterScreen(
          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(session == null ? '/onboarding' : '/login');
            }
          },
          onLogin: () => context.go(session == null ? '/onboarding' : '/login'),
          onContinue: (_) {},
          onRegister: session == null ? null : register,
        ),
      ),
      if (session != null && communityRepository != null)
        GoRoute(
          path: '/community/:section/new',
          builder: (context, state) {
            final section = state.pathParameters['section'];
            if (!_isCommunitySection(section)) return const NotFoundScreen();
            return CommunityCreateScreen(
              repository: communityRepository,
              section: section ?? '',
            );
          },
        ),
      if (session != null && communityRepository != null)
        GoRoute(
          path: '/community/:section/:itemId',
          builder: (context, state) {
            final section = state.pathParameters['section'];
            final id = state.pathParameters['itemId'];
            if (!_isCommunitySection(section) || id == null || id.isEmpty) {
              return const NotFoundScreen();
            }
            return CommunityDetailScreen(
              repository: communityRepository,
              section: section ?? '',
              itemId: id,
            );
          },
        ),
      ShellRoute(
        builder: (context, state, child) => AuthenticatedShell(
          navigation: navigation,
          onSignOut: session?.logout,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                session != null && communityRepository != null
                ? CommunityDiscoveryScreen(repository: communityRepository)
                : HomeScreen(
                    openHub: navigation.openExistingHub,
                    openDestination: navigation.goToDestination,
                    openChallenge: navigation.openChallenge,
                    eligibility:
                        session?.snapshot.eligibility ?? eligibility.value,
                  ),
          ),
          GoRoute(
            path: '/challenges',
            builder: (context, state) =>
                session != null && communityRepository != null
                ? CommunityScreen(
                    repository: communityRepository,
                    section: 'challenges',
                  )
                : ChallengesScreen(openChallenge: navigation.openChallenge),
            routes: [
              GoRoute(
                path: ':challengeId',
                builder: (context, state) => ChallengeDetailScreen(
                  challengeId: state.pathParameters['challengeId'] ?? '',
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/pitches',
            builder: (context, state) => const PitchesScreen(),
            routes: [
              GoRoute(
                path: ':pitchId',
                builder: (context, state) => PitchDetailScreen(
                  pitchId: state.pathParameters['pitchId'] ?? '',
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/squad',
            builder: (context, state) =>
                session != null && communityRepository != null
                ? CommunityScreen(
                    repository: communityRepository,
                    section: 'teams',
                  )
                : SquadScreen(openHub: navigation.openExistingHub),
          ),
          GoRoute(
            path: '/matches',
            builder: (context, state) =>
                session != null && communityRepository != null
                ? CommunityScreen(
                    repository: communityRepository,
                    section: 'games',
                  )
                : const MatchHubScreen(),
          ),
          GoRoute(
            path: '/venues',
            builder: (context, state) => const VenueHubScreen(),
          ),
          GoRoute(
            path: '/payments',
            builder: (context, state) => const PaymentHubScreen(),
          ),
          GoRoute(
            path: '/safety',
            builder: (context, state) => NotificationSafetyScreen(
              notifications: const [],
              isYouth:
                  (session?.snapshot.eligibility ?? eligibility.value)
                      ?.category ==
                  EligibilityCategory.youth,
            ),
          ),
          GoRoute(
            path: '/teams',
            builder: (context, state) =>
                session != null && communityRepository != null
                ? CommunityScreen(
                    repository: communityRepository,
                    section: 'teams',
                  )
                : const TeamHubScreen(),
          ),
        ],
      ),
    ],
  );
  navigation = NavigationController(router);
  return router;
}

bool _isCommunitySection(String? section) =>
    section == 'teams' || section == 'challenges' || section == 'games';

class PitchDetailScreen extends StatelessWidget {
  const PitchDetailScreen({super.key, required this.pitchId});

  final String pitchId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: StitchTopBar(
      title: 'Pitch details',
      subtitle: 'AVAILABILITY · CACHED SNAPSHOT',
      onBack: () => Navigator.of(context).maybePop(),
    ),
    body: Padding(
      padding: EdgeInsets.all(context.midnight.pageMargin),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.stadium_outlined),
          title: Text('Pitch $pitchId'),
          subtitle: const Text(
            'Availability is shown from the local cached snapshot.',
          ),
        ),
      ),
    ),
  );
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Showtime')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.route_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('Page not found'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.go('/home'),
            child: const Text('Go home'),
          ),
        ],
      ),
    ),
  );
}
