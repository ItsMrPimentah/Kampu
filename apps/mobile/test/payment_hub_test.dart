import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showtime_mobile/screens/payments/payment_hub_screen.dart';

void main() {
  testWidgets('shows distinct contribution and dispute states', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: PaymentHubScreen())),
    );
    await tester.tap(find.text('Report paid directly to captain'));
    await tester.pump();
    expect(
      find.text('Participant contribution: Captain-reported'),
      findsOneWidget,
    );
    await tester.tap(find.text('Dispute contribution'));
    await tester.pump();
    expect(find.text('Dispute: captain review pending'), findsOneWidget);
    await tester.tap(find.text('Resolve as unpaid'));
    await tester.pump();
    expect(
      find.text('Participant contribution: Resolved unpaid'),
      findsOneWidget,
    );
  });
}
