import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

import 'match_hub_controller.dart';

class MatchHubScreen extends HookConsumerWidget {
  const MatchHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchHubControllerProvider);
    final controller = ref.read(matchHubControllerProvider.notifier);
    final status = state.status;
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
            onPressed: controller.advance,
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
            value: state.fusion,
            onChanged: controller.setFusion,
          ),
          if (state.fusion)
            const Text('Fusion: two separate captains coordinate this match'),
          const SizedBox(height: 16),
          Text('Open Game', style: Theme.of(context).textTheme.titleLarge),
          Text('Approved players: ${state.players} / 5'),
          OutlinedButton(
            onPressed: state.players < 5 ? controller.apply : null,
            child: const Text('Apply for slot'),
          ),
          const SizedBox(height: 16),
          Text('Attendance', style: Theme.of(context).textTheme.titleLarge),
          CheckboxListTile(
            key: const ValueKey('attendance-checkbox'),
            title: const Text('Confirm attendance'),
            value: state.attendance,
            onChanged: (value) => controller.setAttendance(value ?? false),
          ),
          FilledButton(
            key: const ValueKey('confirm-attendance-button'),
            onPressed: () => controller.setAttendance(true),
            child: const Text('Confirm attendance now'),
          ),
          if (state.attendance)
            const Text(
              'Attendance confirmed',
              key: ValueKey('attendance-confirmed'),
            ),
        ],
      ),
    );
  }
}
