# Backend security audit

Дата: 2026-07-23. Scope: фактическая production-схема Supabase и Flutter callers. Исходный аудит был read-only. Первый hardening patch реализован и проверен только в локальном Supabase; production schema, policies и данные не изменялись.

## Статус первого hardening-этапа

- Добавлен воспроизводимый локальный Supabase PostgreSQL 17 config.
- Зафиксирован schema baseline существующего hosted-проекта без пользовательских данных.
- Миграция `20260723180000_restrict_user_profile_updates.sql` удаляет table-level `UPDATE` у `anon` и `authenticated`.
- `authenticated` получает UPDATE только для `full_name`, `avatar_url`, `updated_at`, `last_device_id`.
- `service_role`, RLS policies, Auth trigger, RPC, таблицы и данные не меняются.
- Два чистых `db reset` и два запуска pgTAP прошли: 20 tests, PASS в каждом запуске.
- `supabase db diff --local --schema public`: изменений не найдено.
- DB lint повторяет существующие замечания PostGIS и legacy-функций; новых findings от grants migration нет.
- Flutter regression: 21 test PASS; format без изменений; analyzer — 2297 существующих warning/info, blocking errors нет.
- Миграция в production не применялась. Finding остаётся P0 для работающего production до отдельного rollout-решения.

## Итог

Backend нельзя считать безопасным для масштабирования в текущем виде. RLS включён на всех семи прикладных таблицах, views используют `security_invoker`, а owner-проверки присутствуют во многих местах. Однако несколько permissive policies и SECURITY DEFINER RPC фактически обходят более строгие правила.

Самый опасный путь сейчас: authenticated user может обновить собственный `users.is_admin`, после чего `is_admin()` даёт административные права. Отдельно любой authenticated user может обновлять любую парковку из-за policy с `USING true`, а `process_referral` принимает произвольный `referee_id` и доступен роли `anon`.

## Findings

### P0 — самостоятельное повышение до admin и premium

Evidence:

- `users_update_own` и `users_update_own_clean`: `USING (auth.uid() = id)`;
- authenticated role имеет table-level `UPDATE` на `users`;
- нет column-level запрета на `is_admin`, `is_premium`, `status`, `referred_by_id`;
- `is_admin()` доверяет `public.users.is_admin` и работает как SECURITY DEFINER.

Impact: пользователь может изменить собственную строку, установить `is_admin=true` или `is_premium=true`, затем получить доступ к административным RLS-веткам, moderation data и delete/update операциям.

Рекомендуемая минимальная защита:

1. revoke table-level UPDATE у `authenticated`;
2. grant UPDATE только колонок, реально изменяемых клиентом: `full_name`, `avatar_url`, `updated_at`, `last_device_id` и отдельно подтверждённые settings;
3. менять `is_admin`, `is_premium`, `status`, referral linkage только server-side функциями с явной авторизацией;
4. добавить негативные SQL tests до применения.

Локальная реализация: выполнена в отдельной migration и покрыта pgTAP. Production status: не применено.

### P0 — любой authenticated user может изменять любую парковку

Evidence: policy `Allow authenticated users to update parkings` имеет `USING (true) WITH CHECK (true)`. Policies permissive, поэтому она логически OR-ится с более строгой `parkings_update`.

Impact: изменение координат, адреса, владельца, статуса, admin comment и moderation result чужой парковки; пользователь может самостоятельно approve запись.

Fix: удалить broad policy; разделить owner update и admin moderation. Owner должен менять только разрешённые business columns и не должен менять `status`, `created_by`, `admin_comment`, `rejection_reason`, `is_active`.

Локальная реализация: начата в `20260724100000_restrict_parking_updates.sql`; migration удаляет broad policy, пересоздаёт owner/admin RLS с `WITH CHECK` и даёт authenticated UPDATE только на owner-maintained поля. pgTAP test добавлен, но локальный запуск сейчас заблокирован недоступным Docker daemon. Production status: не применено.

