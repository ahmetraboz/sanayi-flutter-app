import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const String testEmail = 'ahmetboz@gmail.com';
const String testPassword = 'ahmet11897';

// Müşteri app nav label'ları
const String navHome = 'Anasayfa';
const String navServices = 'Servisler';
const String navRequests = 'Talepler';
const String navBids = 'Teklifler';
const String navVehicles = 'Araçlar';

/// Frame pump — sonsuz animasyonlara takılmadan belirli süre bekler
Future<void> pumpFor(WidgetTester tester, {int seconds = 2}) async {
  for (int i = 0; i < seconds * 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Widget görünene kadar pump et
Future<void> waitForWidget(WidgetTester tester, Finder finder,
    {int timeoutSeconds = 10}) async {
  for (int i = 0; i < timeoutSeconds * 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets,
      reason: '$timeoutSeconds saniye içinde bulunamadı');
}

Future<void> waitForText(WidgetTester tester, String text,
    {int timeoutSeconds = 10}) async {
  await waitForWidget(tester, find.textContaining(text),
      timeoutSeconds: timeoutSeconds);
}

/// Zaten login olduysa (dashboard görünüyorsa) direkt döner.
/// Onboarding slideshow'daysa "Atla" → son sayfaya → "Giriş Yap" → form.
Future<void> loginWith(WidgetTester tester, String email, String password) async {
  await pumpFor(tester, seconds: 3);

  // Zaten login olmuş → dashboard'da 'Anasayfa' nav item'ı görünüyor
  if (find.text(navHome).evaluate().isNotEmpty) return;

  // Onboarding slideshow: "Atla" butonu son auth sayfasına götürür
  final atlaBtn = find.text('Atla');
  if (atlaBtn.evaluate().isNotEmpty) {
    await tester.tap(atlaBtn.first);
    await pumpFor(tester, seconds: 1);
  }

  // Son onboarding sayfasındaki veya landing'deki "Giriş Yap" butonuna bas
  final loginLinks = find.text('Giriş Yap');
  if (loginLinks.evaluate().isNotEmpty &&
      find.byKey(const Key('email_field')).evaluate().isEmpty) {
    await tester.tap(loginLinks.first);
    await pumpFor(tester, seconds: 2);
  }

  // Login form görünene kadar bekle
  await waitForWidget(tester, find.byKey(const Key('email_field')));

  await tester.enterText(find.byKey(const Key('email_field')), email);
  await tester.pump();
  await tester.enterText(find.byKey(const Key('password_field')), password);
  await tester.pump();
  await tester.tap(find.byKey(const Key('login_button')));
  await pumpFor(tester, seconds: 5);
}

/// Dashboard'a gittiğimizi doğrula
Future<void> waitForDashboard(WidgetTester tester) async {
  await waitForText(tester, navHome);
}

/// Anasayfa tab'ına gider — GoRouter önceki testten farklı rotada kalabilir.
Future<void> goHome(WidgetTester tester) async {
  final homeTab = find.text(navHome);
  if (homeTab.evaluate().isNotEmpty) {
    await tester.tap(homeTab.first);
    await pumpFor(tester, seconds: 2);
  }
}
