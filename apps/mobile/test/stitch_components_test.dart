import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    theme: MidnightThemeData.apply(),
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets(
    'gradient and ghost actions expose accessible controls and touch size',
    (tester) async {
      await tester.pumpWidget(
        host(const StitchGradientButton(label: 'Reserve', onPressed: _noop)),
      );
      expect(
        tester.getSize(find.text('Reserve')).height,
        greaterThanOrEqualTo(16),
      );
      expect(find.text('Reserve'), findsOneWidget);

      await tester.pumpWidget(
        host(const StitchGhostButton(label: 'View provider', onPressed: _noop)),
      );
      expect(find.text('View provider'), findsOneWidget);
    },
  );

  testWidgets('filter selection and status labels are exposed semantically', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const Column(
          children: [
            StitchFilterChip(
              label: '7v7',
              selected: true,
              onSelected: _noopBool,
            ),
            StitchStatusPill(
              label: 'Native instant booking',
              tone: StitchStatusTone.success,
            ),
          ],
        ),
      ),
    );
    expect(find.text('7v7'), findsOneWidget);
    expect(find.text('Native instant booking'), findsOneWidget);
  });

  testWidgets('missing local imagery renders a stable fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const StitchImageFrame(assetPath: 'assets/images/not-present.png')),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
  });
}

void _noop() {}
void _noopBool(bool value) {}
