# Интеграция слоя чтения карты в Home

Дата: 2026-07-24

Ветка: `agent/home-map-read-integration`

## Выбранный модуль

Пилотный модуль этого этапа — чтение парковок на главном экране
`HomePage`: загрузка маркеров при движении карты, поиск и повторная загрузка
после применения фильтров.

## Почему выбран Home

Нижние слои уже были подготовлены и покрыты контрактными тестами: immutable
domain-модели, repository, Supabase transport и stale-safe controller. Home —
первый реальный consumer этих слоёв и одновременно самый ценный сценарий для
проверки архитектуры. Scope ограничен read-path одного экрана, поэтому не
затрагивает создание парковки, избранное, оплату, auth, hosted deep links или
backend contracts.

## Поведение до этапа

- camera idle, поиск и применение фильтра напрямую вызывали generated
  `GetFilteredParkingsCall` из widget;
- JSON response сохранялся как `dynamic` в `HomePageModel`;
- параллельные camera/search ответы не имели generation guard;
- transport state (`ApiCallResponse`) хранился в presentation model;
- Home невозможно было изолированно подключить к fake repository.

## Новая структура

```text
HomePage
  ├─ ParkingMapController       camera + filter marker reads
  ├─ ParkingMapController       search reads
  ├─ MapFilterSnapshot          единый snapshot FlutterFlow state
  └─ map_read_adapter           typed points -> legacy custom-map shape
             │
             v
     ParkingMapRepository
             │
             v
 SupabaseParkingMapRepository
             │
             v
 public.get_filtered_parkings
```

Два controller нужны намеренно: поиск и viewport — независимые потоки. Ответ
поиска не может заменить маркеры карты, а ответ camera idle не может заменить
список подсказок. Оба используют один stateless repository instance.

`ChangeNotifier` остаётся локальным application controller, а не глобальным
state manager приложения. Domain и data layers не зависят от FlutterFlow,
Provider или конкретной state-management библиотеки.

## Сохранённое поведение

- RPC, его 18 параметров, anonymous headers и JSON contract не изменены;
- существующие `FFAppState` filter values используются без изменения смысла;
- поиск использует прежний lowercase-only normalization;
- старые markers сохраняются во время загрузки и при ошибке;
- успешный пустой ответ очищает markers/search results;
- marker/cluster tap и `ParkingsDetailsWidget` не изменены;
- SelectParking продолжает прежний generated direct RPC;
- parking/photo hosted deep links и share URLs не изменены;
- production write-команды не выполнялись.

## Все связанные файлы

Нижние слои:

- `lib/features/map/domain/map_bounds.dart`;
- `lib/features/map/domain/map_parking_query.dart`;
- `lib/features/map/domain/map_parking_point.dart`;
- `lib/features/map/domain/parking_map_repository.dart`;
- `lib/features/map/data/supabase_parking_map_repository.dart`;
- `lib/features/map/application/parking_map_controller.dart`.

Presentation и Home:

- `lib/features/map/presentation/map_read_adapter.dart`;
- `lib/map/home_page/home_page_widget.dart`;
- `lib/map/home_page/home_page_model.dart`;
- `lib/custom_code/widgets/custom_google_map.dart` — consumer legacy shape,
  не изменён;
- `lib/filter/filter/filter_widget.dart` — источник результата фильтра, не
  изменён;
- `lib/app_state.dart` — источник filter snapshot, не изменён.

Тесты:

- `test/features/map/application/parking_map_controller_test.dart`;
- `test/features/map/presentation/map_read_adapter_test.dart`;
- `test/features/map/presentation/home_map_read_boundary_test.dart`;
- существующие domain/data/legacy map contract tests.

## Supabase-зависимости

- RPC: `public.get_filtered_parkings`;
- transport остаётся generated anonymous REST boundary;
- query сохраняет viewport bounds, center, radius, capacity, amenity flags,
  zoom, search query и `is_filter_active`;
- response adapter ожидает marker/cluster поля `id`, coordinates, `count`,
  `is_cluster`, optional `address` и `rating`;
- schema, function, grants, RLS, Storage и migrations не изменялись.

## FlutterFlow-зависимости

- `FFAppState` пока остаётся источником фильтров;
- `HomePageModel` и `createModel` остаются частью lifecycle экрана;
- `safeSetState`, generated navigation и dialogs сохранены;
- `CustomGoogleMap` пока принимает legacy `List<dynamic>`;
- generated `GetAddressFromCoordsCall` остаётся для reverse geocoding;
- FlutterFlow dependencies не удалялись, пока они используются.