### P0 — публичное раскрытие профилей и персональных полей

Evidence: `users_select_all` разрешает `SELECT` для `anon` и `authenticated` с `USING true`; generic Flutter adapter запрашивает `select *`.

Exposed contract: UUID, phone, premium/admin flags, moderation status, referral relation, device id, profile fields.

Impact: privacy leak и упрощение атак на UUID/profile/referral flows.

Fix strategy:

- ввести безопасный `public_profiles` contract только с `id`, `full_name`, `avatar_url`;
- owner/admin получает private profile отдельным view/RPC;
- перевести Flutter callers на typed projections;
- только после этого закрыть `users SELECT *` для anon.

Это нельзя делать одним «быстрым» RLS patch: generated client сейчас выбирает все колонки, поэтому сначала нужен совместимый read contract.

### P0 — `process_referral` не привязывает referee к JWT

Evidence:

- SECURITY DEFINER;
- EXECUTE разрешён `anon` и `authenticated`;
- функция принимает `p_referee_id` и не проверяет `p_referee_id = auth.uid()`;
- затем обновляет `users.referred_by_id` и вставляет `referral_stats`.

Impact: caller может применить referral к другому известному UUID; anonymous caller может инициировать mutation через RPC. Антифрод основан на client-controlled device id.

Fix:

- revoke EXECUTE from `anon`;
- игнорировать внешний referee id либо проверять его равенство `auth.uid()`;
- reject unauthenticated call;
- сохранять idempotent result без раскрытия SQL error;
- добавить уникальность referral code и controlled retry генерации;
- rate-limit на backend/edge boundary.

Локальная реализация: начата в `20260724101000_harden_process_referral.sql`; функция теперь требует authenticated EXECUTE, сравнивает `p_referee_id` с `auth.uid()`, возвращает стабильные публичные ошибки без `SQLERRM`, а Flutter RPC wrapper передаёт текущий JWT. pgTAP test добавлен, но локальный запуск сейчас заблокирован недоступным Docker daemon. Production status: не применено.

### P1 — произвольное удаление/создание parking photos

Evidence:

- `Authenticated can delete parking photos`: `USING true`;
- `Authenticated can create parking photos` и `photos_insert`: `WITH CHECK true`;
- эти policies расширяют owner/admin policies.

Impact: удаление чужих photo records, подмена `user_id`, привязка произвольных public URLs и review ids.

Fix: owner/admin delete; insert должен требовать `user_id=auth.uid()` и допустимую parking/review связь. Проверить, кто имеет право добавлять контент к существующей парковке.

Локальная реализация DB-части: начата в `20260724102000_restrict_parking_photo_policies.sql`; broad insert/delete policies удалены, `photos_insert` требует `auth.uid() = user_id`, `photos_delete` оставляет owner/admin. Storage ownership не менялся, потому что storage policies пока не зафиксированы в versioned baseline. pgTAP test добавлен, но локальный запуск сейчас заблокирован недоступным Docker daemon. Production status: не применено.

Локальная реализация Storage-части: начата в `20260724104000_restrict_parking_content_storage_policies.sql`; migration удаляет mutation policies для `parking_content`/stale `parking-images`, если они найдены в `pg_policies`, и создаёт owner-scoped insert/update/delete для direct parking paths и review-author paths. pgTAP test добавлен в `storage_parking_content_authorization_test.sql`. Production status: не применено.

### P1 — Storage avatars не ограничены владельцем

Policies `Avatar_Update` и `Avatar_Delete` проверяют только `bucket_id='avatars'`; `Avatar_Upload` также не проверяет path owner.

Impact: authenticated user может менять или удалять чужие avatar objects при известном path. Bucket публичный, что допустимо для отображения, но write должен быть owner-only.

