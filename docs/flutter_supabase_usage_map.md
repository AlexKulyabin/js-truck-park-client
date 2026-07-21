# Карта использования Supabase из Flutter

## Доступность серверных контрактов

В проекте отсутствуют `supabase/migrations/`, `supabase/functions/`, `docs/database_schema.sql`, `docs/sql_functions.sql`, `docs/rls_policies.csv` и `docs/triggers.csv`. Поэтому:

- определения RPC, views, triggers, indexes, PostGIS expressions и RLS неизвестны;
- параметры ниже подтверждены клиентом, но server defaults/validation не подтверждены;
- для каждой операции зависимость от RLS считается обязательной, но фактическая policy отмечена как неизвестная;
- нельзя утверждать сортировку по расстоянию, лимиты, pagination или точную PostGIS-логику, если её нет в Dart-коде.

## Клиент и auth

| Flutter-файл | Сценарий | API | Результат/null/error | Риск |
|---|---|---|---|---|
| `backend/supabase/supabase.dart` | bootstrap | `Supabase.initialize`, implicit auth flow, singleton `SupaFlow.client` | init Future; error поднимается в `main` без локального recovery | высокий; config и environment coupling |
| `auth/supabase_auth/supabase_user_provider.dart` | session restore/change | `auth.onAuthStateChange`, `currentUser`, `refreshSession` | nullable Supabase User оборачивается в `BaseAuthUser`; stream debounce token refresh | критический |
| `auth/supabase_auth/auth_util.dart` | JWT для authenticated RPC | `auth.onAuthStateChange` → access token | пустая строка до session | критический |
| `auth/supabase_auth/supabase_auth_manager.dart`, `email_auth.dart` | sign-in/out/update/reset | `signOut`, `updateUser`, password reset, email auth | `AuthException` показывается SnackBar; OTP custom actions обрабатывают bool | критический |
| `custom_code/actions/send_otp.dart`, `verify_otp.dart` | phone OTP | Supabase Auth OTP | bool, exceptions печатаются/превращаются в false | критический; abuse/rate-limit contract неизвестен |

## RPC и внешние API wrappers

Все Supabase RPC ниже вызываются не через `client.rpc`, а вручную через REST в `backend/api_requests/api_calls.dart`.

| RPC / caller | Операция и параметры | Ожидаемый ответ / Dart | Null и error | SQL/RLS | Риск |
|---|---|---|---|---|---|
| `get_parkings_by_viewport`; caller не найден, wrapper только объявлен | POST: `min_lng`, `min_lat`, `max_lng`, `max_lat`, `zoom_level` | JSON list; accessors ожидают `lat: double`, `lng: double`, `count: int`, `id: String`, `is_cluster: bool`; outer type `ApiCallResponse` | accessors nullable и отбрасывают null; реального caller error flow нет | definition отсутствует; spatial/PostGIS поведение не доказано; RLS неизвестна | высокий, но сейчас dormant |
| `get_filtered_parkings`; `map/home_page/home_page_widget.dart`, `create_parking2/select_parking/select_parking_widget.dart` | POST: `center_lat/lng`, `radius_meters`, capacity bounds, viewport bounds, six amenity flags, `zoom_level`, lower-case `search_query`, `is_filter_active` | `ApiCallResponse.jsonBody` → `dynamic/List<dynamic>`; map ожидает `lat/lng/is_cluster/count/id` | caller местами использует `succeeded ?? true`; parsing typed validation нет; map silently skips malformed item | definition, PostGIS, ordering, max rows, indexes и RLS отсутствуют | критический |
| `delete_user_account`; `profile/log_out_dialog_copy/log_out_dialog_copy_widget.dart` | POST `{confirm: true}`, Bearer current JWT | `ApiCallResponse`; body не валидируется | при `succeeded ?? true` выполняются sign-out/navigation; failure UI не виден | SECURITY DEFINER/cleanup/cascade/RLS неизвестны | критический |
| `process_referral`; `auth/registration/registration_widget.dart` | `p_ref_code`, `p_referee_id`, `p_device_id` | JSON, helper ожидает map `{success: true}` | пустой/invalid JSON → false; HTTP проверяется через nullable succeeded | anti-fraud, idempotency, permissions, SQL отсутствуют | критический |
| Google Geocoding; Home/SelectParking | `lat`, `lng`; language `en` | `results[0].formatted_address` через JSONPath | индекс/field не проверены typed; при nullable succeeded может выполниться parsing | не Supabase | высокий для UX/config, не DB |

