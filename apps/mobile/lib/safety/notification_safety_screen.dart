import 'package:flutter/material.dart';

import '../theme/stitch_components.dart';

class InAppNotification {
  const InAppNotification({required this.title, required this.body});

  final String title;
  final String body;
}

class NotificationSafetyScreen extends StatefulWidget {
  const NotificationSafetyScreen({
    super.key,
    required this.notifications,
    required this.isYouth,
    this.initialAdvertisingConsent = false,
    this.initialAnalyticsConsent = false,
    this.onAdvertisingConsentChanged,
    this.onAnalyticsConsentChanged,
    this.onReport,
    this.onBlock,
  });

  final List<InAppNotification> notifications;
  final bool isYouth;
  final bool initialAdvertisingConsent;
  final bool initialAnalyticsConsent;
  final ValueChanged<bool>? onAdvertisingConsentChanged;
  final ValueChanged<bool>? onAnalyticsConsentChanged;
  final VoidCallback? onReport;
  final VoidCallback? onBlock;

  @override
  State<NotificationSafetyScreen> createState() =>
      _NotificationSafetyScreenState();
}

class _NotificationSafetyScreenState extends State<NotificationSafetyScreen> {
  late bool _advertisingConsent = widget.initialAdvertisingConsent;
  late bool _analyticsConsent = widget.initialAnalyticsConsent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const StitchTopBar(
        title: 'Notifications & safety',
        subtitle: 'SAFETY CONSOLE',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Notifications', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (widget.notifications.isEmpty)
            const Card(child: ListTile(title: Text('You are all caught up.')))
          else
            ...widget.notifications.map(
              (notification) => Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_none),
                  title: Text(notification.title),
                  subtitle: Text(notification.body),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Privacy & consent',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                if (widget.isYouth)
                  const ListTile(
                    leading: Icon(Icons.shield_outlined),
                    title: Text('Youth advertising protection'),
                    subtitle: Text(
                      'Personalized advertising is disabled for youth accounts.',
                    ),
                  )
                else
                  SwitchListTile(
                    key: const ValueKey('advertising-consent'),
                    title: const Text('Personalized advertising'),
                    subtitle: const Text(
                      'You can change this choice at any time.',
                    ),
                    value: _advertisingConsent,
                    onChanged: (value) {
                      setState(() => _advertisingConsent = value);
                      widget.onAdvertisingConsentChanged?.call(value);
                    },
                  ),
                SwitchListTile(
                  key: const ValueKey('analytics-consent'),
                  title: const Text('Optional analytics'),
                  subtitle: const Text(
                    'Help improve match coordination with aggregate data.',
                  ),
                  value: _analyticsConsent,
                  onChanged: (value) {
                    setState(() => _analyticsConsent = value);
                    widget.onAnalyticsConsentChanged?.call(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Safety actions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Report a user or content'),
                  onTap: widget.onReport,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.block_outlined),
                  title: const Text('Block a user'),
                  onTap: widget.onBlock,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdPolicyGate extends StatelessWidget {
  const AdPolicyGate({
    super.key,
    required this.adsAllowed,
    required this.criticalWorkflow,
    required this.child,
  });

  final bool adsAllowed;
  final bool criticalWorkflow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!adsAllowed || criticalWorkflow) return const SizedBox.shrink();
    return child;
  }
}
