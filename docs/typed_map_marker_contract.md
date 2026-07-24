# Типизированный контракт маркеров карты

Дата: 2026-07-24

Ветка: `agent/typed-map-marker-contract`

## Выбранный модуль

Presentation boundary между `HomePageWidget` / `SelectParkingWidget` и
FlutterFlow custom widget `CustomGoogleMap`.

## Почему он выбран

Map repository и controller уже возвращают валидированные immutable
`MapParkingPoint`, но перед самой отрисовкой данные снова превращались в
`List<dynamic>`. `CustomGoogleMap` был вынужден знать строковые ключи ответа
`id`, `lat`, `lng`, `count`, `is_cluster` и тихо пропускал ошибочные элементы.

Это последний dynamic boundary основного marker flow. Его устранение:

- делает контракт между экраном и renderer проверяемым компилятором;
- не позволяет случайно передать search/backend map вместо marker model;
- локализует изменения Google Maps renderer;
- упрощает дальнейшее разделение UI и FlutterFlow generated state;
- не требует изменения Supabase, RPC, SQL или пользовательского сценария.

## Текущее поведение до этапа

1. Repository парсит RPC response в `MapParkingPoint`.
2. Controller публикует immutable список typed points.
3. `toLegacyMapItems` превращает points обратно в maps.
4. `HomePageModel` и `SelectParkingModel` хранят `List<dynamic>?`.
5. `CustomGoogleMap` повторно читает map keys и ловит любые ошибки через
   `catch`, молча пропуская marker.
6. Parking marker вызывает callback с ID; cluster marker увеличивает zoom на
   два уровня. Объявленный `onClusterTap` исторически не вызывается.

## Новая структура

```text
public.get_filtered_parkings
          │
          v
SupabaseParkingMapRepository
          │ validated
          v
   MapParkingPoint (domain)
          │
          v
    ParkingMapController
          │
          v
toMapMarkerItems (presentation adapter)
          │
          v
    MapMarkerItem (immutable)
          │
          v
     CustomGoogleMap
          │
          v
 google_maps.Marker
```

Search results пока используют отдельный legacy map shape, потому что search
panel читает дополнительные поля `address` и `rating`. Его миграция должна
быть отдельным этапом.

## Сохранённое поведение

- те же parking и cluster ID, координаты и count;
- тот же marker icon и размер;
- cluster tap по-прежнему только приближает карту на два zoom level;
- parking marker tap по-прежнему открывает `ParkingsDetailsWidget`;
- visible bounds, camera idle, long press и current location не менялись;
- поиск, фильтры и сохранение старых markers при read failure не менялись;
- создание парковки и reverse geocoding не менялись;
- Supabase read/write contracts и production data не менялись;
- hosted parking/photo links не менялись.

## Все связанные файлы

Typed domain/application/data:

- `lib/features/map/domain/map_parking_point.dart`;
- `lib/features/map/domain/parking_map_repository.dart`;
- `lib/features/map/data/supabase_parking_map_repository.dart`;
- `lib/features/map/application/parking_map_controller.dart`.

Presentation и renderer:

- `lib/features/map/presentation/map_marker_item.dart`;
- `lib/features/map/presentation/map_read_adapter.dart`;
- `lib/custom_code/widgets/custom_google_map.dart`;
- `lib/map/home_page/home_page_widget.dart`;
- `lib/map/home_page/home_page_model.dart`;
- `lib/create_parking2/select_parking/select_parking_widget.dart`;
- `lib/create_parking2/select_parking/select_parking_model.dart`.

Тесты:

- `test/features/map/presentation/map_read_adapter_test.dart`;
- `test/features/map/presentation/custom_google_map_marker_contract_test.dart`;
- `test/features/map/presentation/home_map_read_boundary_test.dart`;
- `test/features/map/presentation/select_parking_map_read_boundary_test.dart`;
- существующие map domain/data/controller/legacy tests.

## Supabase-зависимости

- `public.get_filtered_parkings`;
- anonymous generated transport внутри `GeneratedAnonymousParkingMapDataSource`;
- все 18 параметров `MapParkingQuery`;
- response keys валидируются только в data/domain boundary;
- migrations, functions, grants и RLS не изменяются.

Новый `MapMarkerItem` не знает о Supabase и JSON.

## FlutterFlow-зависимости

- `CustomGoogleMap` остаётся FlutterFlow custom widget;
- обязательный auto-import block custom widget сохранён;
- `HomePageModel`, `SelectParkingModel`, `createModel` и `safeSetState`
  сохранены;