## Созданные файлы

- `lib/features/map/presentation/map_read_adapter.dart`;
- `test/features/map/presentation/map_read_adapter_test.dart`;
- `test/features/map/presentation/home_map_read_boundary_test.dart`;
- `docs/home_map_read_integration.md`.

## Изменённые файлы

- `lib/features/map/application/parking_map_controller.dart`;
- `lib/map/home_page/home_page_widget.dart`;
- `lib/map/home_page/home_page_model.dart`;
- `test/features/map/application/parking_map_controller_test.dart`;
- `docs/flutter_architecture_map.md`;
- `docs/flutter_supabase_usage_map.md`;
- `docs/map_read_controller_slice.md`.

## Файлы, которые нельзя менять в этом этапе

- `lib/create_parking2/select_parking/**`;
- `lib/custom_code/widgets/custom_google_map.dart`;
- auth, profile, subscription, referral и parking detail features;
- `android/**`, `ios/**`, `pubspec.yaml`;
- `supabase/migrations/**` и production backend contracts;
- hosting/deep-link/share implementation.

## Последовательность изменений

1. Добавить pure adapter для filter/query и legacy marker shape.
2. Добавить reset controller с invalidation in-flight response.
3. Инъецировать repository через optional Home composition boundary.
4. Создать отдельные controller для viewport и search.
5. Перевести camera idle на application controller.
6. Перевести search и clear на независимый controller/reset.
7. Перевести filter apply на viewport controller.
8. Удалить transport response fields из `HomePageModel`.
9. Добавить adapter, concurrency и boundary tests.
10. Выполнить статические, unit, regression и build проверки.

## Необходимые тесты

- точное преобразование filter snapshot в query;
- точное immutable преобразование typed point в legacy map shape;
- старый camera/search response не публикуется;
- reset очищает state и инвалидирует pending response;
- repository может быть инъецирован в Home;
- Home source не содержит direct `GetFilteredParkingsCall`;
- существующие 18-parameter RPC contract tests;
- полный regression test suite.

Результаты автоматической проверки этапа:

- map suite: 27 passed;
- полный regression suite: 148 passed;
- scoped analyzer: 0 errors, 0 warnings, 62 существующих info для generated
  Home widget;
- полный analyzer: 0 errors, 696 warnings и 1290 info; до этапа было 721
  warning, уменьшение связано с удалением неиспользуемых generated transport
  fields/imports из изменённого Home model;
- Android debug APK: built;
- iOS simulator debug app: built;
- автоматические Flutter platform upgrades исключены из рабочего дерева.

## Команды проверки

```bash
dart format --output=none --set-exit-if-changed lib/features/map lib/map/home_page test/features/map
flutter analyze lib/features/map lib/map/home_page test/features/map
flutter test test/features/map
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --debug
flutter build ios --simulator --debug --no-codesign
git diff --check
git status --short
```

## Ручной чек-лист

- открыть Home на реальном Android device с production read access;
- дождаться markers и открыть одиночную парковку;
- быстро выполнить несколько pan/zoom: карта не возвращается к старому
  viewport;
- открыть cluster и проверить прежнюю реакцию;
- выполнить поиск, выбрать результат и очистить поле;
- применить и сбросить каждый тип фильтра;
- отключить сеть во время pan: прежние markers не исчезают;
- вернуть сеть и повторить движение карты;
- проверить guest и authenticated session;
- открыть существующую hosted parking link и photo link;
- начать add parking и убедиться, что SelectParking не изменился.

## Условия отката

Откатить один коммит интеграции, если:

- Home не загружает markers или поиск;
- stale response заменяет новый viewport/search;
- marker/cluster tap или parking details меняются;
- filters передают другой query contract;
- guest/auth поведение изменяется;
- hosted parking/photo links получают регрессию;
- появляется новая analyzer error или падает regression/build.

Backend rollback не нужен: сервер не изменялся.

## Следующий отдельный этап

Сначала выполнить ручной Android smoke test этого Home slice. После
подтверждения — отдельным коммитом подключить тот же repository/controller к
`SelectParking`, не меняя write-flow создания парковки. Не объединять это с
переходом `CustomGoogleMap` на typed marker API.

## Предлагаемое сообщение Git-коммита

```text
refactor(map): route home reads through controller
```
