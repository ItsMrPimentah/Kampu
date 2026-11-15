import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showtime_mobile/core/discovery/local_fixtures.dart';
import 'package:showtime_mobile/core/discovery/local_models.dart';

/// Local pitch discovery and reservation state.
class PitchesState {
  /// Creates pitch discovery state.
  const PitchesState({
    required this.data,
    this.format,
    this.surface,
    this.day,
    this.maxDistance = 10,
    this.selectedSlot,
    this.retryMessage,
    this.notified = false,
    this.slotStates = const {},
  });

  /// Preview data.
  final LocalPresentationData data;

  /// Selected format filter.
  final FootballFormat? format;

  /// Selected surface filter.
  final SurfaceType? surface;

  /// Selected day filter.
  final int? day;

  /// Maximum distance in kilometres.
  final double maxDistance;

  /// Selected slot identifier.
  final String? selectedSlot;

  /// Local refresh feedback.
  final String? retryMessage;

  /// Whether the local notification was requested.
  final bool notified;

  /// Slot states modified in the local preview.
  final Map<String, SlotState> slotStates;

  /// Venues matching all selected filters.
  List<PitchVenue> get venues => data.venues
      .where(
        (venue) =>
            (day == null ||
                venue.slots.any((slot) => slot.startsAt.day == day)) &&
            (format == null || venue.format == format) &&
            (surface == null || venue.surface == surface) &&
            venue.distanceKm <= maxDistance,
      )
      .toList();

  /// Effective preview status of a slot.
  SlotState stateFor(PitchSlot slot) => slotStates[slot.id] ?? slot.state;
}

/// Coordinates pitch filters and local reservation decisions.
class PitchesController extends StateNotifier<PitchesState> {
  /// Creates the pitch screen controller.
  PitchesController(LocalPresentationData data)
    : super(PitchesState(data: data));

  void _update({
    FootballFormat? format,
    bool changeFormat = false,
    SurfaceType? surface,
    bool changeSurface = false,
    int? day,
    bool changeDay = false,
    double? maxDistance,
    String? selectedSlot,
    String? retryMessage,
    bool? notified,
    Map<String, SlotState>? slotStates,
  }) {
    state = PitchesState(
      data: state.data,
      format: changeFormat ? format : state.format,
      surface: changeSurface ? surface : state.surface,
      day: changeDay ? day : state.day,
      maxDistance: maxDistance ?? state.maxDistance,
      selectedSlot: selectedSlot ?? state.selectedSlot,
      retryMessage: retryMessage ?? state.retryMessage,
      notified: notified ?? state.notified,
      slotStates: Map.unmodifiable(slotStates ?? state.slotStates),
    );
  }

  /// Changes the selected date.
  void selectDay(int? value) => _update(day: value, changeDay: true);

  /// Changes the selected format.
  void selectFormat(FootballFormat? value) =>
      _update(format: value, changeFormat: true);

  /// Changes the selected surface.
  void selectSurface(SurfaceType? value) =>
      _update(surface: value, changeSurface: true);

  /// Changes the maximum distance.
  void selectDistance(double value) => _update(maxDistance: value);

  /// Selects a slot.
  void selectSlot(PitchSlot slot) => _update(selectedSlot: slot.id);

  /// Marks a local notification request.
  void notify() => _update(notified: true);

  /// Records a local retry.
  void retry() =>
      _update(retryMessage: 'Local retry complete · cached results retained.');

  /// Reserves an eligible native slot in the preview; returns whether it changed.
  bool reserve(PitchVenue venue, PitchSlot slot) {
    if (venue.source == VenueSource.external) return false;
    final current = state.stateFor(slot);
    if (current != SlotState.available && current != SlotState.pending) {
      return false;
    }
    _update(
      selectedSlot: slot.id,
      slotStates: {...state.slotStates, slot.id: SlotState.confirmed},
    );
    return true;
  }
}

/// Owns the screen-scoped pitch state.
final pitchesControllerProvider =
    StateNotifierProvider.autoDispose<PitchesController, PitchesState>(
      (ref) => PitchesController(LocalFixtures.load()),
    );
