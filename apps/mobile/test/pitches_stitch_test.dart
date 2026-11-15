import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showtime_mobile/screens/pitches/pitches_screen.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

void main() {
  testWidgets(
    'Pitches keeps cached authority and availability labels visible',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1600));
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: MidnightThemeData.apply(),
            home: const PitchesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Offline snapshot'), findsOneWidget);
      expect(
        find.text('Cached slots loaded · synced 02 Nov at 09:00'),
        findsOneWidget,
      );
      expect(find.text('Native'), findsWidgets);
      expect(find.text('External'), findsWidgets);
      await tester.binding.setSurfaceSize(null);
    },
  );
}
