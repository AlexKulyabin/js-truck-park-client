# Characterization-контракт чтения парковок для карты

Дата: 2026-07-24

Ветка: `agent/map-read-contract-characterization`

## Выбранный модуль

Центральная карта парковок: загрузка маркеров и кластеров, поиск по адресу,
фильтрация, повторное использование карты в выборе места новой парковки и
переход к карточке парковки.

## Почему он выбран

Карта — наиболее нагруженная read-feature приложения и основной потребитель
нестандартных Supabase RPC. В ней одновременно соединены generated
FlutterFlow UI, глобальные фильтры, dynamic JSON, Google Maps, геокодирование,
deep-link target и два разных пользовательских сценария. Любая прямая замена
здесь может незаметно изменить набор парковок, кластеризацию или навигацию.

Поэтому первый безопасный шаг — не перенос UI и не менять RPC, а зафиксировать
фактические входные и выходные контракты типами и тестовыми fixtures. Это
создаёт опорную точку для масштабируемого repository/controller слоя и
позволяет далее менять по одному boundary за коммит.

## Scope этого этапа

Выполнена только characterization:

- описаны bounds, все 18 параметров активного RPC и результат marker/cluster;
- добавлен строгий parser ответа без вывода серверных данных в исключение;
- зафиксированы текущая нормализация поиска и шкала радиуса;
- зафиксированы необычные и dormant формы backend-ответа;
- документированы security, race, load и compatibility риски;
- production UI, сетевой transport, RPC, SQL и состояние приложения не
  переключены на новые классы.

Пользовательское поведение в этом коммите не изменяется.

## Текущее поведение

### Home

1. `CustomGoogleMap` после создания карты и каждого `onCameraIdle` получает
   видимую область и zoom.
2. `HomePageWidget` сохраняет границы в generated model и вызывает
   `GetFilteredParkingsCall`.
3. Центр считается как арифметическая середина границ viewport.
4. Фильтры берутся напрямую из `FFAppState`; радиус передаётся только при
   `isFilterShowNearest`, иначе `0.0`.
5. При результате, который caller считает успешным, сырой `jsonBody`
   сохраняется в `parkingsOnMap` и передаётся обратно в custom map.
6. Обычный marker открывает `ParkingsDetailsWidget` по parking ID.
7. Cluster tap внутри custom widget приближает карту на два уровня. Публичный
   callback `onClusterTap` объявлен, но фактически этим действием не вызывается.
8. Поиск использует debounce 500 ms, переводит строку в lower case без trim,
   вызывает тот же RPC и принудительно переводит карту к zoom 20.
9. Deep-link target (`targetParkingId`, `targetLat`, `targetLng`) сохранён в
   route-контракте Home и открывает нужную парковку по существующим правилам.

### SelectParking

- использует тот же `CustomGoogleMap`, тот же RPC и те же глобальные фильтры;
- marker открывает существующую карточку парковки;
- long press запускает flow создания парковки и reverse geocoding;
- этот write-flow не входит в read-рефакторинг и должен оставаться отдельным
  этапом.

### Ошибки и конкурентные запросы

- camera idle не имеет debounce, cancellation или generation guard;
- более старый ответ может прийти после нового и заменить актуальные markers;
- отдельные проверки используют `succeeded ?? true`;
- response остаётся `dynamic`, а malformed элементы карта молча пропускает;
- нет явного loading/failure/retry состояния для marker read;
- RPC не задаёт limit, cursor или стабильную сортировку.

## Все связанные файлы

Активные consumers:

- `lib/map/home_page/home_page_widget.dart`;
- `lib/map/home_page/home_page_model.dart`;
- `lib/create_parking2/select_parking/select_parking_widget.dart`;
- `lib/create_parking2/select_parking/select_parking_model.dart`;
- `lib/custom_code/widgets/custom_google_map.dart`;
- `lib/backend/api_requests/api_calls.dart`;
- `lib/backend/api_requests/api_manager.dart`.

Фильтры и shared state:

- `lib/filter/filter/filter_widget.dart`;
- `lib/filter/filter/filter_model.dart`;
- `lib/app_state.dart`;
- `lib/flutter_flow/custom_functions.dart`.

Навигация, details и deep links:

- `lib/flutter_flow/nav/nav.dart`;
- `lib/flutter_flow/nav/serialization_util.dart`;
- `lib/parkings_details/parkings_details/parkings_details_widget.dart`;
- `lib/onboarding/splash/splash_widget.dart`;
- hosted parking/photo deep-link actions и handlers в `lib/custom_code/actions/`.

Конфигурация и auth boundary:

- `lib/core/config/app_config.dart`;
- `lib/backend/supabase/supabase.dart`;
- `lib/auth/supabase_auth/auth_util.dart`.

Legacy/dormant:

- `lib/map/map/map_widget.dart`;
- `lib/map/map/map_model.dart`;
- `GetParkingsByViewportCall` в
  `lib/backend/api_requests/api_calls.dart`.

Backend evidence:

- `diagnostics/supabase_schema_2026-07-23.sql`;
- `diagnostics/supabase_backend_metadata_2026-07-23.json`;
- `docs/supabase_backend_reference.md`;
- `docs/backend_security_audit.md`;
- `docs/flutter_supabase_usage_map.md`.

## Все Supabase-зависимости

### Активный `public.get_filtered_parkings`

Сигнатура содержит ровно 18 параметров:

```text
center_lat, center_lng, radius_meters,
min_lat, max_lat, min_lng, max_lng,
min_capacity, max_capacity,
need_gas, need_shower, need_laundry,
need_hotel, need_shop, need_recreation,
is_filter_active, zoom_level, search_query
```

Фактическая SQL-семантика:

- `SECURITY DEFINER`, fixed `search_path` не задан;
- допускает `status = approved` либо любую строку для `is_admin()`;
- `is_active` не проверяет;
- поиск: `address_lower LIKE '%' || lower(search_query) || '%'`;
- при активном nearest-filter и положительном radius применяется spherical
  distance;
- при непустом search без radius viewport не ограничивает результат;
- иначе используются переданные viewport bounds;
- capacity и шесть amenity predicates применяются только при
  `is_filter_active`;
- grid: `<4 => 10`, `<6 => 5`, `<8 => 1.5`, `<10 => 0.5`, `<11 => 0.05`,
  иначе `0` градусов;
- hard limit и стабильная сортировка отсутствуют.

Каждая JSON-строка содержит:

```text
id, lat, lng, latitude, longitude,
count, is_cluster, address, rating
```

Текущий Flutter renderer использует `id`, `lat`, `lng`, `count`,
`is_cluster`; `address` и `rating` возвращаются, но marker renderer их не
использует. При grid > 0 одиночная строка имеет UUID-like `id`, `count = 1`,
но `is_cluster = true`. Эта необычная форма теперь зафиксирована тестом и не
должна быть «исправлена» только на клиенте.

### Dormant `public.get_parkings_by_viewport`

- caller во Flutter не найден, wrapper только объявлен;
- invoker function;
- выбирает approved + active;
- при zoom < 8 возвращает clusters с `id = null`;
- при zoom >= 8 возвращает markers с limit 500;
- generated parallel-array accessors удаляют null ID отдельно от остальных
  значений, поэтому индексы массивов для cluster response расходятся.

Нельзя переиспользовать этот wrapper как замену активному RPC без нового
контракта и миграционного задания.

### Dormant `public.get_parkings_by_location`

- Flutter caller и wrapper не найдены;
- `SECURITY DEFINER`, fixed `search_path` не задан;
- возвращает полные строки `parkings` для approved + active в radius;
- hard result limit и верхняя граница radius отсутствуют.

### Tables, indexes и auth

- оба активных read-сценария косвенно зависят от `public.parkings`;
- geo column/index и `address_lower` являются частью backend реализации;
- RPC вызывается через ручной REST wrapper, а не `SupaFlow.client.rpc()`;
- wrapper всегда ставит anonymous Supabase headers, даже при authenticated
  session. Поэтому admin-ветка SQL фактически не получает JWT текущего
  пользователя через этот client boundary;
- RPC/RLS/grants/schema/data на этом этапе не менялись;
- production write-команды не выполнялись.

## Все FlutterFlow-зависимости

- generated `HomePageModel` и `SelectParkingModel` хранят bounds, zoom,
  `ApiCallResponse` и dynamic parking list;
- `FFAppState` хранит filter applied/nearest, radius index, capacity range и
  шесть amenity booleans;
