import 'package:flutter_test/flutter_test.dart';
import 'package:shifai/main.dart';

void main() {
  testWidgets('ShifAI home screen shows the empty state', (tester) async {
    await tester.pumpWidget(const ShifAiApp());
    await tester.pumpAndSettle();

    expect(find.text('Shif'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('Welcome to ShifAI'), findsOneWidget);
  });
}
