import 'package:flutter/material.dart';

Locale createAppLocale(String languageCode) => languageCode.contains('_')
    ? Locale.fromSubtags(
        languageCode: languageCode.split('_').first,
        scriptCode: languageCode.split('_').last,
      )
    : Locale(languageCode);

Locale? createStoredAppLocale(String? languageCode) =>
    languageCode == null || languageCode.isEmpty
        ? null
        : createAppLocale(languageCode);
