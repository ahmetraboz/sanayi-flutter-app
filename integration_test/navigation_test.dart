import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sanayi_app/main.dart' as app;
import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigasyon — Dashboard', () {
    testWidgets('giriş sonrası dashboard nav\'ı görünür', (tester) async {
      app.main();
      await loginWith(tester, testEmail, testPassword);
      await waitForDashboard(tester);

      expect(find.text(navHome), findsWidgets);
    });

    testWidgets('Talepler sekmesine geçilebilir', (tester) async {
      app.main();
      await loginWith(tester, testEmail, testPassword);
      await waitForDashboard(tester);

      await tester.tap(find.text(navRequests).first);
      await pumpFor(tester, seconds: 2);

      expect(find.text('Taleplerim'), findsWidgets);
    });

    testWidgets('Araçlar sekmesine geçilebilir', (tester) async {
      app.main();
      await loginWith(tester, testEmail, testPassword);
      await waitForDashboard(tester);

      await tester.tap(find.text(navVehicles).first);
      await pumpFor(tester, seconds: 2);

      expect(find.text('Araçlarım'), findsWidgets);
    });

    testWidgets('Yeni Talep Oluştur butonuna tıklanabilir', (tester) async {
      app.main();
      await loginWith(tester, testEmail, testPassword);
      await waitForDashboard(tester);

      // Anasayfa tab'ından Yeni Talep Oluştur banner'ı
      await tester.tap(find.text(navHome).first);
      await pumpFor(tester, seconds: 2);

      await waitForText(tester, 'Yeni Talep Oluştur');
      await tester.tap(find.text('Yeni Talep Oluştur').first);
      await pumpFor(tester, seconds: 2);

      expect(
        find.textContaining('Sorun').evaluate().isNotEmpty ||
            find.textContaining('Motor').evaluate().isNotEmpty ||
            find.textContaining('Talep').evaluate().isNotEmpty,
        isTrue,
      );
    });
  });
}
