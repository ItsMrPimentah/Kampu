import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:showtime_mobile/core/community/community_repository.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

import 'community_controllers.dart';
import 'community_create_controller.dart';
import 'community_detail_controller.dart';

typedef Json = Map<String, dynamic>;

class CommunityScreen extends HookConsumerWidget {
  const CommunityScreen({
    super.key,
    required this.repository,
    required this.section,
  });
  final CommunityRepository repository;
  final String section;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = useMemoized(() => CommunityListArgs(repository, section), [
      repository,
      section,
    ]);
    final state = ref.watch(communityListControllerProvider(args));
    final controller = ref.read(communityListControllerProvider(args).notifier);
    useEffect(() {
      Future.microtask(controller.refresh);
      return null;
    }, [controller]);
    return _CommunityListView(context, section, state, controller).build();
  }
}

class CommunityDiscoveryScreen extends HookConsumerWidget {
  const CommunityDiscoveryScreen({super.key, required this.repository});
  final CommunityRepository repository;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communityDiscoveryControllerProvider(repository));
    final controller = ref.read(
      communityDiscoveryControllerProvider(repository).notifier,
    );
    final selectedFormat = useState<String?>(null);
    useEffect(() {
      Future.microtask(controller.refresh);
      return null;
    }, [controller]);
    return _CommunityDiscoveryView(
      context,
      state,
      controller,
      selectedFormat,
    ).build();
  }
}

class _CommunityDiscoveryView {
  _CommunityDiscoveryView(
    this.context,
    this.state,
    this.controller,
    this.selectedFormat,
  );
  final BuildContext context;
  final CommunityLoadState<CommunityDiscoveryData> state;
  final CommunityDiscoveryController controller;
  final ValueNotifier<String?> selectedFormat;

  Future<void> open(String section, Json item) async {
    final id = item['id'];
    if (id is! String || id.isEmpty) return;
    await context.push('/community/$section/${Uri.encodeComponent(id)}');
    if (context.mounted) await controller.refresh();
  }

