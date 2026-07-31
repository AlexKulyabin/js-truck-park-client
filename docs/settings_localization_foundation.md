# Этап рефакторинга: Settings/Localization foundation

## Статус

Реализовано и проверено в отдельной ветке
`agent/settings-localization-foundation`. Пользовательское поведение, маршруты,
переводы и backend-контракты не изменялись.

## Выбранный модуль

Хранение выбранного языка и управление текущей locale приложения.

## Почему он выбран

- пилотный экран `Language` уже находится в feature-boundary;
- модуль не обращается к Supabase, Auth, Storage, RPC, карте или платежам;
- существующий контракт сводится к двум кодам языка и одному ключу
  `SharedPreferences`;
- состояние можно отделить от `MyApp` без изменения router и UI;
- новый port/adapter/controller создаёт повторяемый шаблон для следующих
  feature-этапов с маленьким радиусом изменений.

## Текущее поведение до этапа

- `FFLocalizations.initialize()` открывает `SharedPreferences`;
- выбранный код хранится под ключом `__locale_key__`;
- `_MyAppState` читает сохранённую locale напрямую из `FFLocalizations`;
- `setAppLanguage` ищет `_MyAppState` через `BuildContext`;
- `_MyAppState.setLocale` немедленно перестраивает приложение и асинхронно
  сохраняет код языка;
- при отсутствии сохранённого значения `MaterialApp` использует системную
  locale;
- экран предлагает только `en` и `ru` и остаётся на текущем route после выбора.

## Новая структура

```text
lib/core/localization/
  app_locale.dart
  locale_store.dart
  shared_preferences_locale_store.dart
lib/features/language/
  application/
    language_controller.dart
  presentation/
    language_page.dart
```

Поток зависимостей:

```text
LanguageWidget -> compatibility setAppLanguage
               -> LanguageController -> LocaleStore
                                     -> SharedPreferences adapter
MyApp          -> watches immutable LanguageState
FFLocalizations -> uses the same LocaleStore for legacy compatibility
```

## Созданные файлы

- `lib/core/localization/app_locale.dart`;
- `lib/core/localization/locale_store.dart`;
- `lib/core/localization/shared_preferences_locale_store.dart`;
- `lib/features/language/application/language_controller.dart`;
- `test/core/localization/shared_preferences_locale_store_test.dart`;
- `test/features/language/application/language_controller_test.dart`;
- `test/flutter_flow/internationalization_locale_compatibility_test.dart`;
- `docs/settings_localization_foundation.md`.

## Изменённые файлы

- `lib/main.dart` — создаёт store/controller и предоставляет controller через
  существующий Provider stack;
- `lib/flutter_flow/internationalization.dart` — сохраняет прежний публичный API,
  но делегирует persistence в `LocaleStore`;
- `lib/flutter_flow/flutter_flow_util.dart` — compatibility helper делегирует
  выбор языка контроллеру;
- `test/features/language/presentation/language_page_test.dart` — проверяет
  production boundary контроллера.

## Файлы и контракты, которые нельзя менять в этом этапе

- translation map и существующие пустые русские строки;
- `LanguageWidget.routeName` и `routePath`;
- layout/theme/buttons экрана Language;
- router, redirect и auth bootstrap;
- `FFAppState` и theme persistence;
- весь Supabase schema/RPC/RLS/Storage contract;
- `pubspec.yaml`, Android/iOS/Web configuration и версии сборки;
- RevenueCat, Chottu и hosted deep links.

## Supabase-зависимости

Отсутствуют. Новые core/application файлы и их тесты не импортируют Supabase,
Auth, Storage или generated rows. Инициализация Supabase в `main()` остаётся
без изменений и не участвует в language tests.

## FlutterFlow-зависимости

- `FFLocalizations`, translation map и delegates сохранены;
- `setAppLanguage` сохранён как compatibility API;
- `FlutterFlowTheme`, `FFButtonWidget` и `divide` экрана не менялись;
- storage key `__locale_key__` сохранён, поэтому установленное приложение не
  теряет выбранный пользователем язык после обновления;
