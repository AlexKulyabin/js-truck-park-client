# Этап рефакторинга: Profile theme toggle

## Статус

Реализовано и проверено в ветке `agent/profile-theme-controller` поверх двух
отдельных foundation-коммитов для localization и theme. Production backend,
маршруты, визуальный дизайн и platform-конфигурация не менялись.

## Выбранный модуль

Переключатель светлой/тёмной темы на экране Profile.

## Почему он выбран

- это следующий заранее ограниченный этап после создания `ThemeController`;
- он устраняет два источника истины для одного пользовательского setting;
- изменение не требует Supabase, Auth, RPC, Storage или сетевых запросов;
- прежнюю геометрию и стили можно зафиксировать widget-тестами;
- компонент можно тестировать отдельно от большого generated Profile widget;
- этап мал, обратим и пригоден для отдельного Git-коммита.

## Текущее поведение до этапа

- сохранённый `ThemeMode` применялся в `MyApp` через `ThemeController`;
- Profile отдельно читал и менял неперсистентный
  `FFAppState.isDarkThemeOn`;
- `setDarkModeSetting` был FlutterFlow compatibility helper;
- после перезапуска сохранённая тёмная тема могла быть применена ко всему
  приложению, но переключатель Profile визуально оставался в светлой позиции;
- 170 строк двух почти одинаковых generated веток описывали один toggle.

## Предлагаемая и реализованная структура

```text
ProfileWidget
  -> ThemeModeToggle (presentation)
       -> ThemeController (application, единственный источник состояния)
            -> ThemeStore (port)
                 -> SharedPreferencesThemeStore (adapter)
```

`ThemeModeToggle` наблюдает immutable `ThemeState` и отправляет намерение
выбрать light/dark только в `ThemeController`. Он не знает о persistence,
Supabase или глобальном `FFAppState`.

## Изменение наблюдаемого поведения

Исправлена рассинхронизация после restart: при сохранённой тёмной теме Profile
сразу показывает тёмную позицию. Это ожидаемое следствие удаления ошибочного
дублирующего state. Для `ThemeMode.system` сохранена прежняя видимая позиция
light; нажатие переводит приложение в dark.

## Созданные файлы

- `lib/features/settings/presentation/theme_mode_toggle.dart`;
- `test/features/settings/presentation/theme_mode_toggle_test.dart`;
- `docs/profile_theme_controller_migration.md`.

## Изменённые файлы

- `lib/profile/profile/profile_widget.dart` — generated toggle заменён на
  feature presentation component без изменения окружающего layout;
- `lib/app_state.dart` — удалён неиспользуемый `isDarkThemeOn`;
- `lib/flutter_flow/flutter_flow_util.dart` — удалён неиспользуемый
  `setDarkModeSetting` и его import.

## Удалённые файлы

- `test/core/theme/theme_boundary_widget_test.dart` — тестировал только
  удалённый временный compatibility helper; его сценарии покрыты тестами
  production-компонента и `ThemeController`.

## Файлы и контракты, которые нельзя менять в этом этапе

- остальные Profile actions, layout, auth/profile queries и navigation;
- `ThemeController`, `ThemeStore` и ключ `__theme_mode__`;
- generated colors, typography, icons и размеры переключателя;
- Supabase schema, RPC, RLS, Edge Functions и Storage policies;
- RevenueCat, Chottu и hosted deep links;
- translations и language flow;
- `pubspec.yaml`, version/build number, Android/iOS/Web configuration.

## Supabase-зависимости

Новых нет. `ThemeModeToggle`, его controller и тесты не импортируют Supabase,
Auth, Storage, generated rows или network clients. Сам экран Profile по-прежнему
использует существующие Supabase profile/auth зависимости, но они не изменялись.
Production write-команды не выполнялись.

## FlutterFlow-зависимости

- сохранены `FlutterFlowTheme` для существующих цветов;
- сохранены generated `FFIcons.ksun` и `FFIcons.kmoon`;
- сохранён существующий `Provider` как переходный DI/state механизм;
- удалены только `FFAppState.isDarkThemeOn` и `setDarkModeSetting` после
  подтверждения нулевого usage;
- другие FlutterFlow helpers и весь generated Profile model сохранены.

## Последовательность изменений

1. Зафиксировать старый layout и все usages двух theme states.
2. Создать feature-scoped `ThemeModeToggle` над `ThemeController`.
3. Сохранить размеры, цвета, icons, padding, shadow и tap semantics.
4. Заменить только theme block внутри Profile.
5. Подтвердить нулевой usage и удалить duplicate state/helper.
6. Добавить geometry, restore, toggle и system-mode tests.
7. Выполнить format, analyze, полный test suite и dependency scans.
8. Собрать Android и iOS.
9. Исключить автоматические platform template migrations из Git diff.
10. Зафиксировать этап отдельным коммитом.

