import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/stitch_components.dart';

class MatchHubScreen extends StatefulWidget {
  const MatchHubScreen({super.key});

  @override
  State<MatchHubScreen> createState() => _MatchHubScreenState();
}

class _MatchHubScreenState extends State<MatchHubScreen> {
  final _states = const [
    'Draft',
    'Open',
    'Negotiation',
    'Agreed',
    'Scheduling',
    'Confirmed',
    'Completed',
  ];
  int _state = 0;
  bool _fusion = false;
  bool _attendanceConfirmed = false;
  int _openGamePlayers = 0;

  void _advance() {
    if (_state < _states.length - 1) setState(() => _state++);
  }

  @override
  Widget build(BuildContext context) {
    final status = _states[_state];
    return Scaffold(
      appBar: const StitchTopBar(
        title: 'Matches & Open Games',
        subtitle: 'MATCH COORDINATION',
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Find a game', style: Theme.of(context).textTheme.titleLarge),
          const Text('Lisbon · 5v5 · approximate location'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.push('/venues'),
            child: const Text('Find venues'),
          ),
          const SizedBox(height: 16),
          Text('Team challenge', style: Theme.of(context).textTheme.titleLarge),
          Text('Status: $status', key: const ValueKey('challenge-status')),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _advance,
            child: Text(
              status == 'Draft'
                  ? 'Publish challenge'
                  : status == 'Completed'
                  ? 'Match completed'
                  : 'Advance challenge',
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Fusion game'),
            value: _fusion,
            onChanged: (value) => setState(() => _fusion = value),
          ),
          if (_fusion)
            const Text('Fusion: two separate captains coordinate this match'),
          const SizedBox(height: 16),
          Text('Open Game', style: Theme.of(context).textTheme.titleLarge),
          Text('Approved players: $_openGamePlayers / 5'),
          OutlinedButton(
            onPressed: _openGamePlayers < 5
                ? () => setState(() => _openGamePlayers++)
                : null,
            child: const Text('Apply for slot'),
          ),
          const SizedBox(height: 16),
          Text('Attendance', style: Theme.of(context).textTheme.titleLarge),
          CheckboxListTile(
            key: const ValueKey('attendance-checkbox'),
            title: const Text('Confirm attendance'),
            value: _attendanceConfirmed,
            onChanged: (value) =>
                setState(() => _attendanceConfirmed = value ?? false),
          ),
          FilledButton(
            key: const ValueKey('confirm-attendance-button'),
            onPressed: () => setState(() => _attendanceConfirmed = true),
            child: const Text('Confirm attendance now'),
          ),
          if (_attendanceConfirmed)
            const Text(
              'Attendance confirmed',
              key: ValueKey('attendance-confirmed'),
            ),
        ],
      ),
    );
  }
}
