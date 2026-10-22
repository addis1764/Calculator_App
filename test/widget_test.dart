import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/app.dart';

void main() {
  testWidgets('Calculator Vault smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CalcVaultApp());

    // Verify calculator display starts at 0
    expect(find.text('0'), findsWidgets);
    expect(find.text('Calculator'), findsOneWidget);
  });
}