## Необходимые тесты

- размеры toggle и выбранного segment не изменились;
- сохранённый dark отражается при первом render;
- light -> dark -> light проходит через единственный controller/store;
- system mode сохраняет ожидаемую light-позицию;
- persistence/controller/legacy theme compatibility tests продолжают проходить;
- полный существующий test suite продолжает проходить;
- production build создаётся для Android и iOS Simulator.

## Выполненные команды проверки

```bash
dart format --output=none --set-exit-if-changed lib test
flutter test
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter build apk --debug
flutter build ios --simulator --debug --no-pub \
  --dart-define=APP_ENV=integration
rg -n "isDarkThemeOn|setDarkModeSetting" lib test -g '*.dart'
rg -n "SupaFlow|Supabase|backend/supabase|auth_util|storage_client|RevenueCat|Chottu" \
  lib/features/settings/presentation test/features/settings/presentation
git diff --check
```

Результат:

- format: 188 файлов проверено, 0 изменений;
- tests: 41 PASS;
- analyzer: 2282 существующих замечания FlutterFlow-кода, критических ошибок
  нет; это на 15 замечаний меньше предыдущего baseline 2297;
- новые settings presentation файлы: 0 analyzer findings;
- Android debug APK: успешно;
- iOS Simulator build: успешно;
- duplicate state/helper usages: 0;
- запрещённых backend/plugin зависимостей в новом component boundary: 0;
- Android/iOS template migrations полностью исключены из Git diff.

Существующие infrastructure warnings: будущая необходимость обновить
Gradle/AGP/Kotlin, поддержка Swift Package Manager отдельными plugins и iOS
UIScene lifecycle. Они не вызваны этим этапом и требуют отдельных коммитов.

## Ручной чек-лист

- открыть Profile в светлой теме и проверить прежний внешний вид toggle;
- нажать toggle и подтвердить немедленную смену темы и тёмную позицию;
- перезапустить приложение и подтвердить сохранение тёмной позиции;
- переключить обратно в light и повторить restart;
- проверить Profile на малом и большом Android-экране без overflow;
- проверить Profile на iOS;
- проверить Language, Home, Map и Auth в обеих темах;
- убедиться, что переключение не создаёт HTTP/Supabase запросов;
- убедиться, что в логах нет token, phone, device id или других данных.

## Условия отката

Откатить этап одним `git revert`, если:

- тема или позиция toggle не восстанавливаются после restart;
- внешний вид/размеры Profile изменились;
- переключение перестало немедленно перестраивать приложение;
- появились network/Supabase calls или утечки чувствительных данных;
- полный suite, Android или iOS build перестают проходить;
- обнаружен внешний caller удалённых compatibility API.

Storage key и его значения не менялись, поэтому откат не требует миграции
пользовательских данных.

## Предлагаемое сообщение Git-коммита

```text
refactor(profile): use theme controller for toggle
```

## Точный scope следующего этапа

Выделить только read-only список заявок на парковку в вертикальный feature slice:
domain model, repository port, Supabase read adapter, application controller и
presentation boundary. Перед production-кодом сверить текущие table/view/RPC и
RLS-контракты с backend-документацией. Не менять SQL, RLS, RPC, write-actions,
маршруты или визуальный дизайн; сохранить generated экран как внешний shell.

Предлагаемые файлы следующего этапа:

- `lib/features/parking_requests/domain/parking_request_summary.dart`;
- `lib/features/parking_requests/domain/parking_requests_repository.dart`;
- `lib/features/parking_requests/data/supabase_parking_requests_repository.dart`;
- `lib/features/parking_requests/application/parking_requests_controller.dart`;
- `lib/features/parking_requests/presentation/parking_requests_list.dart`;
- `lib/features/parking_requests/presentation/parking_request_card.dart`;
- `lib/requests/requests/requests_widget.dart` — только подключение нового
  presentation boundary с сохранением route/header/layout;
- `test/features/parking_requests/domain/parking_request_summary_test.dart`;
- `test/features/parking_requests/data/supabase_parking_requests_repository_test.dart`;
- `test/features/parking_requests/application/parking_requests_controller_test.dart`;
- `test/features/parking_requests/presentation/parking_requests_list_test.dart`;
- `docs/parking_requests_read_slice.md`.

Проверки после следующего этапа: format, targeted и полный test suite, analyzer
с сравнением baseline, dependency-direction scan, отсутствие write/RPC-contract
изменений, Android debug build и iOS Simulator build.
