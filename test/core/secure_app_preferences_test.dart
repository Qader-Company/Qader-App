import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/core/storage/secure_app_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'PREFS_KEY_TOKEN': 'old-placeholder',
    });
    FlutterSecureStorage.setMockInitialValues({});
  });
  test(
    'tokens persist securely and plaintext placeholder is removed',
    () async {
      final shared = await SharedPreferences.getInstance();
      final prefs = await SecureAppPreferences.create(shared);
      expect(prefs.isLoggedIn, isFalse);
      await prefs.saveRefreshToken('refresh');
      await prefs.saveToken('access');
      expect(shared.getString('PREFS_KEY_TOKEN'), isNull);
      expect(shared.getString('PREFS_KEY_REFRESH_TOKEN'), isNull);
      final restored = await SecureAppPreferences.create(shared);
      expect(restored.getToken(), 'access');
      expect(restored.getRefreshToken(), 'refresh');
      await restored.logout();
      final afterLogout = await SecureAppPreferences.create(shared);
      expect(afterLogout.isLoggedIn, isFalse);
      expect(afterLogout.getRefreshToken(), isEmpty);
    },
  );
  test('queued token writes cannot resurrect a logged-out session', () async {
    final prefs = await SecureAppPreferences.create(
      await SharedPreferences.getInstance(),
    );
    final saving = prefs.saveToken('late-access');
    final logout = prefs.logout();
    await Future.wait([saving, logout]);
    expect(prefs.isLoggedIn, isFalse);
    expect(prefs.getToken(), isEmpty);
    expect(prefs.sessionRevision.value, 1);
  });
}
