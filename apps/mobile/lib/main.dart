import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app/auth_provider.dart';
import 'app/theme.dart';
import 'app/navigation/app_router.dart';
import 'core/eligibility/eligibility.dart';
import 'shared/config/app_environment.dart';

void main() {
  const AppEnvironment.fromBuild().logConfiguration(debugPrint);
  runApp(const ShowtimeApp());
}

class ShowtimeApp extends StatelessWidget {
  const ShowtimeApp({super.key});

  @override
  Widget build(BuildContext context) =>
      const ProviderScope(child: _ShowtimeApplication());
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
  late final ValueNotifier<int> _sessionChanges;
  late final void Function() _stopSessionListener;

  @override
  void initState() {
    super.initState();
    _eligibility = ValueNotifier<EligibilityDecision?>(null);
    final session = ref.read(sessionControllerProvider.notifier);
    _sessionChanges = ValueNotifier(0);
    _stopSessionListener = session.addListener(
      (_) => _sessionChanges.value++,
      fireImmediately: false,
    );
    _router = createShowtimeRouter(
      eligibility: _eligibility,
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
