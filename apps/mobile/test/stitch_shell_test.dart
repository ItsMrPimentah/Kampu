import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showtime_mobile/app/navigation/app_router.dart';
import 'package:showtime_mobile/core/eligibility/eligibility.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
    await loader.load();
  });
  testWidgets('Stitch dock remains usable across supported mobile widths', (
    tester,
  ) async {
    final eligibility = ValueNotifier<EligibilityDecision?>(
      evaluateEligibility('2000-01-01'),
    );
    final router = createShowtimeRouter(eligibility: eligibility);
    addTearDown(() {
      router.dispose();
      eligibility.dispose();
    });

    for (final width in [360.0, 390.0, 430.0]) {
      await tester.binding.setSurfaceSize(Size(width, 800));
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            theme: MidnightThemeData.apply(),
            routerConfig: router,
          ),
        ),
      );
      router.go('/home');
      await tester.pumpAndSettle();
      expect(find.text('Discover'), findsWidgets);
      expect(find.text('Challenges'), findsOneWidget);
      expect(find.text('Pitches'), findsOneWidget);
      expect(find.text('Squad'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('dock stays compact instead of expanding to the viewport', (
    tester,
  ) async {
    final eligibility = ValueNotifier<EligibilityDecision?>(
      evaluateEligibility('2000-01-01'),
    );
    final router = createShowtimeRouter(eligibility: eligibility);
    addTearDown(() {
      router.dispose();
      eligibility.dispose();
      tester.binding.setSurfaceSize(null);
    });

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: MidnightThemeData.apply(),
          routerConfig: router,
        ),
      ),
    );
    router.go('/home');
    await tester.pumpAndSettle();

    final dock = find.byKey(const ValueKey('stitch-navigation-dock'));
    expect(dock, findsOneWidget);
    expect(tester.getSize(dock).height, 68);
  });

  testWidgets('dock destination selection is exposed semantically', (
    tester,
  ) async {
    final eligibility = ValueNotifier<EligibilityDecision?>(
      evaluateEligibility('2000-01-01'),
    );
    final router = createShowtimeRouter(eligibility: eligibility);
    addTearDown(() {
      router.dispose();
      eligibility.dispose();
    });
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: MidnightThemeData.apply(),
          routerConfig: router,
        ),
      ),
    );
    router.go('/home');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pitches'));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/pitches');
    expect(find.text('Pitches'), findsWidgets);
  });

  for (final scale in [1.5, 2.0]) {
    testWidgets('dock accommodates text at ${scale}x', (tester) async {
      final eligibility = ValueNotifier<EligibilityDecision?>(
        evaluateEligibility('2000-01-01'),
      );
      final router = createShowtimeRouter(eligibility: eligibility);
      addTearDown(() {
        router.dispose();
        eligibility.dispose();
        tester.binding.setSurfaceSize(null);
      });
      await tester.binding.setSurfaceSize(const Size(360, 800));
      router.go('/pitches');
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            theme: MidnightThemeData.apply(),
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final dock = find.byKey(const ValueKey('stitch-navigation-dock'));
      final dockRect = tester.getRect(dock);
      for (final label in ['Discover', 'Challenges', 'Pitches', 'Squad']) {
        final text = find.descendant(of: dock, matching: find.text(label));
        expect(dockRect.contains(tester.getRect(text).bottomRight), isTrue);
        expect(
          tester.renderObject<RenderParagraph>(text).didExceedMaxLines,
          isFalse,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [360.0, 390.0, 430.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('dock labels remain readable at $width and ${scale}x', (
        tester,
      ) async {
        final eligibility = ValueNotifier<EligibilityDecision?>(
          evaluateEligibility('2000-01-01'),
        );
        final router = createShowtimeRouter(eligibility: eligibility);
        addTearDown(router.dispose);
        addTearDown(eligibility.dispose);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(Size(width, 800));
        router.go('/pitches');
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              theme: MidnightThemeData.apply(),
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final dock = find.byKey(const ValueKey('stitch-navigation-dock'));
        for (final label in ['Discover', 'Challenges', 'Pitches', 'Squad']) {
          final text = find.descendant(of: dock, matching: find.text(label));
          expect(
            tester.renderObject<RenderParagraph>(text).didExceedMaxLines,
            isFalse,
            reason: '$label must be readable at $width / $scale',
          );
          if (scale > 1.2) {
            expect(
              tester
                  .renderObject<RenderParagraph>(text)
                  .getBoxesForSelection(
                    TextSelection(baseOffset: 0, extentOffset: label.length),
                  ),
              hasLength(1),
              reason: '$label must not split across lines at $width / $scale',
            );
          }
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
