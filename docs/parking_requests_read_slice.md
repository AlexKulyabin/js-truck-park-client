# Этап рефакторинга: read-only список заявок на парковку

## Статус

Реализовано и проверено в ветке `agent/parking-requests-read-slice` поверх
локализации, темы и Profile theme toggle. Экран больше не выполняет Supabase
query внутри widget. SQL, RLS, RPC, Storage, маршруты и write-actions не
менялись.

## Выбранный модуль

Три read-only списка пользовательских заявок на парковку: pending, approved и
rejected на route `/requests`.

## Почему он выбран

- это ограниченная read-only feature после settings-пилотов;
- текущий экран содержит три почти одинаковых прямых Supabase query;
- контракт основан на одной таблице, владельце и typed status enum;
- списки не выполняют insert/update/delete/RPC/Storage операции;
- UI, routes и detail screens можно оставить совместимыми;
- feature даёт повторяемый шаблон для следующих remote-data модулей.

## Текущее поведение до этапа

- `RequestsWidget` напрямую импортирует generated Supabase table и enum;
- каждая вкладка создаёт собственный `FutureBuilder<List<ParkingsRow>>`;
- каждый запрос фильтрует `parkings` по `created_by=currentUserUid` и одному из
  `pending/approved/rejected`;
- order, pagination и limit отсутствуют;
- loading и error визуально не различаются: при отсутствии data отображается
  progress indicator;
- UI card получает целый `ParkingsRow` и передаёт его в один из трёх detail
  routes как `ParamType.SupabaseRow`;
- labels, empty states, вкладки и Add parking находятся в generated shell.

## Новая структура

```text
RequestsWidget (generated route/layout shell)
  -> ParkingRequestsController (immutable async state)
       -> ParkingRequestsRepository (domain port)
            -> SupabaseParkingRequestsRepository (typed mapper)
                 -> ParkingRequestsDataSource
                      -> generated ParkingsTable (Supabase adapter)

ParkingRequestsList -> ParkingRequestCard -> ParkingRequestSummary
RequestsWidget -> legacy route adapter -> existing detail routes
```

Направление зависимостей:

```text
presentation -> application -> domain repository port
data adapter  -> domain + generated Supabase adapter
domain/application/presentation -X-> Supabase
```

## Созданные файлы

- `lib/features/parking_requests/domain/parking_request_summary.dart`;
- `lib/features/parking_requests/domain/parking_requests_repository.dart`;
- `lib/features/parking_requests/data/supabase_parking_requests_repository.dart`;
- `lib/features/parking_requests/data/legacy_parking_request_route_adapter.dart`;
- `lib/features/parking_requests/application/parking_requests_controller.dart`;
- `lib/features/parking_requests/presentation/parking_requests_list.dart`;
- `lib/features/parking_requests/presentation/parking_request_card.dart`;
- `test/features/parking_requests/domain/parking_request_summary_test.dart`;
- `test/features/parking_requests/data/supabase_parking_requests_repository_test.dart`;
- `test/features/parking_requests/application/parking_requests_controller_test.dart`;
- `test/features/parking_requests/presentation/parking_requests_list_test.dart`;
- `test/features/parking_requests/presentation/requests_widget_boundary_test.dart`;
- `docs/parking_requests_read_slice.md`.

## Изменённые файлы

- `lib/requests/requests/requests_widget.dart` — прямые FutureBuilder/Supabase
  queries заменены controller/list boundary; route/header/tabs/Add parking
  сохранены.

## Файлы, которые намеренно не удалены

- `lib/requests/request_card/request_card_widget.dart`;
- `lib/requests/request_card/request_card_model.dart`;
- `lib/requests/requests/requests_model.dart`.

Generated artifacts пока сохранены для безопасной FlutterFlow-совместимости и
могут удаляться отдельным cleanup-коммитом только после повторного zero-usage
scan и ручной проверки.

## Файлы и контракты, которые нельзя менять в этом этапе

- `supabase/migrations/`, production schema, grants, RLS и policies;
- `parkings` columns/status enum и существующие query filters;
- Requests и detail route names/paths/parameter type;
- три detail screens и их photos/reviews queries;
- Add parking action и глобальные временные form fields;
- Auth/session, map, referrals, RevenueCat, Chottu и deep links;
- translations, assets и визуальная геометрия cards/empty/loading states;
- `pubspec.yaml`, Android/iOS/Web configuration и build number.

## Supabase-зависимости

Единственная новая transport-зависимость изолирована в data layer:

```text
table: public.parkings
operation: SELECT
filters:
  created_by = authenticated user id
  status = pending | approved | rejected
order/limit/pagination: отсутствуют, как до этапа
```

RPC, Storage, Realtime и write operations отсутствуют.

### RLS-контракт и security note

Schema dump подтверждает включённый RLS и несколько permissive SELECT policies.
Owner видит собственные pending/rejected записи благодаря policy с условием
`status = approved OR created_by = auth.uid() OR is_admin()`. PostgreSQL
объединяет permissive policies через OR.

В dump также присутствуют дублирующие policies, включая более узкую
`parkings_select`, которая сама по себе разрешает только approved/admin.
Будущая cleanup-миграция обязана иметь отдельные owner/cross-user/anonymous/admin
contract tests и сохранить owner-read для pending/rejected. Этот клиентский
фильтр не является authorization boundary: доступ обязан ограничиваться RLS.

Production write-команды и backend mutations в этом этапе не выполнялись.

## FlutterFlow-зависимости

- `GeneratedParkingRequestsDataSource` временно использует `ParkingsTable`;
- generated `FlutterFlowTheme`, `FFLocalizations`, `FFButtonWidget`, SVG assets
  и local tab model сохранены;
