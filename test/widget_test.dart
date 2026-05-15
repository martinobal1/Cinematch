import 'package:cinematch_ai/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CineMatch zobrazí hlavnú obrazovku', (WidgetTester tester) async {
    await tester.pumpWidget(const CineMatchApp());
    await tester.pump();

    expect(find.textContaining('CINEMATCH'), findsOneWidget);
    expect(find.text('Nájsť filmy'), findsOneWidget);
  });
}
