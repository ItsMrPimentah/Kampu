import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Available local squad destinations.
class SquadController extends StateNotifier<List<String>> {
  /// Creates the squad screen controller.
  SquadController() : super(const ['teams', 'safety', 'payments']);
}

/// Owns the squad screen's destinations.
final squadControllerProvider =
    StateNotifierProvider.autoDispose<SquadController, List<String>>(
      (ref) => SquadController(),
    );
