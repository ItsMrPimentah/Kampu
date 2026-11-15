import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

import 'squad_controller.dart';

class SquadScreen extends HookConsumerWidget {
  const SquadScreen({super.key, required this.openHub});

  final void Function(String) openHub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinations = ref.watch(squadControllerProvider);
    return Scaffold(
      appBar: const StitchTopBar(title: 'Squad', subtitle: 'TEAM OPERATIONS'),
      body: ListView(
        padding: EdgeInsets.all(context.midnight.pageMargin),
        children: [
          Text(
            'Your football base',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage teams and the tools around your next match.',
            style: TextStyle(color: context.midnight.steelLight),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Profile & teams'),
              subtitle: const Text(
                'Create a team, invite players, coordinate matches',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openHub(destinations[0]),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_none),
              title: const Text('Notifications & safety'),
              subtitle: const Text(
                'Privacy controls, reports, and notifications',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openHub(destinations[1]),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Payments'),
              subtitle: const Text('Contributions and booking guarantees'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openHub(destinations[2]),
            ),
          ),
        ],
      ),
    );
  }
}
