# Типизированный контракт результатов поиска карты

Дата: 2026-07-24

Ветка: `agent/typed-map-search-results`

## Выбранный модуль

Search presentation boundary на `HomePage`: преобразование результатов
`ParkingMapController`, состояние search panel, выбор результата и открытие
`ParkingsDetailsWidget`.

## Почему он выбран

После типизации marker renderer это был последний `List<dynamic>` в основном
map flow. UI повторно разбирал уже валидированные данные через
`getJsonField`, поэтому опечатка в JSONPath или случайная смена формы map могла
обнаружиться только во время выполнения.

Узкий typed result безопасен как следующий этап, потому что repository,
controller, search query и navigation уже изолированы и не требуют изменения
Supabase-контракта.

## Текущее поведение до этапа

1. Пользователь вводит текст; применяется debounce 500 ms.
2. Строка приводится к lower-case существующей FlutterFlow-функцией.
3. Текущий viewport и filter snapshot отправляются в тот же
   `public.get_filtered_parkings` с zoom `20.0`.
4. Typed `MapParkingPoint` превращается обратно в legacy map.
5. `HomePageModel.searchResults` хранит `List<dynamic>`.
6. Search panel получает `lat`, `lng`, `id` и `address` через JSONPath.
7. Tap перемещает карту, закрывает поиск и открывает details выбранного ID.

## Новая структура

```text
ParkingMapController.state.points
              │
              v
      MapParkingPoint (domain)
              │
              v
 toMapSearchResultItems (pure adapter)
              │
              v
 MapSearchResultItem (immutable presentation)
              │
              v
 HomePageModel.searchResults
              │
              v
 typed search panel / details navigation
```

`MapSearchResultItem` содержит только фактически используемые UI-поля:
`id`, `latitude`, `longitude`, nullable `address`. Cluster/count/rating и
transport keys в search UI не передаются.

## Сохранённое поведение

- debounce остаётся 500 ms;
- search normalization и zoom `20.0` не меняются;
- bounds и все filter values не меняются;
- отсутствие адреса по-прежнему показывает `No address`;
- tap выбирает те же coordinates и parking ID;
- search controller reset, keyboard hide и details bottom sheet сохранены;
- stale-response защита controller не меняется;
- marker/cluster renderer, long press и reverse geocoding не меняются;
- Supabase/RPC/write/deep-link contracts не меняются.

## Все связанные файлы

Domain/application/data:

- `lib/features/map/domain/map_parking_point.dart`;
- `lib/features/map/domain/map_parking_query.dart`;
- `lib/features/map/application/parking_map_controller.dart`;
- `lib/features/map/data/supabase_parking_map_repository.dart`.

Presentation:

- `lib/features/map/presentation/map_search_result_item.dart`;
- `lib/features/map/presentation/map_read_adapter.dart`;
- `lib/map/home_page/home_page_widget.dart`;
- `lib/map/home_page/home_page_model.dart`;
- `lib/create_parking2/select_parking/select_parking_model.dart`.

Tests:

- `test/features/map/presentation/map_search_result_contract_test.dart`;
- `test/features/map/presentation/map_read_adapter_test.dart`;
- `test/features/map/presentation/home_map_read_boundary_test.dart`;
- существующие map domain/data/controller/renderer tests.

## Supabase-зависимости

- read RPC `public.get_filtered_parkings`;
- existing anonymous generated transport;
- те же 18 `MapParkingQuery` parameters;
- domain parser `MapParkingPoint.parseFilteredRpcResponse`;
- database schema, SQL functions, RLS, grants и migrations не меняются.

## FlutterFlow-зависимости

- `HomePageModel` и `SelectParkingModel` lifecycle сохранены;
- `safeSetState`, `FFAppState`, generated theme/navigation/dialogs сохранены;
- `EasyDebounce` и `functions.textToLower` сохранены;
- FlutterFlow `LatLng` используется как camera target;
- `getJsonField` удалён только из typed Home search consumer;
- generated model helper methods сохранены, но получили typed signatures.

