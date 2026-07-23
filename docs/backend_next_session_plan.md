# План следующей backend-сессии

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
- будущая migration в `supabase/migrations/`;
- будущие database tests в `supabase/tests/database/`.

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
  migrations/
    <timestamp>_restrict_user_profile_updates.sql
  tests/
    database/
      users_authorization_test.sql
docs/
  backend_security_audit.md
  backend_next_session_plan.md
```

Migration должна:

1. зафиксировать текущие grants;
2. revoke table-level UPDATE у `authenticated`;
3. grant UPDATE только `full_name`, `avatar_url`, `updated_at`, `last_device_id`;
4. сохранить полный доступ `service_role`;
5. не менять SELECT policy, Auth trigger, RPC, таблицы, колонки или данные;
6. содержать обратимый down/rollback SQL в runbook, но не запускать его автоматически.

## Файлы, которые будут созданы

- `supabase/migrations/<timestamp>_restrict_user_profile_updates.sql`;
- `supabase/tests/database/users_authorization_test.sql`;
- при отсутствии тестового bootstrap — один минимальный helper под `supabase/tests/database/support/`.

## Файлы, которые будут изменены

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

1. Создать локальный или отдельный staging Supabase; production не использовать для tests.
2. Применить актуальный schema baseline.
3. Написать negative tests для update `is_admin`, `is_premium`, `status`, referral fields.
4. Написать positive tests для `full_name`, `avatar_url`, `updated_at`, `last_device_id`.
5. Добавить migration grants.
6. Выполнить reset/test/lint минимум два раза с чистого состояния.
7. Запустить Flutter unit/analyze и ручной integration smoke против staging.
8. Проверить diff: только одна migration, tests и docs.
9. Сделать отдельный Git-коммит.
10. Production deployment — только отдельное явное решение после staging evidence.

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
supabase start
supabase db reset
supabase test db
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

## Следующие отдельные этапы

После успешного первого коммита, каждый отдельно:

1. удалить broad parking update policy;
2. harden `process_referral` и grants;
3. ограничить DB/Storage photo ownership;
4. ввести public/private profile projections;
5. harden SECURITY DEFINER search paths;
6. добавить domain constraints после data audit.
