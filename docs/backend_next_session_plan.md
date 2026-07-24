# Первый backend-этап: ограничение обновлений users

## Статус реализации

Статус: реализовано и проверяется локально; в production не применено.

- PR с исходным аудитом слит в `main`.
- Реферальные Flutter-изменения изолированы в отдельном draft PR и не входят в этот этап.
- Создан стандартный `supabase/config.toml` для PostgreSQL 17.
- `20260723173000_remote_schema.sql` фиксирует локальный baseline существующего проекта без данных.
- `20260723180000_restrict_user_profile_updates.sql` содержит только grants hardening.
- `users_authorization_test.sql` проверяет Auth trigger, column grants, own/cross-user RLS, anon и service role.
- Два чистых reset/test: по 20 tests, PASS.
- Schema diff: пустой. Flutter: 21 test PASS, format чистый, blocking analyzer errors нет.
- DB lint содержит только baseline findings PostGIS и старых функций; migration-specific findings отсутствуют.
- Commit `security(supabase): restrict mutable user profile columns` опубликован в draft PR #3.
- Production write-команды не выполнялись.

Baseline migration нельзя повторно выполнять на существующей production-базе: перед будущим rollout её migration version нужно отдельно отметить как already applied после проверки migration history. Это действие не входит в текущий этап.

## Выбранный модуль

Supabase authorization baseline для `public.users`: блокировка самостоятельного изменения `is_admin`, `is_premium`, moderation и referral fields.

## Почему выбран

Это наименьший самостоятельный backend-этап, который закрывает максимальный риск. Сейчас authenticated user может обновить любые колонки своей profile row, а `is_admin()` использует `users.is_admin` как источник административных прав. Исправление можно выполнить column-level grants без изменения Flutter UI и без смешивания с referral/deep-link рефакторингом.

## Текущее поведение

- `users` RLS включён.
- `users_update_own*` ограничивает строку условием `auth.uid() = id`, но не ограничивает колонки.
- authenticated role имеет table-level UPDATE.
- Flutter реально обновляет только `full_name`, `avatar_url`, `updated_at`, `last_device_id`.
- Flutter generated adapter читает `select *`; read policies на этом этапе не меняются, чтобы не ломать profile/review screens.
- `is_admin`, `is_premium`, `status`, `referred_by_id`, `referral_code` и `phone` не должны изменяться обычным profile update.

## Связанные файлы

### Backend contracts

- `diagnostics/supabase_schema_2026-07-23.sql`;
- `diagnostics/supabase_backend_metadata_2026-07-23.json`;
- `supabase/config.toml`;
- `supabase/migrations/20260723173000_remote_schema.sql`;
- `supabase/migrations/20260723180000_restrict_user_profile_updates.sql`;
- `supabase/tests/database/users_authorization_test.sql`.

### Flutter callers, которые должны пройти regression

- `lib/backend/supabase/database/table.dart`;
- `lib/backend/supabase/database/tables/users.dart`;
- `lib/auth/registration/registration_widget.dart`;
- `lib/profile/edit_profile/edit_profile_widget.dart`;
- `lib/profile/profile/profile_widget.dart`;
- `lib/custom_code/actions/get_smart_subscription_prices.dart`;
- `lib/auth/validate_sms_code/validate_sms_code_widget.dart`;
- views/callers, читающие public profile: review и parking detail screens.

## Supabase-зависимости

- `auth.uid()` и роли `anon`, `authenticated`, `service_role`;
- Auth trigger `on_auth_user_created -> public.handle_new_auth_user`;
- `public.users` grants и RLS;
- `public.is_admin()`;
- `sync_user_data_to_auth` trigger;
- FK `users.id -> auth.users.id`;
- PostgREST schema cache после изменения grants.

## FlutterFlow-зависимости

- generated `SupabaseTable.update` и `select *`;
- generated `UsersRow`;
- `currentUserUid` из FlutterFlow auth util;
- upload flow, который затем пишет `avatar_url`;
- `supaSerialize<DateTime>` для `updated_at`;
- screen-local generated models и `safeSetState`.

На этом этапе FlutterFlow-зависимости не удаляются.

## Предлагаемая структура изменения

```text
supabase/
  config.toml
  migrations/
    20260723173000_remote_schema.sql
    20260723180000_restrict_user_profile_updates.sql
  tests/
    database/
      users_authorization_test.sql
docs/
  backend_security_audit.md
  backend_next_session_plan.md
```

Hardening migration:

