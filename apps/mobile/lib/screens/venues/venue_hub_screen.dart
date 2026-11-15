import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

import 'venue_hub_controller.dart';

class VenueHubScreen extends HookConsumerWidget {
  const VenueHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlController = useTextEditingController();
    final state = ref.watch(venueHubControllerProvider);
    final controller = ref.read(venueHubControllerProvider.notifier);
    return Scaffold(
      appBar: const StitchTopBar(
        title: 'Find a venue',
        subtitle: 'VENUE AUTHORITY',
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Lisbon · 5v5', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('PlayArena Lisbon'),
              subtitle: Text(
                'Native booking · operator verified · source: PlayArena\nBooking status: ${state.status}',
              ),
              trailing: FilledButton(
                onPressed: controller.reserve,
                child: const Text('Reserve'),
              ),
            ),
          ),
          if (state.status == 'Failed')
            const Card(
              child: ListTile(
                title: Text('Reservation failed'),
                subtitle: Text(
                  'Try another slot or declare an external booking.',
                ),
              ),
            ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Use external booking'),
            value: state.external,
            onChanged: controller.selectExternal,
          ),
          if (state.external) ...[
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'External booking URL',
              ),
            ),
            OutlinedButton(
              onPressed: controller.declare,
              child: const Text('Declare reservation'),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Source timestamp: current pilot catalog · location shown at region precision',
          ),
        ],
      ),
    );
  }
}
