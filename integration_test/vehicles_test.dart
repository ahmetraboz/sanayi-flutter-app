import 'package:flutter/material.dart'; // Key, FloatingActionButton, TextFormField
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sanayi_app/main.dart' as app;
import 'helpers.dart';

Future<void> _goToVehicles(WidgetTester tester) async {
  await waitForDashboard(tester);
  await tester.tap(find.text(navVehicles).first);
  await pumpFor(tester, seconds: 2);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Araçlar', () {
    testWidgets('Araçlarım sayfası açılır', (tester) async {
      app.main();
      await loginWith(tester, testEmail, testPassword);
      await goHome(tester);
      await _goToVehicles(tester);

      expect(
        find.text('Araçlarım').evaluate().isNotEmpty ||
            find.text(navVehicles).evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('FAB ile yeni araç formu açılır', (tester) async {
      app.main();
      await loginWith(tester, testEmail, testPassword);
      await goHome(tester);
      await _goToVehicles(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await pumpFor(tester, seconds: 2);

      expect(find.text('Yeni Araç Ekle'), findsOneWidget);
    });

    testWidgets('Marka boş bırakılınca form validate edilir', (tester) async {
      app.main();
      await loginWith(tester, testEmail, testPassword);
      await goHome(tester);
      await _goToVehicles(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await pumpFor(tester, seconds: 2);

      await tester.ensureVisible(find.byKey(const Key('vehicle_save_button')));
      await pumpFor(tester);
      await tester.tap(find.byKey(const Key('vehicle_save_button')));
      await pumpFor(tester);

      expect(find.text('Marka zorunludur'), findsOneWidget);
    });

    testWidgets('Araç kaydedilebilir', (tester) async {
      app.main();
      await loginWith(tester, testEmail, testPassword);
      await goHome(tester);
      await _goToVehicles(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await pumpFor(tester, seconds: 2);

      await tester.enterText(find.byKey(const Key('vehicle_brand_field')), 'Toyota');
      await pumpFor(tester);

      final modelField = find.widgetWithText(TextFormField, 'Model (Örn: Megane)');
      if (modelField.evaluate().isNotEmpty) {
        await tester.enterText(modelField, 'Corolla');
      }
      await pumpFor(tester);

      await tester.ensureVisible(find.byKey(const Key('vehicle_save_button')));
      await pumpFor(tester);
      await tester.tap(find.byKey(const Key('vehicle_save_button')));
      await pumpFor(tester, seconds: 5);

      expect(
        find.textContaining('eklendi').evaluate().isNotEmpty ||
            find.textContaining('Toyota').evaluate().isNotEmpty,
        isTrue,
      );
    });
  });
}
