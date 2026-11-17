import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/stitch_components.dart';

class TeamHubScreen extends StatefulWidget {
  const TeamHubScreen({super.key});

  @override
  State<TeamHubScreen> createState() => _TeamHubScreenState();
}

class _TeamHubScreenState extends State<TeamHubScreen> {
  final _profileController = TextEditingController(text: 'New player');
  final _teamController = TextEditingController();
  final _regionController = TextEditingController(text: 'Lisbon');
  final _inviteController = TextEditingController();
  String _format = '5v5';
  int _eligiblePlayers = 1;
  String? _status;

  static const formats = <String, int>{
    '5v5': 5,
    '7v7': 7,
    '11v11': 11,
    'Futsal': 5,
    'Futevoley 2v2': 2,
  };

  @override
  void dispose() {
    _profileController.dispose();
    _teamController.dispose();
    _regionController.dispose();
    _inviteController.dispose();
    super.dispose();
  }

  void _createTeam() {
    if (_teamController.text.trim().isEmpty) {
      setState(() => _status = 'Team name is required.');
      return;
    }
    setState(
      () => _status =
          'Team created as captain in ${_regionController.text.trim()}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final requiredPlayers = formats[_format]!;
    final ready = _eligiblePlayers >= requiredPlayers;
    return Scaffold(
      appBar: const StitchTopBar(
        title: 'Profile & teams',
        subtitle: 'SQUAD OPERATIONS',
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Player profile', style: Theme.of(context).textTheme.titleLarge),
          TextField(
            controller: _profileController,
            decoration: const InputDecoration(labelText: 'Display name'),
          ),
          const SizedBox(height: 24),
          Text('Create a team', style: Theme.of(context).textTheme.titleLarge),
          TextField(
            key: const ValueKey('team-name'),
            controller: _teamController,
            decoration: const InputDecoration(labelText: 'Team name'),
          ),
          TextField(
            key: const ValueKey('team-region'),
            controller: _regionController,
            decoration: const InputDecoration(labelText: 'Approximate region'),
          ),
          DropdownButtonFormField<String>(
            initialValue: _format,
            decoration: const InputDecoration(labelText: 'Football format'),
            items: formats.keys
                .map(
                  (format) =>
                      DropdownMenuItem(value: format, child: Text(format)),
                )
                .toList(),
            onChanged: (value) => setState(() => _format = value ?? _format),
          ),
          const SizedBox(height: 8),
          Text('Eligible starting players: $_eligiblePlayers'),
          Slider(
            value: _eligiblePlayers.toDouble(),
            min: 1,
            max: 11,
            divisions: 10,
            label: '$_eligiblePlayers',
            onChanged: (value) =>
                setState(() => _eligiblePlayers = value.round()),
          ),
          Text(
            ready
                ? 'Ready for $_format'
                : 'Needs ${requiredPlayers - _eligiblePlayers} more eligible player(s)',
            key: const ValueKey('readiness'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _createTeam,
            child: const Text('Create team'),
          ),
          const SizedBox(height: 24),
          Text(
            'Invite a player',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextField(
            key: const ValueKey('invite-player'),
            controller: _inviteController,
            decoration: const InputDecoration(
              labelText: 'Player ID or contact',
            ),
          ),
          OutlinedButton(
            onPressed: () => setState(
              () => _status =
                  'Invitation created for ${_inviteController.text.trim()}.',
            ),
            child: const Text('Send invitation'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.push('/matches'),
            child: const Text('Coordinate matches'),
          ),
          if (_status != null) ...[
            const SizedBox(height: 16),
            Text(_status!, key: const ValueKey('team-status')),
          ],
        ],
      ),
    );
  }
}
