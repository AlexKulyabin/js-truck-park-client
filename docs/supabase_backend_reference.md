# Supabase backend reference

Дата снимка: 2026-07-23. Проект: `truckpark`, ref `jckksrcdmhtafwbimzov`, PostgreSQL 17.6, регион `eu-west-1`.

## Назначение и границы

Документ фиксирует фактический backend-контракт, к которому подключён Flutter-клиент. Источники:

- schema-only dump `public` без строк данных;
- read-only запросы к системным каталогам для RLS, grants, Auth triggers, Storage buckets и Realtime publications;
- статический поиск callers в Flutter-коде.

Диагностические артефакты:

- `diagnostics/supabase_schema_2026-07-23.sql` — таблицы, views, функции, индексы, constraints, triggers и RLS схемы `public`;
- `diagnostics/supabase_backend_metadata_2026-07-23.json` — конфигурационные метаданные, без пользовательских строк.

Управляемые Supabase-схемы `auth`, `storage`, `realtime` и внутренние схемы намеренно не включены целиком в SQL dump. Для них зафиксированы только необходимые приложению contracts и настройки. Секретные ключи, JWT, пароли базы, Auth users и содержимое таблиц не сохранялись.

## Карта backend

```text
Flutter client
  ├─ Supabase Auth: phone OTP, session, current JWT
  ├─ PostgREST tables/views
  │   ├─ users, parkings, parking_photos
  │   ├─ favorites, reviews, reports, referral_stats
  │   └─ four security-invoker views
  ├─ RPC over /rest/v1/rpc
  │   ├─ map/search: get_filtered_parkings, get_parkings_by_viewport
  │   ├─ account: delete_user_account
  │   └─ referrals: process_referral
  ├─ Storage
  │   ├─ assets (public)
  │   ├─ avatars (public, images, 5 MiB)
  │   └─ parking_content (public, images, 5 MiB)
  └─ Realtime publication
      └─ favorites, parkings, reports, reviews

PostgreSQL
  ├─ auth.users ── public.users (1:1)
  ├─ public.parkings
  │   ├─ parking_photos
  │   ├─ favorites
  │   ├─ reviews
  │   └─ reports
  └─ referral_stats ── auth.users (referrer/referee)
```

## Расширения

| Extension | Version | Schema | Использование |
|---|---:|---|---|
| `postgis` | 3.3.7 | `public` | geography point, viewport/radius queries, GiST index |
| `pg_trgm` | 1.6 | `public` | GIN trigram index по `parkings.address_lower` |
| `pgcrypto` | 1.3 | `extensions` | UUID/crypto platform support |
| `uuid-ossp` | 1.1 | `extensions` | UUID support |
| `pg_stat_statements` | 1.11 | `extensions` | performance diagnostics |
| `supabase_vault` | 0.3.1 | `vault` | managed Vault |

## Enum-типы

| Type | Values |
|---|---|
| `parking_status` | `pending`, `approved`, `rejected` |
| `parking_rejection_reason` | `duplicate`, `incomplete_data`, `not_meeting_requirements` |
| `user_status` | `pending`, `approved`, `rejected` |

## Таблицы

### `users`

Профиль с PK/FK `id -> auth.users.id ON DELETE CASCADE`.

| Группа | Колонки |
|---|---|
| Identity | `id uuid`, `created_at timestamptz` |
| Profile | `full_name`, `avatar_url`, `phone`, `theme`, `updated_at` |
| Access/business | `is_premium`, `status`, `is_admin` |
| Referral/device | `referral_code`, `referred_by_id -> users.id`, `last_device_id` |

RLS включён. Текущие permissive policies разрешают чтение всех строк `anon` и `authenticated`, insert с `WITH CHECK true`, а authenticated user может обновлять свою строку. Поскольку column-level ограничения не настроены, эта update policy распространяется и на `is_admin`, `is_premium`, `status` и referral-поля. Это критический security finding; подробности — в `backend_security_audit.md`.

### `parkings`

Основная сущность парковки. PK `id uuid`; `created_by -> auth.users.id ON DELETE SET NULL`.

| Группа | Колонки |
|---|---|
| Location | `address`, `address_lower`, `latitude`, `longitude`, generated `location geography(Point,4326)` |
| Capacity/price | `parking_type`, `total_spaces`, `price`, `is_free` |
| Amenities | `has_gas_station`, `has_shower`, `has_laundry`, `has_hotel`, `has_shop`, `has_recreation_area` |
| Rating | `rating`, `reviews_count`, `stars_1..stars_5` |
| Moderation | `status`, `is_active`, `admin_comment`, `rejection_reason` |
| Audit/media | `created_at`, `updated_at`, `created_by`, legacy `photos text[]` |

Индексы: GiST по `location`, GIN trigram по `address_lower`, btree по `status`. RLS включён. Несколько дублирующих permissive policies объединяются через OR; одна из них сейчас позволяет любому authenticated user обновлять любую парковку.