- `getMetersFromIndex` сохраняет соответствие `0/1/2/3/4` к
  `5/10/50/100/150 km`, fallback — `5 km`;
- `textToLower` задаёт существующую lowercase-only нормализацию поиска;
- `ApiManager`, `ApiCallResponse`, `getJsonField`, `castToType` и
  `escapeStringForJson` формируют generated REST boundary;
- `FlutterFlowModel`, `safeSetState`, `FFLocalizations`, `FlutterFlowTheme`,
  route helpers и serialized parameters остаются активными;
- `CustomGoogleMap` — custom FlutterFlow widget, но внутри использует
  `google_maps_flutter` напрямую;
- public Storage URL marker asset является частью текущего presentation
  contract;
- FlutterFlow-зависимости не удаляются, пока wrappers не переключены и не
  пройдена ручная проверка обоих сценариев.

## Добавленная characterization-структура

```text
features/map/domain
  MapBounds
    - bounds + midpoint + structural diagnostics
  MapParkingQuery
    - точные 18 параметров активного RPC
    - legacy lowercase-only search normalization
  MapParkingPoint
    - строгая marker/cluster модель
    - redacted parsing failure

test/features/map
  domain fixtures
  legacy/dormant contract fixtures
```

Эти типы пока не подключены к production consumer. Они задают контракт, на
который будет опираться следующий repository/data-source этап.

## Предлагаемая новая структура

```text
HomePage / SelectParking FlutterFlow wrappers
                    |
                    v
features/map/presentation
  MapViewportAdapter + typed render model
                    |
                    v
features/map/application
  ParkingMapController + immutable MapReadState
  generation guard + explicit retry
                    |
                    v
features/map/domain
  MapBounds + MapParkingQuery + MapParkingPoint
  ParkingMapRepository
                    |
                    v
features/map/data
  SupabaseParkingMapRepository
  SupabaseMapRpcDataSource
                    |
                    v
authenticated Supabase RPC boundary
```

Один локальный controller должен обслуживать один экземпляр карты. Это не
перевод всего приложения на глобальный state manager. `FFAppState` сначала
остаётся источником filter snapshot; перенос ownership фильтров должен быть
отдельным этапом после read boundary.

## Созданные файлы

- `lib/features/map/domain/map_bounds.dart`;
- `lib/features/map/domain/map_parking_query.dart`;
- `lib/features/map/domain/map_parking_point.dart`;
- `test/features/map/domain/map_read_contract_test.dart`;
- `test/features/map/legacy/legacy_map_rpc_contract_test.dart`;
- `docs/map_read_contract_characterization.md`.

## Изменённые файлы

- `docs/flutter_supabase_usage_map.md`;
- `docs/flutter_architecture_map.md`.

Production consumers не изменены и новые domain types пока не импортируют.

## Файлы, которые нельзя менять в этом этапе

- `supabase/migrations/**`, schema, functions, grants, RLS и production data;
- `lib/backend/api_requests/api_calls.dart` и generated transport;
- `lib/map/home_page/**`;
- `lib/create_parking2/select_parking/**`;
- `lib/custom_code/widgets/custom_google_map.dart`;
- filter UI и `lib/app_state.dart`;
- parking/photo deep-link scheme и handlers;
- parking creation write-flow;
- `android/**`, `ios/**`, signing/store settings и `pubspec.yaml`.

## Последовательность следующих изменений

Каждый пункт ниже — отдельный пригодный к Git-коммиту этап:

1. Добавить `ParkingMapRepository` и injectable RPC data source вокруг
   неизменённого `get_filtered_parkings`. Выполнено в следующем отдельном
   коммите.
2. Написать repository tests на все 18 params, anonymous policy, typed parsing,
   redacted transport failure и immutable result. Выполнено; authenticated
   transport остаётся отдельным security-sensitive изменением.
3. Добавить локальный `ParkingMapController` с loading/loaded/failure,
   generation guard и retry; не подключать UI.
4. Подключить только Home marker reads через composition boundary; сохранить
   search/filter/deep-link поведение и custom map presentation.
5. После device regression test подключить SelectParking reads к тому же
   repository/controller; long press write-flow не менять.
6. Заменить dynamic renderer input на typed presentation adapter и перестать
   молча пропускать malformed server rows.
7. Отдельно решить debounce/cancellation/cache/load policy на основании
   замеров, не смешивая это с transport migration.
