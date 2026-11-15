import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:showtime_mobile/core/discovery/local_models.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

import 'pitches_controller.dart';

class PitchesScreen extends HookConsumerWidget {
  const PitchesScreen({super.key});

  void _reserve(
    BuildContext context,
    PitchesController controller,
    PitchVenue venue,
    PitchSlot slot,
  ) {
    if (venue.source == VenueSource.external) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Open the external provider. No native confirmation was made.',
          ),
        ),
      );
      return;
    }
    if (!controller.reserve(venue, slot)) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Slot reserved in the local demo.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pitchesControllerProvider);
    final controller = ref.read(pitchesControllerProvider.notifier);
    final tokens = context.midnight;
    return Scaffold(
      appBar: const StitchTopBar(
        title: 'Pitches',
        subtitle: 'SMART SCHEDULER · AREA 01',
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          tokens.pageMargin,
          8,
          tokens.pageMargin,
          28,
        ),
        children: [
          StitchTelemetryBanner(
            title: 'Offline snapshot',
            detail: 'Cached slots loaded · synced 02 Nov at 09:00',
            onRetry: controller.retry,
          ),
          if (state.retryMessage case final retryMessage?)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                retryMessage,
                style: TextStyle(color: tokens.emerald),
              ),
            ),
          Text(
            'Smart scheduler',
            style: tokens.displayStyle.copyWith(fontSize: 24, height: 32 / 24),
          ),
          const SizedBox(height: 4),
          Text(
            'Filter local availability by what works for your squad.',
            style: TextStyle(color: tokens.steelLight),
          ),
          const SizedBox(height: 18),
          Text('Date', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              _FilterChip(
                label: 'Any date',
                selected: state.day == null,
                onSelected: () => controller.selectDay(null),
              ),
              _FilterChip(
                label: 'Sat 7 Nov',
                selected: state.day == 7,
                onSelected: () => controller.selectDay(7),
              ),
              _FilterChip(
                label: 'Sun 8 Nov',
                selected: state.day == 8,
                onSelected: () => controller.selectDay(8),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Format', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              _FilterChip(
                label: 'All formats',
                selected: state.format == null,
                onSelected: () => controller.selectFormat(null),
              ),
              ...[
                FootballFormat.fiveAside,
                FootballFormat.sevenAside,
                FootballFormat.futsal,
              ].map(
                (format) => _FilterChip(
                  label: formatName(format),
                  selected: state.format == format,
                  onSelected: () => controller.selectFormat(format),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Surface', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              _FilterChip(
                label: 'Any surface',
                selected: state.surface == null,
                onSelected: () => controller.selectSurface(null),
              ),
              ...SurfaceType.values.map(
                (surface) => _FilterChip(
                  label: surfaceName(surface),
                  selected: state.surface == surface,
                  onSelected: () => controller.selectSurface(surface),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text('Distance'),
              Expanded(
                child: Slider(
                  value: state.maxDistance,
                  min: 2,
                  max: 10,
                  divisions: 4,
                  label: '${state.maxDistance.toStringAsFixed(0)} km',
                  onChanged: controller.selectDistance,
                ),
              ),
              Text(
                '${state.maxDistance.toStringAsFixed(0)} km',
                style: tokens.monoStyle,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (state.venues.isEmpty)
            _EmptyPitches(onNotify: controller.notify, notified: state.notified)
          else
            ...state.venues.map(
              (venue) => _VenueCard(
                venue: venue,
                selectedSlot: state.selectedSlot,
                stateFor: state.stateFor,
                onSelect: controller.selectSlot,
                onReserve: (venue, slot) =>
                    _reserve(context, controller, venue, slot),
              ),
            ),
        ],
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  const _VenueCard({
    required this.venue,
    required this.selectedSlot,
    required this.stateFor,
    required this.onSelect,
    required this.onReserve,
  });

  final PitchVenue venue;
  final String? selectedSlot;
  final SlotState Function(PitchSlot) stateFor;
  final ValueChanged<PitchSlot> onSelect;
  final void Function(PitchVenue, PitchSlot) onReserve;

  @override
  Widget build(BuildContext context) {
    final tokens = context.midnight;
    final available = venue.slots
        .where((slot) => stateFor(slot) != SlotState.soldOut)
        .toList();
    return StitchCard(
      padding: const EdgeInsets.all(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: tokens.gunmetal,
                  child: const Icon(Icons.stadium_outlined),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venue.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${venue.address} · ${venue.distanceKm} km',
                        style: TextStyle(color: tokens.steelLight),
                      ),
                    ],
                  ),
                ),
                _SourcePill(source: venue.source),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${formatName(venue.format)} · ${surfaceName(venue.surface)}',
              style: tokens.monoStyle.copyWith(
                fontSize: 12,
                color: tokens.steelLight,
              ),
            ),
            const SizedBox(height: 10),
            if (available.isEmpty)
              Text(
                'Sold out · choose another date',
                style: TextStyle(color: tokens.amber),
              )
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: available.map((slot) {
                  final state = stateFor(slot);
                  final selected = selectedSlot == slot.id;
                  return ChoiceChip(
                    label: Text('${slot.startsAt.hour}:00 · €${slot.price}'),
                    selected: selected,
                    onSelected: state == SlotState.external
                        ? null
                        : (_) => onSelect(slot),
                    selectedColor: tokens.iris,
                    backgroundColor: tokens.gunmetal,
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              ...available.map(
                (slot) => _SlotAction(
                  venue: venue,
                  slot: slot,
                  state: stateFor(slot),
                  selected: selectedSlot == slot.id,
                  onReserve: onReserve,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SlotAction extends StatelessWidget {
  const _SlotAction({
    required this.venue,
    required this.slot,
    required this.state,
    required this.selected,
    required this.onReserve,
  });

  final PitchVenue venue;
  final PitchSlot slot;
  final SlotState state;
  final bool selected;
  final void Function(PitchVenue, PitchSlot) onReserve;

  @override
  Widget build(BuildContext context) {
    final tokens = context.midnight;
    final label = switch (state) {
      SlotState.available =>
        venue.source == VenueSource.external
            ? 'Open provider'
            : 'Reserve selected slot',
      SlotState.pending => 'Pending local confirmation',
      SlotState.confirmed => 'Confirmed locally',
      SlotState.external => 'External availability',
      SlotState.soldOut => 'Sold out',
    };
    return Row(
      children: [
        Expanded(
          child: Text(
            selected ? 'Selected · $label' : label,
            style: TextStyle(
              color: state == SlotState.confirmed
                  ? tokens.emerald
                  : tokens.steelLight,
            ),
          ),
        ),
        if (state == SlotState.available || state == SlotState.external)
          TextButton(
            onPressed: () => onReserve(venue, slot),
            child: Text(
              venue.source == VenueSource.external
                  ? 'Open provider'
                  : 'Reserve',
            ),
          ),
      ],
    );
  }
}

class _SourcePill extends StatelessWidget {
  const _SourcePill({required this.source});

  final VenueSource source;

  @override
  Widget build(BuildContext context) => StitchStatusPill(
    label: source == VenueSource.native ? 'Native' : 'External',
    tone: source == VenueSource.native
        ? StitchStatusTone.success
        : StitchStatusTone.neutral,
    icon: source == VenueSource.native ? Icons.bolt : Icons.link,
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => StitchFilterChip(
    label: label,
    selected: selected,
    onSelected: (_) => onSelected(),
  );
}

class _EmptyPitches extends StatelessWidget {
  const _EmptyPitches({required this.onNotify, required this.notified});

  final VoidCallback onNotify;
  final bool notified;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: context.midnight.cardDecoration(),
    child: Column(
      children: [
        Icon(
          Icons.event_busy_outlined,
          size: 36,
          color: context.midnight.steelLight,
        ),
        const SizedBox(height: 10),
        const Text(
          'No available pitches for these filters',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Try an alternative date or get notified if a slot opens.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.midnight.steelLight),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: notified ? null : onNotify,
          child: Text(notified ? 'Drop alert enabled' : 'Notify on drop'),
        ),
      ],
    ),
  );
}
