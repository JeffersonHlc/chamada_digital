import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chamada_digital/main.dart';

void main() {
  testWidgets('Login screen appears', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the login screen is displayed.
    expect(find.byKey(const Key('loginTitle')), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
