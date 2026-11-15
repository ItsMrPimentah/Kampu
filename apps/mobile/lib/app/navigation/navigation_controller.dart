import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

enum PrimaryDestination { discover, challenges, pitches, squad }

/// Route command adapter. The router location is the only selected-state authority.
class NavigationController extends ChangeNotifier {
  NavigationController(this.router) {
    router.routerDelegate.addListener(_routeChanged);
  }

  final GoRouter router;
  static const locations = <String>[
    '/home',
    '/challenges',
    '/pitches',
    '/squad',
  ];

  String get location => router.routerDelegate.currentConfiguration.uri.path;

  int get selectedIndex => destinationForLocation(location).index;

  PrimaryDestination destinationForLocation(String path) {
    if (path == '/challenges' || path.startsWith('/challenges/')) {
      return PrimaryDestination.challenges;
    }
    if (path == '/pitches' || path.startsWith('/pitches/')) {
      return PrimaryDestination.pitches;
    }
    if (path == '/squad') return PrimaryDestination.squad;
    return PrimaryDestination.discover;
  }

  void goToDestination(int index) {
    if (index < 0 || index >= locations.length) return;
    final target = locations[index];
    if (location == target) return;
    router.go(target);
  }

  void openChallenge(String challengeId) =>
      router.push('/challenges/$challengeId');

  void openPitch(String pitchId) => router.push('/pitches/$pitchId');

  void openExistingHub(String hub) => router.push('/$hub');

  void _routeChanged() => notifyListeners();

  @override
  void dispose() {
    router.routerDelegate.removeListener(_routeChanged);
    super.dispose();
  }
}
