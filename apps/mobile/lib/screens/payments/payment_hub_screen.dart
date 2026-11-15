import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

import 'payment_hub_controller.dart';

class PaymentHubScreen extends HookConsumerWidget {
  const PaymentHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paymentHubControllerProvider);
    final controller = ref.read(paymentHubControllerProvider.notifier);
    return Scaffold(
      appBar: const StitchTopBar(
        title: 'Payments & contributions',
        subtitle: 'PAYMENT TELEMETRY',
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Booking payment: captain guarantee accepted'),
          const SizedBox(height: 12),
          Text(
            'Participant contribution: ${state.contribution}',
            key: const ValueKey('payment-state'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: controller.reportPaid,
            child: const Text('Report paid directly to captain'),
          ),
          OutlinedButton(
            onPressed: controller.dispute,
            child: const Text('Dispute contribution'),
          ),
          if (state.disputeOpen) ...[
            const SizedBox(height: 12),
            const Text(
              'Dispute: captain review pending',
              key: ValueKey('dispute-state'),
            ),
            FilledButton(
              onPressed: controller.resolveUnpaid,
              child: const Text('Resolve as unpaid'),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: controller.refund,
            child: const Text('Show refund'),
          ),
        ],
      ),
    );
  }
}
