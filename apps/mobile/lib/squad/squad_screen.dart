import 'package:flutter/material.dart';

import '../navigation/navigation_controller.dart';
import '../theme/midnight_theme.dart';
import '../theme/stitch_components.dart';

class SquadScreen extends StatelessWidget {
  const SquadScreen({super.key, required this.navigation});

  final NavigationController navigation;

  @override
  Widget build(BuildContext context) => Scaffold(
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
            onTap: () => navigation.openExistingHub('teams'),
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
            onTap: () => navigation.openExistingHub('safety'),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: const Text('Payments'),
            subtitle: const Text('Contributions and booking guarantees'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => navigation.openExistingHub('payments'),
          ),
        ),
      ],
    ),
  );
}
