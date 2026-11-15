import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:showtime_mobile/core/eligibility/eligibility.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

import 'onboarding_controller.dart';

class OnboardingScreen extends HookConsumerWidget {
  const OnboardingScreen({
    super.key,
    required this.onEligible,
    this.onRegister,
  });

  final ValueChanged<EligibilityDecision> onEligible;
  final VoidCallback? onRegister;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = useTextEditingController();
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    return Scaffold(
      appBar: const StitchTopBar(
        title: 'Join Showtime',
        subtitle: 'PLAYER ELIGIBILITY · STEP 1',
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Football starts with a safe community.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Enter your date of birth. Showtime is for players aged 13 and over.',
            ),
            const SizedBox(height: 24),
            TextField(
              controller: date,
              keyboardType: TextInputType.datetime,
              decoration: InputDecoration(
                labelText: 'Date of birth',
                hintText: 'YYYY-MM-DD',
                errorText: state.error,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                final decision = controller.submit(date.text);
                if (decision != null) onEligible(decision);
              },
              child: const Text('Continue'),
            ),
            if (state.decision case final decision?) ...[
              const SizedBox(height: 16),
              Text(
                'Eligibility established: ${decision.category == EligibilityCategory.youth ? 'Youth' : 'Adult'} account',
              ),
              const OutlinedButton(
                onPressed: null,
                child: Text('Manage teams'),
              ),
            ],
            if (onRegister != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onRegister,
                child: const Text('Create your player pass'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AuthenticatedShell extends StatelessWidget {
  const AuthenticatedShell({super.key, required this.decision});

  final EligibilityDecision decision;

  @override
  Widget build(BuildContext context) {
    final label = decision.category == EligibilityCategory.youth
        ? 'Youth account'
        : 'Adult account';
    return Scaffold(
      appBar: AppBar(title: const Text('Showtime')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Eligibility established: $label'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.push('/teams'),
              child: const Text('Manage teams'),
            ),
          ],
        ),
      ),
    );
  }
}
