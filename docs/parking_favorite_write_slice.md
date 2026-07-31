# Безопасный write-срез избранного парковки

Дата: 2026-07-23
Ветка: `agent/parking-favorite-write-slice`

## Выбранный модуль

Кнопка добавления и удаления парковки из избранного в публичной карточке
парковки.

## Почему он выбран

Это минимальный пользовательский write-flow после изоляции чтения публичной
карточки. До этапа UI выполнял generated Supabase CRUD напрямую, удаление
фильтровалось только по `parking_id`, повторные нажатия не блокировались, а при
ошибке оптимистическое состояние не откатывалось. Модуль ограничен одной
таблицей и уже защищён owner RLS, поэтому его можно мигрировать без изменения
backend-контрактов.

## Поведение до этапа

- начальное состояние брали из `view_full_parking_details.is_favorited`;
- guest видел существующий `GuestDialogWidget`;
- integration read-only mode отключал кнопку;
- authenticated user напрямую вызывал `FavoritesTable().insert(...)` или
  `FavoritesTable().delete(...)` из widget;
- insert передавал `user_id` и `parking_id`;
- delete передавал только `parking_id` и полагался на RLS;
- иконка менялась до ответа Supabase, но rollback и user-facing error
  отсутствовали;
- быстрые повторные нажатия могли запускать конкурентные запросы.

## Связанные файлы

Production UI и state:

- `lib/parkings_details/parkings_details/parkings_details_widget.dart`;
- `lib/parkings_details/parkings_details/parkings_details_model.dart`;
- `lib/parkings_details/parkings_details/parkings_details_widget.dart` получает
  начальный flag через существующий `ParkingDetailsController`.

Generated Supabase contracts:

- `lib/backend/supabase/database/tables/favorites.dart`;
- `lib/backend/supabase/database/tables/view_full_parking_details.dart`;
- `lib/backend/supabase/database/tables/view_user_favorites.dart`;
- `lib/backend/supabase/database/table.dart`;
- `lib/auth/supabase_auth/auth_util.dart`.

Related consumer:

- `lib/favourites/favourites/favourites_widget.dart` читает
  `view_user_favorites`; этот экран данным этапом не мигрируется.

Backend evidence:

- `diagnostics/supabase_schema_2026-07-23.sql`;
- `docs/supabase_backend_reference.md`;
- `docs/backend_security_audit.md`;
- `docs/flutter_supabase_usage_map.md`.

## Supabase-зависимости

Таблица `public.favorites`:

- `id bigint identity`;
- `user_id -> auth.users.id ON DELETE CASCADE`;
- `parking_id -> public.parkings.id ON DELETE CASCADE`;
- unique constraint `(user_id, parking_id)`;
- RLS разрешает authenticated user работать только со своим `user_id`;
- две эквивалентные owner-policy остаются backend-техническим долгом и не
  изменяются в клиентском этапе.

Операции нового data source:

```text
insert favorites { user_id: auth.uid, parking_id }
delete favorites where parking_id = :parkingId and user_id = :auth.uid
```

Код `23505` при insert трактуется как идемпотентный успех, потому что требуемая
пара `(user_id, parking_id)` уже существует. Код `42501` преобразуется в
redacted `forbidden`; остальные transport errors — в `unavailable`.

Миграции, RPC, RLS, grants, views и production data не изменялись. Production
write-команды во время разработки и проверки не выполнялись.

## FlutterFlow-зависимости

- `FFAppState().isGuest` и существующий `GuestDialogWidget` сохранены;
- `AppConfig.current.integrationReadOnly` продолжает запрещать write в debug и
  integration окружении;
- generated тема, SVG assets и геометрия кнопки сохранены;
- `showSnackbar` используется только для безопасного локализованного сообщения;
- generated `ParkingsDetailsModel` сохранён для остальных tabs/page state;
- generated `FavoritesTable` остаётся transport adapter внутри data layer,
  но больше не вызывается из presentation.

## Новая структура

```text
presentation / generated parking details widget
                |
                v
application / ParkingFavoriteController
                |
                v
domain / ParkingFavoriteRepository + typed failure contract
                |
                v
data / SupabaseParkingFavoriteRepository
                |
                v
generated Supabase FavoritesTable + current authenticated user
```

`ParkingFavoriteController` — локальный state holder конкретной карточки. Это
не миграция глобального состояния приложения и не новый глобальный provider.

## Созданные файлы

- `lib/features/parking_details/domain/parking_favorite_repository.dart`;
- `lib/features/parking_details/data/supabase_parking_favorite_repository.dart`;
- `lib/features/parking_details/application/parking_favorite_controller.dart`;
- `test/features/parking_details/data/supabase_parking_favorite_repository_test.dart`;
- `test/features/parking_details/application/parking_favorite_controller_test.dart`;
- `docs/parking_favorite_write_slice.md`.

