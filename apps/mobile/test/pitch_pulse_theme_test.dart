import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtime_mobile/registration/pitch_pulse_theme.dart';

void main() {
  testWidgets('exposes Pitch Pulse registration tokens through the theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PitchPulseThemeData.apply(ThemeData.dark(useMaterial3: true)),
        home: Builder(
          builder: (context) {
            final tokens = Theme.of(context).extension<PitchPulseTheme>()!;
            return Text(
              '${tokens.fieldRadius}:${tokens.cardRadius}:${tokens.controlHeight}',
            );
          },
        ),
      ),
    );

    expect(find.text('10.0:16.0:48.0'), findsOneWidget);
    expect(PitchPulseTheme.defaults.voidColor, const Color(0xFF0F101A));
    expect(PitchPulseTheme.defaults.periwinkle, const Color(0xFF98A4F7));
  });
}
