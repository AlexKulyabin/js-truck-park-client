# Типизированный reverse geocoding boundary

Дата: 2026-07-24

Ветка: `agent/reverse-geocoding-read-integration`

## Выбранный модуль

Выбран общий read-path преобразования координат в адрес для long press на
карте в `HomePage` и `SelectParking`.

## Почему выбран этот модуль

После изоляции чтения парковок reverse geocoding оставался последним внешним
read-вызовом, который оба активных map widget выполняли напрямую через
generated `GetAddressFromCoordsCall`. Это небольшой общий boundary, не
требующий менять renderer, создание парковки или Supabase.

## Поведение до этапа

- Home и SelectParking напрямую вызывали generated Google Geocoding request;
- `ApiCallResponse` хранился в двух generated models;
- UI самостоятельно извлекал `results[0].formatted_address` через JSONPath;
- координаты и структура ответа не валидировались typed;
- `ZERO_RESULTS` или malformed payload могли записать строку `"null"`;
- предыдущий `FFAppState.tempAddress` мог сохраниться после HTTP failure;
- transport/payload errors не имели redacted domain classification.

## Новая структура

```text
HomePage / SelectParking
        │
        v
ReverseGeocodingService
  success -> formatted address
  typed failure -> safe empty address
        │
        v
ReverseGeocodingRepository
        │
        v
GoogleReverseGeocodingRepository
  coordinate validation
  response/status validation
  redacted failure mapping
        │
        v
GeneratedGoogleReverseGeocodingDataSource
        │
        v
legacy GetAddressFromCoordsCall
```

Application service централизует совместимое presentation-поведение двух
экранов. Repository остаётся независимым от Flutter widgets и `FFAppState`.

## Сохранённое поведение

- long press продолжает записывать выбранные координаты;
- при успешном ответе используется первый formatted address;
- язык и существующий generated Google endpoint не менялись;
- после попытки reverse geocoding по-прежнему открывается тот же create dialog;
- Home и SelectParking route contracts не изменены;
- parking marker reads, search, filters и details не изменены;
- Supabase и production write-flow не изменялись.

Осознанное безопасное уточнение: при invalid coordinate, HTTP failure,
`ZERO_RESULTS` или malformed payload временный адрес теперь очищается. Это не
позволяет записать адрес `"null"` или случайно повторно использовать адрес от
предыдущего long press.

## Все связанные файлы

Новый domain/application/data boundary:

- `lib/features/geocoding/domain/reverse_geocoding_repository.dart`;
- `lib/features/geocoding/application/reverse_geocoding_service.dart`;
- `lib/features/geocoding/data/google_reverse_geocoding_repository.dart`.

Подключённые consumers:

- `lib/map/home_page/home_page_widget.dart`;
- `lib/map/home_page/home_page_model.dart`;
- `lib/create_parking2/select_parking/select_parking_widget.dart`;
- `lib/create_parking2/select_parking/select_parking_model.dart`.

Сохранённый transport:

- `lib/backend/api_requests/api_calls.dart` — generated call остаётся только
  внутри data source.

Сохранённые write/UI dependencies:

- `lib/create_parking/create_parking_dialog/**`;
- `lib/create_parking2/create_parking_dialog2/**`;
- `lib/app_state.dart`;
- `lib/custom_code/widgets/custom_google_map.dart`.

Тесты:

- `test/features/geocoding/domain/reverse_geocoding_repository_test.dart`;
- `test/features/geocoding/application/reverse_geocoding_service_test.dart`;
- `test/features/geocoding/data/google_reverse_geocoding_repository_test.dart`;
- обновлённые Home/SelectParking boundary tests.

## Внешние и Supabase-зависимости

Reverse geocoding не использует Supabase. Серверные schema, functions, RLS,
grants и migrations не менялись.

Внешняя зависимость:

- Google Geocoding HTTP endpoint;
- вход: finite latitude `[-90, 90]`, longitude `[-180, 180]`;
- ожидаемый payload: status `OK`, непустой `results`, непустой
  `formatted_address` первого результата;
- `ZERO_RESULTS` отображается как typed `notFound`;
- HTTP/provider failure отображается как redacted `unavailable`;
- malformed payload отображается как redacted `invalidData`.

## FlutterFlow-зависимости

- `FFAppState.tempLat`, `tempLng` и `tempAddress` пока сохранены как legacy
  handoff в create dialogs;
- `safeSetState` и generated dialogs сохранены;
- `GetAddressFromCoordsCall` не удалён, пока data source его использует;
- generated `ApiCallResponse` больше не хранится в Home/SelectParking models;
- UI больше не знает JSONPath или Google response shape.

## Security note

Существующий Google Geocoding credential всё ещё находится в generated
transport. Этот этап уменьшает площадь его использования, но не меняет сам
credential, ограничения в Google Cloud или endpoint architecture.

