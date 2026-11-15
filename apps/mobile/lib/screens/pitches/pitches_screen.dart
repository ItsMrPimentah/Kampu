import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:showtime_mobile/core/discovery/local_models.dart';
import 'package:showtime_mobile/core/discovery/pitch_preview_fixtures.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

import 'pitches_controller.dart';

/// Local-only pitch scheduler.
class PitchesScreen extends HookConsumerWidget {
  const PitchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pitchesControllerProvider);
    final controller = ref.read(pitchesControllerProvider.notifier);
    final search = useTextEditingController();
    final moreFilters = useState(false);
    final tokens = context.midnight;
    final enlarged = MediaQuery.textScalerOf(context).scale(16) > 20;
    void clear() {
      search.clear();
      controller.clearFilters();
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pitches',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              'SMART SCHEDULER · AREA 01',
              style: TextStyle(color: tokens.steelLight, fontSize: 10),
            ),
          ],
        ),
      ),
      body: ListView(
        children: [
          _DemoTelemetry(
            message: state.retryMessage,
            onRetry: controller.retry,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.pageMargin,
              12,
              tokens.pageMargin,
              32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (enlarged) ...[
                  const Text('Search pitches or address'),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: enlarged ? 'Search pitches or address' : null,
                        child: TextField(
                          controller: search,
                          onChanged: controller.search,
                          decoration: InputDecoration(
                            labelText: enlarged
                                ? null
                                : 'Search pitches or address',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: state.query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    onPressed: () {
                                      search.clear();
                                      controller.search('');
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                            filled: true,
                            fillColor: tokens.carbon,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      button: true,
                      expanded: moreFilters.value,
                      label: 'More filters',
                      hint: state.format != null || state.maxDistance != 10
                          ? 'Additional filters active'
                          : 'Format and distance filters',
                      onTap: () => moreFilters.value = !moreFilters.value,
                      child: ExcludeSemantics(
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: OutlinedButton(
                            key: const ValueKey('more-filters'),
                            onPressed: () =>
                                moreFilters.value = !moreFilters.value,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              foregroundColor: tokens.frost,
                              backgroundColor:
                                  moreFilters.value ||
                                      state.format != null ||
                                      state.maxDistance != 10
                                  ? tokens.iris.withValues(alpha: 0.18)
                                  : tokens.carbon,
                              side: BorderSide(
                                color:
                                    moreFilters.value ||
                                        state.format != null ||
                                        state.maxDistance != 10
                                    ? tokens.periwinkle
                                    : tokens.gunmetal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Icon(Icons.tune),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _PitchPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'MATCH WINDOW',
                              style: tokens.labelStyle.copyWith(
                                color: tokens.steelLight,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => controller.selectDate(null),
                            child: const Text('Any date'),
                          ),
                        ],
                      ),
                      _DateStrip(state: state, controller: controller),
                      const SizedBox(height: 4),
                      Text(
                        'Sample options: available, pending or external',
                        style: TextStyle(
                          color: tokens.steelLight,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'ROSTER FORMAT',
                        style: tokens.labelStyle.copyWith(
                          color: tokens.steelLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          for (final format in [
                            FootballFormat.fiveAside,
                            FootballFormat.sevenAside,
                            FootballFormat.elevenAside,
                          ])
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: _chip(
                                  formatName(format),
                                  state.format == format,
                                  () => controller.selectFormat(format),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'SURFACE TYPE',
                        style: tokens.labelStyle.copyWith(
                          color: tokens.steelLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _chip(
                              'Any surface',
                              state.surface == null,
                              () => controller.selectSurface(null),
                            ),
                            ...SurfaceType.values.map(
                              (surface) => Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: _chip(
                                  surfaceName(surface),
                                  state.surface == surface,
                                  () => controller.selectSurface(surface),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${state.format == null ? 'All formats' : formatName(state.format!)} · ${state.maxDistance.toStringAsFixed(0)} km maximum',
                        style: TextStyle(
                          color: tokens.steelLight,
                          fontSize: 12,
                        ),
                      ),
                      if (moreFilters.value) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _chip(
                              'All formats',
                              state.format == null,
                              () => controller.selectFormat(null),
                            ),
                            _chip(
                              formatName(FootballFormat.futsal),
                              state.format == FootballFormat.futsal,
                              () => controller.selectFormat(
                                FootballFormat.futsal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Maximum distance: ${state.maxDistance.toStringAsFixed(0)} km',
                        ),
                        Slider(
                          value: state.maxDistance,
                          min: 2,
                          max: 10,
                          divisions: 4,
                          label: '${state.maxDistance.toStringAsFixed(0)} km',
                          onChanged: controller.selectDistance,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Demo venues (${state.venues.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (state.venues.isEmpty)
                  _EmptyPitches(
                    state: state,
                    controller: controller,
                    onClear: clear,
                  )
                else
                  ...state.venues.map(
                    (venue) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _VenueCard(
                        venue: venue,
                        state: state,
                        controller: controller,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) =>
      _ToggleTile(label: label, selected: selected, onTap: onTap);
}

class _DemoTelemetry extends StatelessWidget {
  const _DemoTelemetry({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.midnight;
    return Container(
      key: const ValueKey('demo-telemetry'),
      padding: EdgeInsets.symmetric(horizontal: tokens.pageMargin, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.carbon,
        border: Border(bottom: BorderSide(color: tokens.gunmetal)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: tokens.amber, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Local demo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Sample pitches and slots · not live availability',
                  style: TextStyle(color: tokens.steelLight, fontSize: 12),
                ),
                if (message != null)
                  Semantics(liveRegion: true, child: Text(message!)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: tokens.amber,
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              side: BorderSide(color: tokens.amber.withValues(alpha: 0.5)),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyPitches extends StatelessWidget {
  const _EmptyPitches({
    required this.state,
    required this.controller,
    required this.onClear,
  });

  final PitchesState state;
  final PitchesController controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final tokens = context.midnight;
    final alternatives = state.alternativeDates;
    return _PitchPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tokens.voidColor,
                  border: Border.all(
                    color: tokens.amber.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.event_busy, color: tokens.amber, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No demo pitches match these filters',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No matching sample venues',
                      style: TextStyle(
                        color: tokens.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alternatives.isEmpty
                          ? 'Adjust or clear your filters to see sample venues.'
                          : 'Adjust your filters or choose another sample date.',
                      style: TextStyle(color: tokens.steelLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (alternatives.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(color: tokens.gunmetal),
            const SizedBox(height: 8),
            const Text(
              'Alternative sample dates',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...alternatives.map(
              (date) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: ValueKey('alternative-${date.toIso8601String()}'),
                    onPressed: () => controller.selectDate(date),
                    style: tokens.secondaryButtonStyle.copyWith(
                      backgroundColor: WidgetStatePropertyAll(tokens.voidColor),
                    ),
                    child: Text(
                      MaterialLocalizations.of(context).formatFullDate(date),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: state.notified ? null : controller.notify,
              style: tokens.primaryButtonStyle,
              child: Text(
                state.notified ? 'Demo request noted' : 'Try demo alert',
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onClear,
              style: tokens.secondaryButtonStyle,
              child: const Text('Clear filters'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Demo only: no real alert is registered or delivered.',
            style: TextStyle(color: tokens.steelLight),
          ),
        ],
      ),
    );
  }
}

class _PitchPanel extends StatelessWidget {
  const _PitchPanel({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.midnight.carbon,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: context.midnight.gunmetal),
    ),
    child: child,
  );
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.midnight;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: tokens.textPrimary,
            backgroundColor: selected
                ? tokens.iris.withValues(alpha: 0.24)
                : tokens.voidColor,
            side: BorderSide(
              color: selected ? tokens.periwinkle : tokens.gunmetal,
              width: selected ? 1.5 : 1,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              if (selected)
                Icon(Icons.check, size: 16, color: tokens.periwinkle),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateStrip extends StatelessWidget {
  const _DateStrip({required this.state, required this.controller});
  final PitchesState state;
  final PitchesController controller;

  @override
  Widget build(BuildContext context) {
    final tokens = context.midnight;
    final localizations = MaterialLocalizations.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = ((constraints.maxWidth - 18) / 4).clamp(
          68.0 * scale,
          double.infinity,
        );
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: state.dates.map((date) {
              final selected =
                  state.date != null && sameDate(state.date!, date);
              final count = state.sampleOptionsForDate(date);
              final optionLabel = count == 1 ? 'option' : 'options';
              final label =
                  '${localizations.formatFullDate(date)}, $count sample $optionLabel '
                  '(available, pending or external)';
              return Padding(
                padding: EdgeInsets.only(
                  right: date == state.dates.last ? 0 : 6,
                ),
                child: Semantics(
                  key: ValueKey('date-${date.toIso8601String()}'),
                  button: true,
                  selected: selected,
                  label: label,
                  onTap: () => controller.selectDate(date),
                  child: ExcludeSemantics(
                    child: SizedBox(
                      width: tileWidth,
                      child: OutlinedButton(
                        onPressed: () => controller.selectDate(date),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: tokens.textPrimary,
                          backgroundColor: selected
                              ? tokens.iris.withValues(alpha: 0.24)
                              : tokens.voidColor,
                          side: BorderSide(
                            color: selected
                                ? tokens.periwinkle
                                : tokens.gunmetal,
                            width: selected ? 1.5 : 1,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 2,
                              children: [
                                if (selected)
                                  Icon(
                                    Icons.check,
                                    size: 14,
                                    color: tokens.periwinkle,
                                  ),
                                Text(
                                  const [
                                    'Mon',
                                    'Tue',
                                    'Wed',
                                    'Thu',
                                    'Fri',
                                    'Sat',
                                    'Sun',
                                  ][date.weekday - 1],
                                ),
                              ],
                            ),
                            Text(
                              '${date.day}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${date.month}/${date.year}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: tokens.steelLight,
                                fontSize: scale > 1.2 ? 10 : 11,
                              ),
                            ),
                            Text(
                              '$count $optionLabel',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: tokens.steelLight,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _VenueCard extends StatelessWidget {
  const _VenueCard({
    required this.venue,
    required this.state,
    required this.controller,
  });
  final PitchVenue venue;
  final PitchesState state;
  final PitchesController controller;

  @override
  Widget build(BuildContext context) {
    final tokens = context.midnight;
    final selected = venue.slots
        .where((slot) => slot.id == state.selectedSlot)
        .firstOrNull;
    final split = selected == null ? null : pitchSplitEstimate(venue, selected);
    final details = pitchPreviewDetails[venue.id];
    return _PitchPanel(
      key: ValueKey('venue-${venue.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StitchStatusPill(
            label: venue.source == VenueSource.native
                ? 'Native demo'
                : 'External demo',
            tone: venue.source == VenueSource.native
                ? StitchStatusTone.success
                : StitchStatusTone.neutral,
          ),
          const SizedBox(height: 8),
          Semantics(
            container: true,
            header: true,
            child: Text(
              venue.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${venue.distanceKm} km · ${formatName(venue.format)} · ${surfaceName(venue.surface)}\n${venue.address}',
            style: tokens.monoStyle.copyWith(
              color: tokens.steelLight,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          _VenueDetails(venue: venue, details: details),
          const SizedBox(height: 12),
          _SlotGrid(venue: venue, state: state, controller: controller),
          if (selected != null) ...[
            const SizedBox(height: 10),
            Container(
              key: const ValueKey('selected-cost'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: tokens.voidColor,
                border: Border.all(color: tokens.gunmetal),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(
                    '€${selected.price} total',
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (split != null)
                    Text(
                      '~€${split.toStringAsFixed(2)} per player estimate',
                      style: TextStyle(
                        color: tokens.periwinkle,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (venue.source == VenueSource.external)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Provider access is not connected in this demo.',
                    ),
                  ),
                ),
                style: tokens.secondaryButtonStyle,
                icon: const Icon(Icons.link, size: 18),
                label: const Text('Provider information'),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient:
                      selected != null &&
                          [
                            SlotState.available,
                            SlotState.pending,
                          ].contains(state.stateFor(selected))
                      // Keep the iris gradient while providing 4.5:1 contrast
                      // for its dark label at both ends and between them.
                      ? LinearGradient(
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                          colors: [
                            Color.alphaBlend(
                              tokens.periwinkle.withValues(alpha: 0.3),
                              tokens.iris,
                            ),
                            tokens.periwinkle,
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FilledButton(
                  style: tokens.primaryButtonStyle.copyWith(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.disabled)
                          ? tokens.gunmetal
                          : Colors.transparent,
                    ),
                    overlayColor: WidgetStatePropertyAll(
                      tokens.textPrimary.withValues(alpha: 0.12),
                    ),
                  ),
                  onPressed:
                      selected == null ||
                          ![
                            SlotState.available,
                            SlotState.pending,
                          ].contains(state.stateFor(selected))
                      ? null
                      : () {
                          if (controller.reserve(venue, selected)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Selection confirmed in this demo only; no provider reservation was made.',
                                ),
                              ),
                            );
                          }
                        },
                  child: Text(
                    selected == null
                        ? 'Select a demo slot'
                        : state.stateFor(selected) == SlotState.confirmed
                        ? 'Confirmed in demo'
                        : 'Reserve demo slot · ${_time(selected.startsAt)} · €${selected.price}',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VenueDetails extends StatelessWidget {
  const _VenueDetails({required this.venue, required this.details});

  final PitchVenue venue;
  final PitchPreviewDetails? details;

  @override
  Widget build(BuildContext context) {
    final tokens = context.midnight;
    final enlarged = MediaQuery.textScalerOf(context).scale(10) > 10;
    final label = 'Sample · ${details?.pitch ?? 'Pitch'}';
    final thumbnail = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 100,
        height: 80,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              details?.sampleImageAsset ?? venue.imageAsset,
              fit: BoxFit.cover,
              semanticLabel: 'Illustrative sample image',
              errorBuilder: (_, _, _) => ColoredBox(
                color: tokens.voidColor,
                child: Icon(Icons.stadium_outlined, color: tokens.steelLight),
              ),
            ),
            if (!enlarged)
              Positioned(
                left: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.voidColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    final amenities = details?.amenities ?? const <String>[];
    Widget detailColumn() => Column(
      spacing: 6,
      children: amenities
          .map(
            (amenity) => SizedBox(
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: tokens.voidColor,
                  border: Border.all(color: tokens.gunmetal),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      _amenityIcon(amenity),
                      size: 15,
                      color: tokens.periwinkle,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        amenity,
                        style: tokens.monoStyle.copyWith(
                          color: tokens.steelLight,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );

    if (enlarged) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          thumbnail,
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          detailColumn(),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        thumbnail,
        const SizedBox(width: 12),
        Expanded(child: detailColumn()),
      ],
    );
  }
}

IconData _amenityIcon(String amenity) => switch (amenity) {
  'Floodlights' => Icons.lightbulb_outline,
  'Changing rooms' || 'Showers and lockers' => Icons.shower_outlined,
  'Parking' => Icons.local_parking_outlined,
  'Turf boots' || 'Non-marking shoes' => Icons.sports_soccer_outlined,
  'Grass pitch' => Icons.grass_outlined,
  'Indoor court' => Icons.roofing_outlined,
  _ => Icons.info_outline,
};

class _SlotGrid extends StatelessWidget {
  const _SlotGrid({
    required this.venue,
    required this.state,
    required this.controller,
  });
  final PitchVenue venue;
  final PitchesState state;
  final PitchesController controller;

  @override
  Widget build(BuildContext context) {
    final tokens = context.midnight;
    final localizations = MaterialLocalizations.of(context);
    final slots = [...venue.slots]
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final dates = <DateTime, List<PitchSlot>>{};
    for (final slot in slots) {
      final date = DateTime(
        slot.startsAt.year,
        slot.startsAt.month,
        slot.startsAt.day,
      );
      dates.putIfAbsent(date, () => []).add(slot);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in dates.entries) ...[
          if (entry.key != dates.keys.first) const SizedBox(height: 12),
          Text(
            'Slots (${localizations.formatFullDate(entry.key)})',
            style: tokens.labelStyle.copyWith(color: tokens.steelLight),
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(1);
              final width = ((constraints.maxWidth - 16) / 3).clamp(
                104.0 * (scale > 1 ? scale : 1),
                double.infinity,
              );
              final eligible = entry.value.where((slot) {
                final status = state.stateFor(slot);
                return status != SlotState.soldOut &&
                    status != SlotState.confirmed;
              });
              final bestPrice = eligible.isEmpty
                  ? null
                  : eligible
                        .map((slot) => slot.price)
                        .reduce((a, b) => a < b ? a : b);
              return SingleChildScrollView(
                key: ValueKey(
                  'slot-strip-${venue.id}-${entry.key.toIso8601String()}',
                ),
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final slot in entry.value) ...[
                      if (slot != entry.value.first) const SizedBox(width: 8),
                      _slot(context, slot, width, bestPrice),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _slot(
    BuildContext context,
    PitchSlot slot,
    double width,
    int? bestPrice,
  ) {
    final tokens = context.midnight;
    final status = state.stateFor(slot);
    final selected = state.selectedSlot == slot.id;
    final enabled = status != SlotState.soldOut;
    final best =
        bestPrice != null &&
        slot.price == bestPrice &&
        status != SlotState.soldOut &&
        status != SlotState.confirmed;
    final statusLabel = switch (status) {
      SlotState.available => 'Available sample',
      SlotState.pending => 'Pending sample',
      SlotState.confirmed => 'Confirmed in demo',
      SlotState.external => 'External sample',
      SlotState.soldOut => 'Unavailable sample',
    };
    final date = MaterialLocalizations.of(context)
        .formatFullDate(slot.startsAt);
    final badgeHeight = MediaQuery.textScalerOf(context).scale(10) * 1.4 + 8;
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: EdgeInsets.only(top: badgeHeight / 2),
                child: SizedBox(
                  width: double.infinity,
                  child: Semantics(
                    key: ValueKey('slot-${slot.id}'),
                    button: true,
                    selected: selected,
                    enabled: enabled,
                    onTap: enabled ? () => controller.selectSlot(slot) : null,
                    label:
                        '$date, ${_time(slot.startsAt)}, €${slot.price}, $statusLabel${best ? ', Best price' : ''}',
                    child: ExcludeSemantics(
                      child: OutlinedButton(
                        onPressed: enabled
                            ? () => controller.selectSlot(slot)
                            : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: tokens.textPrimary,
                          disabledForegroundColor: tokens.steelLight,
                          backgroundColor: selected
                              ? tokens.iris.withValues(alpha: 0.24)
                              : tokens.voidColor,
                          side: BorderSide(
                            color: selected
                                ? tokens.periwinkle
                                : tokens.gunmetal,
                            width: selected ? 1.5 : 1,
                          ),
                          padding: EdgeInsets.fromLTRB(
                            4,
                            badgeHeight / 2 + 6,
                            4,
                            8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _time(slot.startsAt),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '€${slot.price}',
                              style: TextStyle(color: tokens.steelLight),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (best)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ExcludeSemantics(
                    child: Center(
                      child: Container(
                        key: ValueKey('best-price-${slot.id}'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.periwinkle,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Best price',
                          style: TextStyle(
                            color: tokens.voidColor,
                            fontSize: 10,
                            height: 1.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (status != SlotState.available) ...[
            const SizedBox(height: 4),
            ExcludeSemantics(
              child: Text(
                statusLabel,
                textAlign: TextAlign.center,
                style: TextStyle(color: tokens.steelLight, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _time(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
