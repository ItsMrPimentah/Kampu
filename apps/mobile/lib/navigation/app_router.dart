import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_client.dart';
import '../auth/login_screen.dart';
import '../auth/verify_phone_screen.dart';
import '../community/community_screen.dart';
import '../challenges/challenge_detail_screen.dart';
import '../challenges/challenges_screen.dart';
import '../discovery/home_screen.dart';
import '../matches/match_hub_screen.dart';
import '../onboarding/eligibility.dart';
import '../onboarding/onboarding_screen.dart' show OnboardingScreen;
import '../payments/payment_hub_screen.dart';
import '../registration/registration_screen.dart';
import '../pitches/pitches_screen.dart';
import '../safety/notification_safety_screen.dart';
import '../squad/squad_screen.dart';
import '../teams/team_hub_screen.dart';
import '../theme/midnight_theme.dart';
import '../theme/stitch_components.dart';
import '../venues/venue_hub_screen.dart';
import 'authenticated_shell.dart';
import 'navigation_controller.dart';

GoRouter createShowtimeRouter({
  required ValueNotifier<EligibilityDecision?> eligibility,
  AuthClient? auth,
  VoidCallback? onRegister,
}) {
  late final GoRouter router;
  late final NavigationController navigation;

  router = GoRouter(
    initialLocation: auth == null ? '/onboarding' : '/login',
    refreshListenable: auth ?? eligibility,
    redirect: (context, state) {
      if (auth != null) {
        final path = state.matchedLocation;
        if (!auth.initialized) return path == '/loading' ? null : '/loading';
        if (auth.connectionFailed) {
          return path == '/loading' ? null : '/loading';
        }
        if (!auth.hasSession) {
          return path == '/login' || path == '/register' ? null : '/login';
        }
        if (!auth.verified) {
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
      if (auth != null) ...[
        GoRoute(
          path: '/loading',
          builder: (context, state) => Scaffold(
            body: Center(
              child: auth.connectionFailed
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Unable to connect to ShowTime.'),
                        TextButton(
                          onPressed: auth.restore,
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
            onLogin: auth.login,
            onRegister: () => context.push('/register'),
          ),
        ),
        GoRoute(
          path: '/verify-phone',
          builder: (context, state) => VerifyPhoneScreen(
            phone: auth.phone ?? '',
            smsSent: auth.smsSent,
            onVerify: auth.verify,
            onResend: auth.resend,
            onSignOut: auth.logout,
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
          onBack: () => context.pop(),
          onLogin: () => context.go(auth == null ? '/onboarding' : '/login'),
          onContinue: (_) {},
          onRegister: auth?.register,
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => AuthenticatedShell(
          navigation: navigation,
          onSignOut: auth?.logout,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => auth != null
                ? CommunityDiscoveryScreen(auth: auth)
                : HomeScreen(
                    navigation: navigation,
                    eligibility: auth?.eligibility ?? eligibility.value,
                  ),
          ),
          GoRoute(
            path: '/challenges',
            builder: (context, state) => auth != null
                ? CommunityScreen(auth: auth, section: 'challenges')
                : ChallengesScreen(navigation: navigation),
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
            builder: (context, state) => PitchesScreen(navigation: navigation),
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
            builder: (context, state) => auth != null
                ? CommunityScreen(auth: auth, section: 'teams')
                : SquadScreen(navigation: navigation),
          ),
          GoRoute(
            path: '/matches',
            builder: (context, state) => auth != null
                ? CommunityScreen(auth: auth, section: 'games')
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
                  (auth?.eligibility ?? eligibility.value)?.category ==
                  EligibilityCategory.youth,
            ),
          ),
          GoRoute(
            path: '/teams',
            builder: (context, state) => auth != null
                ? CommunityScreen(auth: auth, section: 'teams')
                : const TeamHubScreen(),
          ),
        ],
      ),
    ],
  );
  navigation = NavigationController(router);
  return router;
}

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
