import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/auth_client.dart';
import '../theme/midnight_theme.dart';
import '../theme/stitch_components.dart';

typedef Json = Map<String, dynamic>;

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key, required this.auth, required this.section});
  final AuthClient auth;
  final String section;
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class CommunityDiscoveryScreen extends StatefulWidget {
  const CommunityDiscoveryScreen({super.key, required this.auth});
  final AuthClient auth;
  @override
  State<CommunityDiscoveryScreen> createState() =>
      _CommunityDiscoveryScreenState();
}

class _CommunityDiscoveryScreenState extends State<CommunityDiscoveryScreen> {
  late Future<List<List<dynamic>>> data;
  String? selectedFormat;
  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    data = Future.wait([
      widget.auth.communityList('challenges'),
      widget.auth.communityList('games'),
    ]);
  }

  Future<void> open(String section, Json item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityDetailScreen(
          auth: widget.auth,
          section: section,
          item: item,
        ),
      ),
    );
    if (mounted) setState(refresh);
  }

  Future<void> _notifications() async {
    try {
      final items = await widget.auth.communityList('notifications');
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              Text('Notifications', style: Theme.of(ctx).textTheme.titleLarge),
              if (items.isEmpty)
                const ListTile(title: Text('No notifications yet.')),
              ...items.map(
                (item) => ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text(
                    item['type']
                        .toString()
                        .replaceAll('.', ' · ')
                        .replaceAll('_', ' '),
                  ),
                  subtitle: Text(_date(item['created_at'])),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      if (mounted) _message(context, 'Unable to load notifications.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
    body: FutureBuilder<List<List<dynamic>>>(
      future: data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorPanel(onRetry: () => setState(refresh));
        }
        final challenges = snapshot.data![0]
            .where(
              (item) =>
                  selectedFormat == null || item['format'] == selectedFormat,
            )
            .toList();
        final games = snapshot.data![1]
            .where(
              (item) =>
                  selectedFormat == null || item['format'] == selectedFormat,
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
          onRefresh: () async {
            setState(refresh);
            await data;
          },
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
                  item: Map<String, dynamic>.from(upcoming.first as Map),
                  onTap: () => open(
                    'challenges',
                    Map<String, dynamic>.from(upcoming.first as Map),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    StitchFilterChip(
                      label: 'All formats',
                      selected: selectedFormat == null,
                      onSelected: (_) => setState(() => selectedFormat = null),
                    ),
                    ...['5v5', '7v7', '11v11'].map(
                      (value) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: StitchFilterChip(
                          label: value,
                          selected: selectedFormat == value,
                          onSelected: (_) =>
                              setState(() => selectedFormat = value),
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
                  Text('${challenges.length} challenges'),
                ],
              ),
              const SizedBox(height: 12),
              if (challenges.isEmpty)
                const StitchCard(child: Text('No challenges yet.')),
              ...challenges.take(4).map((v) {
                final item = Map<String, dynamic>.from(v as Map);
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
                final item = Map<String, dynamic>.from(v as Map);
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
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CommunityScreen(auth: widget.auth, section: 'games'),
                    ),
                  );
                  if (mounted) setState(refresh);
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

class _CommunityScreenState extends State<CommunityScreen> {
  late Future<List<dynamic>> _data;
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(covariant CommunityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) _refresh();
  }

  void _refresh() {
    _data = widget.auth.communityList(widget.section);
  }

  void _reload() => setState(_refresh);

  Future<void> _create() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            CommunityCreateScreen(auth: widget.auth, section: widget.section),
      ),
    );
    if (created == true && mounted) _reload();
  }

  Future<void> _open(Json item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CommunityDetailScreen(
          auth: widget.auth,
          section: widget.section,
          item: item,
        ),
      ),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.section) {
      'teams' => 'Squad',
      'challenges' => 'Challenges',
      _ => 'Open Games',
    };
    final subtitle = switch (widget.section) {
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
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorPanel(onRetry: _reload);
          final items = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _data;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(context.midnight.pageMargin),
              children: [
                Text(switch (widget.section) {
                  'teams' => 'Your football base',
                  'challenges' => 'Team negotiations',
                  _ => 'Find your next game',
                }, style: context.midnight.displayStyle.copyWith(fontSize: 24)),
                const SizedBox(height: 8),
                Text(switch (widget.section) {
                  'teams' => 'Build your squad and manage your roster.',
                  'challenges' => 'Keep every offer and decision in one place.',
                  _ => 'Discover matches and coordinate your next kickoff.',
                }, style: context.midnight.bodyStyle),
                const SizedBox(height: 16),
                StitchGradientButton(
                  label: switch (widget.section) {
                    'teams' => 'CREATE TEAM',
                    'challenges' => 'CREATE CHALLENGE',
                    _ => 'CREATE GAME',
                  },
                  icon: Icons.add,
                  onPressed: _create,
                ),
                if (widget.section == 'teams') ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _acceptInvite,
                    icon: const Icon(Icons.link),
                    label: const Text('Join with invitation code'),
                  ),
                ],
                if (widget.section == 'games') ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _acceptGameInvite,
                    icon: const Icon(Icons.link),
                    label: const Text('Join with invitation code'),
                  ),
                ],
                const SizedBox(height: 20),
                if (items.isEmpty)
                  StitchCard(
                    color: context.midnight.carbon,
                    child: const Text(
                      'Nothing here yet. Create one to get started.',
                    ),
                  ),
                ...items.map((raw) {
                  final item = Map<String, dynamic>.from(raw as Map);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CommunityCard(
                      section: widget.section,
                      item: item,
                      onTap: () => _open(item),
                    ),
                  );
                }),
              ],
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
    try {
      await widget.auth.communityPost('invites/$token/accept');
      if (mounted) _reload();
    } catch (_) {
      if (mounted) {
        _message(context, 'Unable to accept invitation. Check the code.');
      }
    }
  }

  Future<void> _acceptGameInvite() async {
    final token = await _ask(
      context,
      'Game invitation',
      'Paste the invitation code',
    );
    if (token == null || token.isEmpty) return;
    try {
      await widget.auth.communityPost('game-invites/$token/accept');
      if (mounted) _reload();
    } catch (_) {
      if (mounted) {
        _message(context, 'Unable to join this game. Check the invitation.');
      }
    }
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
        '${item['host_name']}  vs  ${item['opponent_name'] ?? 'Seeking opponent'}',
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
                tone: StitchStatusTone.active,
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
                  ? 'View negotiation →'
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

class CommunityCreateScreen extends StatefulWidget {
  const CommunityCreateScreen({
    super.key,
    required this.auth,
    required this.section,
  });
  final AuthClient auth;
  final String section;
  @override
  State<CommunityCreateScreen> createState() => _CommunityCreateScreenState();
}

class _CommunityCreateScreenState extends State<CommunityCreateScreen> {
  final name = TextEditingController();
  final region = TextEditingController(text: 'Lisbon');
  final location = TextEditingController();
  final capacity = TextEditingController(text: '14');
  final positions = TextEditingController();
  final description = TextEditingController();
  String format = '7v7';
  bool approval = true;
  bool private = false;
  DateTime? kickoff;
  String? teamId;
  List<Json> teams = [];
  bool busy = false;
  @override
  void initState() {
    super.initState();
    if (widget.section == 'challenges') _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      final values = await widget.auth.communityList('teams');
      if (mounted) {
        setState(() {
          teams = values
              .map((v) => Map<String, dynamic>.from(v as Map))
              .where((v) => v['my_role'] == 'captain')
              .toList();
        });
      }
    } catch (_) {
      if (mounted) _message(context, 'Unable to load your teams.');
    }
  }

  @override
  void dispose() {
    name.dispose();
    region.dispose();
    location.dispose();
    capacity.dispose();
    positions.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      initialDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
    );
    if (time != null && mounted) {
      setState(
        () => kickoff = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (busy) return;
    if (region.text.trim().isEmpty ||
        (widget.section != 'challenges' && name.text.trim().isEmpty) ||
        (widget.section != 'teams' &&
            (kickoff == null || !kickoff!.isAfter(DateTime.now()))) ||
        (widget.section == 'challenges' && teamId == null) ||
        (widget.section == 'games' &&
            (location.text.trim().isEmpty ||
                int.tryParse(capacity.text) == null))) {
      _message(
        context,
        'Complete the required fields and choose a future kickoff.',
      );
      return;
    }
    if (widget.section == 'challenges' &&
        !(teams.firstWhere((team) => team['id'] == teamId)['supported_formats']
                as List)
            .contains(format)) {
      _message(context, 'Choose a format supported by your team.');
      return;
    }
    setState(() => busy = true);
    try {
      final Json body = switch (widget.section) {
        'teams' => {
          'name': name.text,
          'region': region.text,
          'formats': [format],
          'visibility': private ? 'private' : 'public',
          'description': description.text,
        },
        'challenges' => {
          'teamId': teamId,
          'format': format,
          'scheduledAt': kickoff!.toUtc().toIso8601String(),
          'region': region.text,
          'field': location.text,
        },
        _ => {
          'title': name.text,
          'region': region.text,
          'location': location.text,
          'format': format,
          'scheduledAt': kickoff!.toUtc().toIso8601String(),
          'capacity': int.parse(capacity.text),
          'approvalRequired': approval,
          'visibility': private ? 'private' : 'public',
          'requiredPositions': positions.text
              .split(',')
              .map((v) => v.trim())
              .where((v) => v.isNotEmpty)
              .toList(),
        },
      };
      await widget.auth.communityPost(widget.section, body);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        _message(context, 'Unable to save. Check the details and try again.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: StitchTopBar(
      title: switch (widget.section) {
        'teams' => 'Create team',
        'challenges' => 'Create challenge',
        _ => 'Create game',
      },
      onBack: () => Navigator.pop(context),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.section == 'challenges')
          DropdownButtonFormField<String>(
            initialValue: teamId,
            decoration: const InputDecoration(labelText: 'Your captain team'),
            items: teams
                .map(
                  (t) => DropdownMenuItem(
                    value: t['id'] as String,
                    child: Text(t['name'] as String),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() {
              teamId = v;
              final selected = teams.firstWhere((team) => team['id'] == v);
              final supported = selected['supported_formats'] as List;
              if (!supported.contains(format) && supported.isNotEmpty) {
                format = supported.first as String;
              }
            }),
          ),
        if (widget.section != 'challenges')
          TextField(
            controller: name,
            decoration: InputDecoration(
              labelText: widget.section == 'teams' ? 'Team name' : 'Game title',
            ),
          ),
        if (widget.section == 'teams') ...[
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
          initialValue: format,
          decoration: const InputDecoration(labelText: 'Format'),
          items: [
            '5v5',
            '7v7',
            '11v11',
          ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setState(() => format = v!),
        ),
        if (widget.section != 'teams') ...[
          const SizedBox(height: 12),
          TextField(
            controller: location,
            decoration: InputDecoration(
              labelText: widget.section == 'games'
                  ? 'Field / location'
                  : 'Field (optional)',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event),
            label: Text(
              kickoff == null
                  ? 'Choose kickoff'
                  : _date(kickoff!.toIso8601String()),
            ),
          ),
        ],
        if (widget.section == 'games') ...[
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
            value: approval,
            onChanged: (v) => setState(() => approval = v),
          ),
        ],
        if (widget.section != 'challenges')
          SwitchListTile(
            title: const Text('Private'),
            value: private,
            onChanged: (v) => setState(() => private = v),
          ),
        const SizedBox(height: 16),
        StitchGradientButton(
          label: busy ? 'SAVING…' : 'CREATE',
          onPressed: busy ? null : _submit,
        ),
      ],
    ),
  );
}

class CommunityDetailScreen extends StatefulWidget {
  const CommunityDetailScreen({
    super.key,
    required this.auth,
    required this.section,
    required this.item,
  });
  final AuthClient auth;
  final String section;
  final Json item;
  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  Json? detail;
  List<Json> teams = [];
  List<Json> requests = [];
  bool loading = true;
  bool busy = false;
  String get itemId => widget.item['id'] as String;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      detail = null;
    });
    try {
      if (widget.section == 'teams') {
        detail = await widget.auth.communityGet('teams/$itemId');
        if (detail!['myRole'] == 'captain') {
          requests = (await widget.auth.communityList('teams/$itemId/requests'))
              .map((v) => Map<String, dynamic>.from(v as Map))
              .toList();
        }
      } else if (widget.section == 'challenges') {
        detail = await widget.auth.communityGet('challenges/$itemId');
        teams = (await widget.auth.communityList('teams'))
            .map((v) => Map<String, dynamic>.from(v as Map))
            .where((v) => v['my_role'] == 'captain')
            .toList();
      } else {
        detail = await widget.auth.communityGet('games/$itemId');
        if (detail!['is_organizer'] == true) {
          requests = (await widget.auth.communityList(
            'games/$itemId/applications',
          )).map((v) => Map<String, dynamic>.from(v as Map)).toList();
        } else {
          requests = [];
        }
      }
    } catch (_) {
      detail = null;
      if (mounted) _message(context, 'Unable to load details.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _action(String path, [Json body = const {}]) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await widget.auth.communityPost(path, body);
      await _load();
    } catch (_) {
      if (mounted) {
        _message(
          context,
          'Unable to complete this action. Please check the current status.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
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
    if (confirm != true || !mounted) return;
    try {
      await widget.auth.communityPost('teams/$itemId/leave');
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) _message(context, 'Unable to leave this team.');
    }
  }

  Future<String?> _teamForAction(String action) async {
    final match = detail!['match'] as Map;
    final proposals = detail!['proposals'] as List;
    final votes = detail!['votes'] as List;
    final eligible = teams.where((t) {
      if (action == 'join') {
        return t['id'] != match['host_team_id'] &&
            (t['supported_formats'] as List).contains(match['format']);
      }
      if (![
        match['host_team_id'],
        match['opponent_team_id'],
      ].contains(t['id'])) {
        return false;
      }
      if (action == 'accept' && proposals.isNotEmpty) {
        return t['id'] != proposals.last['proposed_by_team_id'];
      }
      if (action == 'field-approve' && votes.isNotEmpty) {
        return t['id'] != votes.first['proposed_by_team_id'];
      }
      return true;
    }).toList();
    if (eligible.isEmpty) {
      _message(context, 'An eligible captain team is required.');
      return null;
    }
    if (eligible.length == 1) return eligible.first['id'] as String;
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
    if (team == null || !mounted) return;
    final Json body = {'teamId': team};
    if (action == 'field-proposal') {
      final field = await _ask(context, 'Propose a field', 'Field name');
      if (field == null || field.isEmpty || !mounted) return;
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
      if (status == null || !mounted) return;
      body['status'] = status;
    }
    if (action == 'counter') {
      final match = detail!['match'] as Map;
      String field;
      if (match['status'] == 'agreed' || match['status'] == 'scheduling') {
        field = match['field_name'] as String? ?? '';
        if (field.isEmpty) {
          _message(context, 'Propose a field using the field vote.');
          return;
        }
      } else {
        final value = await _ask(context, 'Counter offer', 'New field');
        if (value == null || value.isEmpty || !mounted) return;
        field = value;
      }
      final date = await showDatePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 730)),
        initialDate: DateTime.now().add(const Duration(days: 1)),
      );
      if (date == null || !mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 19, minute: 0),
      );
      if (time == null) return;
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
    if (confirm == true && mounted) await _challengeAction('cancel');
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
    if (confirm == true && mounted) await _challengeAction('decline');
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
    if (choice == null || !mounted) return;
    final Json body;
    if (choice == 'position') {
      final position = await _ask(context, 'Player position', 'Position');
      if (position == null || position.isEmpty || !mounted) return;
      body = {'position': position};
    } else if (choice == 'remove') {
      body = {'active': false};
    } else {
      body = {'role': choice};
    }
    try {
      await widget.auth.communityPatch(
        'teams/$itemId/members/${member['user_id']}',
        body,
      );
      await _load();
    } catch (_) {
      if (mounted) _message(context, 'Unable to update this player.');
    }
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
    if (result == null || !mounted) return;
    try {
      await widget.auth.communityPatch('teams/$itemId/formats', {
        'formats': result,
      });
      await _load();
    } catch (_) {
      if (mounted) _message(context, 'Unable to update formats.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: StitchTopBar(
      title: switch (widget.section) {
        'teams' => 'Squad roster',
        'challenges' => 'Challenge negotiation',
        _ => 'Match details',
      },
      onBack: () => Navigator.pop(context),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : detail == null
        ? _ErrorPanel(onRetry: _load)
        : ListView(
            padding: const EdgeInsets.all(16),
            children: switch (widget.section) {
              'teams' => _teamView(),
              'challenges' => _challengeView(),
              _ => _gameView(),
            },
          ),
  );
  List<Widget> _teamView() {
    final team = detail!['team'] as Map;
    final members = detail!['members'] as List;
    final captain = detail!['myRole'] == 'captain';
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
      if (detail!['myRole'] == null) ...[
        const SizedBox(height: 12),
        if (team['visibility'] == 'public')
          StitchGradientButton(
            label: 'REQUEST TO JOIN',
            onPressed: busy ? null : () => _action('teams/$itemId/requests'),
          ),
      ],
      if (detail!['myRole'] != null && !captain)
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
              : () async {
                  try {
                    final invite = await widget.auth.communityPost(
                      'teams/$itemId/invites',
                    );
                    await Clipboard.setData(
                      ClipboardData(text: invite['token']),
                    );
                    if (mounted) {
                      _message(
                        context,
                        'Invitation code copied; valid for 7 days.',
                      );
                    }
                  } catch (_) {
                    if (mounted) {
                      _message(context, 'Unable to create invitation.');
                    }
                  }
                },
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

  List<Widget> _challengeView() {
    final m = detail!['match'] as Map;
    final proposals = detail!['proposals'] as List;
    final votes = detail!['votes'] as List;
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
              tone: StitchStatusTone.active,
            ),
            const SizedBox(height: 12),
            Text(
              '${m['host_name']}  vs  ${m['opponent_name'] ?? 'Seeking opponent'}',
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
        if (canAccept)
          StitchGradientButton(
            label: 'CHALLENGE TEAM',
            onPressed: busy ? null : () => _challengeAction('join'),
          ),
      if (myCaptainTeam && m['status'] == 'negotiation') ...[
        StitchGradientButton(
          label: 'ACCEPT TERMS',
          onPressed: busy ? null : () => _challengeAction('accept'),
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

  List<Widget> _gameView() {
    final g = detail!;
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
                    if (confirmed == true && mounted) {
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
              : () async {
                  try {
                    final invite = await widget.auth.communityPost(
                      'games/$itemId/invites',
                    );
                    await Clipboard.setData(
                      ClipboardData(text: invite['token']),
                    );
                    if (mounted) {
                      _message(
                        context,
                        'Game invitation code copied; valid for 7 days.',
                      );
                    }
                  } catch (_) {
                    if (mounted) {
                      _message(context, 'Unable to create invitation.');
                    }
                  }
                },
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
