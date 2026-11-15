import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app/auth_provider.dart';
import 'app/theme.dart';
import 'app/auth/auth_client.dart';
import 'app/navigation/app_router.dart';
import 'core/eligibility/eligibility.dart';
import 'shared/config/app_environment.dart';

void main() {
  const AppEnvironment.fromBuild().logConfiguration(debugPrint);
  runApp(const ShowtimeApp());
}

class ShowtimeApp extends StatelessWidget {
  const ShowtimeApp({super.key, this.auth});

  final AuthClient? auth;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      if (auth case final client?)
        authClientProvider.overrideWith((ref) {
          ref.onDispose(client.dispose);
          return client;
        }),
    ],
    child: const _ShowtimeApplication(),
  );
}

class _ShowtimeApplication extends ConsumerStatefulWidget {
  const _ShowtimeApplication();

  @override
  ConsumerState<_ShowtimeApplication> createState() =>
      _ShowtimeApplicationState();
}

class _ShowtimeApplicationState extends ConsumerState<_ShowtimeApplication> {
  late final ValueNotifier<EligibilityDecision?> _eligibility;
  late final GoRouter _router;
  late final AuthClient _auth;
  late final ValueNotifier<int> _sessionChanges;
  late final void Function() _stopSessionListener;

  @override
  void initState() {
    super.initState();
    _eligibility = ValueNotifier<EligibilityDecision?>(null);
    _auth = ref.read(authClientProvider);
    final session = ref.read(authSessionProvider.notifier);
    _sessionChanges = ValueNotifier(0);
    _stopSessionListener = session.addListener(
      (_) => _sessionChanges.value++,
      fireImmediately: false,
    );
    _router = createShowtimeRouter(
      eligibility: _eligibility,
      auth: _auth,
      session: session,
      sessionChanges: _sessionChanges,
      community: ref.read(communityRepositoryProvider),
    );
    Future.microtask(session.restore);
  }

  @override
  void dispose() {
    _router.dispose();
    _stopSessionListener();
    _sessionChanges.dispose();
    _eligibility.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Showtime Football Community',
    theme: createAppTheme(),
    routerConfig: _router,
  );
}
