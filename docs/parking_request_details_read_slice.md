# Этап рефакторинга: read-only детали заявок на парковку

## Статус

Реализовано и проверено в ветке
`agent/parking-request-details-read-slice` после переноса списка заявок в
feature-слой. Три detail route сохранены, Supabase schema/RLS/RPC/Storage и
production data не менялись.

## State management

На этом этапе глобальное состояние приложения не переводилось на новую
библиотеку. Существующие `Provider`, `FFAppState` и FlutterFlow navigation state
остаются совместимыми.

Для экрана деталей используется локальный `ChangeNotifier` controller с
immutable state. Он живёт только пока открыт экран, разделяет загрузку фотографий
и количества отзывов, защищает от устаревших async-ответов и освобождается вместе
с экраном. Выбор Riverpod/BLoC для всего приложения следует принимать отдельно
после нескольких feature-пилотов, а не смешивать с переносом конкретного экрана.

## Выбранный модуль

Read-only экраны деталей собственных заявок на парковку:

- pending: `ModerationParking` / `/moderationParking`;
- approved: `AcceptedParking` / `/acceptedParking`;
- rejected: `RejectedParking` / `/rejectedParking`.

## Почему он выбран

- это следующая часть уже изолированного списка заявок;
- три generated widget почти полностью дублировали друг друга;
- экран выполняет только два простых SELECT-запроса;
- отсутствуют формы, платежи, RPC, Storage upload и production writes;
- старые route names, paths и `ParkingsRow` parameter можно сохранить через
  compatibility wrappers;
- модуль позволяет проверить feature-local state и repository pattern без
  изменения глобальной архитектуры за один большой шаг.

## Поведение до этапа

- каждый из трёх экранов содержал около 900–1000 строк generated UI;
- каждый widget напрямую выполнял запросы к `parking_photos` и `reviews`;
- фотографии фильтровались по `parking_id` и сортировались по `created_at`;
- отзывы загружались целиком только для отображения их количества;
- loading и failure визуально отображались одинаковым progress indicator;
- pending/rejected имели разные status banners, approved — без banner;
- экраны использовали разные FlutterFlow translation keys при одинаковом UI;
- nullable service flags визуально трактовались как `true`;
- при `parkingRow == null` generated `eqOrNull` мог пропустить фильтр и
  потенциально прочитать все доступные RLS строки фотографий/отзывов.

## Новая структура

```text
Legacy detail route wrapper (ParkingsRow compatibility)
  -> legacy input adapter -> ParkingRequestSummary
  -> ParkingRequestDetailsView (единый UI трёх статусов)
       -> ParkingRequestDetailsController (локальное immutable state)
            -> ParkingRequestDetailsRepository (domain port)
                 -> SupabaseParkingRequestDetailsRepository
                      -> ParkingRequestDetailsDataSource
                           -> generated ParkingPhotosTable / ReviewsTable
```

Зависимости направлены внутрь feature:

```text
presentation -> application -> domain repository port
data adapter  -> domain + generated Supabase tables
domain/application/presentation -X-> Supabase generated rows
```

## Созданные файлы

- `lib/features/parking_requests/domain/parking_request_details.dart`;
- `lib/features/parking_requests/domain/parking_request_details_repository.dart`;
- `lib/features/parking_requests/data/supabase_parking_request_details_repository.dart`;
- `lib/features/parking_requests/application/parking_request_details_controller.dart`;
- `lib/features/parking_requests/presentation/parking_request_details_view.dart`;
- `test/features/parking_requests/data/supabase_parking_request_details_repository_test.dart`;
- `test/features/parking_requests/application/parking_request_details_controller_test.dart`;
- `test/features/parking_requests/presentation/parking_request_details_view_test.dart`;
- `test/features/parking_requests/presentation/parking_request_details_routes_test.dart`;
- `docs/parking_request_details_read_slice.md`.

## Изменённые файлы

- `lib/features/parking_requests/data/legacy_parking_request_route_adapter.dart`
  — добавлено безопасное преобразование `ParkingsRow?` во входную domain model;
- `lib/requests/moderation_parking/moderation_parking_widget.dart`;
- `lib/requests/accepted_parking/accepted_parking_widget.dart`;
- `lib/requests/rejected_parking/rejected_parking_widget.dart` — оставлены
  компактными route compatibility wrappers;
