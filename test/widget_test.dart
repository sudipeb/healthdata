// Basic smoke test for the Health Data app.

import 'package:flutter_test/flutter_test.dart';

import 'package:healthdata/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const HealthDataApp());
    // Expect the app bar title to appear.
    expect(find.text('Health Dashboard'), findsOneWidget);
  });
}
