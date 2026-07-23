import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/core/localization/locale_store.dart';
import 'package:j_s_truck_park/features/language/application/language_controller.dart';

class _FakeLocaleStore implements LocaleStore {
  _FakeLocaleStore({this.storedLanguageCode});

  String? storedLanguageCode;
  final writes = <String>[];
  Completer<void>? pendingWrite;

  @override
  String? readLanguageCode() => storedLanguageCode;

  @override
  Future<void> writeLanguageCode(String languageCode) {
    writes.add(languageCode);
    storedLanguageCode = languageCode;
    return pendingWrite?.future ?? Future.value();
  }
}

void main() {
  test('restores the persisted locale when it is created', () {
    final controller = LanguageController(
      localeStore: _FakeLocaleStore(storedLanguageCode: 'ru'),
    );

    expect(controller.state.locale?.languageCode, 'ru');
  });

  test('keeps system locale selection when no locale was persisted', () {
    final controller = LanguageController(localeStore: _FakeLocaleStore());

    expect(controller.state.locale, isNull);
  });

  test('updates state immediately and persists the selected language',
      () async {
    final store = _FakeLocaleStore()..pendingWrite = Completer<void>();
    final controller = LanguageController(localeStore: store);
    var notifications = 0;
    controller.addListener(() => notifications++);

    final persistence = controller.selectLanguage('en');

    expect(controller.state.locale?.languageCode, 'en');
    expect(store.writes, ['en']);
    expect(notifications, 1);

    store.pendingWrite!.complete();
    await persistence;
  });
}
