import 'package:flutter_test/flutter_test.dart';

import 'package:botique/main.dart';

void main() {
  testWidgets('App boots and shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const QueensTouchApp());
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('QUEENS\' TOUCH'), findsOneWidget);
  });
}
