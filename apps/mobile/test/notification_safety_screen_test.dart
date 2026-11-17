import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtime_mobile/safety/notification_safety_screen.dart';

void main() {
  testWidgets('renders safe notifications and youth advertising protection', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NotificationSafetyScreen(
          isYouth: true,
          notifications: [
            InAppNotification(
              title: 'Booking failed',
              body: 'Choose another slot or declare an external booking.',
            ),
          ],
        ),
      ),
    );

    expect(find.text('Booking failed'), findsOneWidget);
    expect(
      find.text('Personalized advertising is disabled for youth accounts.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('advertising-consent')), findsNothing);
  });

  testWidgets('records adult consent choices and exposes safety actions', (
    tester,
  ) async {
    var advertisingConsent = false;
    var analyticsConsent = false;
    var reports = 0;
    var blocks = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationSafetyScreen(
          isYouth: false,
          notifications: const [],
          onAdvertisingConsentChanged: (value) => advertisingConsent = value,
          onAnalyticsConsentChanged: (value) => analyticsConsent = value,
          onReport: () => reports++,
          onBlock: () => blocks++,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('advertising-consent')));
    await tester.tap(find.byKey(const ValueKey('analytics-consent')));
    await tester.tap(find.text('Report a user or content'));
    await tester.tap(find.text('Block a user'));

    expect(advertisingConsent, true);
    expect(analyticsConsent, true);
    expect(reports, 1);
    expect(blocks, 1);
  });

  testWidgets('does not render an ad inside a critical workflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdPolicyGate(
          adsAllowed: true,
          criticalWorkflow: true,
          child: Text('Advertisement'),
        ),
      ),
    );

    expect(find.text('Advertisement'), findsNothing);
  });

  testWidgets(
    'renders an ad only when policy allows it outside critical workflows',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdPolicyGate(
            adsAllowed: true,
            criticalWorkflow: false,
            child: Text('Advertisement'),
          ),
        ),
      );

      expect(find.text('Advertisement'), findsOneWidget);
    },
  );
}
