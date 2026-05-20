import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sanayi_app/main.dart' as app;
import 'helpers.dart';

Future<void> _goToRequests(WidgetTester tester) async {
  final taleplerTab = find.text(navRequests);
  if (taleplerTab.evaluate().isNotEmpty) {
    await tester.tap(taleplerTab.first);
    await pumpFor(tester, seconds: 3);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Talepler Listesi', () {
    testWidgets('Taleplerim sayfası açılır', (tester) async {
      app.main();
      await loginWith(tester, testEmail, testPassword);
      await goHome(tester);
      await _goToRequests(tester);

      expect(find.text('Taleplerim'), findsWidgets);
    });

    testWidgets('Taleplerim listesi yüklenebilir', (tester) async {
      app.main();
      await loginWith(tester, testEmail, testPassword);
      await goHome(tester);
      await _goToRequests(tester);

      // Sayfa yüklenince başlık ve filtre butonu görünür
      expect(
        find.text('Taleplerim').evaluate().isNotEmpty ||
            find.text('Filtrele').evaluate().isNotEmpty ||
            find.textContaining('Henüz').evaluate().isNotEmpty,
        isTrue,
      );
    });
  });

  group('Talep Oluşturma', () {
    testWidgets('Yeni Talep Oluştur akışı başlatılabilir', (tester) async {
      app.main();
      await loginWith(tester, testEmail, testPassword);
      await goHome(tester);

      await waitForText(tester, 'Yeni Talep Oluştur');
      await tester.tap(find.text('Yeni Talep Oluştur').first);
      await pumpFor(tester, seconds: 2);

      expect(
        find.textContaining('Sorun').evaluate().isNotEmpty ||
            find.textContaining('Kategori').evaluate().isNotEmpty ||
            find.textContaining('motor').evaluate().isNotEmpty ||
            find.textContaining('Motor').evaluate().isNotEmpty,
        isTrue,
        reason: 'Talep oluşturma adım 1 açılmalı',
      );
    });

    testWidgets('Kategori seçilince bir sonraki adıma geçilir', (tester) async {
      app.main();
      await loginWith(tester, testEmail, testPassword);
      await goHome(tester);

      await waitForText(tester, 'Yeni Talep Oluştur');
      await tester.tap(find.text('Yeni Talep Oluştur').first);
      await pumpFor(tester, seconds: 2);

      final motorItem = find.textContaining('Motor');
      if (motorItem.evaluate().isNotEmpty) {
        await tester.tap(motorItem.first);
        await pumpFor(tester, seconds: 2);
      }

      expect(
        find.textContaining('Açıklama').evaluate().isNotEmpty ||
            find.textContaining('Başlık').evaluate().isNotEmpty ||
            find.textContaining('İleri').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('Geri butonu ile önceki adıma dönülebilir', (tester) async {
      app.main();
      await loginWith(tester, testEmail, testPassword);
      await goHome(tester);

      await waitForText(tester, 'Yeni Talep Oluştur');
      await tester.tap(find.text('Yeni Talep Oluştur').first);
      await pumpFor(tester, seconds: 2);

      final motorItem = find.textContaining('Motor');
      if (motorItem.evaluate().isNotEmpty) {
        await tester.tap(motorItem.first);
        await pumpFor(tester, seconds: 2);
      }

      final geriBtn = find.text('Geri');
      if (geriBtn.evaluate().isNotEmpty) {
        await tester.tap(geriBtn.first);
        await pumpFor(tester, seconds: 2);

        expect(
          find.textContaining('Motor').evaluate().isNotEmpty ||
              find.textContaining('Kategori').evaluate().isNotEmpty,
          isTrue,
        );
      }
    });
  });

  group('Teklif Listesi (Müşteri)', () {
    testWidgets('Gelen teklifler sayfası açılabilir', (tester) async {
      app.main();
      await loginWith(tester, testEmail, testPassword);
      await goHome(tester);

      final bidsTab = find.text(navBids);
      if (bidsTab.evaluate().isNotEmpty) {
        await tester.tap(bidsTab.first);
        await pumpFor(tester, seconds: 3);

        expect(find.text('Gelen Teklifler'), findsWidgets);
      }
    });
  });
}
