import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../discovery/local_fixtures.dart';
import '../discovery/local_models.dart';
import '../navigation/navigation_controller.dart';
import '../onboarding/eligibility.dart';
import '../theme/midnight_theme.dart';
import '../theme/stitch_components.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.navigation, this.eligibility});

  final NavigationController navigation;
  final EligibilityDecision? eligibility;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repository = LocalPresentationRepository();
  final Set<String> _sentChallengeIds = <String>{};
  String? _joinedGameId;
  String? _refreshMessage;
  bool _showLoading = false;
  FootballFormat? _formatFilter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_showLoading) {
      precacheImage(const AssetImage('assets/images/placeholder.png'), context);
    }
  }

  void _join(OpenGame game) {
    setState(() => _joinedGameId = game.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Joined ${game.title} in the local preview.')),
    );
  }

  void _sendChallenge(TeamChallenge challenge) {
    setState(() => _sentChallengeIds.add(challenge.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Challenge saved in the local preview.')),
    );
  }

  void _refreshLocalSnapshot() {
    setState(() {
      _showLoading = true;
      _refreshMessage = null;
    });
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _showLoading = false;
        _refreshMessage = 'Local refresh complete · cached results retained.';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _repository.snapshot;
    final home = data.homeContext;
    final tokens = context.midnight;
    final filteredGames = data.openGames
        .where((game) => _formatFilter == null || game.format == _formatFilter)
        .toList();

    return Scaffold(
      appBar: StitchTopBar(
        title: 'ShowTime',
        subtitle: 'MATCH DISCOVERY · AREA 01',
        actions: [
          _NotificationButton(
            count: home.unreadNotifications,
            onPressed: () => widget.navigation.openExistingHub('safety'),
          ),
        ],
      ),
      body: ListView(
        scrollCacheExtent: const ScrollCacheExtent.pixels(5000),
        padding: EdgeInsets.fromLTRB(
          tokens.pageMargin,
          8,
          tokens.pageMargin,
          32,
        ),
        children: [
          Text(
            'Discover',
            style: tokens.displayStyle.copyWith(fontSize: 26, height: 34 / 26),
          ),
          const SizedBox(height: 4),
          Text(
            'Your football week, in one place.',
            style: TextStyle(color: tokens.steelLight),
          ),
          const SizedBox(height: 16),
          _HomeContextCard(contextData: home),
          const SizedBox(height: 12),
          StitchTelemetryBanner(
            title: data.snapshot.label,
            detail:
                'Captured ${_date(data.snapshot.capturedAt)} · local preview only',
            onRetry: _refreshLocalSnapshot,
          ),
          if (_refreshMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _refreshMessage!,
                style: TextStyle(color: tokens.emerald),
              ),
            ),
          const SizedBox(height: 20),
          if (_showLoading)
            const LinearProgressIndicator()
          else ...[
            const _FeedSectionLabel(label: 'Upcoming fixture'),
            const SizedBox(height: 8),
            _FixtureCard(fixture: data.fixture),
            const SizedBox(height: 20),
            const _FeedSectionLabel(label: 'Discovery filters'),
            const SizedBox(height: 8),
            _FormatFilters(
              selected: _formatFilter,
              onChanged: (format) => setState(() => _formatFilter = format),
            ),
            const SizedBox(height: 20),
            _SectionHeader(
              title: 'Team challenges',
              action: 'See all',
              onTap: () => widget.navigation.goToDestination(1),
            ),
            const SizedBox(height: 10),
            ...data.challenges.map(
              (challenge) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ChallengeCard(
                  challenge: challenge,
                  onTap: () => widget.navigation.openChallenge(challenge.id),
                  onChallenge: () => _sendChallenge(challenge),
                  sent: _sentChallengeIds.contains(challenge.id),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _SectionHeader(
              title: 'Open games',
              action: 'Find a game',
              onTap: () => widget.navigation.openExistingHub('matches'),
            ),
            const SizedBox(height: 10),
            ...filteredGames.map(
              (game) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OpenGameCard(
                  game: game,
                  joined: _joinedGameId == game.id,
                  onJoin: () => _join(game),
                ),
              ),
            ),
            if (filteredGames.isEmpty)
              StitchCard(
                child: Row(
                  children: [
                    Icon(Icons.event_busy_outlined, color: tokens.amber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No local games match this format. Try another filter.',
                        style: TextStyle(color: tokens.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => widget.navigation.goToDestination(3),
              icon: const Icon(Icons.groups_outlined),
              label: const Text('Manage teams'),
            ),
            if (_joinedGameId != null)
              const _LocalStatus(
                message: 'Your open-game place is held in this local preview.',
              ),
          ],
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = count == 0 ? 'Notifications' : 'Notifications, $count unread';
    return Semantics(
      button: true,
      label: label,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            tooltip: label,
            onPressed: onPressed,
            icon: const Icon(Icons.notifications_none),
          ),
          if (count > 0)
            Positioned(
              right: 7,
              top: 7,
              child: Container(
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.midnight.amber,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: context.midnight.voidColor),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeContextCard extends StatelessWidget {
  const _HomeContextCard({required this.contextData});

  final HomePreviewContext contextData;

  @override
  Widget build(BuildContext context) {
    final tokens = context.midnight;
    return StitchCard(
      color: tokens.carbon,
      padding: const EdgeInsets.all(14),
      child: Semantics(
        container: true,
        label:
            '${contextData.displayName}, ${contextData.activeTeam}, ${contextData.locationLabel}, ${contextData.eligibilityLabel}',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final avatar = _PreviewAvatar(
              initials: contextData.initials,
              assetPath: contextData.avatarAsset,
              label: '${contextData.displayName} avatar',
            );
            final identity = Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${contextData.displayName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    contextData.activeTeam,
                    style: TextStyle(color: tokens.frost),
                  ),
                  Text(
                    '${contextData.locationLabel} · ${formatName(contextData.preferredFormat)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: tokens.steelLight, fontSize: 12),
                  ),
                ],
              ),
            );
            final status = StitchStatusPill(
              label: contextData.eligibilityLabel,
              tone: StitchStatusTone.success,
              icon: Icons.verified_outlined,
            );

            if (constraints.maxWidth < 350) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [avatar, const SizedBox(width: 12), identity],
                  ),
                  const SizedBox(height: 10),
                  Align(alignment: Alignment.centerRight, child: status),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                avatar,
                const SizedBox(width: 12),
                identity,
                const SizedBox(width: 8),
                status,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PreviewAvatar extends StatelessWidget {
  const _PreviewAvatar({
    required this.initials,
    required this.assetPath,
    required this.label,
  });

  final String initials;
  final String? assetPath;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.midnight;
    final fallback = CircleAvatar(
      radius: 24,
      backgroundColor: tokens.gunmetal,
      child: Text(
        initials,
        style: TextStyle(color: tokens.frost, fontWeight: FontWeight.w800),
      ),
    );
    if (assetPath == null) {
      return Tooltip(
        message: label,
        child: Semantics(image: true, label: label, child: fallback),
      );
    }
    return Tooltip(
      message: label,
      child: Semantics(
        image: true,
        label: label,
        child: ClipOval(
          child: Image.asset(
            assetPath!,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stackTrace) => fallback,
          ),
        ),
      ),
    );
  }
}

class _FormatFilters extends StatelessWidget {
  const _FormatFilters({required this.selected, required this.onChanged});

  final FootballFormat? selected;
  final ValueChanged<FootballFormat?> onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        StitchFilterChip(
          label: 'All formats',
          icon: Icons.tune,
          selected: selected == null,
          onSelected: (_) => onChanged(null),
        ),
        const SizedBox(width: 8),
        ...[
          FootballFormat.fiveAside,
          FootballFormat.sevenAside,
          FootballFormat.elevenAside,
          FootballFormat.futsal,
        ].map(
          (format) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: StitchFilterChip(
              label: formatName(format),
              selected: selected == format,
              onSelected: (_) => onChanged(format),
            ),
          ),
        ),
      ],
    ),
  );
}

class _FeedSectionLabel extends StatelessWidget {
  const _FeedSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: context.midnight.labelStyle.copyWith(
      color: context.midnight.steelLight,
      letterSpacing: 1.1,
    ),
  );
}

class _FixtureCard extends StatelessWidget {
  const _FixtureCard({required this.fixture});

  final UpcomingFixture fixture;

  @override
  Widget build(BuildContext context) {
    final tokens = context.midnight;
    return StitchCard(
      color: tokens.surfaceCard,
      padding: const EdgeInsets.all(16),
      child: Semantics(
        container: true,
        label:
            'Upcoming fixture: ${fixture.homeTeam} versus ${fixture.awayTeam} at ${fixture.venue}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StitchStatusPill(
                  label: 'NEXT GAME · 24H',
                  tone: StitchStatusTone.active,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    formatName(fixture.format),
                    textAlign: TextAlign.end,
                    style: tokens.monoStyle.copyWith(
                      color: tokens.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${fixture.homeTeam}  vs  ${fixture.awayTeam}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('${_date(fixture.kickoff)} · ${fixture.venue}'),
            Text(
              formatName(fixture.format),
              style: tokens.monoStyle.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.challenge,
    required this.onTap,
    required this.onChallenge,
    required this.sent,
  });

  final TeamChallenge challenge;
  final VoidCallback onTap;
  final VoidCallback onChallenge;
  final bool sent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.midnight;
    return StitchCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: tokens.gunmetal,
              child: const Icon(Icons.bolt),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Tooltip(
                message: 'Open challenge with ${challenge.opponent}',
                child: Semantics(
                  button: true,
                  label: 'Open challenge with ${challenge.opponent}',
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: tokens.cardBorderRadius,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge.opponent,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            _status(challenge.status),
                            style: TextStyle(color: tokens.amber),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: sent ? null : onChallenge,
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(sent ? 'Saved' : 'Challenge'),
            ),
          ],
        ),
      ),
    );
  }

  String _status(ChallengeAction action) => switch (action) {
    ChallengeAction.pending => 'Awaiting response',
    ChallengeAction.accepted => 'Locked in',
    ChallengeAction.declined => 'Declined',
    ChallengeAction.countered => 'Counter offer',
  };
}

class _OpenGameCard extends StatelessWidget {
  const _OpenGameCard({
    required this.game,
    required this.joined,
    required this.onJoin,
  });

  final OpenGame game;
  final bool joined;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final tokens = context.midnight;
    final isFull = game.approvedPlayers >= game.playerCapacity;
    final slotsOpen = game.playerCapacity - game.approvedPlayers;
    return StitchCard(
      child: Tooltip(
        message: '${game.title}, ${isFull ? 'full' : '$slotsOpen slots open'}',
        child: Semantics(
          container: true,
          label: '${game.title}, ${isFull ? 'full' : '$slotsOpen slots open'}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: tokens.gunmetal,
                    child: const Icon(Icons.sports_soccer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StitchStatusPill(
                          label: isFull ? 'FULL' : '$slotsOpen slots open',
                          tone: isFull
                              ? StitchStatusTone.warning
                              : StitchStatusTone.active,
                          icon: isFull ? Icons.lock_outline : Icons.person_add,
                        ),
                        const SizedBox(height: 7),
                        Text(
                          game.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${game.venue} · ${formatName(game.format)} · ${game.approvedPlayers}/${game.playerCapacity} approved',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: tokens.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: StitchGradientButton(
                  label: joined
                      ? 'Joined locally'
                      : isFull
                      ? 'Game full'
                      : 'Join game',
                  icon: joined ? Icons.check : Icons.arrow_forward,
                  onPressed: joined || isFull ? null : onJoin,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Flexible(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: Text(action),
      ),
    ],
  );
}

class _LocalStatus extends StatelessWidget {
  const _LocalStatus({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(message, style: TextStyle(color: context.midnight.emerald)),
  );
}

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
