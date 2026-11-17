import 'package:flutter/material.dart';

import '../theme/stitch_components.dart';

class PaymentHubScreen extends StatefulWidget {
  const PaymentHubScreen({super.key});

  @override
  State<PaymentHubScreen> createState() => _PaymentHubScreenState();
}

class _PaymentHubScreenState extends State<PaymentHubScreen> {
  String _contribution = 'Outstanding';
  bool _disputeOpen = false;

  @override
  Widget build(BuildContext context) {
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
            'Participant contribution: $_contribution',
            key: const ValueKey('payment-state'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => setState(() => _contribution = 'Captain-reported'),
            child: const Text('Report paid directly to captain'),
          ),
          OutlinedButton(
            onPressed: () => setState(() {
              _contribution = 'Disputed';
              _disputeOpen = true;
            }),
            child: const Text('Dispute contribution'),
          ),
          if (_disputeOpen) ...[
            const SizedBox(height: 12),
            const Text(
              'Dispute: captain review pending',
              key: ValueKey('dispute-state'),
            ),
            FilledButton(
              onPressed: () => setState(() {
                _contribution = 'Resolved unpaid';
                _disputeOpen = false;
              }),
              child: const Text('Resolve as unpaid'),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => setState(() => _contribution = 'Refunded'),
            child: const Text('Show refund'),
          ),
        ],
      ),
    );
  }
}
