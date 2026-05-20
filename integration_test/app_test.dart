// Tüm integration testleri tek komutla çalıştırmak için bu dosyayı kullan:
// flutter test integration_test/app_test.dart --dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=...

import 'auth_test.dart' as auth;
import 'navigation_test.dart' as navigation;
import 'vehicles_test.dart' as vehicles;
import 'requests_test.dart' as requests;

void main() {
  auth.main();
  navigation.main();
  vehicles.main();
  requests.main();
}