- route names и `ParamType.SupabaseRow` сохранены;
- отдельный legacy adapter восстанавливает только поля `ParkingsRow`, реально
  используемые тремя detail screens;
- application/domain/presentation не импортируют Supabase/generated rows;
- старый generated RequestCard оставлен без изменений и больше не является
  remote-data boundary.

## Изменения поведения

- authenticated пользователь видит те же три status lists и те же cards;
- query parameters и отсутствие ordering/pagination сохранены;
- stale async response больше не может заменить результат другой вкладки;
- raw backend exceptions не сохраняются и не показываются пользователю;
- failure визуально сохраняет прежний progress indicator; tap по нему вызывает
  безопасный retry;
- при пустом user id Supabase query не выполняется и возвращается пустой список.
  Route штатно защищён auth navigation, поэтому это defensive поведение для
  некорректного signed-out состояния.

## Последовательность изменений

1. Сверить widget queries с schema dump и RLS policies.
2. Зафиксировать status/storage values и реально используемые detail fields.
3. Добавить typed domain summary и repository port.
4. Изолировать generated Supabase query в data source/adapter.
5. Добавить immutable controller state, typed failures и stale-load protection.
6. Перенести list/card/loading/empty presentation в feature.
7. Подключить controller в generated Requests shell через injection seam.
8. Сохранить detail routes через ограниченный legacy route adapter.
9. Добавить domain/data/application/presentation/boundary tests.
10. Выполнить format, analyze, tests, dependency scans и platform builds.
11. Исключить Flutter platform template migrations из diff.
12. Зафиксировать этап отдельным rollbackable коммитом.

## Необходимые тесты

- status enum точно соответствует database enum;
- repository сохраняет owner/status filters;
- nullable/number/bool fields преобразуются в typed summary;
- invalid/mismatched row отклоняется как typed invalid-data failure;
- data-source error редактируется до безопасной категории;
- empty user id не вызывает network query;
- controller загружает pending, переключает status и игнорирует stale result;
- loading, empty, card, tap, retry и dark mode UI сохраняются;
- generated route shell работает с fake repository без Supabase initialization;
- route name/path не меняются;
- полный существующий test suite продолжает проходить.

## Выполненные команды проверки

```bash
dart format --output=none --set-exit-if-changed lib test
flutter test
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter build apk --debug
flutter build ios --simulator --debug --no-pub \
  --dart-define=APP_ENV=integration
rg -n "ParkingsTable|SupaFlow|backend/supabase|supabase_flutter" \
  lib/requests/requests/requests_widget.dart \
  lib/features/parking_requests/{domain,application,presentation} \
  test/features/parking_requests
rg -n "insert\\(|update\\(|delete\\(|\\.rpc\\(" \
  lib/features/parking_requests lib/requests/requests/requests_widget.dart
git diff --check
```

Результат:

- format: 200 файлов проверено, 0 изменений;
- tests: 59 PASS, было 41;
- analyzer: 2262 существующих замечания generated FlutterFlow-кода, было
  2282; новых findings в feature layer нет;
- Android debug APK: успешно;
- iOS Simulator build: успешно;
- direct Supabase dependency вне data/legacy adapters: 0;
- insert/update/delete/RPC в этапе: 0;
- Android/iOS template migrations полностью исключены из diff.

Существующие infrastructure warnings: будущая необходимость обновить
Gradle/AGP/Kotlin, поддержка Swift Package Manager отдельными plugins и iOS
UIScene lifecycle. Они не вызваны этим этапом.

## Ручной чек-лист

- войти authenticated тестовым пользователем с заявками разных statuses;
- открыть Profile -> Requests;
- проверить pending list, адреса, status label и переход в Moderation details;
- проверить approved list и переход в Accepted details;
- проверить rejected list и переход в Rejected details;
- проверить empty state каждой вкладки на пользователе без заявок;
- быстро переключать вкладки на медленной сети и убедиться, что данные не
  смешиваются;
- проверить light/dark theme и маленький Android экран на overflow;
- проверить iOS;
- убедиться, что открытие списков выполняет только SELECT;
- убедиться, что пользователь не видит чужие pending/rejected requests;
- убедиться, что logs не содержат JWT, user id или raw backend payload.

## Условия отката

Откатить этап одним `git revert`, если:

- одна из status вкладок возвращает другой набор заявок;
- карточка или empty/loading state визуально изменились;
- существующий detail route перестал открываться или потерял используемые поля;
- появились write/RPC/Storage operations;
- raw backend error или идентификатор попадает в UI/log;
- cross-user pending/rejected запись становится доступна;
- полный suite, Android или iOS build перестают проходить.

Backend и storage data не менялись, поэтому откат не требует data migration.

## Предлагаемое сообщение Git-коммита

```text
refactor(requests): add read-only repository boundary
```

## Точный scope следующего этапа

Перевести три read-only request detail screens на общий typed presentation/data
boundary. Сохранить три публичных route name/path и входной SupabaseRow parameter
как временный compatibility API, но сразу преобразовывать его в domain model.
Вынести SELECT `parking_photos` в repository, объединить повторяющийся layout и
добавить typed loading/failure state. Не менять reviews, SQL/RLS/Storage, write
actions, translations или routes.

Предлагаемые файлы следующего этапа:

- `lib/features/parking_requests/domain/parking_request_details.dart`;
- `lib/features/parking_requests/domain/parking_request_photos_repository.dart`;
- `lib/features/parking_requests/data/supabase_parking_request_photos_repository.dart`;
- `lib/features/parking_requests/application/parking_request_details_controller.dart`;
- `lib/features/parking_requests/presentation/parking_request_details_view.dart`;
- три существующих detail widgets — только как route compatibility wrappers;
- зеркальные domain/data/application/widget tests;
- `docs/parking_request_details_read_slice.md`.
