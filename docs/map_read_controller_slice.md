# Controller-срез чтения парковок для карты

Дата: 2026-07-24

Ветка: `agent/map-read-controller`

## Выбранный модуль и причина

Выбран application-state слой карты между `ParkingMapRepository` и будущим
Home composition boundary. Repository уже изолирует Supabase transport, но без
controller UI по-прежнему должен был бы самостоятельно управлять параллельными
camera requests, loading, failure и retry.

Главный риск текущей карты — ответы приходят не обязательно в порядке
запросов. При быстром перемещении старый viewport может заменить новый. Этот
этап устраняет риск внутри тестируемого application слоя до подключения UI.

## Текущее production-поведение

- Home и SelectParking пока продолжают generated direct RPC calls;
- production widgets и custom map не импортируют новый controller;
- UI, markers, filters, search, deep links и write-flow не изменены;
- backend/RPC/headers не изменены;
- новый controller локален будущему экземпляру карты и не является глобальным
  state manager приложения.

## Реализованная структура

```text
future Home/SelectParking composition boundary
                    |
                    v
ParkingMapController (ChangeNotifier)
  ParkingMapState
    idle | loading | loaded | failure
  current query snapshot
  immutable points
  typed failure kind
  request generation guard
  retry last query
                    |
                    v
ParkingMapRepository
                    |
                    v
Generated anonymous Supabase RPC data source
```

`ChangeNotifier` здесь используется как небольшой Flutter-compatible adapter.
Domain и data layers от него не зависят. При дальнейшей смене state-management
библиотеки repository/domain останутся неизменными.

## Сохранённая семантика

Текущая карта не очищает старые markers во время нового запроса и после
сетевой ошибки. Controller повторяет это поведение:

- `loading` сохраняет предыдущий immutable список points;
- `failure` сохраняет предыдущие points и добавляет typed failure;
- успешный пустой результат очищает markers;
- retry повторяет последний query;
- retry до первого query ничего не делает.

## Защита от конкурентных ответов

Каждый `load(query)` получает generation number. State меняет только ответ,
generation которого всё ещё является последним. Поэтому:

- старый success не заменит новый viewport;
- старый failure не заменит новый success;
- ответ после `dispose()` игнорируется;
- настоящая сетевая cancellation пока не требуется для корректности и может
  быть добавлена отдельно после замеров.

## Связанные файлы

Новый application layer:

- `lib/features/map/application/parking_map_controller.dart`.

Domain/data dependencies:

- `lib/features/map/domain/map_bounds.dart`;
- `lib/features/map/domain/map_parking_query.dart`;
- `lib/features/map/domain/map_parking_point.dart`;
- `lib/features/map/domain/parking_map_repository.dart`;
- `lib/features/map/data/supabase_parking_map_repository.dart`.

Production consumers, не изменены:

- `lib/map/home_page/home_page_widget.dart`;
- `lib/map/home_page/home_page_model.dart`;
- `lib/create_parking2/select_parking/select_parking_widget.dart`;
- `lib/create_parking2/select_parking/select_parking_model.dart`;
- `lib/custom_code/widgets/custom_google_map.dart`;
- `lib/filter/filter/filter_widget.dart`;
- `lib/app_state.dart`.

## Supabase-зависимости

Controller знает только `ParkingMapRepository` и типы domain failure. Он не
знает URL, key, headers, `ApiCallResponse`, JSONPath, RLS или SQL.

Фактический нижний boundary остаётся прежним:

- `public.get_filtered_parkings`;
- anonymous REST headers;
- 18 RPC parameters;
- marker/cluster JSON response.

Supabase functions, schema, RLS, grants и production data не изменялись.
Production write-команды не выполнялись.

## FlutterFlow-зависимости

- controller зависит только от Flutter `ChangeNotifier`/`@immutable`;
- `FFAppState`, generated models, Widgets и BuildContext не используются;
- Home/SelectParking integration пока отсутствует;
- существующий FlutterFlow lifecycle можно будет сохранить через создание и
  dispose controller в wrapper State;
- глобальный Provider приложения не меняется.

## Созданные файлы

- `lib/features/map/application/parking_map_controller.dart`;
- `test/features/map/application/parking_map_controller_test.dart`;
- `docs/map_read_controller_slice.md`.

## Изменённые файлы

- `docs/map_read_repository_slice.md`;
- `docs/map_read_contract_characterization.md`.

## Файлы, которые нельзя менять в этом этапе

- Home/SelectParking/custom map/filter production UI;
- generated API wrappers;
- Supabase backend;
- parking creation writes;
- parking/photo/referral deep links и Hosting;
- Android/iOS/signing/store configuration и `pubspec.yaml`.

## Последовательность изменений

1. Добавить immutable `ParkingMapState`.
2. Добавить четыре явные фазы.
3. Сохранять query snapshot в каждом активном state.
4. Сохранять прежние markers при loading/failure.
5. Публиковать immutable result при success.
6. Добавить generation guard.
7. Добавить retry последнего query.
8. Redact unexpected exception как `unavailable`.
9. Инвалидировать pending response при dispose.
10. Не подключать production UI в этом коммите.

## Тесты

- loading → immutable loaded result;
- прежние markers во время следующего viewport load;
- старый success игнорируется;
- старый failure игнорируется;
- failure сохраняет markers и typed kind;
- retry повторяет тот же query;
- retry до первого query — no-op;
- unexpected exception становится redacted unavailable;
- response после dispose не публикуется;
- repository/data/characterization tests продолжают проходить.

Результаты:

- map tests: 22 passed;
- полный набор: 143 passed;
- analyzer новых map files/tests: 0 issues;
- полный analyzer: 0 errors, 721 warnings и 1290 info — 2011 ранее
  существовавших замечаний generated FlutterFlow-кода;
- Android debug APK: built;
- iOS simulator debug app: built;
- автоматические Flutter platform upgrades исключены из рабочего дерева.

## Команды проверки

```bash
dart format --output=none --set-exit-if-changed lib/features/map test/features/map
flutter analyze lib/features/map test/features/map
flutter test test/features/map
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --debug
flutter build ios --simulator --debug --no-codesign
git diff --check
git status --short
```

## Ручной чек-лист будущего Home-подключения

- прежние markers видны во время движения карты;
- быстрые pan/zoom не возвращают старую область;
- пустой успешный ответ очищает markers;
- network failure не очищает markers;
- retry получает текущий viewport/filter snapshot;
- search и filter reset не конфликтуют с camera idle;
- marker/cluster tap и parking bottom sheet не меняются;
- hosted parking/photo links не получают регрессию;
- Android real-device smoke test с production read-only Supabase.

## Условия отката

Откатить один controller-коммит, если:

- production widget был изменён в этом этапе;
- controller публикует stale response;
- loading/failure очищают предыдущие markers;
- raw transport details попадают в state;
- dispose приводит к позднему notify;
- tests/analyzer/build получают новую регрессию.

Backend rollback не требуется.

## Следующий отдельный этап

Подключить controller только к Home через явный composition boundary:

- создать controller в State и корректно dispose;
- преобразовать `FFAppState` filter snapshot в `MapParkingQuery` в одном месте;
- передать typed points в presentation adapter, сохранив пока формат custom map;
- не менять SelectParking;
- добавить Home boundary/widget tests и real-device APK smoke test.

## Сообщение Git-коммита

```text
refactor(map): add stale-safe read controller
```