## Файлы, которые создаются

- `lib/features/map/presentation/map_search_result_item.dart`;
- `test/features/map/presentation/map_search_result_contract_test.dart`;
- `docs/typed_map_search_results.md`.

## Файлы, которые изменяются

- `lib/features/map/presentation/map_read_adapter.dart`;
- `lib/map/home_page/home_page_widget.dart`;
- `lib/map/home_page/home_page_model.dart`;
- `lib/create_parking2/select_parking/select_parking_model.dart`;
- `test/features/map/presentation/map_read_adapter_test.dart`;
- `test/features/map/presentation/home_map_read_boundary_test.dart`;
- map architecture documents.

## Файлы, которые нельзя менять

- `lib/features/map/data/supabase_parking_map_repository.dart`;
- `lib/backend/api_requests/api_calls.dart`;
- `lib/custom_code/widgets/custom_google_map.dart`;
- create parking write flow;
- auth, referral, subscription, sharing и deep links;
- `android/**`, `ios/**`, `pubspec.yaml`;
- `supabase/migrations/**` и production backend contracts.

## Последовательность изменений

1. Зафиксировать четыре реально используемых search fields.
2. Добавить immutable presentation model.
3. Заменить legacy adapter на pure typed adapter.
4. Типизировать generated model state/helpers.
5. Заменить JSONPath в Home на прямой доступ к полям.
6. Сохранить selection/navigation sequence.
7. Добавить contract/boundary tests.
8. Выполнить format, analyze, tests и platform builds.

## Необходимые тесты

- adapter сохраняет ID, coordinates и nullable address;
- result list immutable;
- model equality стабильна;
- Home и SelectParking models не содержат dynamic search state;
- Home не использует `toLegacyMapItems` или `getJsonField`;
- Home использует typed adapter;
- marker/repository/controller tests продолжают проходить;
- полный regression suite.

Результаты scoped-проверки:

- map suite: 34 passed;
- scoped analyzer: 0 errors и warnings, только существующие generated info.

Результаты полной проверки:

- полный regression suite: 165 passed;
- полный analyzer: 0 errors, 686 существующих warnings и 1289 info;
- новые analyzer warnings не добавились;
- Android debug APK: built;
- iOS simulator debug app: built;
- автоматические Flutter platform upgrades исключены из рабочего дерева.

## Команды проверки

```bash
dart format --output=none --set-exit-if-changed lib/features/map lib/map/home_page lib/create_parking2/select_parking test/features/map
flutter analyze --no-fatal-infos --no-fatal-warnings lib/features/map lib/map/home_page lib/create_parking2/select_parking test/features/map
flutter test test/features/map
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --debug
flutter build ios --simulator --debug --no-codesign
git diff --check
git status --short
```

## Ручной чек-лист

- открыть Home и дождаться markers;
- ввести часть существующего адреса;
- проверить тот же порядок и текст результатов;
- нажать результат и проверить перемещение карты;
- проверить открытие правильной парковки;
- проверить строку без результатов;
- очистить строку и проверить закрытие списка;
- быстро менять запрос и убедиться, что старый ответ не заменяет новый;
- проверить поиск с активными filters;
- проверить marker/cluster tap и long press;
- проверить hosted parking/photo deep links.

## Условия отката

Откатить один коммит этапа, если:

- поиск не показывает существующую парковку;
- адрес или fallback изменился;
- tap перемещает карту к неверным координатам;
- открывается неверный parking ID;
- stale search response возвращается после нового запроса;
- marker/create/deep-link flow получил регрессию;
- появилась новая analyzer error/warning;
- regression suite или platform build не проходит.

Backend rollback не требуется.

## Следующий отдельный этап

Search panel выделен из большого generated Home widget следующим отдельным
этапом с typed callbacks. Актуальный отчёт:
`docs/home_map_search_panel_extraction.md`.

## Предлагаемое сообщение Git-коммита

```text
refactor(map): type search result presentation
```
