import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtime_mobile/auth/auth_client.dart';
import 'package:showtime_mobile/community/community_screen.dart';
import 'package:showtime_mobile/theme/midnight_theme.dart';

class CommunityFake extends AuthClient {
  final List<String> calls = [];
  String status = 'pending';
  @override
  Future<List<dynamic>> communityList(String path) async {
    calls.add('GET $path');
    if (path == 'games') return [game];
    if (path == 'games/game-1/applications') {
      return [
        {'id': 'a1', 'display_name': 'First', 'status': 'waitlisted'},
        {'id': 'a2', 'display_name': 'Second', 'status': status},
      ];
    }
    return [];
  }

  Map<String, dynamic> get game => {
    'id': 'game-1',
    'title': 'Friday Football',
    'format': '7v7',
    'region': 'Lisbon',
    'location': 'Pitch',
    'scheduled_at': '2030-01-01T18:00:00Z',
    'approved_count': 0,
    'capacity': 14,
    'approval_required': true,
    'my_status': null,
    'is_organizer': true,
    'required_positions': [],
    'status': 'open',
  };
  @override
  Future<Map<String, dynamic>> communityGet(String path) async => game;
  @override
  Future<Map<String, dynamic>> communityPost(
    String path, [
    Map<String, dynamic> body = const {},
  ]) async {
    calls.add('POST $path');
    if (path.endsWith('/a2/approve')) status = 'approved';
    return {};
  }
}

void main() {
  testWidgets('organizer can select any waiting player from the ordered list', (
    tester,
  ) async {
    final auth = CommunityFake();
    await tester.pumpWidget(
      MaterialApp(
        theme: MidnightThemeData.apply(),
        home: CommunityScreen(auth: auth, section: 'games'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Friday Football'));
    await tester.pumpAndSettle();
    expect(find.text('First · waitlisted'), findsOneWidget);
    expect(find.text('Second · pending'), findsOneWidget);
    final secondCard = find
        .ancestor(
          of: find.text('Second · pending'),
          matching: find.byType(Column),
        )
        .first;
    await tester.tap(
      find.descendant(of: secondCard, matching: find.text('Approve')),
    );
    await tester.pumpAndSettle();
    expect(auth.calls, contains('POST games/game-1/applications/a2/approve'));
    expect(find.text('Second · approved'), findsOneWidget);
  });
}