### `parking_photos`

`id uuid`, `url`, `parking_id -> parkings.id CASCADE`, nullable `user_id -> auth.users.id SET NULL`, nullable `review_id -> reviews.id CASCADE`, `created_at`. Индексы по `parking_id` и `review_id`. RLS включён, но дублирующие policies расширяют insert/delete сильнее owner-модели.

### `favorites`

`id bigint identity`, `user_id -> auth.users.id CASCADE`, `parking_id -> parkings.id CASCADE`, `created_at`. Уникальность `(user_id, parking_id)`, индекс по `user_id`. RLS ограничивает authenticated user его `user_id`; две эквивалентные policies дублируются.

### `reviews`

`id bigint identity`, `user_id -> auth.users.id SET NULL`, `parking_id -> parkings.id CASCADE`, `comment`, пять `smallint` ratings, calculated `average_score`, `created_at`. Уникальность `(user_id, parking_id)`, индекс по `parking_id`. RLS: публичное чтение, insert только с `user_id = auth.uid()`, delete только admin. Ограничений диапазона 1..5 на rating columns нет.

### `reports`

`id bigint identity`, `parking_id -> parkings.id CASCADE`, `user_id -> auth.users.id SET NULL`, `category`, `comment`, `report`, `status`, `created_at`. Default `status` сейчас равен строке `penging` — подтверждённая опечатка контракта. RLS разрешает insert владельцу и select владельцу/admin.

Flutter report-create writes through `features/reports/data/ReportsService`
with explicit `parking_id`, `user_id = currentUserUid`, `comment`,
`status = approved`, `report` enum name and `created_at`. Because the client
writes `status` explicitly, the typo default is documented but not part of the
active Flutter insert path. The local contract test
`supabase/tests/database/reports_authorization_test.sql` verifies owner insert,
cross-user denial, anonymous denial, owner/admin select scope and service-role
insert access without changing production data.

### `referral_stats`

`id uuid`, `referrer_id -> auth.users.id SET NULL`, `referee_id -> auth.users.id CASCADE`, `device_id`, `ip_address`, `status`, `created_at`. Уникальны `referee_id` и `device_id`. RLS включён, прямых policies нет; доступ выполняет SECURITY DEFINER RPC `process_referral`.

## Связи и каскады

| Parent | Child | Delete behavior |
|---|---|---|
| `auth.users` | `users` | cascade |
| `auth.users` | `favorites` | cascade |
| `auth.users` | `parkings.created_by` | set null |
| `auth.users` | `parking_photos.user_id` | set null |
| `auth.users` | `reviews.user_id` | set null |
| `auth.users` | `reports.user_id` | set null |
| `auth.users` | `referral_stats.referee_id` | cascade |
| `auth.users` | `referral_stats.referrer_id` | set null |
| `parkings` | `favorites`, `parking_photos`, `reviews`, `reports` | cascade |
| `reviews` | `parking_photos.review_id` | cascade |
| `users` | `users.referred_by_id` | no explicit delete action |

## Views

Все четыре view созданы с `security_invoker=true`; они используют права и RLS вызывающего пользователя.

| View | Назначение | Чувствительные поля/особенности |
|---|---|---|
| `view_full_parking_details` | Полная карточка, photos JSON, favorite flag, creator profile | включает moderation columns; фильтр approved или admin |
| `view_reviews_with_users` | Review + parking address + author + review photos | публичные reviews и profile fields |
| `view_user_favorites` | Favorite + компактная parking card + photos | source RLS должен ограничить favorites owner |
| `view_reports_detailed` | Report + parking + reporter | содержит `reporter_phone`; source RLS reports критична |

## RPC и функции

Все перечисленные функции сейчас имеют EXECUTE для `anon`, `authenticated` и `service_role`. Это стандартный широкий default grant, но для SECURITY DEFINER функций он небезопасен и должен быть сужен отдельной миграцией.

| Function | Contract | Security | Фактическое поведение |
|---|---|---|---|
| `get_filtered_parkings(...) -> setof json` | 18 map/filter/search parameters | SECURITY DEFINER, без fixed `search_path` | approved или admin; radius/viewport, amenities, address search, zoom clustering |
| `get_parkings_by_viewport(...) -> table` | bounds + zoom | invoker | clusters при zoom < 8; markers с limit 500 иначе |
| `get_parkings_by_location(...) -> setof parkings` | lat/lng/radius | SECURITY DEFINER, без fixed `search_path` | approved + active в радиусе; без result limit |
| `delete_user_account(confirm=true) -> void` | Bearer user JWT | SECURITY DEFINER | игнорирует `confirm`, удаляет `auth.users` по `auth.uid()` |
| `process_referral(code, referee_id, device_id) -> jsonb` | Bearer JWT в Flutter caller | SECURITY DEFINER, без fixed `search_path` | связывает referral и пишет stats; не сверяет `referee_id` с `auth.uid()` |
| `is_admin() -> boolean` | no args | SECURITY DEFINER, без fixed `search_path` | читает `users.is_admin` для `auth.uid()` |
| `generate_referral_code() -> text` | no args | invoker | случайный 8-char code; не гарантирует uniqueness |