Fix: единый path `users/<auth.uid()>/...`; INSERT/UPDATE/DELETE проверяют соответствующий segment. Не полагаться на UI path generation как на security boundary.

Локальная реализация: начата в `20260724103000_restrict_avatar_storage_policies.sql`; migration удаляет bucket-only `Avatar_Upload`, `Avatar_Update`, `Avatar_Delete` и создаёт owner-scoped policies для `avatars/users/<auth.uid()>/...`. pgTAP test добавлен в `storage_avatars_authorization_test.sql`, но локальный запуск Supabase tests пока зависит от доступности Docker daemon. Production status: не применено.

### P1 — SECURITY DEFINER без безопасного `search_path`

Без fixed search path работают `aggregate_parking_stats_after`, `delete_user_account`, `get_filtered_parkings`, `get_parkings_by_location`, `handle_review_score_before`, `is_admin`, `process_referral`, `sync_user_data_to_auth`.

Impact: object shadowing/search-path injection при наличии CREATE в доступной schema; повышенный blast radius ошибок. Расширения PostGIS и pg_trgm размещены в `public`, поэтому remediation требует полной qualification, а не слепого `search_path=''` без адаптации SQL.

Fix: квалифицировать tables/functions/operators, задать безопасный `SET search_path`, revoke unnecessary EXECUTE. Trigger functions не должны быть публичными RPC contracts.

### P1 — Auth trigger скрывает ошибки создания профиля

`handle_new_auth_user` ловит `WHEN OTHERS` и возвращает NEW. Auth user создаётся даже при сбое public profile insert/update.

Impact: пользователь без profile row; registration и profile flows предполагают существование строки. Это также делает потенциально применимой опасную public insert policy.

Fix: логировать redacted error в контролируемый канал, добавить repair/idempotent job, определить допустимое поведение при profile failure. Не менять trigger до теста существующих auth flows.

### P2 — referral integrity и fraud controls

- `users.referral_code` не UNIQUE;
- active trigger генерирует code через 8 символов `md5(random())`, без retry;
- отдельная `generate_referral_code()` не используется trigger;
- `device_id` приходит от клиента и сбрасывается переустановкой/подменой;
- `ip_address` существует, но RPC его не пишет;
- функция возвращает raw `SQLERRM`, что раскрывает детали backend.

Impact: неоднозначный referrer, обход device uniqueness, information disclosure.

### P2 — отсутствие domain constraints

- ratings не ограничены 1..5;
- latitude/longitude не ограничены допустимыми диапазонами;
- price/capacity допускают отрицательные значения;
- `reports.status` default — `penging`;
- free-text statuses у referral/report не перечислены enum/check.

Impact: некорректные агрегаты, невозможные координаты, drift business states.

### P2 — публичные buckets и stale policies

`assets`, `avatars`, `parking_content` публичные. Это может быть намеренно для UI, но URL не должен считаться приватным. Локальные migrations теперь закрывают avatar и parking_content write/delete по owner path; до production rollout нужен read-only diff hosted Storage policies, чтобы подтвердить отсутствие дополнительных permissive rules.

### P2 — неограниченные read RPC

`get_filtered_parkings` и `get_parkings_by_location` доступны anon, SECURITY DEFINER и не имеют строгого максимума результата/radius. Первый выполняет text/geo filtering и clustering, второй возвращает полный parking row set.

Impact: resource abuse и неожиданный объём ответа. Нужны bounds, limit и rate monitoring без изменения обычного map UX.

## Положительные свойства текущей схемы

- RLS включён на всех прикладных tables.
- Все четыре views используют `security_invoker=true`.
- Favorites ownership выражен через `auth.uid()` и уникальную пару user/parking.
- Review insert и report insert проверяют `user_id=auth.uid()`.
- `referral_stats` имеет unique device/referee constraints.
- Foreign keys и каскады покрывают основные связи.
- Геопоиск имеет GiST index; address search — trigram GIN index.
- Storage image buckets ограничивают size до 5 MiB и image MIME metadata.

