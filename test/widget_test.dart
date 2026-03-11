// Basic smoke test for the Health Data app.

import 'package:flutter_test/flutter_test.dart';

import 'package:healthdata/data/services/open_wearables_service.dart';
import 'package:healthdata/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    final service = OpenWearablesService(host: 'https://test.example.com');
    await tester.pumpWidget(HealthDataApp(openWearablesService: service));
    // Expect the app bar title to appear.
    expect(find.text('Health Dashboard'), findsOneWidget);
  });
}