Trigger-only functions: `handle_new_auth_user`, `handle_new_user`, `handle_review_score_before`, `aggregate_parking_stats_after`, `initialize_parking_rating`, `sync_user_data_to_auth`.

## Triggers

| Trigger | Source | Function | Назначение |
|---|---|---|---|
| `auth.on_auth_user_created` | `auth.users` after insert | `handle_new_auth_user` | создаёт/обновляет public profile и referral code |
| `tr_init_parking_rating` | `parkings` before insert | `initialize_parking_rating` | rating 4.0, review count 0 |
| `tr_1_calculate_review_score` | `reviews` before insert/update | `handle_review_score_before` | average непустых rating fields |
| `tr_2_aggregate_parkings` | `reviews` after insert/update/delete | `aggregate_parking_stats_after` | rating, count и stars buckets парковки |
| `trigger_sync_user_data` | `users` after profile update | `sync_user_data_to_auth` | display name/avatar в Auth metadata |

В базе остаётся вторая функция `handle_new_user`, но активный Auth trigger вызывает `handle_new_auth_user`. Это подтверждённый legacy/dead contract, удалять его без проверки истории нельзя.

## Storage

| Bucket | Public | Limit | MIME |
|---|---:|---:|---|
| `assets` | yes | platform default | unrestricted metadata |
| `avatars` | yes | 5 MiB | jpeg/png/webp |
| `parking_content` | yes | 5 MiB | jpeg/png/webp |

Flutter paths:

- `avatars/users/<uid>/...` для регистрации и редактирования профиля;
- `parking_content/parkings/<parkingId>/<index>/<timestamp>.<ext>` для парковки;
- `parking_content/parkings/<parkingId>/reviews/<reviewId>/<index>/<timestamp>.<ext>` для review;
- hardcoded public `assets/icnLocation.png` для marker icon.

Есть stale Storage policies для отсутствующего bucket `parking-images`. Policies `Avatar_Update` и `Avatar_Delete` проверяют только bucket, но не owner path; authenticated user потенциально может менять чужие avatars. Локальная migration `20260724103000_restrict_avatar_storage_policies.sql` заменяет avatar writes на owner path `avatars/users/<auth.uid()>/...`; локальная migration `20260724104000_restrict_parking_content_storage_policies.sql` заменяет parking_content writes на owner/review-author path contract. Production schema пока не изменялась.

## Realtime

В `supabase_realtime` опубликованы `favorites`, `parkings`, `reports`, `reviews`. Явных realtime subscriptions в текущем Flutter-коде не найдено: generated CRUD использует обычные PostgREST запросы. Publication следует считать dormant backend-контрактом до отдельной проверки consumers.

## Flutter-зависимости

### Core и generated adapters

- `lib/core/config/app_config.dart`;
- `lib/backend/supabase/supabase.dart`;
- `lib/backend/supabase/storage/storage.dart`;
- `lib/backend/supabase/database/{database,row,table}.dart`;
- `lib/backend/supabase/database/tables/*.dart`;
- `lib/backend/api_requests/{api_calls,api_manager}.dart`;
- `lib/auth/supabase_auth/*.dart`;
- `lib/main.dart`.

### Прямые feature callers

- auth/profile: `auth/registration`, `auth/validate_sms_code`, `profile/profile`, `profile/edit_profile`, OTP custom actions;
- parking: `map/home_page`, `create_parking/*`, `create_parking2/*`, `parkings_details/*`, `requests/*`;
- social/moderation: `favourites/*`, `reviews/*`;
- referral/subscription: `custom_code/actions/get_smart_subscription_prices.dart`, registration referral call, profile invite flow.

Generated `SupabaseTable` всегда выполняет `select()` без явного column list. Поэтому переход к column-level grants или public/private profile split потребует сначала typed repositories/DTO либо совместимого view-контракта.

## Подтверждённые ограничения данных

- Нет CHECK для latitude/longitude, capacity/price, rating 1..5 и referral status values.
- `users.referral_code` не UNIQUE.
- `process_referral` полагается на client-controlled `device_id`; `ip_address` не заполняется функцией.
- `reports.status` имеет typo default `penging`.
- Aggregated parking rating обновляется триггерами, не приложением.
- Storage object upload и последующий table insert не атомарны; возможны orphan objects/partial state.

Эти особенности являются частью текущего поведения. Исправлять их вместе с Flutter-рефакторингом нельзя: backend hardening и feature refactor должны быть отдельными этапами и коммитами.