- `Provider` уже был зависимостью проекта и используется как переходный DI/state
  механизм согласно целевой архитектуре.

## Последовательность изменений

1. Снять baseline tests/analyzer.
2. Ввести `LocaleStore` и совместимый SharedPreferences adapter.
3. Вынести создание `Locale` в один parser с прежней семантикой.
4. Добавить `LanguageController` и immutable `LanguageState`.
5. Подключить controller в app bootstrap.
6. Перевести compatibility helper на controller.
7. Добавить unit/widget regression tests.
8. Выполнить format, analyze, test, dependency scan и APK build.
9. Проверить и исключить любые автоматические Android-миграции из diff.

## Необходимые тесты

- существующий storage key читается без миграции данных;
- код языка сохраняется под тем же ключом;
- сохранённая `ru` восстанавливается при создании controller;
- отсутствие значения оставляет locale `null` для системного выбора;
- выбор языка немедленно обновляет state и затем сохраняется;
- default callback экрана проходит через application controller;
- route, labels, layout и тёмная тема Language не меняются;
- полный набор существующих тестов продолжает проходить.

## Выполненные команды проверки

```bash
dart format --output=none --set-exit-if-changed lib test
flutter test
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter build apk --debug
flutter run -d <ios-simulator-id> --route=/language --debug \
  --dart-define=APP_ENV=integration
rg -n "SupaFlow|Supabase|backend/supabase|auth_util|storage_client|RevenueCat|Chottu" \
  lib/core/localization lib/features/language \
  test/core/localization test/features/language
git diff --check
```

Результат:

- format: 179 файлов проверено, 0 изменений;
- tests: 29 PASS, было 21;
- analyzer: 2297 существующих замечаний, ровно как baseline, новых нет;
- APK: `app-debug.apk` собран успешно;
- iOS Simulator: приложение собрано и `/language` открылся в read-only
  integration mode; сохранённая `ru` восстановилась;
- dependency scan: запрещённых зависимостей в новом boundary нет;
- Flutter build предупреждает о будущих обновлениях Gradle/AGP/Kotlin и старых
  Java target/plugin APIs. Это существующий infrastructure debt, не ошибка
  localization-этапа.

Flutter автоматически предложил и применил platform template migrations во
время Android/iOS build. Они не относятся к этапу и полностью исключены из Git
diff; `android/` и `ios/` остались без изменений.

## Ручной чек-лист

- открыть `/language` и проверить прежний внешний вид;
- выбрать `Ru`, убедиться в немедленном переключении языка без смены route;
- перезапустить приложение и подтвердить сохранение `ru`;
- выбрать `En`, перезапустить и подтвердить `en`;
- очистить данные приложения и подтвердить выбор системной locale;
- проверить light/dark theme;
- подтвердить текущее поведение пустых переводов, не исправляя их в этом этапе;
- убедиться, что Home, Map, Auth и Profile открываются как раньше;
- убедиться, что выбор языка не создаёт сетевых/Supabase-запросов;
- проверить, что в логах нет token, phone, device id и иных чувствительных данных.

## Условия отката

Откатить этап, если:

- ранее выбранный язык теряется после обновления;
- locale не меняется немедленно или не сохраняется после restart;
- меняется route/UI экрана Language;
- появляется Supabase/network вызов;
- число analyzer findings становится выше baseline;
- полный test suite или Android build перестаёт проходить.

Откат выполняется одним `git revert` feature-коммита. Storage key и сохранённое
значение не удаляются, поэтому возврат к прежнему коду не требует миграции данных.

## Предлагаемое сообщение Git-коммита

```text
refactor(localization): add typed locale state boundary
```

## Scope следующего отдельного этапа

Следующим безопасным шагом предлагается вынести theme persistence в отдельные
`ThemeStore` и `ThemeController`, используя тот же pattern. Не следует одновременно
мигрировать translation map на `gen_l10n`: исправление переводов и замена generated
localization — отдельные функциональный и инфраструктурный этапы.
