import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workspace/main.dart';

void main() {
  Future<void> tapKeys(WidgetTester tester, String keys) async {
    for (final key in keys.split(' ')) {
      await tester.tap(find.widgetWithText(FilledButton, key));
    }
    await tester.pump();
  }

  testWidgets('shows the ongoing expression and respects precedence',
      (tester) async {
    await tester.pumpWidget(const MyApp());

    await tapKeys(tester, '2 + 3 × 4 =');

    expect(find.textContaining('2 + 3 × 4 = 14'), findsOneWidget);
  });

  testWidgets('C clears the expression and result', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tapKeys(tester, '9 × 9 =');
    await tester.tap(find.text('C'));
    await tester.pump();

    expect(find.text('0').first, findsOneWidget);
    expect(find.text('9 × 9 = 81'), findsNothing);
  });

  testWidgets('displays a friendly error for division by zero', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tapKeys(tester, '8 ÷ 0 =');

    expect(find.text('Unable to calculate this expression'), findsOneWidget);
  });

  testWidgets('evaluates a longer expression', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tapKeys(tester, '1 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9 =');

    expect(find.text('1 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9 = 45'),
        findsOneWidget);
  });

  testWidgets('accepts typed numbers and operators', (tester) async {
    await tester.pumpWidget(const MyApp());

    for (final key in [
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.add,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.enter,
    ]) {
      await tester.sendKeyEvent(key);
    }
    await tester.pump();

    expect(find.textContaining('2 + 3 = 5'), findsOneWidget);
  });

  testWidgets('arrow keys move the insertion point for editing', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.widgetWithText(FilledButton, '1'));
    await tester.tap(find.widgetWithText(FilledButton, '2'));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.pump();

    expect(find.textContaining('13|2'), findsOneWidget);
  });
}
