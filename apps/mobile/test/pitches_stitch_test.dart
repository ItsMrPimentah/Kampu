import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtime_mobile/navigation/navigation_controller.dart';
import 'package:showtime_mobile/pitches/pitches_screen.dart';
import 'package:showtime_mobile/theme/midnight_theme.dart';

void main() {
  testWidgets(
    'Pitches keeps cached authority and availability labels visible',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1600));
      final router = GoRouter(
        routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())],
      );
      final navigation = NavigationController(router);
      addTearDown(() {
        navigation.dispose();
        router.dispose();
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: MidnightThemeData.apply(),
          home: PitchesScreen(navigation: navigation),
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
