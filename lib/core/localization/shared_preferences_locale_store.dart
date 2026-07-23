import 'package:shared_preferences/shared_preferences.dart';

import 'locale_store.dart';

class SharedPreferencesLocaleStore implements LocaleStore {
  SharedPreferencesLocaleStore(this._preferences);

  static const storageKey = '__locale_key__';

  final SharedPreferences _preferences;

  static Future<SharedPreferencesLocaleStore> create() async =>
      SharedPreferencesLocaleStore(await SharedPreferences.getInstance());

  @override
  String? readLanguageCode() => _preferences.getString(storageKey);

  @override
  Future<void> writeLanguageCode(String languageCode) async {
    await _preferences.setString(storageKey, languageCode);
  }
}
