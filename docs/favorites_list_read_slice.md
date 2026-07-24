# Read-срез списка избранных парковок

Дата: 2026-07-24

Ветка: `agent/favorites-list-read-slice`

## Выбранный модуль

Экран `Favourites` (`/favourites`), список сохранённых парковок и переход из
карточки списка к соответствующей парковке на карте.

## Почему он выбран

Write-операции избранного уже изолированы предыдущим этапом. Оставшийся экран
списка был небольшим read-only flow, но напрямую создавал generated Supabase
query в `FutureBuilder`, передавал `ViewUserFavoritesRow` в presentation и не
различал loading и failure. Его можно вынести без изменения backend, карты,
deep links или глобального state management.

## Поведение до этапа

- маршрут: `Favourites`, path `/favourites`;
- вход из profile; guest до маршрута получает существующий `GuestDialogWidget`;
- экран выполняет `ViewUserFavoritesTable().queryRows(...)` напрямую;
- client predicate: `user_id = currentUserUid` через `eqOrNull`;
- отсутствие current user могло убрать filter и полагаться только на RLS;
- loading показывал полноэкранный spinner;
- query failure выглядел как бесконечный loading без retry;
- presentation получал nullable generated `ViewUserFavoritesRow`;
- список показывал address, первую фотографию и favorite icon;
- tap открывал `HomePage` с `targetParkingId`, `targetLat`, `targetLng`;
- empty state использовал существующие RU/EN FlutterFlow strings.

## Все связанные файлы

Активный UI:

- `lib/favourites/favourites/favourites_widget.dart`;
- `lib/favourites/favourites/favourites_model.dart`;
- `lib/profile/profile/profile_widget.dart`;
- `lib/flutter_flow/nav/nav.dart`;
- `lib/index.dart`.

Legacy FlutterFlow card, сохранённый для rollback/export parity:

- `lib/favourites/favourite_card/favourite_card_widget.dart`;
- `lib/favourites/favourite_card/favourite_card_model.dart`.

Он больше не используется активным экраном, но не удаляется в этом этапе.

Generated Supabase:

- `lib/backend/supabase/database/tables/view_user_favorites.dart`;
- `lib/backend/supabase/database/tables/favorites.dart`;
- `lib/backend/supabase/database/tables/parkings.dart`;
- `lib/backend/supabase/database/tables/parking_photos.dart`;
- `lib/backend/supabase/database/table.dart`;
- `lib/auth/supabase_auth/auth_util.dart`.

Backend evidence:

- `diagnostics/supabase_schema_2026-07-23.sql`;
- `docs/supabase_backend_reference.md`;
- `docs/backend_security_audit.md`;
- `docs/flutter_supabase_usage_map.md`.

## Все Supabase-зависимости

`public.view_user_favorites`:

- создана с `security_invoker=true`;
- source `public.favorites f JOIN public.parkings p`;
- возвращает `favorite_record_id`, `user_id`, `parking_id`, address,
  latitude/longitude, rating/reviews_count и JSON-массив photo URL;
- новый клиент запрашивает view только с обязательным
  `user_id = authenticated user id`;
- пустой user ID возвращает пустой список до обращения к transport;
- repository дополнительно отклоняет строку с другим `user_id`;
- presentation получает только bounded typed model, без owner ID,
  rating/reviews и сырого JSON.

Underlying RLS:

- `favorites` имеет RLS;
- две эквивалентные authenticated owner policies проверяют
  `auth.uid() = user_id`;
- `(user_id, parking_id)` уникален;
- `security_invoker` заставляет view учитывать права вызывающего пользователя.

RPC, migrations, RLS, grants, tables, views и production data не изменялись.
Production write-команды не выполнялись.

## Все FlutterFlow-зависимости

- route name/path и generated router сохранены;
- profile guest gate и `GuestDialogWidget` не менялись;
- `currentUserUid` используется только на composition boundary;
- `FFLocalizations` keys `visdd4n6` и `u0idlh6r` сохранены;
- `FlutterFlowTheme`, spacing, icons и SVG assets сохранены;
- `serializeParam` продолжает формировать прежние map query parameters;
- `context.safePop()` и переход в `HomePageWidget` сохранены;
- generated model остаётся lifecycle compatibility wrapper;
- старый generated favorite card не удалён.

## Предлагаемая и реализованная структура

```text
favourites route wrapper
        |
        v
features/favorites/presentation
  FavoritesList + FavoriteParkingCard + navigation params
        |
        v
features/favorites/application
  FavoritesController + immutable FavoritesState
        |
        v
features/favorites/domain
  FavoriteParkingSummary + FavoritesRepository
        |
        v
features/favorites/data
  SupabaseFavoritesRepository + generated data source
        |
        v
view_user_favorites (security_invoker) -> source RLS
```

Контроллер локален конкретному экрану. Глобальные Provider, FFAppState и общий
state management не менялись.

## Созданные файлы

