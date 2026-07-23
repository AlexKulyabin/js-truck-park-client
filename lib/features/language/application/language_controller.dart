import 'package:flutter/material.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/localization/locale_store.dart';

@immutable
class LanguageState {
  const LanguageState({required this.locale});

  final Locale? locale;
}

class LanguageController extends ChangeNotifier {
  LanguageController({required LocaleStore localeStore})
      : _localeStore = localeStore,
        _state = LanguageState(
          locale: createStoredAppLocale(localeStore.readLanguageCode()),
        );

  final LocaleStore _localeStore;
  LanguageState _state;

  LanguageState get state => _state;

  Future<void> selectLanguage(String languageCode) {
    _state = LanguageState(locale: createAppLocale(languageCode));
    notifyListeners();
    return _localeStore.writeLanguageCode(languageCode);
  }
}
