import 'package:flutter_test/flutter_test.dart';
import 'package:showtime_mobile/auth/auth_client.dart';
import 'package:showtime_mobile/main.dart';

class TestAuth extends AuthClient {
  @override
  Future<void> restore() async {
    initialized = true;
    notifyListeners();
  }
}

void main() {
  testWidgets('requires sign in before showing the authenticated shell', (
    tester,
  ) async {
    await tester.pumpWidget(ShowtimeApp(auth: TestAuth()));
    await tester.pumpAndSettle();
    expect(find.text('WELCOME BACK, BALLER'), findsOneWidget);
    expect(find.text('SIGN IN & PLAY'), findsOneWidget);
    expect(find.text('Discover'), findsNothing);
  });
}
