# Этап рефакторинга: Theme settings foundation

## Статус

Реализовано и проверено в ветке `agent/settings-theme-foundation` поверх
localization foundation. Тема приложения получила отдельные port, adapter и
application controller. Пользовательский UI и backend-контракты не менялись.

## Выбранный модуль

Хранение и применение `ThemeMode` приложения.

## Почему он выбран

- это второй небольшой глобальный setting после языка;
- модуль не зависит от Supabase, Auth, Storage, RPC, карты или платежей;
- контракт хранения состоит из одного совместимого `SharedPreferences` ключа;
- удаление состояния из `MyApp` уменьшает ответственность app shell;
- pattern `controller -> port -> adapter` можно повторять для следующих settings
  и feature boundaries;
- этап безопасен для отдельного отката и не требует миграции пользовательских
  данных.

## Текущее поведение до этапа

- `FlutterFlowTheme.initialize()` открывает `SharedPreferences`;
- ключ `__theme_mode__` хранит `bool?`:
  - отсутствие ключа — `ThemeMode.system`;
  - `false` — `ThemeMode.light`;
  - `true` — `ThemeMode.dark`;
- `_MyAppState` самостоятельно читает, хранит и применяет `ThemeMode`;
- `setDarkModeSetting` ищет `_MyAppState` через `BuildContext`;
- профиль отдельно меняет неперсистентный `FFAppState.isDarkThemeOn` для
  положения собственного переключателя.

Последний пункт является дублирующим UI-state. Он не удаляется в этом коммите,
чтобы не смешивать foundation refactor с изменением поведения Profile.

## Новая структура

```text
lib/core/theme/
  theme_store.dart
  shared_preferences_theme_store.dart
lib/features/settings/application/
  theme_controller.dart
```

Поток зависимостей:

```text
Profile compatibility helper -> ThemeController -> ThemeStore
                                        |              |
                                        |              -> SharedPreferences adapter
                                        -> immutable ThemeState

MyApp -> watches ThemeController -> MaterialApp.themeMode
FlutterFlowTheme -> delegates legacy persistence API to ThemeStore
```

## Созданные файлы

- `lib/core/theme/theme_store.dart`;
- `lib/core/theme/shared_preferences_theme_store.dart`;
- `lib/features/settings/application/theme_controller.dart`;
- `test/core/theme/shared_preferences_theme_store_test.dart`;
- `test/core/theme/theme_boundary_widget_test.dart`;
- `test/features/settings/application/theme_controller_test.dart`;
- `test/flutter_flow/flutter_flow_theme_compatibility_test.dart`;
- `docs/theme_settings_foundation.md`.

## Изменённые файлы

- `lib/main.dart` — создаёт и предоставляет `ThemeController`, а
  `MaterialApp.router` наблюдает immutable theme state;
- `lib/flutter_flow/flutter_flow_theme.dart` — сохраняет generated theme и
  legacy API, делегируя persistence в `ThemeStore`;
- `lib/flutter_flow/flutter_flow_util.dart` — compatibility helper делегирует
  действие application controller.

## Файлы и контракты, которые нельзя менять в этом этапе

- `lib/profile/profile/profile_widget.dart` и геометрия theme toggle;
- `FFAppState.isDarkThemeOn` — его удаление требует отдельного Profile-коммита;
- цвета, typography и generated `LightModeTheme`/`DarkModeTheme`;
- router, auth bootstrap и app routes;
- Supabase schema/RPC/RLS/Storage contracts;
- translations и language flow;
- RevenueCat, Chottu и hosted deep links;
- `pubspec.yaml`, version/build number, Android/iOS/Web configuration.

## Supabase-зависимости

Отсутствуют. Новые theme/settings файлы и тесты не импортируют Supabase, Auth,
Storage, generated rows или network clients.

## FlutterFlow-зависимости

- публичные `FlutterFlowTheme.initialize`, `themeMode` и `saveThemeMode`
  сохранены;
