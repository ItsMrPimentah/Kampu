import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:showtime_mobile/core/safety/in_app_notification.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

import 'notification_safety_controller.dart';

class NotificationSafetyScreen extends HookConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final args = useMemoized(
      () => SafetyControllerArgs(
        advertising: initialAdvertisingConsent,
        analytics: initialAnalyticsConsent,
        onAdvertisingChanged: onAdvertisingConsentChanged,
        onAnalyticsChanged: onAnalyticsConsentChanged,
      ),
      [
        initialAdvertisingConsent,
        initialAnalyticsConsent,
        onAdvertisingConsentChanged,
        onAnalyticsConsentChanged,
      ],
    );
    final state = ref.watch(notificationSafetyControllerProvider(args));
    final controller = ref.read(
      notificationSafetyControllerProvider(args).notifier,
    );
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
          if (notifications.isEmpty)
            const Card(child: ListTile(title: Text('You are all caught up.')))
          else
            ...notifications.map(
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
                if (isYouth)
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
                    value: state.advertising,
                    onChanged: controller.setAdvertising,
                  ),
                SwitchListTile(
                  key: const ValueKey('analytics-consent'),
                  title: const Text('Optional analytics'),
                  subtitle: const Text(
                    'Help improve match coordination with aggregate data.',
                  ),
                  value: state.analytics,
                  onChanged: controller.setAnalytics,
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
                  onTap: onReport,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.block_outlined),
                  title: const Text('Block a user'),
                  onTap: onBlock,
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
