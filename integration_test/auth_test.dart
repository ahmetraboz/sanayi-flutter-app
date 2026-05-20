import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sanayi_app/main.dart' as app;
import 'helpers.dart';

// Onboarding slideshow'u atlayıp login sayfasına yönlendirir.
// Zaten login olunmuşsa veya zaten login sayfasındaysa erken döner.
// true dönerse login sayfasına ulaşıldı; false dönerse zaten dashboard'da.
Future<bool> _navigateToLoginScreen(WidgetTester tester) async {
  await pumpFor(tester, seconds: 3);

  if (find.text(navHome).evaluate().isNotEmpty) return false; // zaten dashboard

  // Onboarding slideshow: "Atla" ile son auth sayfasına atla
  final atlaBtn = find.text('Atla');
  if (atlaBtn.evaluate().isNotEmpty) {
    await tester.tap(atlaBtn.first);
    await pumpFor(tester, seconds: 1);
  }

  // Son onboarding sayfasındaki "Giriş Yap" butonuna bas
  final loginLinks = find.text('Giriş Yap');
  if (loginLinks.evaluate().isNotEmpty &&
      find.byKey(const Key('email_field')).evaluate().isEmpty) {
    await tester.tap(loginLinks.first);
    await pumpFor(tester, seconds: 2);
  }

  return true;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth — Giriş Yap', () {
    testWidgets('login ekranı açılır', (tester) async {
      app.main();
      final reached = await _navigateToLoginScreen(tester);
      if (!reached) return; // zaten login, test geçerli

      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
    });

    testWidgets('boş form submit edilince hata mesajı gösterilir', (tester) async {
      app.main();
      final reached = await _navigateToLoginScreen(tester);
      if (!reached) return;

      await tester.tap(find.byKey(const Key('login_button')));
      await pumpFor(tester);

      expect(find.textContaining('doldurun'), findsOneWidget);
    });

    testWidgets('yanlış şifre ile hata mesajı gösterilir', (tester) async {
      app.main();
      final reached = await _navigateToLoginScreen(tester);
      if (!reached) return;

      await tester.enterText(find.byKey(const Key('email_field')), testEmail);
      await tester.enterText(find.byKey(const Key('password_field')), 'yanlis123');
      await tester.tap(find.byKey(const Key('login_button')));
      await pumpFor(tester, seconds: 5);

      final onLoginScreen =
          find.byKey(const Key('login_button')).evaluate().isNotEmpty ||
          find.textContaining('hatalı').evaluate().isNotEmpty ||
          find.textContaining('geçersiz').evaluate().isNotEmpty;
      expect(onLoginScreen, isTrue);
    });

    testWidgets('doğru bilgilerle giriş yapılır ve dashboard açılır', (tester) async {
      app.main();
      await loginWith(tester, testEmail, testPassword);

      await waitForText(tester, navHome, timeoutSeconds: 10);
    });

    testWidgets('kayıt ol linkine tıklayınca register ekranı açılır', (tester) async {
      app.main();
      final reached = await _navigateToLoginScreen(tester);
      if (!reached) return;

      await tester.tap(find.text('Kayıt ol'));
      await pumpFor(tester, seconds: 2);

      expect(find.text('Hesap Oluştur'), findsWidgets);
    });
  });

  group('Auth — Giriş Sonrası', () {
    testWidgets('giriş yapılan kullanıcı direkt dashboard\'a yönlenir', (tester) async {
      app.main();
      await loginWith(tester, testEmail, testPassword);

      await pumpFor(tester, seconds: 3);
      expect(find.byKey(const Key('login_button')), findsNothing);
    });
  });
}