- ключ `__theme_mode__` и его `bool?` semantics сохранены;
- `setDarkModeSetting` сохранён как compatibility API;
- generated theme classes, colors и typography не менялись;
- `Provider`, уже используемый проектом, остаётся переходным DI/state-механизмом;
- Profile пока сохраняет отдельный `FFAppState.isDarkThemeOn`.

## Последовательность изменений

1. Зафиксировать storage semantics и все callers.
2. Ввести `ThemeStore` port.
3. Добавить SharedPreferences adapter с прежним ключом и значениями.
4. Добавить immutable `ThemeState` и feature-scoped `ThemeController`.
5. Подключить controller в app bootstrap.
6. Удалить theme state и persistence responsibility из `_MyAppState`.
7. Перевести compatibility APIs на store/controller.
8. Добавить unit/widget/legacy compatibility tests.
9. Выполнить format, analyze, test, dependency scan, Android и iOS builds.
10. Исключить автоматические platform template migrations из Git diff.

## Необходимые тесты

- отсутствие значения восстанавливает system mode;
- старые `true/false` восстанавливают dark/light;
- dark/light записываются тем же boolean contract;
- system mode удаляет override;
- controller восстанавливает persisted state;
- controller немедленно публикует новое immutable state;
- compatibility helper вызывает controller;
- legacy `FlutterFlowTheme` API читает и пишет через injected store;
- полный существующий test suite продолжает проходить.

## Выполненные команды проверки

```bash
dart format --output=none --set-exit-if-changed lib test
flutter test
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter build apk --debug
flutter build ios --simulator --debug --no-pub \
  --dart-define=APP_ENV=integration
rg -n "SupaFlow|Supabase|backend/supabase|auth_util|storage_client|RevenueCat|Chottu" \
  lib/core/theme lib/features/settings test/core/theme test/features/settings
git diff --check
```

Результат:

- format: 187 файлов проверено, 0 изменений;
- tests: 38 PASS, было 29;
- analyzer: 2297 существующих замечаний, ровно как baseline;
- новые theme/settings файлы: 0 analyzer findings;
- Android debug APK: успешно;
- iOS Simulator build: успешно;
- запрещённых backend/plugin зависимостей в новом boundary нет;
- автоматические Android/iOS template migrations полностью исключены из diff.

Существующие infrastructure warnings: будущая необходимость обновить
Gradle/AGP/Kotlin, Swift Package Manager support отдельных plugins и iOS UIScene
lifecycle. Они не вызваны theme-этапом.

## Ручной чек-лист

- открыть Profile и переключить light -> dark;
- подтвердить немедленную смену цветов без смены route;
- переключить dark -> light;
- перезапустить приложение после каждого режима и проверить persistence;
- отдельно проверить system mode через тестовую/диагностическую точку;
- проверить Language, Home, Map, Auth и Profile в light/dark;
- убедиться, что theme change не вызывает HTTP/Supabase запросов;
- убедиться, что в логах нет tokens, phone, device id или иных данных.

## Условия отката

Откатить этап, если:

- установленная тема теряется после обновления или restart;
- переключение не перестраивает `MaterialApp` немедленно;
- значения существующего storage key интерпретируются иначе;
- появляются network/Supabase calls;
- analyzer findings превышают baseline;
- полный suite, Android или iOS build перестают проходить.

Откат выполняется одним `git revert` theme-коммита. Прежний storage key не
изменяется, поэтому миграция данных при откате не требуется.

## Предлагаемое сообщение Git-коммита

```text
refactor(settings): add typed theme state boundary
```

## Scope следующего отдельного этапа

Перевести только theme toggle в Profile с `FFAppState.isDarkThemeOn` на
`ThemeController.state.themeMode`, добавить widget characterization tests и после
нулевого usage удалить поле `isDarkThemeOn` из `FFAppState`. Не менять остальные
Profile settings, Supabase profile queries или визуальную геометрию toggle.
