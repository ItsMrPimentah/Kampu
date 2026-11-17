import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app/auth_provider.dart';
import 'app/theme.dart';
import 'core/auth/auth_client.dart';
import 'navigation/app_router.dart';
import 'onboarding/eligibility.dart';

void main() => runApp(const ShowtimeApp());

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

  @override
  void initState() {
    super.initState();
    _eligibility = ValueNotifier<EligibilityDecision?>(null);
    _auth = ref.read(authClientProvider);
    _router = createShowtimeRouter(eligibility: _eligibility, auth: _auth);
    _auth.restore();
  }

  @override
  void dispose() {
    _router.dispose();
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