- `lib/features/favorites/domain/favorite_parking_summary.dart`;
- `lib/features/favorites/domain/favorites_repository.dart`;
- `lib/features/favorites/data/supabase_favorites_repository.dart`;
- `lib/features/favorites/application/favorites_controller.dart`;
- `lib/features/favorites/presentation/favorite_parking_card.dart`;
- `lib/features/favorites/presentation/favorites_list.dart`;
- `lib/features/favorites/presentation/favorite_parking_navigation.dart`;
- `test/features/favorites/data/supabase_favorites_repository_test.dart`;
- `test/features/favorites/application/favorites_controller_test.dart`;
- `test/features/favorites/presentation/favorites_list_test.dart`;
- `test/features/favorites/presentation/favorite_parking_navigation_test.dart`;
- `test/features/favorites/presentation/favourites_widget_boundary_test.dart`;
- `docs/favorites_list_read_slice.md`.

## Изменённые файлы

- `lib/favourites/favourites/favourites_widget.dart`;
- `lib/favourites/favourites/favourites_model.dart`;
- `docs/flutter_supabase_usage_map.md`.

## Файлы, которые нельзя менять в этом этапе

- `supabase/migrations/**`, production schema/data/RLS/grants;
- generated `lib/backend/supabase/**`;
- `lib/auth/**` и session contracts;
- `lib/profile/**`, guest dialog и profile menu;
- `lib/home_page/**`, map marker loading и map controller;
- router route name/path;
- parking/photo hosted deep links;
- favorite write layer предыдущего этапа;
- `android/**`, `ios/**`, signing, store configuration и `pubspec.yaml`.

Flutter build временно предложил platform upgrades. Они полностью исключены из
рабочего дерева после проверки.

## Последовательность изменений

1. Зафиксировать route, view schema, owner filter и card fields.
2. Добавить bounded `FavoriteParkingSummary`.
3. Добавить repository contract и redacted failures.
4. Добавить data source с обязательным `.eq('user_id', userId)`.
5. Не выполнять query при пустом user ID.
6. Валидировать owner, record/parking IDs, coordinates и photo JSON.
7. Добавить local controller с immutable loading/loaded/failure state.
8. Защититься от stale load/retry responses.
9. Перенести card/list presentation на typed model.
10. Сохранить loading geometry и empty localization.
11. Добавить tappable retry без raw server error.
12. Сохранить map target query parameter contract.
13. Перезагружать список после возврата с parking/map route.
14. Добавить unit, presentation и boundary tests.
15. Выполнить format, analyze, full tests и platform builds.

## Необходимые и выполненные тесты

Repository:

- owner filter передаётся data source;
- typed bounded mapping и первая фотография;
- пустой user ID не вызывает transport;
- cross-user row отклоняется;
- malformed photo JSON отклоняется;
- coordinates вне map contract отклоняются;
- source error redacted.

Controller:

- immutable loaded list;
- stale response после retry игнорируется;
- typed failure не сохраняет старые данные.

Presentation:

- loading key/geometry;
- существующий empty state;
- failure retry без raw text;
- typed card, no-photo state и selection callback;
- dark mode;
- точные `targetParkingId`, `targetLat`, `targetLng`.

Route boundary:

- route name/path не изменены;
- injected repository получает ожидаемый user ID;
- header и empty state отображаются без exception.

Результаты:

- favorites tests: 17 passed;
- полный набор: 121 passed;
- feature/widget/test analyzer: 0 issues;
- полный analyzer: 2011 существующих замечаний generated FlutterFlow-кода,
  было 2034;
- Android debug APK: built;
- iOS simulator debug app: built.

## Команды проверки

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze lib/features/favorites lib/favourites/favourites test/features/favorites
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test test/features/favorites
flutter test
flutter build apk --debug
flutter build ios --simulator --debug --no-codesign
git diff --check
git status --short
```

## Ручной чек-лист

Проверять на реальном устройстве с internal testing build и тестовым account:

- открыть Profile -> Favourites;
- подтвердить полноэкранный spinner до загрузки;
- подтвердить прежний empty state у пользователя без favorites;
- добавить parking в избранное и увидеть address/photo в списке;
- открыть favorite и проверить правильную парковку на карте;
- вернуться назад и убедиться, что список обновился;
- удалить favorite из details, вернуться и убедиться, что карточка исчезла;
- проверить parking без фотографии;
- отключить сеть: увидеть безопасный retry state, затем восстановить сеть и
  нажать для повторной загрузки;
- проверить второго пользователя: favorites первого не отображаются;
- проверить guest flow из Profile;
- проверить русский/английский язык и светлую/тёмную тему;
- проверить parking/photo share и hosted deep links на отсутствие регрессии.

## Условия отката

Откатить один клиентский коммит, если:

- route `/favourites` или profile navigation изменились;
- пользователь видит favorites другого пользователя;
- карта открывается с неправильным parking ID/coordinates;
- список не обновляется после возврата;
- loading/empty/card layout заметно отличается;
- raw Supabase error попадает в UI/log contract;
- Android/iOS перестают собираться;
- parking/photo deep links получают регрессию.

Backend rollback не требуется: backend не менялся.

## Предлагаемое сообщение Git-коммита

```text
refactor(favorites): isolate owned list reads
```

## Следующий отдельный этап

Перед изменением центральной карты выполнить отдельную characterization-сессию:

- инвентаризировать `get_filtered_parkings`, `get_parkings_by_viewport` и search
  consumers;
- описать typed map marker/cluster contract;
- зафиксировать viewport/filter/deep-link tests;
- не менять RPC, map UI или production backend в characterization-коммите;
- только после этого вынести map reads в repository/controller layer.
