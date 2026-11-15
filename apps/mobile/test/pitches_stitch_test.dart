import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtime_mobile/app/navigation/app_router.dart';
import 'package:showtime_mobile/core/discovery/local_fixtures.dart';
import 'package:showtime_mobile/core/eligibility/eligibility.dart';
import 'package:showtime_mobile/core/discovery/local_models.dart';
import 'package:showtime_mobile/core/discovery/pitch_preview_fixtures.dart';
import 'package:showtime_mobile/screens/pitches/pitches_controller.dart';
import 'package:showtime_mobile/screens/pitches/pitches_screen.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

void main() {
  testWidgets(
    'sample thumbnails are mapped to cards without changing shared fixtures',
    (tester) async {
      const images = {
        'venue-001': 'assets/images/sample_pitch_floodlit_turf.png',
        'venue-002': 'assets/images/sample_pitch_stadium_grass.png',
        'venue-003': 'assets/images/sample_pitch_indoor_court.png',
        'pitch-venue-004': 'assets/images/sample_pitch_stadium_grass.png',
      };
      final sharedBefore = LocalFixtures.load().venues;
      pitchPreviewFixtures();
      final sharedAfter = LocalFixtures.load().venues;
      expect(
        sharedBefore.map((venue) => venue.imageAsset),
        everyElement('assets/images/placeholder.png'),
      );
      expect(
        sharedAfter.map((venue) => venue.imageAsset),
        sharedBefore.map((venue) => venue.imageAsset),
      );

      await tester.binding.setSurfaceSize(const Size(390, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: MidnightThemeData.apply(),
            home: const PitchesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final entry in images.entries) {
        final card = find.byKey(ValueKey('venue-${entry.key}'));
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        final image = tester.widget<Image>(
          find.descendant(of: card, matching: find.byType(Image)),
        );
        expect((image.image as AssetImage).assetName, entry.value);
        expect(image.semanticLabel, 'Illustrative sample image');
        expect(image.errorBuilder, isNotNull);
        expect(
          find.descendant(of: card, matching: find.textContaining('Sample ·')),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('missing preview image shows the sample fallback', (
    tester,
  ) async {
    final original = pitchPreviewFixtures().first;
    final venue = PitchVenue(
      id: 'unknown-venue',
      name: original.name,
      address: original.address,
      distanceKm: original.distanceKm,
      format: original.format,
      surface: original.surface,
      source: original.source,
      slots: original.slots,
      imageAsset: 'assets/images/not-present.png',
    );
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pitchesControllerProvider.overrideWith(
            (ref) => PitchesController([venue]),
          ),
        ],
        child: MaterialApp(
          theme: MidnightThemeData.apply(),
          home: const PitchesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.stadium_outlined), findsOneWidget);
    expect(find.text('Sample · Pitch'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('combined filters use full dates and discard stale selections', () {
    final controller = PitchesController(pitchPreviewFixtures());
    addTearDown(controller.dispose);
    final slot = controller.state.venues.first.slots.first;
    controller.selectSlot(slot);
    controller.search(' ÍNDICO ');
    controller.selectDate(DateTime(2026, 12, 7));
    controller.selectFormat(FootballFormat.fiveAside);
    controller.selectSurface(SurfaceType.artificial);
    controller.selectDistance(2);
    expect(controller.state.venues.single.slots.single.id, 'pitch-006');
    expect(controller.state.selectedSlot, isNull);
    controller.selectDate(DateTime(2027, 11, 7));
    expect(controller.state.venues.single.slots.single.id, 'pitch-007');
    controller.selectSurface(SurfaceType.indoor);
    expect(controller.state.venues, isEmpty);
    controller.clearFilters();
    expect(controller.state.venues.length, 4);
  });

  test('date sample option counts honor all other filters and slot states', () {
    final controller = PitchesController(pitchPreviewFixtures());
    addTearDown(controller.dispose);
    final nov7 = DateTime(2026, 11, 7);
    final nov8 = DateTime(2026, 11, 8);
    expect(controller.state.sampleOptionsForDate(nov7), 4);
    expect(
      controller.state.sampleOptionsForDate(nov8),
      1,
    ); // Sold-out excluded.
    controller.selectDate(nov8);
    expect(controller.state.sampleOptionsForDate(nov7), 4);
    controller.search(' ÍNDICO ');
    controller.selectFormat(FootballFormat.fiveAside);
    controller.selectSurface(SurfaceType.artificial);
    controller.selectDistance(2);
    expect(controller.state.sampleOptionsForDate(nov7), 3);
    expect(controller.state.sampleOptionsForDate(DateTime(2026, 12, 7)), 1);
    expect(controller.state.sampleOptionsForDate(DateTime(2027, 11, 7)), 1);
    expect(controller.state.sampleOptionsForDate(nov8), 0);
    controller.selectDate(nov7);
    final venue = controller.state.venues.first;
    controller.selectSlot(venue.slots.first);
    expect(controller.reserve(venue, venue.slots.first), isTrue);
    expect(controller.state.sampleOptionsForDate(nov7), 2);
    controller.selectDistance(1);
    expect(controller.state.sampleOptionsForDate(nov7), 0);
    controller.selectDistance(2);
    controller.selectSurface(SurfaceType.indoor);
    expect(controller.state.sampleOptionsForDate(nov7), 0);
    controller.selectSurface(SurfaceType.artificial);
    controller.selectFormat(FootballFormat.sevenAside);
    expect(controller.state.sampleOptionsForDate(nov7), 0);
  });

  testWidgets('date counts update with search and expose sample options', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: MidnightThemeData.apply(),
          home: const PitchesScreen(),
        ),
      ),
    );
    final day = find.byKey(
      ValueKey('date-${DateTime(2026, 11, 7).toIso8601String()}'),
    );
    expect(
      tester.getSemantics(day).label,
      'Saturday, November 7, 2026, 4 sample options (available, pending or external)',
    );
    await tester.enterText(find.byType(TextField), 'Riverside');
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(day).label,
      'Saturday, November 7, 2026, 1 sample option (available, pending or external)',
    );
    expect(
      find.descendant(of: day, matching: find.text('1 option')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  for (final scale in [1.5, 2.0]) {
    testWidgets('sample thumbnail label is fully below image at ${scale}x', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: MidnightThemeData.apply(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const PitchesScreen(),
          ),
        ),
      );
      final label = find.text('Sample · Pitch 4');
      await tester.scrollUntilVisible(
        label,
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      final card = find.byKey(const ValueKey('venue-venue-001'));
      final image = find.descendant(of: card, matching: find.byType(Image));
      expect(
        tester.getRect(label).top,
        greaterThanOrEqualTo(tester.getRect(image).bottom),
      );
      expect(
        tester.getRect(card).contains(tester.getRect(label).bottomRight),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });
  }

  test(
    'alternative dates respect all other filters and full date identity',
    () {
      final controller = PitchesController(pitchPreviewFixtures());
      addTearDown(controller.dispose);
      controller.search(' ÍNDICO ');
      controller.selectFormat(FootballFormat.fiveAside);
      controller.selectSurface(SurfaceType.artificial);
      controller.selectDistance(2);
      controller.selectDate(DateTime(2026, 11, 8));
      expect(controller.state.venues, isEmpty);
      expect(controller.state.alternativeDates, [
        DateTime(2026, 11, 7),
        DateTime(2026, 12, 7),
        DateTime(2027, 11, 7),
      ]);
      controller.selectDistance(1);
      expect(controller.state.alternativeDates, isEmpty);
      controller.selectDistance(2);
      controller.selectSurface(SurfaceType.indoor);
      expect(controller.state.alternativeDates, isEmpty);
      controller.selectSurface(SurfaceType.artificial);
      controller.selectFormat(FootballFormat.sevenAside);
      expect(controller.state.alternativeDates, isEmpty);
      controller.selectFormat(FootballFormat.fiveAside);
      controller.search('unknown');
      expect(controller.state.alternativeDates, isEmpty);
    },
  );

  test('only selected native sample slots can be reserved', () {
    final controller = PitchesController(pitchPreviewFixtures());
    addTearDown(controller.dispose);
    final native = controller.state.venues.first;
    final first = native.slots.first;
    expect(controller.reserve(native, first), isFalse);
    controller.selectSlot(first);
    expect(controller.reserve(native, first), isTrue);
    expect(controller.state.stateFor(first), SlotState.confirmed);
    final external = controller.state.venues[1];
    controller.selectSlot(external.slots.first);
    expect(controller.reserve(external, external.slots.first), isFalse);
    expect(pitchSplitEstimate(native, first), 4);
    expect(
      pitchSplitEstimate(
        controller.state.venues[2],
        controller.state.venues[2].slots.first,
      ),
      isNull,
    );
    final reopened = PitchesController(pitchPreviewFixtures());
    addTearDown(reopened.dispose);
    expect(reopened.state.stateFor(first), SlotState.available);
  });

  test('reservation and selection use canonical visible venue and slot', () {
    final controller = PitchesController(pitchPreviewFixtures());
    addTearDown(controller.dispose);
    final native = controller.state.venues[0];
    final external = controller.state.venues[1];
    final unavailable = controller.state.venues[2];
    final externalSlot = external.slots.first;
    final forgedExternal = PitchVenue(
      id: external.id,
      name: external.name,
      address: external.address,
      distanceKm: external.distanceKm,
      format: external.format,
      surface: external.surface,
      source: VenueSource.native,
      slots: external.slots,
      imageAsset: external.imageAsset,
    );
    controller.selectSlot(externalSlot);
    expect(
      controller.reserve(
        forgedExternal,
        externalSlot.copyWith(state: SlotState.available),
      ),
      isFalse,
    );
    expect(controller.state.stateFor(externalSlot), SlotState.external);

    final soldOut = unavailable.slots.single;
    final forgedAvailable = soldOut.copyWith(state: SlotState.available);
    controller.selectSlot(forgedAvailable);
    expect(controller.state.selectedSlot, externalSlot.id);
    expect(controller.reserve(unavailable, forgedAvailable), isFalse);
    expect(controller.state.stateFor(soldOut), SlotState.soldOut);

    final first = native.slots.first;
    controller.selectSlot(first);
    expect(controller.reserve(native, native.slots[1]), isFalse);
    expect(controller.reserve(external, first), isFalse);
    controller.selectDate(DateTime(2026, 12, 7));
    expect(controller.state.selectedSlot, isNull);
    controller.selectSlot(first);
    expect(controller.state.selectedSlot, isNull);
    expect(controller.reserve(native, first), isFalse);
    controller.selectDate(null);
    controller.selectSlot(first);
    expect(
      controller.reserve(native, first.copyWith(state: SlotState.soldOut)),
      isTrue,
    );
    expect(controller.reserve(native, first), isFalse);
    expect(controller.state.stateFor(first), SlotState.confirmed);
  });

  test(
    'forged available slot cannot reserve a canonical unavailable selection',
    () {
      final venues = pitchPreviewFixtures();
      final unavailable = venues[2];
      final soldOut = unavailable.slots.single;
      final controller = PitchesController(venues, initialSlot: soldOut.id);
      addTearDown(controller.dispose);
      expect(
        controller.reserve(
          unavailable,
          soldOut.copyWith(state: SlotState.available),
        ),
        isFalse,
      );
      expect(controller.state.stateFor(soldOut), SlotState.soldOut);
      expect(controller.state.slotStates, isEmpty);
    },
  );

  test('pending, unavailable and changing prices behave locally', () {
    final controller = PitchesController(pitchPreviewFixtures());
    addTearDown(controller.dispose);
    final venue = controller.state.venues.first;
    final pending = venue.slots[1];
    controller.selectSlot(pending);
    expect(pitchSplitEstimate(venue, pending), 4.5);
    expect(controller.reserve(venue, pending), isTrue);
    final soldOut = controller.state.venues[2].slots.single;
    controller.selectSlot(soldOut);
    expect(controller.state.selectedSlot, pending.id);
    controller.retry();
    controller.notify();
    expect(controller.state.retryMessage, 'Local preview data retained.');
    expect(controller.state.notified, isTrue);
  });

  testWidgets('selection, price, semantics and local actions', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: MidnightThemeData.apply(),
          home: const PitchesScreen(),
        ),
      ),
    );
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.text('Local preview data retained.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('slot-slot-001')),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('slot-slot-001')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('slot-slot-001')));
    await tester.pump();
    expect(find.textContaining('€40 total'), findsOneWidget);
    expect(find.text('~€4.00 per player estimate'), findsOneWidget);
    expect(find.byKey(const ValueKey('selected-cost')), findsOneWidget);
    await tester.ensureVisible(find.text('Campo do Oriente'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('Campo do Oriente')),
      matchesSemantics(isHeader: true, label: 'Campo do Oriente'),
    );
    await tester.ensureVisible(find.byKey(const ValueKey('slot-slot-001')));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.byKey(const ValueKey('slot-slot-001'))),
      matchesSemantics(
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        label: 'Saturday, November 7, 2026, 18:00, €40, Available sample, Best price',
      ),
    );
    await tester.tap(find.byKey(const ValueKey('slot-slot-002')));
    await tester.pump();
    expect(find.textContaining('€45 total'), findsOneWidget);
    expect(find.text('~€4.50 per player estimate'), findsOneWidget);
    expect(find.text('~€4.00 per player estimate'), findsNothing);
    expect(find.text('Pending sample'), findsOneWidget);
    final reserve = find.text('Reserve demo slot · 20:00 · €45');
    await tester.ensureVisible(reserve);
    await tester.pumpAndSettle();
    final nativeButton = find.ancestor(
      of: reserve,
      matching: find.byType(FilledButton),
    );
    final nativeCard = find.byKey(const ValueKey('venue-venue-001'));
    expect(
      tester.getSize(nativeButton).width,
      tester.getSize(nativeCard).width - 30,
    );
    final nativeStyle = tester.widget<FilledButton>(nativeButton).style;
    expect(nativeStyle?.backgroundColor?.resolve({}), Colors.transparent);
    final decorated = tester.widget<DecoratedBox>(
      find
          .ancestor(of: nativeButton, matching: find.byType(DecoratedBox))
          .first,
    );
    final gradient =
        (decorated.decoration as BoxDecoration).gradient! as LinearGradient;
    final foreground = nativeStyle!.foregroundColor!.resolve({})!;
    // Sample the whole gradient, including the actual Flutter pressed overlay.
    for (final states in <Set<WidgetState>>[
      {},
      {WidgetState.pressed},
    ]) {
      final overlay = nativeStyle.overlayColor!.resolve(states)!;
      for (var i = 0; i <= 100; i++) {
        final background = Color.alphaBlend(
          overlay,
          Color.lerp(gradient.colors.first, gradient.colors.last, i / 100)!,
        );
        final l1 = foreground.computeLuminance();
        final l2 = background.computeLuminance();
        final ratio =
            (l1 > l2 ? l1 + 0.05 : l2 + 0.05) /
            (l1 > l2 ? l2 + 0.05 : l1 + 0.05);
        expect(ratio, greaterThanOrEqualTo(4.5));
      }
    }
    expect(
      find.descendant(of: nativeCard, matching: find.text('Floodlights')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: nativeCard,
        matching: find.byIcon(Icons.lightbulb_outline),
      ),
      findsOneWidget,
    );
    await tester.tap(reserve);
    await tester.pump();
    expect(
      find.textContaining('no provider reservation was made'),
      findsOneWidget,
    );
    expect(find.text('Confirmed in demo'), findsWidgets);
    semantics.dispose();
  });

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('slot rows remain aligned at ${scale}x text', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: MidnightThemeData.apply(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const PitchesScreen(),
          ),
        ),
      );
      await tester.tap(
        find.byKey(ValueKey('date-${DateTime(2026, 11, 7).toIso8601String()}')),
      );
      await tester.pumpAndSettle();
      final first = find.byKey(const ValueKey('slot-slot-001'));
      final second = find.byKey(const ValueKey('slot-slot-002'));
      await tester.scrollUntilVisible(
        first,
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(first).top, tester.getRect(second).top);
      expect(tester.getRect(first).bottom, tester.getRect(second).bottom);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('date strips scroll and best price excludes unavailable slots', (
    tester,
  ) async {
    final original = pitchPreviewFixtures().first;
    PitchSlot slot(String id, int day, int hour, int price, SlotState status) =>
        PitchSlot(
          id: id,
          startsAt: DateTime(2026, 11, day, hour),
          endsAt: DateTime(2026, 11, day, hour + 1),
          price: price,
          state: status,
        );
    final venue = original.copyWith(
      slots: [
        slot('cheap-sold', 7, 17, 5, SlotState.soldOut),
        slot('first', 7, 18, 30, SlotState.available),
        slot('tie', 7, 19, 30, SlotState.pending),
        slot('later', 7, 20, 50, SlotState.available),
        slot('next-day', 8, 18, 10, SlotState.available),
      ],
    );
    final semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pitchesControllerProvider.overrideWith(
            (ref) => PitchesController([venue]),
          ),
        ],
        child: MaterialApp(
          theme: MidnightThemeData.apply(),
          home: const PitchesScreen(),
        ),
      ),
    );
    final strip = find.byKey(
      ValueKey(
        'slot-strip-${venue.id}-${DateTime(2026, 11, 7).toIso8601String()}',
      ),
    );
    await tester.scrollUntilVisible(
      strip,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Slots (Saturday, November 7, 2026)'), findsOneWidget);
    expect(find.text('Slots (Sunday, November 8, 2026)'), findsOneWidget);
    expect(find.byKey(const ValueKey('best-price-cheap-sold')), findsNothing);
    expect(find.byKey(const ValueKey('best-price-first')), findsOneWidget);
    expect(find.byKey(const ValueKey('best-price-tie')), findsOneWidget);
    expect(find.byKey(const ValueKey('best-price-next-day')), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('slot-cheap-sold'))),
      isSemantics(isButton: true, isEnabled: false),
    );
    expect(
      tester.getSemantics(find.byKey(const ValueKey('slot-cheap-sold'))).label,
      contains('Unavailable sample'),
    );
    final scrollable = find.descendant(
      of: strip,
      matching: find.byType(Scrollable),
    );
    final before = tester.state<ScrollableState>(scrollable).position.pixels;
    await tester.drag(strip, const Offset(-240, 0));
    await tester.pumpAndSettle();
    expect(
      tester.state<ScrollableState>(scrollable).position.pixels,
      greaterThan(before),
    );
    await tester.tap(find.byKey(const ValueKey('slot-later')));
    await tester.pumpAndSettle();
    expect(find.text('€50 total'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('initial sample selection and disclosed filters remain usable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: MidnightThemeData.apply(),
          home: const PitchesScreen(),
        ),
      ),
    );
    expect(find.text('€40 total'), findsOneWidget);
    expect(find.text('Reserve demo slot · 18:00 · €40'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('more-filters')));
    await tester.pumpAndSettle();
    expect(find.text('Maximum distance: 10 km'), findsOneWidget);
    await tester.ensureVisible(find.text('Futsal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Futsal'));
    await tester.pumpAndSettle();
    expect(find.text('Demo venues (1)'), findsOneWidget);
    expect(find.text('€40 total'), findsNothing);
    await tester.tap(find.text('All formats'));
    await tester.pumpAndSettle();
    expect(find.text('Demo venues (4)'), findsOneWidget);
  });

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('telemetry and filter disclosure are accessible at ${scale}x', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: MidnightThemeData.apply(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const PitchesScreen(),
          ),
        ),
      );
      final telemetry = find.byKey(const ValueKey('demo-telemetry'));
      expect(tester.getRect(telemetry).width, 360);
      expect(
        find.text('Sample pitches and slots · not live availability'),
        findsOneWidget,
      );
      if (scale > 1.25) {
        expect(find.text('Search pitches or address'), findsOneWidget);
        expect(
          tester.getSemantics(find.byType(TextField)).label,
          contains('Search pitches or address'),
        );
      }
      final retry = find.widgetWithText(TextButton, 'Retry');
      expect(tester.getSize(retry).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(retry).height, greaterThanOrEqualTo(44));
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(find.text('Local preview data retained.'), findsOneWidget);
      final filter = find.byKey(const ValueKey('more-filters'));
      await tester.ensureVisible(filter);
      await tester.pumpAndSettle();
      expect(tester.getSize(filter), const Size(48, 48));
      final node = tester.getSemantics(filter);
      expect(node.label, 'More filters');
      expect(
        node,
        isSemantics(
          hasTapAction: true,
          hasExpandedState: true,
          isExpanded: false,
        ),
      );
      await tester.tap(filter);
      await tester.pumpAndSettle();
      expect(tester.getSemantics(filter), isSemantics(isExpanded: true));
      await tester.scrollUntilVisible(
        find.text('Futsal'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Futsal'));
      await tester.pumpAndSettle();
      expect(find.text('Demo venues (1)'), findsOneWidget);
      await tester.ensureVisible(filter);
      await tester.pumpAndSettle();
      expect(tester.getSemantics(filter).hint, 'Additional filters active');
      await tester.tap(filter);
      await tester.pumpAndSettle();
      expect(tester.getSemantics(filter), isSemantics(isExpanded: false));
      expect(tester.getSemantics(filter).hint, 'Additional filters active');
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('external action reports disconnected provider', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: MidnightThemeData.apply(),
          home: const PitchesScreen(),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Riverside');
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Provider information'));
    await tester.pumpAndSettle();
    final externalButton = find.ancestor(
      of: find.text('Provider information'),
      matching: find.byType(OutlinedButton),
    );
    expect(
      tester.getSize(externalButton).width,
      tester.getSize(find.byKey(const ValueKey('venue-venue-002'))).width - 30,
    );
    await tester.tap(find.text('Provider information'));
    await tester.pump();
    expect(
      find.text('Provider access is not connected in this demo.'),
      findsOneWidget,
    );
  });

  testWidgets('alternative date and alert remain local', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: MidnightThemeData.apply(),
          home: const PitchesScreen(),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Alvalade');
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('date-${DateTime(2026, 11, 7).toIso8601String()}')),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Try demo alert'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(find.text('Try demo alert'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try demo alert'));
    await tester.pump();
    expect(
      find.text('Demo only: no real alert is registered or delivered.'),
      findsOneWidget,
    );
    expect(find.text('Alternative sample dates'), findsOneWidget);
    expect(
      find.byKey(
        ValueKey('alternative-${DateTime(2026, 11, 7).toIso8601String()}'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        ValueKey('alternative-${DateTime(2026, 12, 7).toIso8601String()}'),
      ),
      findsNothing,
    );
    final alternative = find.text('Sunday, November 8, 2026');
    await tester.scrollUntilVisible(
      alternative,
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(alternative);
    await tester.pumpAndSettle();
    expect(find.text('Demo venues (1)'), findsOneWidget);
  });

  test('auto-disposed provider drops demo reservations', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subscription = container.listen(pitchesControllerProvider, (_, _) {});
    final controller = container.read(pitchesControllerProvider.notifier);
    final venue = controller.state.venues.first;
    controller.selectSlot(venue.slots.first);
    expect(controller.reserve(venue, venue.slots.first), isTrue);
    subscription.close();
    await container.pump();
    final reopened = container.listen(pitchesControllerProvider, (_, _) {});
    expect(reopened.read().stateFor(venue.slots.first), SlotState.available);
    reopened.close();
  });

  for (final width in [360.0, 390.0, 430.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('last pitch action clears dock at $width and ${scale}x', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(Size(width, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final eligibility = ValueNotifier<EligibilityDecision?>(
          evaluateEligibility('2000-01-01'),
        );
        final router = createShowtimeRouter(eligibility: eligibility);
        addTearDown(router.dispose);
        addTearDown(eligibility.dispose);
        router.go('/pitches');
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              theme: MidnightThemeData.apply(),
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  padding: const EdgeInsets.only(top: 44, bottom: 34),
                  viewPadding: const EdgeInsets.only(top: 44, bottom: 34),
                ),
                child: child!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final dock = find.byKey(const ValueKey('stitch-navigation-dock'));
        final card = find.byKey(const ValueKey('venue-pitch-venue-004'));
        final action = find.descendant(
          of: card,
          matching: find.widgetWithText(FilledButton, 'Select a demo slot'),
        );
        await tester.scrollUntilVisible(
          action,
          300,
          scrollable: find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(
          tester.getRect(action).bottom,
          lessThan(tester.getRect(dock).top),
        );
        expect(tester.getRect(dock).bottom, lessThanOrEqualTo(800 - 34));
        final slot = find.byKey(const ValueKey('slot-pitch-008'));
        await tester.ensureVisible(slot);
        await tester.pumpAndSettle();
        await tester.tap(slot);
        await tester.pumpAndSettle();
        final reserve = find.text('Reserve demo slot · 17:00 · €90');
        await tester.ensureVisible(reserve);
        await tester.pumpAndSettle();
        expect(
          tester.getRect(reserve).bottom,
          lessThan(tester.getRect(dock).top),
        );
        await tester.tap(reserve);
        await tester.pumpAndSettle();
        expect(find.text('Confirmed in demo'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final width in [360.0, 390.0, 430.0]) {
    testWidgets('actual shell remains reachable at $width and 1.5x', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final eligibility = ValueNotifier<EligibilityDecision?>(
        evaluateEligibility('2000-01-01'),
      );
      final router = createShowtimeRouter(eligibility: eligibility);
      addTearDown(router.dispose);
      addTearDown(eligibility.dispose);
      router.go('/pitches');
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            theme: MidnightThemeData.apply(),
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('stitch-navigation-dock')),
        findsOneWidget,
      );
      expect(find.text('Local demo'), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, -1800));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [360.0, 390.0, 430.0]) {
    testWidgets('local preview and empty recovery at $width', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: MidnightThemeData.apply(),
            home: const PitchesScreen(),
          ),
        ),
      );
      expect(find.text('Local demo'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'no matching venue');
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(find.text('No demo pitches match these filters'), findsOneWidget);
      expect(find.text('Alternative sample dates'), findsNothing);
      expect(
        find.byKey(
          ValueKey('alternative-${DateTime(2026, 11, 7).toIso8601String()}'),
        ),
        findsNothing,
      );
      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(find.text('Demo venues (4)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('empty recovery and selected cost fit enlarged text', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: MidnightThemeData.apply(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: const PitchesScreen(),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Alvalade');
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('date-${DateTime(2026, 11, 7).toIso8601String()}')),
    );
    await tester.pumpAndSettle();
    final alternative = find.byKey(
      ValueKey('alternative-${DateTime(2026, 11, 8).toIso8601String()}'),
    );
    await tester.scrollUntilVisible(
      alternative,
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(alternative),
      matchesSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
        label: 'Sunday, November 8, 2026',
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Clear filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    final slot = find.byKey(const ValueKey('slot-slot-001'));
    await tester.scrollUntilVisible(
      slot,
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(slot);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('selected-cost')));
    await tester.pumpAndSettle();
    expect(find.text('€40 total'), findsOneWidget);
    expect(find.text('~€4.00 per player estimate'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