## Изменённые файлы

- `lib/parkings_details/parkings_details/parkings_details_widget.dart`;
- `lib/parkings_details/parkings_details/parkings_details_model.dart`;
- `test/features/parking_details/presentation/parkings_details_widget_boundary_test.dart`;
- `docs/flutter_supabase_usage_map.md`.

## Файлы, которые нельзя менять в этом этапе

- `supabase/migrations/**` и production Supabase schema/data;
- generated `lib/backend/supabase/**` wrappers;
- `lib/auth/**`;
- `lib/app_state.dart` и глобальные Provider/FFAppState contracts;
- `lib/favourites/**`;
- router, Chottu, hosting и deep-link contracts;
- review/report/referral writes;
- `android/**`, `ios/**`, `pubspec.yaml`, signing и store configuration.

Flutter build временно предложил platform upgrades, но эти generated изменения
не включены в этап и полностью восстановлены после проверки.

## Последовательность изменений

1. Зафиксировать старый direct CRUD и owner/RLS контракт.
2. Добавить domain repository и typed failure categories.
3. Добавить Supabase adapter с обязательным authenticated user ID.
4. Ограничить delete одновременно `parking_id` и `user_id`.
5. Сделать duplicate insert идемпотентным.
6. Добавить локальный controller с optimistic state, single-flight и rollback.
7. Инициализировать controller из существующего read model.
8. Заменить direct CRUD в widget на controller boundary.
9. Сохранить guest dialog и integration read-only guard.
10. Добавить безопасное RU/EN сообщение после rollback.
11. Удалить неиспользуемые generated action outputs из model.
12. Добавить unit и widget boundary tests.
13. Выполнить format, analyze, full tests и platform builds.

## Автоматические тесты

Repository:

- insert передаёт authenticated `user_id` и requested `parking_id`;
- delete передаёт оба owner filter;
- пустой parking ID не вызывает transport;
- пустой user ID не вызывает transport;
- duplicate insert `23505` идемпотентен;
- RLS rejection и неизвестная ошибка redacted.

Controller:

- инициализация из server read model выполняется один раз;
- optimistic add и успешный commit;
- повторный tap во время запроса игнорируется;
- rollback add при typed failure;
- rollback delete при неизвестной ошибке;
- write невозможен до инициализации server state.

Boundary:

- существующая карточка по-прежнему загружается через details repository;
- integration read-only mode не вызывает favorite repository.

Результаты:

- parking details tests: 30 passed;
- полный набор: 104 passed;
- feature/test analyzer: 0 issues;
- полный analyzer: 2034 существующих замечания generated FlutterFlow-кода,
  было 2038;
- Android debug APK: built;
- iOS simulator debug app: built.

## Команды проверки

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze lib/features/parking_details test/features/parking_details
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test test/features/parking_details
flutter test
flutter build apk --debug
flutter build ios --simulator --debug --no-codesign
git diff --check
git status --short
```

## Ручной чек-лист

Проверять в production-configured internal testing build с отдельным тестовым
пользователем:

- открыть approved parking с карты;
- убедиться, что начальная иконка соответствует данным пользователя;
- добавить parking в избранное и дождаться окончания spinner;
- открыть экран избранного и увидеть parking;
- вернуться, удалить parking и проверить исчезновение из списка;
- быстро нажать кнопку несколько раз: должна выполниться одна операция;
- отключить сеть перед нажатием: иконка должна вернуться в исходное состояние,
  должно появиться безопасное сообщение без технического текста;
- повторить операцию после восстановления сети;
- под guest убедиться, что открывается прежний guest dialog;
- под вторым пользователем убедиться, что favorite первого пользователя не
  отображается и не удаляется;
- проверить светлую/тёмную тему и русский/английский текст;
- повторно проверить share/deep link парковки и фотографий.

## Условия отката

Откатить один клиентский коммит, если:

- initial favorite flag отличается от production;
- add/delete не отражается в `view_user_favorites` после повторного открытия;
- guest dialog или integration read-only guard перестал работать;
- ошибка не возвращает исходную иконку;
- обнаружена cross-user операция;
- карта, карточка, share или deep links получили регрессию;
- Android/iOS перестали собираться.

Database rollback не требуется: backend-контракты не менялись.

## Предлагаемое сообщение Git-коммита

```text
refactor(parking): secure favorite mutations
```

## Следующий отдельный этап

Изолировать read-only экран списка избранного:

- typed `FavoriteParkingSummary`;
- repository для `view_user_favorites` с обязательным current user filter;
- локальный controller с loading/empty/failure/retry;
- сохранить текущий route, cards и переход в parking details;
- не добавлять новые writes и не менять Supabase/RLS в том же коммите.
