import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

void main() {
  testWidgets('header and status affordances expose accessible labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MidnightThemeData.apply(),
        home: const Scaffold(
          appBar: StitchTopBar(
            title: 'Challenge negotiation',
            onBack: _noop,
            actions: [
              IconButton(
                tooltip: 'More options',
                onPressed: _noop,
                icon: Icon(Icons.more_vert),
              ),
            ],
          ),
          body: StitchStatusPill(
            label: 'Counter offer pending',
            tone: StitchStatusTone.warning,
          ),
        ),
      ),
    );
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byTooltip('More options'), findsOneWidget);
    expect(find.text('Counter offer pending'), findsOneWidget);
  });

  testWidgets('primary action remains keyboard-focusable and tappable', (
    tester,
  ) async {
    var activated = false;
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: MidnightThemeData.apply(),
        home: Scaffold(
          body: Focus(
            focusNode: focusNode,
            child: StitchGradientButton(
              label: 'Accept & lock',
              onPressed: () => activated = true,
            ),
          ),
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
    await tester.tap(find.text('Accept & lock'));
    expect(activated, isTrue);
  });
}

void _noop() {}
