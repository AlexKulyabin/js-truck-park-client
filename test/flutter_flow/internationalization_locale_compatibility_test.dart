import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/core/localization/locale_store.dart';
import 'package:j_s_truck_park/flutter_flow/internationalization.dart';

class _MemoryLocaleStore implements LocaleStore {
  _MemoryLocaleStore(this.languageCode);

  String? languageCode;

  @override
  String? readLanguageCode() => languageCode;

  @override
  Future<void> writeLanguageCode(String languageCode) async {
    this.languageCode = languageCode;
  }
}

void main() {
  test('legacy localization API reads through the injected store', () async {
    final store = _MemoryLocaleStore('ru');
    await FFLocalizations.initialize(localeStore: store);

    expect(FFLocalizations.getStoredLocale()?.languageCode, 'ru');
  });

  test('legacy localization API writes through the injected store', () async {
    final store = _MemoryLocaleStore(null);
    await FFLocalizations.initialize(localeStore: store);

    await FFLocalizations.storeLocale('en');

    expect(store.languageCode, 'en');
  });
}
