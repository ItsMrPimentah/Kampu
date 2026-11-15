import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

import 'team_hub_controller.dart';

class TeamHubScreen extends HookConsumerWidget {
  const TeamHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = useTextEditingController(text: 'New player');
    final team = useTextEditingController();
    final region = useTextEditingController(text: 'Lisbon');
    final invite = useTextEditingController();
    final state = ref.watch(teamHubControllerProvider);
    final controller = ref.read(teamHubControllerProvider.notifier);
    final requiredPlayers = state.requiredPlayers;
    final ready = state.players >= requiredPlayers;
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
            controller: profile,
            decoration: const InputDecoration(labelText: 'Display name'),
          ),
          const SizedBox(height: 24),
          Text('Create a team', style: Theme.of(context).textTheme.titleLarge),
          TextField(
            key: const ValueKey('team-name'),
            controller: team,
            decoration: const InputDecoration(labelText: 'Team name'),
          ),
          TextField(
            key: const ValueKey('team-region'),
            controller: region,
            decoration: const InputDecoration(labelText: 'Approximate region'),
          ),
          DropdownButtonFormField<String>(
            initialValue: state.format,
            decoration: const InputDecoration(labelText: 'Football format'),
            items: TeamHubState.formats.keys
                .map(
                  (format) =>
                      DropdownMenuItem(value: format, child: Text(format)),
                )
                .toList(),
            onChanged: controller.selectFormat,
          ),
          const SizedBox(height: 8),
          Text('Eligible starting players: ${state.players}'),
          Slider(
            value: state.players.toDouble(),
            min: 1,
            max: 11,
            divisions: 10,
            label: '${state.players}',
            onChanged: (value) => controller.setPlayers(value.round()),
          ),
          Text(
            ready
                ? 'Ready for ${state.format}'
                : 'Needs ${requiredPlayers - state.players} more eligible player(s)',
            key: const ValueKey('readiness'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => controller.createTeam(team.text, region.text),
            child: const Text('Create team'),
          ),
          const SizedBox(height: 24),
          Text(
            'Invite a player',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextField(
            key: const ValueKey('invite-player'),
            controller: invite,
            decoration: const InputDecoration(
              labelText: 'Player ID or contact',
            ),
          ),
          OutlinedButton(
            onPressed: () => controller.invite(invite.text),
            child: const Text('Send invitation'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.push('/matches'),
            child: const Text('Coordinate matches'),
          ),
          if (state.status case final status?) ...[
            const SizedBox(height: 16),
            Text(status, key: const ValueKey('team-status')),
          ],
        ],
      ),
    );
  }
}