8. Отдельным backend-заданием спроектировать RPC v2: fixed search path,
   bounded inputs/results, active semantics, stable ordering и auth/grants.
9. После server rollout переключить новый client contract с rollback window;
   старый RPC не удалять до подтверждения production telemetry.
10. Отдельно вынести reverse geocoding key/config; не смешивать с map read.

## Необходимые тесты

Characterization:

- точный набор и значения 18 RPC параметров;
- legacy lowercase-only search normalization;
- midpoint обычного viewport;
- обнаружение antimeridian viewport, который текущий SQL не поддерживает;
- marker, cluster и low-zoom single-point cluster fixtures;
- malformed/non-list response и redacted exception;
- точная шкала radius slider;
- dormant viewport null-ID misalignment.

Следующий repository/controller этап:

- anonymous и authenticated header/session contract;
- HTTP success/non-success/invalid JSON;
- stale camera response не заменяет новый result;
- retry после failure;
- Home и SelectParking передают одинаковый filter snapshot;
- empty result очищает старые markers;
- deep-link target и marker selection не меняются;
- никакой write operation не вызывается read controller.

Backend v2 до rollout:

- anon/owner/admin matrix;
- inactive/pending/rejected visibility;
- negative/oversized radius и invalid bounds;
- antimeridian;
- максимальный размер результата и query plan/load test;
- search + viewport/radius precedence;
- cluster threshold boundary fixtures.

Результаты этого этапа:

- map characterization: 8 passed;
- полный набор: 129 passed;
- analyzer новых map domain/tests: 0 issues;
- полный analyzer: 0 errors, 721 warnings и 1290 info — всего 2011
  существующих замечаний generated FlutterFlow-кода;
- Android debug APK: built;
- iOS simulator debug app: built;
- предложенные Flutter platform upgrades после build полностью исключены из
  рабочего дерева.

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

## Ручной чек-лист следующего этапа

Проверять на Android real device и затем iOS simulator/device:

- Home загружает те же markers на одинаковом viewport и zoom;
- перемещение и быстрое масштабирование не возвращают старый viewport;
- clusters приближают карту как раньше;
- одиночный low-zoom cluster не ломает marker tap;
- marker открывает правильный parking ID;
- поиск RU/EN выдаёт прежний набор и корректно очищается;
- все шесть amenities, capacity и пять radius значений дают прежний результат;
- filter apply/reset сохраняют поведение;
- parking hosted deep link открывает нужную парковку;
- photo hosted deep link не получает регрессию;
- guest/integration read-only режим работает;
- SelectParking отображает тот же набор markers;
- long press в SelectParking продолжает открывать существующий create flow;
- offline/failure показывает безопасный retry без raw backend текста;
- возврат сети восстанавливает markers;
- светлая/тёмная тема и RU/EN layout не меняются.

## Условия отката

Characterization-коммит откатывается целиком, если:

- production consumer начал импортировать новые types;
- изменился RPC body/header, SQL или пользовательское поведение;
- fixture не соответствует schema dump;
- Android/iOS build получает новую ошибку из-за добавленных файлов;
- полный набор тестов получает регрессию.

На следующих этапах переключение Home/SelectParking откатывается одним
клиентским коммитом к generated caller, если меняется marker count/selection,
filter/search/deep-link поведение, появляется stale result или растёт частота
ошибок. Backend rollback для текущего коммита не требуется.

## Security findings, не исправленные в этом этапе

1. Активный map wrapper всегда использует anonymous headers.
2. `get_filtered_parkings` — `SECURITY DEFINER` без fixed `search_path`.
3. Active RPC не проверяет `is_active` и не ограничивает результат.
4. Search без radius может читать результат вне viewport.
5. Google reverse-geocoding credential находится literal в generated client
   wrapper, а передаваемый параметр key не определяет URL. Значение ключа в
   документации намеренно не приводится; перенос/rotation — отдельное
   security-задание.
6. Dynamic parsing и отсутствие redaction boundary повышают риск crash/data
   exposure при диагностике.

Эти findings требуют отдельных задач, потому что исправление может менять
production authorization, billing, выдачу парковок или совместимость старой
FlutterFlow-версии.

## Предлагаемое сообщение Git-коммита

```text
test(map): characterize parking read contracts
```
