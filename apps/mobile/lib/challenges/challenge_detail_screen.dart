import 'package:flutter/material.dart';

import '../discovery/local_fixtures.dart';
import '../discovery/local_models.dart';
import '../theme/midnight_theme.dart';
import '../theme/stitch_components.dart';

class ChallengeDetailScreen extends StatefulWidget {
  const ChallengeDetailScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  late TeamChallenge _challenge;

  @override
  void initState() {
    super.initState();
    final challenges = LocalFixtures.load().challenges;
    _challenge = challenges.firstWhere(
      (challenge) => challenge.id == widget.challengeId,
      orElse: () => challenges.first,
    );
  }

  void _update(ChallengeAction action, String message) {
    setState(() => _challenge = _challenge.copyWith(status: action));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final latest = _challenge.latestOffer;
    final tokens = context.midnight;
    return Scaffold(
      appBar: StitchTopBar(
        title: 'Challenge negotiation',
        subtitle: 'MATCH · LOCAL REVISION',
        onBack: () => Navigator.of(context).maybePop(),
        actions: [
          IconButton(
            tooltip: 'More options',
            onPressed: () {},
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          tokens.pageMargin,
          8,
          tokens.pageMargin,
          32,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: _TeamLabel(
                  name: _challenge.homeTeam,
                  icon: Icons.shield_outlined,
                ),
              ),
              Icon(Icons.compare_arrows, color: tokens.periwinkle),
              Expanded(
                child: _TeamLabel(
                  name: _challenge.opponent,
                  icon: Icons.sports_soccer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _StatusBanner(status: _challenge.status),
          const SizedBox(height: 16),
          Text(
            'Offer history',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ..._challenge.revisions.asMap().entries.map(
            (entry) => _OfferCard(
              revision: entry.value,
              isLatest: entry.key == _challenge.revisions.length - 1,
            ),
          ),
          const SizedBox(height: 18),
          StitchCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest offer',
                  style: TextStyle(color: tokens.steelLight),
                ),
                const SizedBox(height: 12),
                Text(
                  '${_time(latest.kickoff)} · ${latest.venue}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '€${latest.costPerTeam} per team',
                  style: tokens.monoStyle.copyWith(color: tokens.periwinkle),
                ),
                const SizedBox(height: 8),
                Text(latest.message),
                if (latest.changedTerms.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...latest.changedTerms.map(
                    (term) => Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 15,
                          color: tokens.amber,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            term,
                            style: TextStyle(color: tokens.amber),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_challenge.status == ChallengeAction.accepted)
            _ResultMessage(
              message: 'Match accepted and locked locally.',
              color: tokens.emerald,
            )
          else if (_challenge.status == ChallengeAction.declined)
            _ResultMessage(
              message: 'Challenge declined locally.',
              color: tokens.danger,
            )
          else ...[
            StitchGradientButton(
              label: 'Accept & lock',
              icon: Icons.lock_outline,
              onPressed: () => _update(
                ChallengeAction.accepted,
                'Offer accepted and match locked locally.',
              ),
            ),
            const SizedBox(height: 10),
            StitchGhostButton(
              label: 'Propose counter',
              icon: Icons.edit_calendar_outlined,
              onPressed: () => _update(
                ChallengeAction.countered,
                'Counter offer saved locally.',
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _update(
                ChallengeAction.declined,
                'Challenge declined locally.',
              ),
              child: const Text('Decline'),
            ),
          ],
        ],
      ),
    );
  }
}

class _TeamLabel extends StatelessWidget {
  const _TeamLabel({required this.name, required this.icon});

  final String name;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      CircleAvatar(
        backgroundColor: context.midnight.gunmetal,
        child: Icon(icon),
      ),
      const SizedBox(height: 8),
      Text(
        name,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});

  final ChallengeAction status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      ChallengeAction.pending => 'Your response is pending',
      ChallengeAction.countered => 'Counter offer needs a decision',
      ChallengeAction.accepted => 'Accepted · match locked',
      ChallengeAction.declined => 'Challenge declined',
    };
    final tone = switch (status) {
      ChallengeAction.accepted => StitchStatusTone.success,
      ChallengeAction.declined => StitchStatusTone.danger,
      ChallengeAction.pending ||
      ChallengeAction.countered => StitchStatusTone.warning,
    };
    return StitchStatusPill(label: label, tone: tone, icon: Icons.circle);
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.revision, required this.isLatest});

  final OfferRevision revision;
  final bool isLatest;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: StitchCard(
      color: isLatest
          ? context.midnight.gunmetal
          : context.midnight.surfaceCard,
      padding: EdgeInsets.zero,
      child: ListTile(
        title: Text('${revision.author} · €${revision.costPerTeam}'),
        subtitle: Text(
          '${_time(revision.kickoff)} · ${revision.venue}\n${revision.message}',
        ),
        isThreeLine: true,
        trailing: isLatest
            ? const Icon(Icons.fiber_manual_record, size: 12)
            : null,
      ),
    ),
  );
}

class _ResultMessage extends StatelessWidget {
  const _ResultMessage({required this.message, required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(color: color, fontWeight: FontWeight.w700),
    ),
  );
}

String _time(DateTime date) =>
    '${date.day}/${date.month} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
