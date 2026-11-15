import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showtime_mobile/app/navigation/app_router.dart';
import 'package:showtime_mobile/core/eligibility/eligibility.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

void main() {
  testWidgets(
    'representative Stitch routes render without mobile layout exceptions',
    (tester) async {
      final eligibility = ValueNotifier<EligibilityDecision?>(
        evaluateEligibility('2000-01-01'),
      );
      final router = createShowtimeRouter(eligibility: eligibility);
      addTearDown(() {
        router.dispose();
        eligibility.dispose();
      });

      for (final width in [360.0, 390.0, 430.0]) {
        await tester.binding.setSurfaceSize(Size(width, 844));
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              theme: MidnightThemeData.apply(),
              routerConfig: router,
            ),
          ),
        );
        for (final location in [
          '/home',
          '/pitches',
          '/challenges/challenge-001',
          '/squad',
        ]) {
          router.go(location);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'layout exception at $location / $width',
          );
        }
      }
      await tester.binding.setSurfaceSize(null);
    },
  );
}