Эти свойства нужно сохранить в hardening migrations.

## Безопасная последовательность исправлений

Каждый пункт — отдельный Git-коммит и отдельная migration. Сначала staging clone, затем production rollout с заранее подготовленным rollback.

1. **Characterization tests.** Зафиксировать текущие разрешённые owner flows и негативные exploit cases.
2. **User privilege escalation block.** Column-level UPDATE grants; убрать anon profile insert, если Auth trigger подтверждён.
3. **Parking update policy.** Удалить broad policy, разделить owner fields и moderation action.
4. **Referral RPC hardening.** Auth binding, grants, uniqueness, idempotency, safe errors.
5. **Photo table + Storage ownership.** Согласовать DB owner и object path policies.
6. **Public/private profiles.** Сначала новый read contract и Flutter migration, затем закрытие phone/device/admin fields.
7. **SECURITY DEFINER hardening.** Qualification/search path/grants function-by-function.
8. **Domain constraints.** `NOT VALID` checks, audit существующих значений, validate отдельно.
9. **Policy cleanup.** Удалить дубликаты и stale bucket policies после parity tests.

Не объединять пункты 2–9 в одну migration: rollback и диагностика станут небезопасными.

## Необходимые автоматические тесты

### RLS matrix

Для `anon`, user A, user B, admin:

- user не может менять `is_admin`, `is_premium`, `status`, referral fields;
- user A не может update/delete parking user B;
- owner не может approve/reject свою парковку;
- anon видит только approved/active parking contract;
- favorite доступен только owner;
- report доступен reporter/admin;
- review create требует собственный `user_id`, delete — admin;
- photo delete — owner/admin;
- profile private fields — owner/admin only.

### Referral RPC

- unauthenticated call denied;
- mismatched referee/JWT denied;
- self-referral denied;
- invalid code returns stable public error;
- second referral and reused device idempotently denied;
- concurrent requests дают один result;
- duplicate referral code невозможен;
- raw SQL errors не возвращаются клиенту.

### Storage

- owner upload/update/delete succeeds;
- cross-user avatar mutation fails;
- cross-user parking content mutation fails;
- wrong bucket/path/MIME/oversize fails;
- public read работает только там, где это явно принято продуктом.

### Compatibility

- phone OTP создаёт/восстанавливает profile;
- registration обновляет `full_name`, `avatar_url`, `last_device_id`;
- profile edit обновляет разрешённые fields;
- map/search contracts сохраняют JSON shape;
- moderation admin flow сохраняется;
- RevenueCat eligibility читает referral state после успешного RPC.

## Команды проверки следующей backend-сессии

Команды выполняются только против локального Supabase или отдельного staging project:

```bash
supabase start -x vector,logflare,studio,storage-api,imgproxy,edge-runtime,mailpit,postgres-meta,postgrest,realtime,gotrue,kong,supavisor
supabase db reset
supabase test db supabase/tests/database/users_authorization_test.sql --local
supabase db lint --level warning
supabase db diff --local --schema public,storage
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

Production write-команды не входят в этот чек-лист.

## Условия остановки и отката

Остановить rollout до production, если:

- owner flow получает 401/403/42501;
- Auth signup не создаёт profile;
- map RPC меняет shape/lat-lng semantics;
- admin moderation теряет доступ;
- Storage URLs перестают отображаться;
- referral eligibility расходится с RevenueCat offering.

Rollback должен возвращать только policies/grants/function конкретного этапа. Не откатывать данные, не удалять таблицы/колонки и не восстанавливать broad policies «на всякий случай» без инцидентного решения.

## Предлагаемое сообщение первого backend-коммита

`security(supabase): restrict mutable user profile columns`

Этот коммит должен содержать только migration + SQL tests + обновление документации. Flutter refactor и изменение referral functionality в него не входят.