- три соответствующих `*_model.dart` — удалены только ставшие неиспользуемыми
  imports, сами FlutterFlow model classes сохранены.

## Все связанные файлы

Кроме созданных и изменённых файлов, контракт этапа связан с:

- `lib/features/parking_requests/domain/parking_request_summary.dart`;
- `lib/features/parking_requests/domain/parking_requests_repository.dart`;
- `lib/features/parking_requests/application/parking_requests_controller.dart`;
- `lib/requests/requests/requests_widget.dart`;
- `lib/flutter_flow/nav/nav.dart`;
- `lib/backend/supabase/database/tables/parking_photos.dart`;
- `lib/backend/supabase/database/tables/reviews.dart`;
- `lib/backend/supabase/database/tables/parkings.dart`;
- `assets/images/pending.svg`, `pending_dark.svg`, `attantion.svg`, `map.svg`,
  `review.svg`, `spaces.svg`, `gas.svg`, `shower.svg`, `laundry.svg`,
  `hotel.svg`, `shop.svg`, `coffee.svg`.

## Supabase-зависимости

```text
public.parking_photos
  operation: SELECT
  filter: parking_id = <non-empty selected parking id>
  order: created_at ascending (существующее поведение)
  mapped fields: id, url

public.reviews
  operation: SELECT
  filter: parking_id = <non-empty selected parking id>
  use: rows.length
```

RPC, Realtime, Storage и insert/update/delete отсутствуют. Контракты таблиц,
индексы, grants и RLS не изменялись.

Schema dump показывает permissive public SELECT policies для фотографий и
отзывов. Поэтому клиентский фильтр важен для минимизации выдачи, но не является
authorization boundary. Безопасность должна окончательно обеспечиваться RLS.
Отдельная backend-задача должна проверить, действительно ли публичное чтение
всех review/photo rows соответствует продуктовой модели.

### Security improvements

- пустой parking ID возвращает `[]` и `0` без обращения к transport;
- запрос без `parking_id` теперь невозможен через repository;
- URL/id фотографии валидируются перед передачей в UI;
- raw Supabase exception и row payload не сохраняются в state и не показываются;
- presentation получает только domain objects, а не произвольные row maps;
- контроллер игнорирует stale responses и updates после dispose.

## FlutterFlow-зависимости

- старые route names/paths и nullable `ParkingsRow` parameter сохранены;
- wrappers по-прежнему экспортируют generated `*_model.dart`;
- `FlutterFlowTheme`, `FFLocalizations`, `valueOrDefault`, `safePop` и
  `.divide()` временно используются общим presentation widget;
- существующие translation keys сохранены отдельно для каждого status;
- существующие SVG assets и точная базовая геометрия сохранены;
- generated `ParkingPhotosTable`, `ReviewsTable` и `ParkingsRow` разрешены
  только в data/compatibility boundary;
- FlutterFlow dependencies не удалялись, пока они используются.

## Файлы и контракты, которые нельзя менять в этом этапе

- `supabase/migrations/`, schema, grants, RLS, policies, RPC и production data;
- `pubspec.yaml`, dependency versions и global state-management library;
- `android/`, `ios/`, Maps keys, signing и build numbers;
- public route names/paths и `ParamType.SupabaseRow` navigation contract;
- список заявок и Add parking flow;
- public parking page, photo deep links и parking deep links;
- auth/session, map, referral, subscription/RevenueCat и Chottu;
- translations, assets и service availability semantics.

## Сохранённое и уточнённое поведение

- pending, approved и rejected открываются по прежним маршрутам;
- status banners, labels, address, rating, review count, capacity и services
  соответствуют прежним status-specific keys;
- photos и reviews продолжают загружаться независимо;
- photo order сохраняется;
- loading/failure сохраняют прежний progress indicator; tap по failure запускает
  локальный retry;
- valid route input визуально не меняется;
- null route input больше не вызывает неограниченный SELECT и показывает
  безопасные empty/default значения.

## Последовательность изменений

1. Сравнить три generated detail widgets и зафиксировать отличия.
2. Сверить два SELECT с schema dump и RLS policies.
3. Добавить photo domain model и repository port.
4. Изолировать generated Supabase tables в data source/adapter.
5. Запретить transport query для пустого ID и редактировать ошибки.
6. Добавить feature-local controller с независимыми async states.
7. Перенести общий UI в один presentation widget.
8. Заменить три generated экрана route wrappers без изменения navigation API.
9. Добавить data/application/widget/route contract tests.
10. Выполнить format, targeted/full analyze, tests и platform builds.
11. Исключить автоматические Android/iOS template migrations из diff.
12. Зафиксировать этап отдельным rollbackable Git-коммитом.