1. зафиксировать текущие grants;
2. revoke table-level UPDATE у `anon` и `authenticated`;
3. grant UPDATE только `full_name`, `avatar_url`, `updated_at`, `last_device_id`;
4. сохранить полный доступ `service_role`;
5. не менять SELECT policy, Auth trigger, RPC, таблицы, колонки или данные;
6. содержать обратимый down/rollback SQL в runbook, но не запускать его автоматически.

## Созданные файлы

- `supabase/.gitignore`;
- `supabase/config.toml`;
- `supabase/migrations/20260723173000_remote_schema.sql`;
- `supabase/migrations/20260723180000_restrict_user_profile_updates.sql`;
- `supabase/tests/database/users_authorization_test.sql`;

## Изменённые файлы

- `docs/backend_security_audit.md` — фактический результат tests;
- `docs/backend_next_session_plan.md` — status/rollback evidence.

Production Flutter files на первом backend-этапе изменяться не должны. Если tests докажут, что client пишет дополнительную колонку, сначала документируется новый contract; scope не расширяется молча.

## Файлы, которые нельзя менять в этом этапе

- весь `lib/`;
- `android/`, `ios/`, `web/`;
- `pubspec.yaml`, lockfile и Flutter dependencies;
- существующие parking/referral/photo policies;
- существующие таблицы/колонки и данные;
- Auth/Storage settings;
- RevenueCat/Chottu/deep-link configuration.

## Последовательность

1. [x] Создать локальный Supabase; production не использовать для tests.
2. [x] Применить актуальный schema baseline без данных.
3. [x] Написать negative tests для update `is_admin`, `is_premium`, `status`, referral fields.
4. [x] Написать positive tests для `full_name`, `avatar_url`, `updated_at`, `last_device_id`.
5. [x] Добавить migration grants.
6. [x] Выполнить reset/test/lint второй раз с чистого состояния.
7. [x] Запустить Flutter unit/analyze.
8. [x] Проверить финальный diff: config, baseline, одна hardening migration, tests и docs.
9. [x] Сделать отдельный Git-коммит и draft PR.
10. [ ] Staging/production deployment — только отдельное явное решение.

## Необходимые тесты

| Actor | Operation | Expected |
|---|---|---|
| user A | update own `full_name` | success |
| user A | update own `avatar_url` | success |
| user A | update own `last_device_id` | success |
| user A | update own `is_admin` | denied |
| user A | update own `is_premium` | denied |
| user A | update own `status` | denied |
| user A | update own referral fields | denied |
| user A | update user B | denied |
| anon | update any user | denied |
| service role | administrative update | success |

Дополнительно: Auth signup/profile trigger, registration update, profile edit, referral eligibility read и `is_admin()` regression.

## Команды проверки

```bash
supabase start -x vector,logflare,studio,storage-api,imgproxy,edge-runtime,mailpit,postgres-meta,postgrest,realtime,gotrue,kong,supavisor
supabase db reset
supabase test db supabase/tests/database/users_authorization_test.sql --local
supabase db lint --level warning
supabase db diff --local --schema public
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
git diff --check
git status --short
```

## Ручной чек-лист

- Новый SMS user получает profile row.
- Registration сохраняет name/avatar/device id.
- Edit Profile сохраняет name/avatar.
- Profile и review author продолжают отображаться.
- Referral eligibility read не изменился.
- Обычный user не получает admin UI/data после попытки прямого update.
- В логах нет JWT, phone, device id и SQL errors.
- Production app во время staging tests не затрагивается.

## Условия отката

- registration/profile edit получает permission denied на разрешённых колонках;
- Auth trigger перестаёт создавать profile;
- PostgREST schema cache не принимает column grants;
- service/admin maintenance теряет необходимый доступ;
- Flutter generated update формирует контракт, несовместимый с column grants.

При откате вернуть только предыдущий UPDATE grant для `users`, зафиксировать причину и не продолжать остальные hardening stages. Данные не изменять.

## Предлагаемый Git-коммит

`security(supabase): restrict mutable user profile columns`

## Текущая следующая сессия

Статус: второй backend-hardening блок продолжается; production не затрагивать.
Локальный `supabase db reset` сейчас заблокирован окружением: Docker daemon недоступен. До rollout обязательно повторить pgTAP на локальном Supabase или staging clone.

Выполненные локальные этапы:

