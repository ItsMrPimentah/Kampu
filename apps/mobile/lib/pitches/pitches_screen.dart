import 'package:flutter/material.dart';

import '../discovery/local_fixtures.dart';
import '../discovery/local_models.dart';
import '../navigation/navigation_controller.dart';
import '../theme/midnight_theme.dart';
import '../theme/stitch_components.dart';

class PitchesScreen extends StatefulWidget {
  const PitchesScreen({super.key, required this.navigation});

  final NavigationController navigation;

  @override
  State<PitchesScreen> createState() => _PitchesScreenState();
}

class _PitchesScreenState extends State<PitchesScreen> {
  final _data = LocalFixtures.load();
  FootballFormat? _format;
  SurfaceType? _surface;
  int? _dateDay;
  double _maxDistance = 10;
  String? _selectedSlot;
  String? _retryMessage;
  bool _notified = false;
  final Map<String, SlotState> _localStates = {};

  List<PitchVenue> get _venues => _data.venues.where((venue) {
    final dateMatches =
        _dateDay == null ||
        venue.slots.any((slot) => slot.startsAt.day == _dateDay);
    final formatMatches = _format == null || venue.format == _format;
    final surfaceMatches = _surface == null || venue.surface == _surface;
    return dateMatches &&
        formatMatches &&
        surfaceMatches &&
        venue.distanceKm <= _maxDistance;
  }).toList();

  SlotState _state(PitchSlot slot) => _localStates[slot.id] ?? slot.state;

  void _reserve(PitchVenue venue, PitchSlot slot) {
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
    if (_state(slot) != SlotState.available &&
        _state(slot) != SlotState.pending) {
      return;
    }
    setState(() {
      _selectedSlot = slot.id;
      _localStates[slot.id] = SlotState.confirmed;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Slot reserved in the local demo.')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            onRetry: () => setState(
              () => _retryMessage =
                  'Local retry complete · cached results retained.',
            ),
          ),
          if (_retryMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _retryMessage!,
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
                selected: _dateDay == null,
                onSelected: () => setState(() => _dateDay = null),
              ),
              _FilterChip(
                label: 'Sat 7 Nov',
                selected: _dateDay == 7,
                onSelected: () => setState(() => _dateDay = 7),
              ),
              _FilterChip(
                label: 'Sun 8 Nov',
                selected: _dateDay == 8,
                onSelected: () => setState(() => _dateDay = 8),
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
                selected: _format == null,
                onSelected: () => setState(() => _format = null),
              ),
              ...[
                FootballFormat.fiveAside,
                FootballFormat.sevenAside,
                FootballFormat.futsal,
              ].map(
                (format) => _FilterChip(
                  label: formatName(format),
                  selected: _format == format,
                  onSelected: () => setState(() => _format = format),
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
                selected: _surface == null,
                onSelected: () => setState(() => _surface = null),
              ),
              ...SurfaceType.values.map(
                (surface) => _FilterChip(
                  label: surfaceName(surface),
                  selected: _surface == surface,
                  onSelected: () => setState(() => _surface = surface),
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
                  value: _maxDistance,
                  min: 2,
                  max: 10,
                  divisions: 4,
                  label: '${_maxDistance.toStringAsFixed(0)} km',
                  onChanged: (value) => setState(() => _maxDistance = value),
                ),
              ),
              Text(
                '${_maxDistance.toStringAsFixed(0)} km',
                style: tokens.monoStyle,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_venues.isEmpty)
            _EmptyPitches(
              onNotify: () => setState(() => _notified = true),
              notified: _notified,
            )
          else
            ..._venues.map(
              (venue) => _VenueCard(
                venue: venue,
                selectedSlot: _selectedSlot,
                stateFor: _state,
                onSelect: (slot) => setState(() => _selectedSlot = slot.id),
                onReserve: _reserve,
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