  Future<void> _notifications() async {
    final result = await controller.notifications();
    if (!context.mounted) return;
    await result.when(
      val: (items) => showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            itemCount: items.isEmpty ? 2 : items.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Text(
                  'Notifications',
                  style: Theme.of(ctx).textTheme.titleLarge,
                );
              }
              if (items.isEmpty) {
                return const ListTile(title: Text('No notifications yet.'));
              }
              final item = items[index - 1];
              return ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: Text(
                  item['type']
                      .toString()
                      .replaceAll('.', ' · ')
                      .replaceAll('_', ' '),
                ),
                subtitle: Text(_date(item['created_at'])),
              );
            },
          ),
        ),
      ),
      err: (_) async => _message(context, 'Unable to load notifications.'),
    );
  }

  Widget build() => Scaffold(
    appBar: StitchTopBar(
      title: 'ShowTime',
      subtitle: 'MATCH DISCOVERY',
      actions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: _notifications,
          icon: const Icon(Icons.notifications_none),
        ),
      ],
    ),
    body: Builder(
      builder: (context) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = state.data;
        if (data == null) {
          return _ErrorPanel(onRetry: controller.refresh);
        }
        final challenges = data.challenges
            .where(
              (item) =>
                  selectedFormat.value == null ||
                  item['format'] == selectedFormat.value,
            )
            .toList();
        final games = data.games
            .where(
              (item) =>
                  selectedFormat.value == null ||
                  item['format'] == selectedFormat.value,
            )
            .toList();
        final seeking = challenges
            .where(
              (c) => c['status'] == 'open' && c['opponent_team_id'] == null,
            )
            .toList();
        final upcoming =
            challenges
                .where(
                  (c) =>
                      c['status'] == 'confirmed' &&
                      c['scheduled_at'] != null &&
                      (DateTime.tryParse(c['scheduled_at'].toString())
                              ?.isAfter(DateTime.now()) ??
                          false),
                )
                .toList()
              ..sort(
                (a, b) => DateTime.parse(a['scheduled_at'].toString())
                    .compareTo(DateTime.parse(b['scheduled_at'].toString())),
              );
        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Text('Discover', style: context.midnight.displayStyle),
              const SizedBox(height: 8),
              Text(
                'Find your squad. Play together.',
                style: context.midnight.bodyStyle,
              ),
              if (upcoming.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('NEXT FIXTURE', style: context.midnight.labelStyle),
                const SizedBox(height: 8),
                _CommunityCard(
                  section: 'challenges',
                  item: upcoming.first,
                  onTap: () => open('challenges', upcoming.first),
                ),
              ],
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    StitchFilterChip(
                      label: 'All formats',
                      selected: selectedFormat.value == null,
                      onSelected: (_) => selectedFormat.value = null,
                    ),
                    ...['5v5', '7v7', '11v11'].map(
                      (value) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: StitchFilterChip(
                          label: value,
                          selected: selectedFormat.value == value,
                          onSelected: (_) => selectedFormat.value = value,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Seeking Opponent',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text('${seeking.length} challenges'),
                ],
              ),
              const SizedBox(height: 12),
              if (seeking.isEmpty)
                const StitchCard(child: Text('No challenges yet.')),
              ...seeking.take(4).map((v) {
                final item = v;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CommunityCard(
                    section: 'challenges',
                    item: item,
                    onTap: () => open('challenges', item),
                  ),
                );
              }),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Open Games',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text('${games.length} games'),
                ],
              ),
              const SizedBox(height: 12),
              if (games.isEmpty) const StitchCard(child: Text('No games yet.')),
              ...games.take(4).map((v) {
                final item = v;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CommunityCard(
                    section: 'games',
                    item: item,
                    onTap: () => open('games', item),
                  ),
                );
              }),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await context.push('/matches');
                  if (context.mounted) await controller.refresh();
                },
                icon: const Icon(Icons.groups_outlined),
                label: const Text('Browse & create games'),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _CommunityListView {
  _CommunityListView(this.context, this.section, this.state, this.controller);
  final BuildContext context;
  final String section;
  final CommunityLoadState<List<CommunityJson>> state;
  final CommunityListController controller;

  Future<void> _create() async {
    final created = await context.push<bool>('/community/$section/new');
    if (created == true && context.mounted) await controller.refresh();
  }

  Future<void> _open(Json item) async {
    final id = item['id'];
    if (id is! String || id.isEmpty) return;
    await context.push('/community/$section/${Uri.encodeComponent(id)}');
    if (context.mounted) await controller.refresh();
  }

  Widget build() {
    final title = switch (section) {
      'teams' => 'Squad',
      'challenges' => 'Challenges',
      _ => 'Open Games',
    };
    final subtitle = switch (section) {
      'teams' => 'TEAM OPERATIONS',
      'challenges' => 'NEGOTIATION STREAM',
      _ => 'MATCH DISCOVERY',
    };
    return Scaffold(
      appBar: StitchTopBar(
        title: title,
        subtitle: subtitle,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = state.data;
          if (items == null) {
            return _ErrorPanel(onRetry: controller.refresh);
          }
          final active = section == 'challenges'
              ? items
                    .where(
                      (item) => ![
                        'completed',
                        'cancelled',
                        'expired',
                      ].contains(item['status']),
                    )
                    .toList()
              : items;
          final history = section == 'challenges'
              ? items.where((item) => item['status'] == 'completed').toList()
              : <CommunityJson>[];
          final closed = section == 'challenges'
              ? items
                    .where(
                      (item) =>
                          ['cancelled', 'expired'].contains(item['status']),
                    )
                    .toList()
              : <CommunityJson>[];
          final rows = <Object>[
            if (section == 'challenges') ...[
              'Upcoming & active',
              if (active.isEmpty) 'No active challenges yet.' else ...active,
              'Match history',
              if (history.isEmpty) 'No completed matches yet.' else ...history,
              if (closed.isNotEmpty) ...['Other challenges', ...closed],
            ] else if (items.isEmpty)
              'Nothing here yet. Create one to get started.'
            else
              ...items,
          ];
          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(context.midnight.pageMargin),
              itemCount: rows.length + 1,
              itemBuilder: (context, index) {
                if (index > 0) {
                  final row = rows[index - 1];
                  if (row is String &&
                      [
                        'Upcoming & active',
                        'Match history',
                        'Other challenges',
                      ].contains(row)) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: Text(
                        row,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    );
                  }
                  if (row is String) {
                    return StitchCard(
                      color: context.midnight.carbon,
                      child: Text(row),
                    );
                  }
                  final item = row as CommunityJson;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CommunityCard(
                      section: section,
                      item: item,
                      onTap: () => _open(item),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      switch (section) {
                        'teams' => 'Your football base',
                        'challenges' => 'Team negotiations',
                        _ => 'Find your next game',
                      },
                      style: context.midnight.displayStyle.copyWith(
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(switch (section) {
                      'teams' => 'Build your squad and manage your roster.',
                      'challenges' =>
                        'Keep every offer and decision in one place.',
                      _ => 'Discover matches and coordinate your next kickoff.',
                    }, style: context.midnight.bodyStyle),
                    const SizedBox(height: 16),
                    StitchGradientButton(
                      label: switch (section) {
                        'teams' => 'CREATE TEAM',
                        'challenges' => 'CREATE CHALLENGE',
                        _ => 'CREATE GAME',
                      },
                      icon: Icons.add,
                      onPressed: _create,
                    ),
                    if (section == 'teams') ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _acceptInvite,
                        icon: const Icon(Icons.link),
                        label: const Text('Join with invitation code'),
                      ),
                    ],
                    if (section == 'games') ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _acceptGameInvite,
                        icon: const Icon(Icons.link),
                        label: const Text('Join with invitation code'),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _acceptInvite() async {
    final token = await _ask(
      context,
      'Invitation code',
      'Paste the invitation code',
    );
    if (token == null || token.isEmpty) return;
    final result = await controller.acceptInvite(token);
    if (!context.mounted) return;
    result.when(
      val: (_) {},
      err: (_) =>
          _message(context, 'Unable to accept invitation. Check the code.'),
    );
  }

  Future<void> _acceptGameInvite() async {
    final token = await _ask(
      context,
      'Game invitation',
      'Paste the invitation code',
    );
    if (token == null || token.isEmpty) return;
    final result = await controller.acceptInvite(token);
    if (!context.mounted) return;
    result.when(
      val: (_) {},
      err: (_) =>
          _message(context, 'Unable to join this game. Check the invitation.'),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({
    required this.section,
    required this.item,
    required this.onTap,
  });
  final String section;
  final Json item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final tokens = context.midnight;
    final name = switch (section) {
      'teams' => item['name'],
      'challenges' =>
        '${item['host_name']}  vs  ${item['opponent_name'] ?? (item['status'] == 'open' ? 'Seeking opponent' : 'Opponent not set')}',
      _ => item['title'],
    };
    final detail = switch (section) {
      'teams' =>
        '${item['region']} · ${item['member_count']} players · ${item['my_role'] ?? 'Public team'}',
      'challenges' =>
        '${item['format']} · ${item['region']} · ${item['field_name'] ?? 'Field in confirmation'}',
      _ =>
        '${item['format']} · ${item['location']} · ${item['approved_count']}/${item['capacity']} joined',
    };
    final status = switch (section) {
      'teams' => (item['my_role'] ?? item['visibility']).toString(),
      'challenges' => item['status'].toString(),
      _ =>
        item['my_status']?.toString() ??
            (item['approval_required'] == true ? 'Approval required' : 'Open'),
    };
    final metadata = switch (section) {
      'teams' =>
        '${item['region']} · ${(item['supported_formats'] as List).join(' / ')}',
      'challenges' =>
        '${_date(item['scheduled_at'])} · ${item['field_name'] ?? 'Field in confirmation'}',
      _ =>
        '${_date(item['scheduled_at'])} · ${item['approval_required'] == true ? 'Approval required' : 'Open joining'}',
    };
    return StitchCard(
      color: tokens.carbon,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: tokens.gunmetal,
                child: Icon(
                  section == 'teams'
                      ? Icons.shield_outlined
                      : section == 'challenges'
                      ? Icons.handshake_outlined
                      : Icons.sports_soccer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$name',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              StitchStatusPill(
                label: status.toUpperCase(),
                tone: section == 'challenges' && item['status'] == 'completed'
                    ? StitchStatusTone.neutral
                    : StitchStatusTone.active,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(detail, style: tokens.bodyStyle),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tokens.voidColor,
              border: Border.all(color: tokens.gunmetal),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(metadata, style: tokens.bodyStyle),
          ),
          if (section == 'games') ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value:
                  ((item['approved_count'] as num).toDouble() /
                          (item['capacity'] as num).toDouble())
                      .clamp(0, 1),
              backgroundColor: tokens.gunmetal,
              color: tokens.periwinkle,
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              section == 'teams'
                  ? 'View squad →'
                  : section == 'challenges'
                  ? item['status'] == 'completed'
                        ? 'View match details →'
                        : 'View negotiation →'
                  : 'View match →',
              style: TextStyle(
                color: tokens.periwinkle,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CommunityCreateScreen extends HookConsumerWidget {
  const CommunityCreateScreen({
    super.key,
    required this.repository,
    required this.section,
  });
  final CommunityRepository repository;
  final String section;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = useMemoized(() => CommunityListArgs(repository, section), [
      repository,
      section,
    ]);
    final state = ref.watch(communityCreateControllerProvider(args));
    final controller = ref.read(
      communityCreateControllerProvider(args).notifier,
    );
    final name = useTextEditingController();
    final region = useTextEditingController(text: 'Lisbon');
    final location = useTextEditingController();
    final capacity = useTextEditingController(text: '14');
    final positions = useTextEditingController();
    final description = useTextEditingController();
    final format = useState('7v7');
    final approval = useState(true);
    final private = useState(false);
    final kickoff = useState<DateTime?>(null);
    final teamId = useState<String?>(null);
    useEffect(() {
      if (section == 'challenges') {
        Future.microtask(() async {
          final result = await controller.loadTeams();
          if (!context.mounted) return;
          result.when(
            val: (_) {},
            err: (_) => _message(context, 'Unable to load your teams.'),
          );
        });
      }
      return null;
    }, [controller]);
    return _CommunityCreateView(
      context: context,
      section: section,
      state: state,
      controller: controller,
      name: name,
      region: region,
      location: location,
      capacity: capacity,
      positions: positions,
      description: description,
      format: format,
      approval: approval,
      private: private,
      kickoff: kickoff,
      teamId: teamId,
    ).build();
  }
}

class _CommunityCreateView {
  _CommunityCreateView({
    required this.context,
    required this.section,
    required this.state,
    required this.controller,
    required this.name,
    required this.region,
    required this.location,
    required this.capacity,
    required this.positions,
    required this.description,
    required this.format,
    required this.approval,
    required this.private,
    required this.kickoff,
    required this.teamId,
  });
  final BuildContext context;
  final String section;
  final CommunityCreateState state;
  final CommunityCreateController controller;
  final TextEditingController name,
      region,
      location,
      capacity,
      positions,
      description;
  final ValueNotifier<String> format;
  final ValueNotifier<bool> approval, private;
  final ValueNotifier<DateTime?> kickoff;
  final ValueNotifier<String?> teamId;

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      initialDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
    );
    if (time != null && context.mounted) {
      kickoff.value = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    }
  }

  Future<void> _submit() async {
    final error = await controller.submit(
      CommunityCreateInput(
        name: name.text,
        region: region.text,
        location: location.text,
        capacity: capacity.text,
        positions: positions.text,
        description: description.text,
        format: format.value,
        approval: approval.value,
        private: private.value,
        kickoff: kickoff.value,
        teamId: teamId.value,
      ),
    );
    if (!context.mounted) return;
    if (error == null) {
      _leaveCommunityPage(context, section, created: true);
    } else {
      _message(context, error);
    }
  }

  Widget build() => Scaffold(
    appBar: StitchTopBar(
      title: switch (section) {
        'teams' => 'Create team',
        'challenges' => 'Create challenge',
        _ => 'Create game',
      },
      onBack: () => _leaveCommunityPage(context, section),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (section == 'challenges')
          DropdownButtonFormField<String>(
            initialValue: teamId.value,
            decoration: const InputDecoration(labelText: 'Your captain team'),
            items: state.teams
                .map(
                  (t) => DropdownMenuItem(
                    value: t['id'] as String,
                    child: Text(t['name'] as String),
                  ),
                )
                .toList(),
            onChanged: (v) {
              teamId.value = v;
              final matches = state.teams.where((team) => team['id'] == v);
              if (matches.isEmpty) return;
              final selected = matches.first;
              final supported = selected['supported_formats'] as List;
              if (!supported.contains(format.value) && supported.isNotEmpty) {
                format.value = supported.first as String;
              }
            },
          ),
        if (section != 'challenges')
          TextField(
            controller: name,
            decoration: InputDecoration(
              labelText: section == 'teams' ? 'Team name' : 'Game title',
            ),
          ),
        if (section == 'teams') ...[
          const SizedBox(height: 12),
          TextField(
            controller: description,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: region,
          decoration: const InputDecoration(labelText: 'Region'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: format.value,
          decoration: const InputDecoration(labelText: 'Format'),
          items: [
            '5v5',
            '7v7',
            '11v11',
          ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) {
            if (v != null) format.value = v;
          },
        ),
        if (section != 'teams') ...[
          const SizedBox(height: 12),
          TextField(
            controller: location,
            decoration: InputDecoration(
              labelText: section == 'games'
                  ? 'Field / location'
                  : 'Field (optional)',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event),
            label: Text(
              kickoff.value == null
                  ? 'Choose kickoff'
                  : _date(kickoff.value?.toIso8601String()),
            ),
          ),
        ],
        if (section == 'games') ...[
          TextField(
            controller: capacity,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Player capacity'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: positions,
            decoration: const InputDecoration(
              labelText: 'Positions needed (comma-separated)',
            ),
          ),
          SwitchListTile(
            title: const Text('Require approval'),
            subtitle: const Text('Organizers approve requests'),
            value: approval.value,
            onChanged: (v) => approval.value = v,
          ),
        ],
        if (section != 'challenges')
          SwitchListTile(
            title: const Text('Private'),
            value: private.value,
            onChanged: (v) => private.value = v,
          ),
        const SizedBox(height: 16),
        StitchGradientButton(
          label: state.busy ? 'SAVING…' : 'CREATE',
          onPressed: state.busy ? null : _submit,
        ),
      ],
    ),
  );
}

class CommunityDetailScreen extends HookConsumerWidget {
  const CommunityDetailScreen({
    super.key,
    required this.repository,
    required this.section,
    required this.itemId,
  });
  final CommunityRepository repository;
  final String section;
  final String itemId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = useMemoized(
      () => CommunityDetailArgs(repository, section, itemId),
      [repository, section, itemId],
    );
    final state = ref.watch(communityDetailControllerProvider(args));
    final controller = ref.read(
      communityDetailControllerProvider(args).notifier,
    );
    useEffect(() {
      Future.microtask(controller.load);
      return null;
    }, [controller]);
    return _CommunityDetailView(context, this, state, controller).build();
  }
}

class _CommunityDetailView {
  _CommunityDetailView(this.context, this.widget, this.state, this.controller);
  final BuildContext context;
  final CommunityDetailScreen widget;
  final CommunityDetailState state;
  final CommunityDetailController controller;
  String get itemId => widget.itemId;
  Json? get detail => state.detail;
  List<Json> get teams => state.teams;
  List<Json> get requests => state.requests;
  bool get loading => state.loading;
  bool get busy => state.busy;
  Future<void> _load() => controller.load();

  Future<void> _action(String path, [Json body = const {}]) async {
    if (busy) return;
    final result = await controller.post(path, body);
    if (!context.mounted) return;
    await result.when(
      val: (_) async {},
      err: (_) async => _message(
        context,
        'Unable to complete this action. Please check the current status.',
      ),
    );
  }

  Future<void> _leaveTeam() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final result = await controller.post(
      'teams/$itemId/leave',
      const {},
      false,
    );
    if (!context.mounted) return;
    result.when(
      val: (_) => _leaveCommunityPage(context, widget.section),
      err: (_) => _message(context, 'Unable to leave this team.'),
    );
  }

  Future<String?> _teamForAction(String action) async {
    final eligible = controller.eligibleTeams(action);
    if (eligible.isEmpty) {
      _message(context, 'An eligible captain team is required.');
      return null;
    }
    if (eligible.length == 1) return eligible.first['id'] as String?;
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Choose your team'),
        children: eligible
            .map(
              (team) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, team['id']),
                child: Text(team['name']),
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _challengeAction(String action) async {
    final team = await _teamForAction(action);
    if (team == null || !context.mounted) return;
    final Json body = {'teamId': team};
    if (action == 'field-proposal') {
      final field = await _ask(context, 'Propose a field', 'Field name');
      if (field == null || field.isEmpty || !context.mounted) return;
      body['field'] = field;
    }
    if (action == 'field-status') {
      final status = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Field status'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'confirmed'),
              child: const Text('Confirmed by captain'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'in_confirmation'),
              child: const Text('In confirmation'),
            ),
          ],
        ),
      );
      if (status == null || !context.mounted) return;
      body['status'] = status;
    }
    if (action == 'counter') {
      final currentDetail = detail;
      if (currentDetail == null) return;
      final match = currentDetail['match'] as Map;
      String field;
      if (match['status'] == 'agreed' || match['status'] == 'scheduling') {
        field = match['field_name'] as String? ?? '';
        if (field.isEmpty) {
          _message(context, 'Propose a field using the field vote.');
          return;
        }
      } else {
        final value = await _ask(context, 'Counter offer', 'New field');
        if (value == null || value.isEmpty || !context.mounted) return;
        field = value;
      }
      final date = await showDatePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 730)),
        initialDate: DateTime.now().add(const Duration(days: 1)),
      );
      if (date == null || !context.mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 19, minute: 0),
      );
      if (time == null || !context.mounted) return;
      body.addAll({
        'field': field,
        'region': match['region'],
        'scheduledAt': DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ).toUtc().toIso8601String(),
      });
    }
    await _action('challenges/$itemId/$action', body);
  }

  Future<void> _cancelChallenge() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel challenge?'),
        content: const Text('This closes the challenge for both teams.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep challenge'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel challenge'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) await _challengeAction('cancel');
  }

  Future<void> _declineChallenge() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline this challenge?'),
        content: const Text('This closes the negotiation for both teams.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep negotiating'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) await _challengeAction('decline');
  }

  Future<void> _manageMember(Map member) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(member['display_name']),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'position'),
            child: const Text('Set position'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'manager'),
            child: const Text('Make co-captain'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'member'),
            child: const Text('Make player'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'remove'),
            child: const Text('Remove player'),
          ),
        ],
      ),
    );
    if (choice == null || !context.mounted) return;
    final Json body;
    if (choice == 'position') {
      final position = await _ask(context, 'Player position', 'Position');
      if (position == null || position.isEmpty || !context.mounted) return;
      body = {'position': position};
    } else if (choice == 'remove') {
      body = {'active': false};
    } else {
      body = {'role': choice};
    }
    final result = await controller.patch(
      'teams/$itemId/members/${member['user_id']}',
      body,
    );
    if (!context.mounted) return;
    await result.when(
      val: (_) async {},
      err: (_) async => _message(context, 'Unable to update this player.'),
    );
  }

  Future<void> _editFormats(List current) async {
    final selected = current.cast<String>().toSet();
    final result = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: const Text('Team formats'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['5v5', '7v7', '11v11']
                .map(
                  (value) => CheckboxListTile(
                    title: Text(value),
                    value: selected.contains(value),
                    onChanged: (enabled) => update(() {
                      if (enabled == true) {
                        selected.add(value);
                      } else {
                        selected.remove(value);
                      }
                    }),
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(ctx, selected.toList()),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    final response = await controller.patch('teams/$itemId/formats', {
      'formats': result,
    });
    if (!context.mounted) return;
    await response.when(
      val: (_) async {},
      err: (_) async => _message(context, 'Unable to update formats.'),
    );
  }

  Future<void> _copyInvite(String path, String success) async {
    final result = await controller.post(path, const {}, false);
    if (!context.mounted) return;
    await result.when(
      val: (invite) async {
        final token = invite['token'];
        if (token is! String || token.isEmpty) {
          _message(context, 'Unable to create invitation.');
          return;
        }
        try {
          await Clipboard.setData(ClipboardData(text: token));
          if (context.mounted) _message(context, success);
        } on PlatformException {
          if (context.mounted) {
            _message(context, 'Unable to create invitation.');
          }
        }
      },
      err: (_) async => _message(context, 'Unable to create invitation.'),
    );
  }

  Widget build() => Scaffold(
    appBar: StitchTopBar(
      title: switch (widget.section) {
        'teams' => 'Squad roster',
        'challenges' => 'Challenge negotiation',
        _ => 'Match details',
      },
      onBack: () => _leaveCommunityPage(context, widget.section),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : switch (detail) {
            final currentDetail? => ListView(
              padding: const EdgeInsets.all(16),
              children: switch (widget.section) {
                'teams' => _teamView(currentDetail),
                'challenges' => _challengeView(currentDetail),
                _ => _gameView(currentDetail),
              },
            ),
            null => _ErrorPanel(onRetry: _load),
          },
  );
  List<Widget> _teamView(Json currentDetail) {
    final team = currentDetail['team'] as Map;
    final members = currentDetail['members'] as List;
    final captain = currentDetail['myRole'] == 'captain';
    return [
      StitchCard(
        color: context.midnight.carbon,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              team['name'],
              style: context.midnight.displayStyle.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              '${team['region']} · ${(team['supported_formats'] as List).join(' / ')}',
            ),
            const SizedBox(height: 12),
            Text('${members.length} players · ${team['visibility']}'),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Text('SQUAD ROSTER', style: context.midnight.labelStyle),
      const SizedBox(height: 8),
      ...members.map(
        (m) => StitchCard(
          color: context.midnight.carbon,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(m['display_name']),
            subtitle: Text(
              '${m['role']} · ${m['position'] ?? 'Position not set'}',
            ),
            trailing: captain && m['role'] != 'captain'
                ? IconButton(
                    tooltip: 'Manage player',
                    onPressed: () => _manageMember(m as Map),
                    icon: const Icon(Icons.more_vert),
                  )
                : null,
          ),
        ),
      ),
      if (currentDetail['myRole'] == null) ...[
        const SizedBox(height: 12),
        if (team['visibility'] == 'public')
          StitchGradientButton(
            label: 'REQUEST TO JOIN',
            onPressed: busy ? null : () => _action('teams/$itemId/requests'),
          ),
      ],
      if (currentDetail['myRole'] != null && !captain)
        TextButton(
          onPressed: busy ? null : _leaveTeam,
          child: const Text('Leave team'),
        ),
      if (captain) ...[
        OutlinedButton.icon(
          onPressed: () => _editFormats(team['supported_formats'] as List),
          icon: const Icon(Icons.tune),
          label: const Text('Manage formats'),
        ),
        const SizedBox(height: 16),
        StitchGradientButton(
          label: 'CREATE INVITATION',
          icon: Icons.person_add,
          onPressed: busy
              ? null
              : () => _copyInvite(
                  'teams/$itemId/invites',
                  'Invitation code copied; valid for 7 days.',
                ),
        ),
        const SizedBox(height: 16),
        if (requests.isNotEmpty)
          Text('JOIN REQUESTS', style: context.midnight.labelStyle),
        ...requests.map(
          (r) => _requestCard(r, 'teams/$itemId/requests/${r['id']}'),
        ),
      ],
    ];
  }

  List<Widget> _challengeView(Json currentDetail) {
    final m = currentDetail['match'] as Map;
    final proposals = currentDetail['proposals'] as List;
    final votes = currentDetail['votes'] as List;
    final myCaptainTeam = teams.any(
      (t) => [m['host_team_id'], m['opponent_team_id']].contains(t['id']),
    );
    final canAccept =
        proposals.isNotEmpty &&
        teams.any(
          (t) =>
              [m['host_team_id'], m['opponent_team_id']].contains(t['id']) &&
              t['id'] != proposals.last['proposed_by_team_id'],
        );
    final canApproveField =
        votes.isNotEmpty &&
        teams.any(
          (t) =>
              [m['host_team_id'], m['opponent_team_id']].contains(t['id']) &&
              t['id'] != votes.first['proposed_by_team_id'],
        );
    return [
      StitchCard(
        color: context.midnight.carbon,
        child: Column(
          children: [
            StitchStatusPill(
              label: '${m['status']}'.toUpperCase(),
              tone: m['status'] == 'completed'
                  ? StitchStatusTone.neutral
                  : StitchStatusTone.active,
            ),
            const SizedBox(height: 12),
            Text(
              '${m['host_name']}  vs  ${m['opponent_name'] ?? (m['status'] == 'open' ? 'Seeking opponent' : 'Opponent not set')}',
              textAlign: TextAlign.center,
              style: context.midnight.displayStyle.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 12),
            Text(
              '${m['format']} · ${m['region']} · ${_date(m['scheduled_at'])}',
            ),
            Text(
              'Field: ${m['field_name'] ?? 'Not set'} · ${m['field_status']}',
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Text('NEGOTIATION STREAM', style: context.midnight.labelStyle),
      const SizedBox(height: 8),
      ...proposals.map(
        (p) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: StitchCard(
            color: context.midnight.carbon,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Proposal ${p['version']} · ${p['decision'] ?? 'Pending'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(p['terms'] as Map)['field'] ?? 'Field not set'} · ${(p['terms'] as Map)['region']}',
                ),
                Text(_date((p['terms'] as Map)['scheduledAt'])),
              ],
            ),
          ),
        ),
      ),
      if (votes.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(
          'FIELD VOTE: ${votes.first['proposed_field']} · ${votes.first['status']}',
        ),
        if (canApproveField && votes.first['status'] == 'pending')
          TextButton(
            onPressed: busy ? null : () => _challengeAction('field-approve'),
            child: const Text('Approve field'),
          ),
      ],
      const SizedBox(height: 16),
      if (m['status'] == 'open' && !myCaptainTeam)
        if (teams.any(
          (team) =>
              team['id'] != m['host_team_id'] &&
              (team['supported_formats'] as List).contains(m['format']),
        ))
          StitchGradientButton(
            label: 'CHALLENGE TEAM',
            onPressed: busy ? null : () => _challengeAction('join'),
          ),
      if (myCaptainTeam && m['status'] == 'negotiation') ...[
        StitchGradientButton(
          label: 'ACCEPT TERMS',
          onPressed: busy || !canAccept
              ? null
              : () => _challengeAction('accept'),
        ),
        if (myCaptainTeam && m['status'] == 'open')
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Waiting for an opposing team to join.'),
          ),
        const SizedBox(height: 8),
        StitchGhostButton(
          label: 'Propose counter',
          onPressed: busy ? null : () => _challengeAction('counter'),
        ),
        TextButton(
          onPressed: busy ? null : _declineChallenge,
          child: const Text('Decline'),
        ),
      ],
      if (myCaptainTeam && ['agreed', 'scheduling'].contains(m['status']))
        StitchGradientButton(
          label: 'CONFIRM MATCH',
          onPressed: busy ? null : () => _challengeAction('confirm'),
        ),
      if (myCaptainTeam &&
          ['open', 'negotiation', 'agreed', 'scheduling'].contains(m['status']))
        TextButton(
          onPressed: busy ? null : _cancelChallenge,
          child: const Text('Cancel challenge'),
        ),
      if (myCaptainTeam &&
          ['agreed', 'scheduling', 'confirmed'].contains(m['status'])) ...[
        TextButton(
          onPressed: busy ? null : () => _challengeAction('field-status'),
          child: const Text('Update field status'),
        ),
        TextButton(
          onPressed: busy ? null : () => _challengeAction('field-proposal'),
          child: const Text('Propose another field'),
        ),
      ],
    ];
  }

  List<Widget> _gameView(Json g) {
    final joined =
        g['my_status'] != null &&
        !['rejected', 'withdrawn'].contains(g['my_status']);
    return [
      StitchCard(
        color: context.midnight.carbon,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StitchStatusPill(
              label: g['approval_required'] == true
                  ? 'APPROVAL REQUIRED'
                  : 'OPEN GAME',
              tone: StitchStatusTone.active,
            ),
            const SizedBox(height: 12),
            Text(
              g['title'],
              style: context.midnight.displayStyle.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              '${g['format']} · ${g['location']} · ${_date(g['scheduled_at'])}',
            ),
            if ((g['required_positions'] as List).isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Needed: ${(g['required_positions'] as List).join(', ')}'),
            ],
            const SizedBox(height: 12),
            Text('${g['approved_count']}/${g['capacity']} joined'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: ((g['approved_count'] as num) / (g['capacity'] as num))
                  .clamp(0, 1)
                  .toDouble(),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      if (g['is_organizer'] != true && !joined)
        if (g['status'] == 'open')
          StitchGradientButton(
            label: (g['approved_count'] as num) >= (g['capacity'] as num)
                ? 'JOIN WAITING LIST'
                : g['approval_required'] == true
                ? 'REQUEST TO JOIN'
                : 'JOIN GAME',
            onPressed: busy ? null : () => _action('games/$itemId/apply'),
          ),
      if (joined) Text('Your status: ${g['my_status']}'),
      if (joined)
        TextButton(
          onPressed: busy ? null : () => _action('games/$itemId/withdraw'),
          child: const Text('Withdraw'),
        ),
      if (g['is_organizer'] == true) ...[
        Text('Game status: ${g['status']}'),
        if (g['status'] == 'open')
          TextButton(
            onPressed: busy
                ? null
                : () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Cancel game?'),
                        content: const Text('Participants will be notified.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Keep game'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Cancel game'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await _action('games/$itemId/lifecycle/cancel');
                    }
                  },
            child: const Text('Cancel game'),
          ),
        if (g['status'] == 'open' &&
            (DateTime.tryParse(g['scheduled_at'].toString())
                    ?.isBefore(DateTime.now()) ??
                false))
          TextButton(
            onPressed: busy
                ? null
                : () => _action('games/$itemId/lifecycle/complete'),
            child: const Text('Mark game completed'),
          ),
        OutlinedButton.icon(
          onPressed: busy
              ? null
              : () => _copyInvite(
                  'games/$itemId/invites',
                  'Game invitation code copied; valid for 7 days.',
                ),
          icon: const Icon(Icons.share),
          label: const Text('Copy game invitation'),
        ),
        Text('APPLICATIONS & WAITING LIST', style: context.midnight.labelStyle),
        const SizedBox(height: 8),
        if (requests.isEmpty) const Text('No applications yet.'),
        ...requests.map(
          (r) => _requestCard(r, 'games/$itemId/applications/${r['id']}'),
        ),
      ],
    ];
  }

  Widget _requestCard(Json r, String path) => StitchCard(
    color: context.midnight.carbon,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${r['display_name']} · ${r['status']}'),
        if (['pending', 'waitlisted'].contains(r['status']))
          Row(
            children: [
              TextButton(
                onPressed: busy ? null : () => _action('$path/approve'),
                child: const Text('Approve'),
              ),
              TextButton(
                onPressed: busy ? null : () => _action('$path/reject'),
                child: const Text('Deny'),
              ),
            ],
          ),
        if (widget.section == 'games' && r['status'] == 'approved')
          TextButton(
            onPressed: busy ? null : () => _action('$path/remove'),
            child: const Text('Remove participant'),
          ),
      ],
    ),
  );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Unable to load. Check your connection.'),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

void _leaveCommunityPage(
  BuildContext context,
  String section, {
  bool created = false,
}) {
  if (context.canPop()) {
    context.pop(created ? true : null);
    return;
  }
  context.go(switch (section) {
    'teams' => '/squad',
    'challenges' => '/challenges',
    _ => '/matches',
  });
}

void _message(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
String _date(dynamic value) {
  if (value == null) return 'Time not set';
  final date = DateTime.tryParse(value.toString())?.toLocal();
  if (date == null) return value.toString();
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

Future<String?> _ask(BuildContext context, String title, String label) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}
