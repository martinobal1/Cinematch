import 'package:cinematch_ai/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Prihlasovacia obrazovka', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen()),
    );

    expect(find.textContaining('CINEMATCH'), findsOneWidget);
    expect(find.text('Prihlásiť sa'), findsOneWidget);
    expect(find.text('Registrácia'), findsOneWidget);
  });
}