- `FFAppState` остаётся источником filters, guest state и временных координат;
- FlutterFlow `LatLng`, navigation, dialogs и theme не менялись;
- legacy search results остаются `List<dynamic>` до отдельной миграции.

## Файлы, которые создаются

- `lib/features/map/presentation/map_marker_item.dart`;
- `test/features/map/presentation/custom_google_map_marker_contract_test.dart`;
- `docs/typed_map_marker_contract.md`.

## Файлы, которые изменяются

- `lib/features/map/presentation/map_read_adapter.dart`;
- `lib/custom_code/widgets/custom_google_map.dart`;
- `lib/map/home_page/home_page_widget.dart`;
- `lib/map/home_page/home_page_model.dart`;
- `lib/create_parking2/select_parking/select_parking_widget.dart`;
- `lib/create_parking2/select_parking/select_parking_model.dart`;
- четыре map presentation test files;
- архитектурные документы карты.

## Файлы, которые нельзя менять на этом этапе

- `lib/backend/api_requests/api_calls.dart`;
- `lib/features/map/data/supabase_parking_map_repository.dart`;
- auth, referral, subscription, sharing и deep-link flows;
- create parking dialogs и write flow;
- `android/**`, `ios/**`, `pubspec.yaml`;
- `supabase/migrations/**` и production backend contracts.

## Последовательность изменений

1. Зафиксировать dynamic marker keys и callback behavior.
2. Добавить immutable presentation model без transport knowledge.
3. Добавить pure adapter `MapParkingPoint -> MapMarkerItem`.
4. Типизировать local model state Home и SelectParking.
5. Переключить оба экрана на новый adapter.
6. Удалить map-key parsing из `CustomGoogleMap`.
7. Сохранить cluster/marker tap semantics.
8. Защитить contract и consumers тестами.
9. Выполнить format, analyze, tests и platform builds.

## Необходимые тесты

- adapter сохраняет ID, coordinates, count и cluster flag;
- returned marker list immutable;
- `CustomGoogleMap` принимает `List<MapMarkerItem>`;
- renderer больше не читает dynamic map keys;
- Home и SelectParking используют `toMapMarkerItems`;
- legacy map adapter остаётся только для search consumers;
- marker details/create flow boundary остаётся подключённым;
- полный regression suite.

Результаты scoped-проверки:

- map suite: 32 passed;
- analyzer: 0 errors; auto-generated FlutterFlow imports и существующие
  generated files продолжают выдавать прежние warnings/info.

Результаты полной проверки:

- полный regression suite: 163 passed;
- полный analyzer: 0 errors, 686 существующих warnings и 1289 info;
- по сравнению с предыдущим этапом warnings не добавились, количество info
  уменьшилось на одно после удаления dynamic parsing/catch;
- Android debug APK: built;
- iOS simulator debug app: built;
- автоматические Flutter platform upgrades исключены из рабочего дерева.

## Команды проверки

```bash
dart format --output=none --set-exit-if-changed lib/features/map lib/custom_code/widgets/custom_google_map.dart lib/map/home_page lib/create_parking2/select_parking test/features/map
flutter analyze --no-fatal-infos --no-fatal-warnings lib/features/map lib/custom_code/widgets/custom_google_map.dart lib/map/home_page lib/create_parking2/select_parking test/features/map
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
- нажать parking marker и открыть правильную карточку;
- нажать cluster и проверить увеличение zoom;
- быстро выполнить pan/zoom и проверить обновление markers;
- выполнить поиск и открыть результат;
- применить и очистить filters;
- открыть SelectParking и повторить marker/cluster проверки;
- выполнить long press и открыть create dialog без сохранения;
- проверить поведение с временно отключённой сетью;
- проверить hosted parking/photo deep links.

## Условия отката

Откатить один коммит этапа, если:

- marker или cluster исчезли либо получили неверную позицию;
- marker tap открывает неправильную парковку;
- cluster tap перестал увеличивать zoom;
- search/filter/read failure behavior изменилось;
- create parking или reverse geocoding получили регрессию;
- появилась новая analyzer error/warning;
- regression suite или platform build не проходит.

Backend rollback не требуется.

## Следующий отдельный этап

После real-device smoke test следующий безопасный кандидат — typed search
result presentation model. Он устранит оставшийся `List<dynamic>` в Home и
SelectParking, не затрагивая Supabase contracts.

## Предлагаемое сообщение Git-коммита

```text
refactor(map): type custom marker contract
```
