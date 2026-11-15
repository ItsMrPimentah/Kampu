import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:showtime_mobile/core/discovery/local_models.dart';
import 'package:showtime_mobile/core/discovery/pitch_preview_fixtures.dart';

part 'pitches_controller.freezed.dart';

/// Local pitch discovery and reservation state.
@freezed
abstract class PitchesState with _$PitchesState {
  const PitchesState._();

  const factory PitchesState({
    required List<PitchVenue> data,
    @Default('') String query,
    FootballFormat? format,
    SurfaceType? surface,
    DateTime? date,
    @Default(10) double maxDistance,
    String? selectedSlot,
    String? retryMessage,
    @Default(false) bool notified,
    @Default({}) Map<String, SlotState> slotStates,
  }) = _PitchesState;

  /// The visible venue and slot set share the same date predicate.
  List<PitchVenue> get venues {
    final search = query.trim().toLowerCase();
    return data
        .where(
          (venue) =>
              (search.isEmpty ||
                  '${venue.name} ${venue.address}'.toLowerCase().contains(
                    search,
                  )) &&
              (format == null || venue.format == format) &&
              (surface == null || venue.surface == surface) &&
              venue.distanceKm <= maxDistance,
        )
        .map(
          (venue) => venue.copyWith(
            slots: venue.slots
                .where((slot) => date == null || sameDate(slot.startsAt, date!))
                .toList(),
          ),
        )
        .where((venue) => venue.slots.isNotEmpty)
        .toList();
  }

  /// Stable dates represented in the fixture set.
  List<DateTime> get dates {
    final dates = data
        .expand((venue) => venue.slots)
        .map(
          (slot) => DateTime(
            slot.startsAt.year,
            slot.startsAt.month,
            slot.startsAt.day,
          ),
        )
        .toSet()
        .toList();
    dates.sort();
    return dates;
  }

  /// Sample dates that yield venues without changing the other filters.
  List<DateTime> get alternativeDates => dates
      .where((candidate) => date == null || !sameDate(candidate, date!))
      .where((candidate) => copyWith(date: candidate).venues.isNotEmpty)
      .toList();

  /// Effective preview status of a slot.
  SlotState stateFor(PitchSlot slot) => slotStates[slot.id] ?? slot.state;

  /// Matching sample options for a date, independent of the current date filter.
  /// Unavailable and locally confirmed slots are not options; pending and
  /// external slots are included without implying provider availability.
  int sampleOptionsForDate(DateTime candidate) => copyWith(date: candidate)
      .venues
      .expand((venue) => venue.slots)
      .where(
        (slot) => switch (stateFor(slot)) {
          SlotState.available ||
          SlotState.pending ||
          SlotState.external => true,
          SlotState.confirmed || SlotState.soldOut => false,
        },
      )
      .length;
}

/// Compares calendar dates without discarding month or year.
bool sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Rounded split estimate, when the roster size is defined.
double? pitchSplitEstimate(PitchVenue venue, PitchSlot slot) {
  final players = switch (venue.format) {
    FootballFormat.fiveAside => 10,
    FootballFormat.sevenAside => 14,
    FootballFormat.elevenAside => 22,
    FootballFormat.futsal => null,
  };
  return players == null ? null : slot.price / players;
}

/// Coordinates pitch filters and local reservation decisions.
class PitchesController extends StateNotifier<PitchesState> {
  PitchesController(List<PitchVenue> data, {String? initialSlot})
    : super(PitchesState(data: data, selectedSlot: initialSlot));

  void _filter(PitchesState next) {
    final visible = next.venues.expand((venue) => venue.slots);
    if (!visible.any(
      (slot) =>
          slot.id == next.selectedSlot &&
          next.stateFor(slot) != SlotState.soldOut,
    )) {
      next = next.copyWith(selectedSlot: null);
    }
    state = next;
  }

  void search(String value) => _filter(state.copyWith(query: value));
  void selectDate(DateTime? value) => _filter(state.copyWith(date: value));
  void selectFormat(FootballFormat? value) =>
      _filter(state.copyWith(format: value));
  void selectSurface(SurfaceType? value) =>
      _filter(state.copyWith(surface: value));
  void selectDistance(double value) =>
      _filter(state.copyWith(maxDistance: value));
  void clearFilters() => _filter(
    state.copyWith(
      query: '',
      date: null,
      format: null,
      surface: null,
      maxDistance: 10,
    ),
  );

  void selectSlot(PitchSlot slot) {
    final visibleSlot = state.venues
        .expand((venue) => venue.slots)
        .where((item) => item.id == slot.id)
        .firstOrNull;
    if (visibleSlot != null &&
        state.stateFor(visibleSlot) != SlotState.soldOut) {
      state = state.copyWith(selectedSlot: visibleSlot.id);
    }
  }

  void notify() => state = state.copyWith(notified: true);
  void retry() =>
      state = state.copyWith(retryMessage: 'Local preview data retained.');

  bool reserve(PitchVenue venue, PitchSlot slot) {
    if (state.selectedSlot != slot.id) {
      return false;
    }
    final visibleVenue = state.venues
        .where((item) => item.id == venue.id)
        .firstOrNull;
    if (visibleVenue == null || visibleVenue.source != VenueSource.native) {
      return false;
    }
    final visibleSlot = visibleVenue.slots
        .where((candidate) => candidate.id == slot.id)
        .firstOrNull;
    if (visibleSlot == null) return false;
    final current = state.stateFor(visibleSlot);
    if (current != SlotState.available && current != SlotState.pending) {
      return false;
    }
    state = state.copyWith(
      slotStates: {...state.slotStates, visibleSlot.id: SlotState.confirmed},
    );
    return true;
  }
}

/// Owns the screen-scoped pitch state.
final pitchesControllerProvider =
    StateNotifierProvider.autoDispose<PitchesController, PitchesState>(
      (ref) =>
          PitchesController(pitchPreviewFixtures(), initialSlot: 'slot-001'),
    );
