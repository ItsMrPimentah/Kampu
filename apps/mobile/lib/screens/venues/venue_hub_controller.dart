import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Local venue booking preview state.
class VenueHubState {
  /// Creates a booking state.
  const VenueHubState({this.external = false, this.status = 'Not requested'});

  /// Whether external booking controls are visible.
  final bool external;

  /// Current booking authority/status label.
  final String status;
}

/// Coordinates local venue booking preview actions.
class VenueHubController extends StateNotifier<VenueHubState> {
  /// Creates a venue controller.
  VenueHubController() : super(const VenueHubState());

  /// Changes the booking method.
  void selectExternal(bool external) =>
      state = VenueHubState(external: external, status: state.status);

  /// Requests a native booking in the local preview.
  void reserve() => state = VenueHubState(
    external: state.external,
    status: 'Pending provider confirmation',
  );

  /// Records a user-declared external reservation.
  void declare() => state = VenueHubState(
    external: state.external,
    status: 'Externally declared · user-declared · not provider confirmed',
  );
}

/// Owns the venue screen's preview state.
final venueHubControllerProvider =
    StateNotifierProvider.autoDispose<VenueHubController, VenueHubState>(
      (ref) => VenueHubController(),
    );