## Загрузка парковок, геопоиск и фильтры

1. `CustomGoogleMap` получает visible region и zoom от Google Maps.
2. Home/SelectParking вычисляют center как midpoint viewport, не как GPS пользователя.
3. `FFAppState.filterRadius` — индекс slider; `getMetersFromIndex` переводит его в 5, 10, 50, 100 или 150 км. Если nearest выключен, передаётся `0.0`.
4. Capacity defaults: 0..100. Amenity flags: gas, shower, laundry, hotel, shop, recreation.
5. Search использует debounce 500 ms, lower-case query и принудительный zoom 20, сохраняя остальные filter/bounds params.
6. Ответ RPC напрямую передаётся в map/search UI как dynamic JSON.
7. Клиент не задаёт `limit`, `range`, page/cursor. В generated table adapter limit существует, но эти RPC wrappers его не передают.
8. Сортировка по расстоянию, cluster algorithm, PostGIS operator/SRID, max result count и server-side pagination неизвестны. Их нельзя воспроизводить при рефакторинге без SQL definition и contract fixtures.

## Tables и views: фактические callers

Во всех строках RLS/policy и SQL definition неизвестны.

| Flutter-файл / сценарий | Entity | Операция и параметры | Dart-результат | Null/error handling | Риск |
|---|---|---|---|---|---|
| `auth/validate_sms_code/validate_sms_code_widget.dart` / после OTP | `users` | select where `id = currentUserUid` | `List<UsersRow>` | `firstOrNull`; без catch; выбирает Home или Registration | критический |
| `auth/registration/registration_widget.dart` / завершение профиля | `users` | update by id: `full_name`, optional `avatar_url`, `last_device_id` | generated update result не используется | upload length check; DB error не показана | критический |
| `profile/profile/profile_widget.dart` / header | `users` | querySingle where id | `List<UsersRow>` max 1 | empty → nullable row/default name; FutureBuilder error не отделён от loading | высокий |
| `profile/profile/profile_widget.dart` / referral | `users` | select by id → `referral_code` | `List<UsersRow>` | force unwrap first row/code | высокий |
| `profile/edit_profile/edit_profile_widget.dart` | `users` | querySingle; update `full_name`, optional `avatar_url`, `updated_at` by id | `UsersRow` list / update rows | FutureBuilder spinner; no explicit DB catch | высокий |
| `favourites/favourites/favourites_widget.dart` | `view_user_favorites` | select where `user_id = currentUserUid` | `List<ViewUserFavoritesRow>` | empty state есть; error отдельно не показан | средний |
| `parkings_details/parkings_details/parkings_details_widget.dart` / initial toggle | `favorites` | select where `parking_id` and `user_id` | `List<FavoritesRow>` | empty → false; no explicit error | высокий |
| тот же / toggle | `favorites` | delete by `parking_id`; insert `user_id`, `parking_id` | `List<FavoritesRow>` | optimistic local bool до await; rollback/error UI нет; delete не фильтрует user в client predicate, security зависит от RLS | критический |
| тот же / details | `view_full_parking_details` | querySingle where `id = parkingId` | `List<ViewFullParkingDetailsRow>` | spinner on no data; nullable row handling частичное | высокий |
| `parkings_details/parkings_details` и request detail screens | `parking_photos` | select where `parking_id`, иногда order `created_at` | `List<ParkingPhotosRow>` | empty supported; error not distinct | средний |
| `parkings_details/info_tab`, accepted/moderation/rejected | `reviews` | select where `parking_id` | `List<ReviewsRow>` | aggregate/display defaults; error not distinct | средний |
| `parkings_details/reviews_tab/reviews_tab_widget.dart` | `view_reviews_with_users` | select by parking id, order `created_at` | `List<ViewReviewsWithUsersRow>` | empty state; error spins | средний |
| `reviews/reviews_and_complaints/reviews_and_complaints_widget.dart` | `view_reviews_with_users` | select `user_id = currentUserUid`, order `created_at` | typed row list | empty state; error spins | средний |
| тот же | `view_reports_detailed` | select `reporter_id = currentUserUid`, order `report_date` | typed row list | empty state; error spins | средний |
| `reviews/report_create/report_create_widget.dart` | `reports` | insert `parking_id`, `user_id`, category/report/comment/status fields | `ReportsRow?` | button validation; no DB catch/typed error UI | высокий |
| `reviews/review_create/review_create_widget.dart` | `reviews` | insert parking/user/comment, five rating dimensions, timestamp | `ReviewsRow?` | response id force-used for photo path; no transaction | критический |
| тот же | `parking_photos` | one insert per uploaded photo: URL, parking/user/review ids, timestamp | `ParkingPhotosRow?` | partial upload/rows possible; no rollback transaction | критический |
| `create_parking/add_parking/add_parking_widget.dart` | `parkings` | insert capacity, amenities, address/lowercase, lat/lng, creator, timestamp, pending status | `ParkingsRow?` | generated form validation; no transaction/catch | критический |
| `create_parking2/create_parking/create_parking_widget.dart` | `parkings` | тот же новый flow | `ParkingsRow?` | no transaction/catch | критический |
| оба create screens | `parking_photos` | one insert per uploaded public URL and parking/user ids | `ParkingPhotosRow?` | partial write possible if upload/insert fails | критический |
| `requests/requests/requests_widget.dart` | `parkings` | three selects by `created_by` + status pending/approved/rejected | `List<ParkingsRow>` | separate FutureBuilders; error not distinct; no pagination | средне-высокий |

