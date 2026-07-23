abstract interface class LocaleStore {
  String? readLanguageCode();

  Future<void> writeLanguageCode(String languageCode);
}
