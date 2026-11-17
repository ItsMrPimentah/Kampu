import 'package:flutter/material.dart';

import '../discovery/local_fixtures.dart';
import '../discovery/local_models.dart';
import '../navigation/navigation_controller.dart';
import '../theme/midnight_theme.dart';
import '../theme/stitch_components.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key, required this.navigation});

  final NavigationController navigation;

  @override
  Widget build(BuildContext context) {
    final challenges = LocalFixtures.load().challenges;
    return Scaffold(
      appBar: const StitchTopBar(
        title: 'Challenges',
        subtitle: 'NEGOTIATION STREAM',
      ),
      body: ListView(
        padding: EdgeInsets.all(context.midnight.pageMargin),
        children: [
          Text(
            'Team negotiations',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Keep every offer and decision in one place.',
            style: TextStyle(color: context.midnight.steelLight),
          ),
          const SizedBox(height: 18),
          ...challenges.map(
            (challenge) => StitchCard(
              padding: EdgeInsets.zero,
              onTap: () => navigation.openChallenge(challenge.id),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: context.midnight.gunmetal,
                  child: const Icon(Icons.handshake_outlined),
                ),
                title: Text(
                  '${challenge.homeTeam}  vs  ${challenge.opponent}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${_label(challenge.status)}\nLatest: ${challenge.latestOffer.kickoff.hour.toString().padLeft(2, '0')}:${challenge.latestOffer.kickoff.minute.toString().padLeft(2, '0')} · ${challenge.latestOffer.venue}',
                ),
                isThreeLine: true,
                trailing: StitchStatusPill(
                  label: challenge.status == ChallengeAction.countered
                      ? 'Counter'
                      : 'Pending',
                  tone: challenge.status == ChallengeAction.countered
                      ? StitchStatusTone.warning
                      : StitchStatusTone.active,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _label(ChallengeAction action) => switch (action) {
    ChallengeAction.pending => 'Pending response',
    ChallengeAction.accepted => 'Accepted · locked',
    ChallengeAction.declined => 'Declined',
    ChallengeAction.countered => 'Counter offer pending',
  };
}