## Storage

Generated helper: `backend/supabase/storage/storage.dart`. Upload делает `uploadBinary` и возвращает public URL; delete разбирает bucket/path из public URL.

| Caller | Bucket/path | Операция | Error/atomicity | Security dependency |
|---|---|---|---|---|
| registration, edit profile | `avatars/users/<uid>/...` | upload, public URL stored in `users.avatar_url` | upload list length проверяется; DB update отдельно | Storage policy должна ограничивать owner/path/content type/size; неизвестна |
| create parking flows | `parking_content/parkings/<parkingId>/<index>` | upload, then insert `parking_photos` | нет transaction/compensation; orphan object/partial rows возможны | write/read/delete policies неизвестны |
| create review | `parking_content/parkings/<parkingId>/reviews/<reviewId>/<index>` | upload, then insert row | review создаётся до uploads; partial state возможен | owner/moderation/content policies неизвестны |
| marker asset | public `assets` URL hardcoded в Home | read | fallback default marker on load error | bucket public exposure intentionality неизвестна |

Helper `deleteSupabaseFileFromPublicUrl` существует; фактические callers в production widgets не найдены. Signed URLs не используются. Uploaded objects предполагаются public.

## Realtime и Edge Functions

- Realtime channels/table streams не найдены. Единственный live stream Supabase — Auth `onAuthStateChange`.
- `functions.invoke` и callers Edge Functions не найдены.
- Packages `realtime_client` и `functions_client` присутствуют транзитивно/явно, но feature usage не подтверждено.

## Generated, но неиспользуемые table wrappers

`geography_columns`, `geometry_columns`, `spatial_ref_sys`, `referral_stats` экспортированы в generated database layer, но прямых callers в `lib/` нет. Это не доказывает, что server-side SQL их не использует.

## Security и масштабирование: обязательные следующие артефакты

До миграции data-heavy features получить в version control:

1. schema migrations и точные signatures/bodies RPC;
2. RLS policies с тестами authenticated/guest/cross-user;
3. Storage bucket policies и limits;
4. contract fixtures для `get_filtered_parkings`, включая empty/malformed/cluster/edge coordinates;
5. query plans/indexes и max-row/pagination contract;
6. environment config без server secrets в клиенте;
7. audit delete-account/referral functions на authorization, idempotency и abuse controls.

Repository/service слой должен вводиться на этих проверенных контрактах, а не маскировать неизвестное поведение.
