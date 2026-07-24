# Интеграция слоя чтения карты в SelectParking

Дата: 2026-07-24

Ветка: `agent/select-parking-map-read-integration`

## Выбранный модуль

Выбран read-path существующих парковок на экране `SelectParking`, который
используется перед добавлением новой парковки.

## Почему выбран этот модуль

Home уже проверил новый map read layer в реальном consumer. `SelectParking`
был последним активным экраном, который напрямую вызывал generated
`GetFilteredParkingsCall`. Его перевод завершает изоляцию активных map reads,
но остаётся небольшим и откатываемым этапом: long press, reverse geocoding и
создание парковки не меняются.

## Поведение до этапа

- каждый camera idle напрямую вызывал `GetFilteredParkingsCall` из widget;
- generated `ApiCallResponse` сохранялся в `SelectParkingModel`;
- JSON result передавался в custom map как `dynamic`;
- быстрые pan/zoom могли завершиться в обратном порядке и показать старый
  viewport;
- repository нельзя было подменить в тесте.

## Новая структура

```text
SelectParkingWidget
  ├─ local ParkingMapController
  ├─ MapFilterSnapshot
  └─ typed-to-legacy presentation adapter
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

Controller принадлежит lifecycle экрана и корректно dispose. Repository
может быть передан через constructor для тестов и будущей composition root.
Это локальный application state, а не глобальный state manager.

## Сохранённое поведение

- camera bounds, center, zoom и текущий `FFAppState` filter snapshot передаются
  с прежней семантикой;
- RPC `public.get_filtered_parkings` и все 18 параметров не изменены;
- marker и cluster response shape для `CustomGoogleMap` сохранён adapter-ом;
- старые markers сохраняются во время загрузки и при read failure;
- marker tap по-прежнему открывает `ParkingsDetailsWidget`;
- long press по-прежнему записывает временные координаты, выполняет reverse
  geocoding и открывает `CreateParkingDialog2Widget`;
- route name/path не изменены;
- production write-команды не выполнялись.

## Все связанные файлы

Изменённые consumers:

- `lib/create_parking2/select_parking/select_parking_widget.dart`;
- `lib/create_parking2/select_parking/select_parking_model.dart`.

Повторно используемый map layer, без изменений:

- `lib/features/map/domain/map_bounds.dart`;
- `lib/features/map/domain/map_parking_query.dart`;
- `lib/features/map/domain/map_parking_point.dart`;
- `lib/features/map/domain/parking_map_repository.dart`;
- `lib/features/map/data/supabase_parking_map_repository.dart`;
- `lib/features/map/application/parking_map_controller.dart`;
- `lib/features/map/presentation/map_read_adapter.dart`.

Сохранённые legacy/write dependencies:

- `lib/custom_code/widgets/custom_google_map.dart`;
- `lib/create_parking2/create_parking_dialog2/**`;
- `lib/backend/api_requests/api_calls.dart` — reverse geocoding и нижний
  repository transport;
- `lib/app_state.dart`.

Тесты:

- `test/features/map/presentation/select_parking_map_read_boundary_test.dart`;
- существующие domain/data/controller/adapter/Home boundary tests.

## Supabase-зависимости

- read RPC: `public.get_filtered_parkings`;
- generated anonymous REST transport остаётся внутри data source;
- response парсится в immutable `MapParkingPoint`;
- malformed response и transport failure redacted до typed failure;
- database schema, functions, RLS, grants и migrations не менялись.

Write-path создания парковки на этом этапе не анализировался и не менялся.

## FlutterFlow-зависимости

- `FFAppState` остаётся источником map filter values и временных координат;
- `SelectParkingModel`, `createModel` и `safeSetState` сохранены;
- `CustomGoogleMap` пока принимает legacy `List<dynamic>`;
- reverse geocoding позднее вынесен в typed shared boundary; generated call
  остался только внутри data source;
- `CreateParkingDialog2Widget` остаётся generated write-flow;
- FlutterFlow dependencies не удалялись, пока они используются.

## Созданные файлы

- `test/features/map/presentation/select_parking_map_read_boundary_test.dart`;
- `docs/select_parking_map_read_integration.md`.

## Изменённые файлы

- `lib/create_parking2/select_parking/select_parking_widget.dart`;
- `lib/create_parking2/select_parking/select_parking_model.dart`;
- `docs/flutter_architecture_map.md`;
- `docs/flutter_supabase_usage_map.md`;
- `docs/home_map_read_integration.md`.

## Файлы, которые нельзя менять в этом этапе

- `lib/create_parking2/create_parking_dialog2/**`;
- остальные шаги create parking flow;
- `lib/map/home_page/**` и `CustomGoogleMap`;
- auth, profile, subscription, referral, sharing и deep links;
- `android/**`, `ios/**`, `pubspec.yaml`;
- `supabase/migrations/**` и production backend contracts.

## Последовательность изменений

1. Создать отдельную ветку от проверенного Home integration commit.
2. Добавить optional repository injection в `SelectParkingWidget`.
3. Создать и dispose локальный `ParkingMapController`.
4. Снимать immutable query/filter snapshot при camera idle.
5. Передавать loaded typed points через legacy presentation adapter.
6. Удалить generated map transport response из model.
7. Добавить boundary test для route, injection и отсутствия direct RPC.
8. Защитить тестом сохранение reverse geocoding/create dialog flow.
9. Выполнить format, analyze, tests и builds.

## Необходимые тесты

- route name/path не меняются;
- repository можно инъецировать;
- SelectParking source не вызывает `GetFilteredParkingsCall` напрямую;
- controller и adapter присутствуют на read boundary;
- direct `GetAddressFromCoordsCall` отсутствует, а
  `CreateParkingDialog2Widget` остаётся;
- map domain/data/controller contracts продолжают проходить;
- полный regression suite.

Результаты автоматической проверки этапа:

- map suite: 29 passed;
- полный regression suite: 150 passed;
- scoped analyzer: 0 errors, 0 warnings, 12 существующих info для generated
  SelectParking widget;
- полный analyzer: 0 errors, 686 warnings и 1290 info; до этапа было 696
  warnings, уменьшение связано с удалением неиспользуемого generated
  transport state/imports из изменённого model;
- Android debug APK: built;
- iOS simulator debug app: built;
- автоматические Flutter platform upgrades исключены из рабочего дерева.

## Команды проверки

```bash
dart format --output=none --set-exit-if-changed lib/features/map lib/create_parking2/select_parking test/features/map
flutter analyze lib/features/map lib/create_parking2/select_parking test/features/map
flutter test test/features/map
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --debug
flutter build ios --simulator --debug --no-codesign
git diff --check
git status --short
```

## Ручной чек-лист

- открыть flow добавления парковки на authenticated production-like build;
- перейти на SelectParking и дождаться существующих markers;
- быстро выполнить pan/zoom и убедиться, что старый viewport не возвращается;
- открыть существующую парковку marker tap;
- выполнить long press в свободной точке;
- проверить найденный адрес и открытие create dialog;
- закрыть dialog без сохранения;
- повторить long press с отключённой/нестабильной сетью;
- убедиться, что existing markers не исчезают при read failure;
- проверить, что Home map/search/filter не получили регрессию;
- проверить hosted parking/photo links.

## Условия отката

Откатить один коммит этапа, если:

- SelectParking перестал показывать existing markers;
- stale response заменяет новый viewport;
- marker tap перестал открывать детали;
- long press, reverse geocoding или create dialog изменились;
- route contract изменился;
- появилась новая analyzer error/warning или упала regression/build.

Backend rollback не требуется: сервер и production data не менялись.

## Следующий отдельный этап

Reverse geocoding изолирован следующим отдельным этапом без изменения create
write-flow. Актуальный отчёт: `docs/reverse_geocoding_read_integration.md`.
Следующий возможный этап — typed API для `CustomGoogleMap`, устраняющий
последний `List<dynamic>` presentation adapter.

## Предлагаемое сообщение Git-коммита

```text
refactor(map): isolate select parking reads
```