## Необходимые тесты

- photo/review queries всегда получают выбранный parking ID;
- пустой ID никогда не вызывает data source;
- photo rows корректно преобразуются, malformed data отклоняется;
- backend errors становятся только безопасной failure category;
- photos и review count загружаются независимо;
- stale response и update after dispose не меняют state;
- retry не смешивает старые и новые результаты;
- pending/rejected banner и отсутствие approved banner сохранены;
- address/review/capacity/services и размеры ключевых блоков сохранены;
- route names, paths, parameter type и status mapping сохранены;
- light/dark rendering не создаёт exception;
- полный существующий test suite проходит.

## Выполненные команды проверки

```bash
dart format lib/features/parking_requests \
  lib/requests/accepted_parking \
  lib/requests/moderation_parking \
  lib/requests/rejected_parking \
  test/features/parking_requests
flutter analyze lib/features/parking_requests \
  lib/requests/accepted_parking \
  lib/requests/moderation_parking \
  lib/requests/rejected_parking \
  test/features/parking_requests
flutter test test/features/parking_requests
flutter test
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter build apk --debug --no-pub
flutter build ios --simulator --debug --no-pub \
  --dart-define=APP_ENV=integration
rg -n "ParkingPhotosTable|ReviewsTable|Supabase|backend/supabase" \
  lib/features/parking_requests lib/requests/{accepted_parking,moderation_parking,rejected_parking}
rg -n "insert\\(|update\\(|delete\\(|\\.rpc\\(" \
  lib/features/parking_requests lib/requests/{accepted_parking,moderation_parking,rejected_parking}
git diff --check
```

Результат:

- targeted analyze: 0 issues;
- parking request tests: 33 PASS;
- full test suite: 74 PASS, было 59;
- full analyzer: 2083 существующих замечания generated FlutterFlow-кода, было
  2262; новых findings в изменённом scope нет;
- Android debug APK: успешно;
- iOS Simulator integration build: успешно;
- production writes/RPC в scope: 0;
- platform template migrations полностью исключены из diff.

Существующие infrastructure warnings: в будущем понадобятся обновления
Gradle/AGP/Kotlin, Swift Package Manager support у части plugins и iOS UIScene
lifecycle. Они не вызваны этим feature-этапом.

## Ручной чек-лист

- войти тестовым authenticated пользователем;
- открыть Profile -> Requests;
- открыть pending request и проверить banner, фото, адрес, отзывы, capacity и
  services;
- повторить для approved (без banner) и rejected (красный banner);
- проверить заявку без фотографий и заявку с несколькими фотографиями;
- проверить свайп фотографий и page indicator;
- проверить значения rating/review count и длинный адрес;
- проверить запись с nullable service flags;
- быстро открыть/закрыть экран на медленной сети;
- отключить сеть, проверить loading/failure и retry tap;
- проверить light/dark theme и маленький Android экран на overflow;
- проверить iOS;
- убедиться по network logs, что запросы содержат один `parking_id`;
- убедиться, что logs/UI не содержат JWT, user id, raw exception или row payload.

## Условия отката

Откатить этап одним `git revert`, если:

- изменился route name/path или перестал декодироваться `ParkingsRow`;
- один из status screens показывает неверный banner/translation/services;
- фотографии или количество отзывов отличаются от production при том же ID;
- появился запрос к photos/reviews без `parking_id`;
- появились regression, overflow, crash или утечка чувствительных данных;
- Android/iOS сборка либо полный test suite перестали проходить.

Откат не требует backend migration: schema и production data не менялись.

## Предлагаемое сообщение Git-коммита

```text
refactor(requests): unify read-only detail screens
```

## Предлагаемый следующий этап

Следующий отдельный feature-этап: read-only public parking details, открываемые с
карты и deep links. Точный scope: сначала инвентаризация route/photo/deep-link
контрактов, затем repository/controller boundary только для SELECT-данных,
обязательные route/deep-link/photo interaction tests. Не менять карту, Chottu,
hosting redirects, Supabase/RPC contracts и write actions в том же коммите.
