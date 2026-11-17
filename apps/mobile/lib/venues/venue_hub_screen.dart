import 'package:flutter/material.dart';

import '../theme/stitch_components.dart';

class VenueHubScreen extends StatefulWidget {
  const VenueHubScreen({super.key});

  @override
  State<VenueHubScreen> createState() => _VenueHubScreenState();
}

class _VenueHubScreenState extends State<VenueHubScreen> {
  bool _external = false;
  String _status = 'Not requested';
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                'Native booking · operator verified · source: PlayArena\nBooking status: $_status',
              ),
              trailing: FilledButton(
                onPressed: () =>
                    setState(() => _status = 'Pending provider confirmation'),
                child: const Text('Reserve'),
              ),
            ),
          ),
          if (_status == 'Failed')
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
            value: _external,
            onChanged: (value) => setState(() => _external = value),
          ),
          if (_external) ...[
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'External booking URL',
              ),
            ),
            OutlinedButton(
              onPressed: () => setState(
                () => _status = 'Externally declared · user-declared · not provider confirmed',
              ),
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
