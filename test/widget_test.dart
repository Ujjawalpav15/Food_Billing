import 'package:flutter_test/flutter_test.dart';
import 'package:food_billing/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MessBillingApp());

    // Verify that our app header text is displayed.
    expect(find.text('Mess Billing Manager'), findsOneWidget);
    expect(find.text('Module 1: Foundation Complete ✓'), findsOneWidget);
  });
}