Отдельный security-этап должен решить один из вариантов после проверки
production setup:

- ограниченный client credential с корректными platform restrictions; или
- server-side proxy/Edge Function с rate limiting и закрытым server credential.

Не следует переносить credential в новый repository, логировать его или менять
его без согласованной ротации и проверки production.

## Созданные файлы

- `lib/features/geocoding/domain/reverse_geocoding_repository.dart`;
- `lib/features/geocoding/application/reverse_geocoding_service.dart`;
- `lib/features/geocoding/data/google_reverse_geocoding_repository.dart`;
- `test/features/geocoding/domain/reverse_geocoding_repository_test.dart`;
- `test/features/geocoding/application/reverse_geocoding_service_test.dart`;
- `test/features/geocoding/data/google_reverse_geocoding_repository_test.dart`;
- `docs/reverse_geocoding_read_integration.md`.

## Изменённые файлы

- `lib/map/home_page/home_page_widget.dart`;
- `lib/map/home_page/home_page_model.dart`;
- `lib/create_parking2/select_parking/select_parking_widget.dart`;
- `lib/create_parking2/select_parking/select_parking_model.dart`;
- Home/SelectParking presentation boundary tests;
- `docs/flutter_architecture_map.md`;
- `docs/flutter_supabase_usage_map.md`;
- Home/SelectParking integration reports.

## Файлы, которые нельзя менять в этом этапе

- generated `GetAddressFromCoordsCall` implementation/credential;
- create parking dialogs и write repositories;
- `CustomGoogleMap` renderer;
- auth, profile, subscriptions, referrals, sharing и deep links;
- `android/**`, `ios/**`, `pubspec.yaml`;
- `supabase/migrations/**` и production backend contracts.

## Последовательность изменений

1. Зафиксировать active consumers и legacy response contract.
2. Добавить immutable domain address и typed failure kinds.
3. Добавить generated transport adapter.
4. Валидировать coordinates, provider status и response shape.
5. Redact unexpected source failures.
6. Добавить application service с единым safe fallback.
7. Инъецировать repository в Home и SelectParking.
8. Удалить `ApiCallResponse` из presentation models.
9. Защитить boundaries и preserved create dialogs тестами.
10. Выполнить format, analyze, tests и platform builds.

## Необходимые тесты

- domain не содержит transport details;
- exact latitude/longitude передаются в generated data source;
- HTTP failure становится `unavailable`;
- invalid coordinate не вызывает transport;
- `OK` response возвращает typed formatted address;
- `ZERO_RESULTS` отличается от malformed payload;
- raw source error redacted;
- application service одинаково очищает адрес для всех typed failures;
- Home/SelectParking принимают injected repository;
- direct generated geocoding call отсутствует в widgets;
- create dialogs остаются подключены;
- полный regression suite.

Результаты автоматической проверки этапа:

- geocoding + map suite: 39 passed;
- полный regression suite: 160 passed;
- scoped analyzer: 0 errors, 0 warnings, только существующие generated info;
- полный analyzer: 0 errors, 686 warnings и 1290 info;
- Android debug APK: built;
- iOS simulator debug app: built;
- автоматические Flutter platform upgrades исключены из рабочего дерева.

## Команды проверки

```bash
dart format --output=none --set-exit-if-changed lib/features/geocoding lib/map/home_page lib/create_parking2/select_parking test/features/geocoding test/features/map
flutter analyze lib/features/geocoding lib/map/home_page lib/create_parking2/select_parking test/features/geocoding test/features/map
flutter test test/features/geocoding test/features/map
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --debug
flutter build ios --simulator --debug --no-codesign
git diff --check
git status --short
```

## Ручной чек-лист

- выполнить long press в Home и проверить корректный адрес;
- закрыть create dialog без сохранения;
- выполнить long press в SelectParking и проверить корректный адрес;
- проверить адрес рядом с границей/дорогой без точного номера;
- временно отключить сеть перед long press: dialog открывается без старого
  адреса;
- вернуть сеть и повторить long press;
- проверить marker tap, map search и filters;
- проверить, что создание парковки не выполнялось автоматически;
- проверить hosted parking/photo deep links.

## Условия отката

Откатить один коммит этапа, если:

- успешный reverse geocoding перестал возвращать адрес;
- long press или create dialog не открываются;
- старый адрес сохраняется после failure;
- widgets снова зависят от JSON response shape;
- marker reads/search/filter получили регрессию;
- появилась новая analyzer error/warning или упала regression/build.

Backend rollback не требуется.

## Следующий отдельный этап

После real-device smoke test безопаснее перейти к typed marker API для
`CustomGoogleMap`. Security migration Google credential должна быть отдельной
задачей с доступом к актуальным Google Cloud restrictions и планом ротации.

## Предлагаемое сообщение Git-коммита

```text
refactor(geocoding): isolate reverse address reads
```
