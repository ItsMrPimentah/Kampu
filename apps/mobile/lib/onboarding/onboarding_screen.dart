import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/stitch_components.dart';
import 'eligibility.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onEligible,
    this.onRegister,
  });

  final ValueChanged<EligibilityDecision> onEligible;
  final VoidCallback? onRegister;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _dateController = TextEditingController();
  String? _error;
  String? _eligibilityNotice;

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  void _continue() {
    try {
      final decision = evaluateEligibility(_dateController.text.trim());
      setState(() {
        _error = null;
        _eligibilityNotice =
            'Eligibility established: ${decision.category == EligibilityCategory.youth ? 'Youth' : 'Adult'} account';
      });
      widget.onEligible(decision);
    } on EligibilityValidationException catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              controller: _dateController,
              keyboardType: TextInputType.datetime,
              decoration: InputDecoration(
                labelText: 'Date of birth',
                hintText: 'YYYY-MM-DD',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _continue, child: const Text('Continue')),
            if (_eligibilityNotice != null) ...[
              const SizedBox(height: 16),
              Text(_eligibilityNotice!),
              const OutlinedButton(
                onPressed: null,
                child: Text('Manage teams'),
              ),
            ],
            if (widget.onRegister != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: widget.onRegister,
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
