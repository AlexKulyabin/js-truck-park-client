# Repository-срез чтения парковок для карты

Дата: 2026-07-24

Ветка: `agent/map-read-repository`

## Выбранный модуль и причина

Выбран data boundary активного RPC `get_filtered_parkings`. Предыдущий этап
зафиксировал его фактический контракт; теперь можно добавить масштабируемый
repository слой, не меняя одновременно Home, SelectParking, карту или SQL.

Это отделяет Supabase/FlutterFlow transport от domain types и позволяет
следующим коммитом создать controller с защитой от stale camera responses.

## Текущее production-поведение

- Home и SelectParking продолжают напрямую вызывать generated
  `GetFilteredParkingsCall`;
- RPC по-прежнему получает anonymous headers и ровно 18 параметров;
- dynamic JSON по-прежнему передаётся в `CustomGoogleMap`;
- search, filters, marker/cluster tap, parking creation и deep links не
  изменены;
- новые repository/data-source классы production UI пока не импортирует.

## Реализованная структура

```text
ParkingMapRepository (domain contract)
            |
            v
SupabaseParkingMapRepository
  - query validation
  - typed immutable result
  - redacted failures
            |
            v
ParkingMapDataSource
            |
            v
GeneratedAnonymousParkingMapDataSource
  - exact 18-parameter map
  - existing GetFilteredParkingsCall
  - explicit non-2xx failure
```

Название data source намеренно содержит `Anonymous`: это не скрывает текущую
authorization semantics. Переход к authenticated RPC нельзя выполнять
неявно, потому что он активирует admin-ветку существующей SQL-функции.

## Все связанные файлы

Новый boundary:

- `lib/features/map/domain/map_bounds.dart`;
- `lib/features/map/domain/map_parking_query.dart`;
- `lib/features/map/domain/map_parking_point.dart`;
- `lib/features/map/domain/parking_map_repository.dart`;
- `lib/features/map/data/supabase_parking_map_repository.dart`.

Legacy transport, не изменён:

- `lib/backend/api_requests/api_calls.dart`;
- `lib/backend/api_requests/api_manager.dart`;
- `lib/core/config/app_config.dart`.

Production consumers, не изменены:

- `lib/map/home_page/home_page_widget.dart`;
- `lib/map/home_page/home_page_model.dart`;
- `lib/create_parking2/select_parking/select_parking_widget.dart`;
- `lib/create_parking2/select_parking/select_parking_model.dart`;
- `lib/custom_code/widgets/custom_google_map.dart`;
- `lib/filter/filter/filter_widget.dart`;
- `lib/app_state.dart`.

Backend evidence:

- `diagnostics/supabase_schema_2026-07-23.sql`;
- `docs/map_read_contract_characterization.md`;
- `docs/supabase_backend_reference.md`;
- `docs/backend_security_audit.md`.

## Supabase-зависимости

- RPC: `public.get_filtered_parkings`;
- source table: `public.parkings`;
- transport: REST wrapper `GetFilteredParkingsCall`;
- headers: publishable key как `apikey` и anonymous Bearer;
- result: JSON list marker/cluster;
- SQL, RLS, grants, indexes, Storage и production data не менялись;
- production write-команды не выполнялись.

Repository проверяет до transport:

- finite и допустимые coordinate ranges;
- правильный порядок latitude bounds;
- antimeridian viewport отклоняется, потому что текущий SQL его не понимает;
- finite zoom;
- finite non-negative radius;
- non-negative capacity и `max >= min`.

Это защита client boundary, но не замена server-side validation.

## FlutterFlow-зависимости

- существующий static `GetFilteredParkingsCall` сохранён;
- `ApiCallResponse` остаётся transport result;
- все generated models, `FFAppState`, filters и custom widget сохранены;
- новый domain/repository слой не зависит от Widget/BuildContext/FFAppState;
- FlutterFlow code можно будет заменять по одному composition boundary.

## Созданные файлы

- `lib/features/map/domain/parking_map_repository.dart`;
- `lib/features/map/data/supabase_parking_map_repository.dart`;
- `test/features/map/data/supabase_parking_map_repository_test.dart`;
- `docs/map_read_repository_slice.md`.

## Изменённые файлы

- `docs/map_read_contract_characterization.md`;
- `docs/flutter_supabase_usage_map.md`.

## Файлы, которые нельзя менять в этом этапе

- production Home/SelectParking/custom map/filter UI;
- generated API wrapper и API manager;
- Supabase schema/functions/RLS/grants/data;
- parking creation write-flow;
- parking/photo/referral deep links;
- Android/iOS/signing/store configuration и `pubspec.yaml`.

## Последовательность изменений

1. Добавить domain repository contract.
2. Добавить injectable data-source boundary.
3. Передавать точную 18-параметровую map без string interpolation в domain.
4. Сохранить generated anonymous transport.
5. Явно обрабатывать non-2xx.
6. Проверять структурно некорректный query до сети.
7. Парсить ответ только в immutable `MapParkingPoint`.
8. Различать `invalidQuery`, `invalidData`, `unavailable`.
9. Не включать сырой response/exception в domain failure.
10. Добавить tests и документацию; UI не переключать.

## Тесты

- exact 18-parameter body;
- successful data-source body;
- non-2xx redacted failure;
- typed immutable marker/cluster result;
- invalid bounds/antimeridian/zoom/radius/capacity до transport;
- invalid response отдельно от unavailable;
- unexpected source exception redacted;
- все characterization fixtures предыдущего этапа.

Результаты:

- map tests: 14 passed;
- полный набор: 135 passed;
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

## Ручной чек-лист

Production UI этим коммитом не меняется. После будущего подключения controller:

- сравнить marker/cluster count на одинаковых viewport/zoom;
- быстро двигать и масштабировать карту, проверяя stale response;
- проверить search, reset и все filters;
- открыть marker и hosted parking link;
- проверить SelectParking и long press;
- проверить offline/retry без raw backend текста;
- повторить Android real-device smoke test.

## Условия отката

Откатить один коммит, если:

- production consumer начал использовать repository в этом этапе;
- изменились headers/body/RPC/SQL;
- response fixtures расходятся с schema snapshot;
- raw backend details появляются в exception contract;
- tests/analyzer/build получают новую регрессию.

Backend rollback не требуется.

## Следующий отдельный этап

Добавить локальный `ParkingMapController` и immutable state без подключения UI:

- generation token для stale responses;
- loading/loaded/failure/retry;
- filter/query snapshot;
- controller unit tests.

После этого отдельным коммитом переключить только Home.

## Сообщение Git-коммита

```text
refactor(map): isolate parking read transport
```