1. удалить broad parking update policy и ограничить прямые client update grants;
2. harden `process_referral` и перевести Flutter RPC call на authenticated bearer;
3. ограничить broad DB policies для `parking_photos`;
4. зафиксировать Storage baseline;
5. ограничить avatar Storage mutations owner path;
6. ограничить `parking_content` Storage mutations owner/review-author path.
7. изолировать parking-content ownership lookup от client table grants и
   подтвердить локальными pgTAP-тестами совместимость с avatar policies.

## Следующие отдельные этапы

Каждый отдельно:

1. перед production rollout сделать read-only diff hosted Storage policies и подтвердить parity;
2. перед включением profile writes выполнить `profile_security_activation_checklist.md`;
3. пройти `profile_select_rollout_checklist.md` перед отдельным rollout для
   закрытия broad `users SELECT *`;
4. harden SECURITY DEFINER search paths;
5. добавить domain constraints после data audit.

## Текущий Flutter write-pilot: favorites

Статус: реализовано локально отдельными коммитами; production write-команды не
выполнялись. Цель этапа — начать разрешать только малые user-owned изменения
данных через явную client-side capability и typed service boundary, не меняя
Supabase-контракты.

Выполненные этапы:

1. `refactor(config): gate allowed write operations` — добавлен
   `AppWriteOperation.favoriteToggle` и единая проверка
   `AppConfig.canPerformWrite(...)`.
2. `refactor(favorites): move toggle writes into service` — toggle избранного
   вынесен в `features/favorites/data/FavoritesService`; delete теперь
   фильтруется по `parking_id` и `user_id`; UI делает optimistic update с
   rollback/snackbar.
3. Документация и verification — `integration_runbook`,
   `flutter_supabase_usage_map` и `target_architecture_proposal` обновлены под
   новый pilot.
4. `refactor(favorites): move list reads into service` — список избранного
   читает `view_user_favorites` через `FavoritesService`, а UI получает
   typed `FavoriteParking` вместо generated Supabase row.
5. `refactor(favorites): introduce list controller state` — страница
   избранного использует feature-scoped `FavoritesController` и immutable
   `FavoritesState` через текущий `provider`, без глобальной замены state
   manager.
6. `refactor(reviews): isolate parking detail reads` — `info_tab` и
   `reviews_tab` читают `reviews` / `view_reviews_with_users` через
   `ReviewsService`; карточка parking details получает `ParkingReview`, а
   создание reviews/reports не менялось.
7. `test(reports): document create authorization contract` — добавлен
   транзакционный pgTAP contract test для `reports`: owner insert, запрет
   cross-user/anon insert, owner/admin select и service-role insert. Схема и
   Flutter UI не менялись, production write-команды не выполнялись. Локальный
   запуск `supabase test db ... --local` заблокирован отсутствующим соединением
   с local Postgres/Supabase (`LegacyDbConnectError`).
8. `refactor(reports): move create writes into service` — report-create UI
   пишет через `ReportsService` и `AppWriteOperation.reportCreate`, сохраняя
   текущие поля insert. На ошибке UI показывает snackbar и не закрывает экран.
9. `security(reviews): allow owner review mutations` — добавлен локальный
   Supabase contract для отзывов: owner insert сохранён, owner/admin могут
   менять только `comment` и пять rating fields, owner/admin могут удалить
   review row. Identity, parking, timestamp и calculated `average_score`
   закрыты для прямого client update. Production write-команды не выполнялись.

Проверки:

- `dart format --output=none --set-exit-if-changed lib test`;
- `flutter analyze --no-fatal-infos --no-fatal-warnings`;
- `flutter test`;
- `git diff --check`.

Ограничения:

- локальный полный pgTAP-набор запускается; Storage/profile tests
  проходят, но `reports_authorization_test.sql` отдельно выявил отсутствие
  ожидаемого `service_role INSERT` grant в baseline. Исправлять grant или
  корректировать ожидание теста нужно отдельным reports-этапом;
- favorite toggle в parking details всё ещё хранит локальный bool в
  FlutterFlow model; перенос optimistic action в controller лучше делать
  отдельным этапом после read-side pilots;
- reviews/reports profile tabs и request detail screens всё ещё используют
  generated rows напрямую и должны мигрировать отдельными маленькими этапами;
- review create можно включать следующим отдельным Flutter-этапом через
  `ReviewSubmissionService`, но фото должны идти через staged upload с
  компенсацией и FlutterFlow constraints `maxWidth=1920`, `maxHeight=1920`,
  `imageQuality=80`, bucket `parking_content`, MIME jpeg/png/webp и лимит
  5 MiB.
