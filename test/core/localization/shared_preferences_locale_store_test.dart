import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/core/localization/shared_preferences_locale_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('reads the existing FlutterFlow locale storage key', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesLocaleStore.storageKey: 'ru',
    });

    final store = await SharedPreferencesLocaleStore.create();

    expect(store.readLanguageCode(), 'ru');
  });

  test('persists a language code under the compatible storage key', () async {
    final store = await SharedPreferencesLocaleStore.create();

    await store.writeLanguageCode('en');

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString(SharedPreferencesLocaleStore.storageKey),
      'en',
    );
  });
}
