# Карта использования Supabase из Flutter

## Доступность серверных контрактов

23 июля 2026 года выполнена read-only schema-only выгрузка production Supabase. Теперь подтверждены tables, views, functions/RPC, triggers, indexes, foreign keys, grants, RLS, Storage buckets/policies, Auth profile trigger и Realtime publications.

Основная backend-спецификация: `docs/supabase_backend_reference.md`. Security findings и порядок исправлений: `docs/backend_security_audit.md`. Сырые диагностические снимки находятся в `diagnostics/` и не содержат строк пользовательских данных.

Versioned `supabase/migrations/` всё ещё отсутствуют. Dump является baseline/reference, но не заменяет migration history и не должен автоматически применяться к базе.

## Клиент и auth

| Flutter-файл | Сценарий | API | Результат/null/error | Риск |
|---|---|---|---|---|
| `backend/supabase/supabase.dart` | bootstrap | `Supabase.initialize`, implicit auth flow, singleton `SupaFlow.client` | init Future; error поднимается в `main` без локального recovery | высокий; config и environment coupling |
| `auth/supabase_auth/supabase_user_provider.dart` | session restore/change | `auth.onAuthStateChange`, `currentUser`, `refreshSession` | nullable Supabase User оборачивается в `BaseAuthUser`; stream debounce token refresh | критический |
| `auth/supabase_auth/auth_util.dart` | JWT для authenticated RPC | `auth.onAuthStateChange` → access token | пустая строка до session | критический |
| `auth/supabase_auth/supabase_auth_manager.dart`, `email_auth.dart` | sign-in/out/update/reset | `signOut`, `updateUser`, password reset, email auth | `AuthException` показывается SnackBar; OTP custom actions обрабатывают bool | критический |
| `custom_code/actions/send_otp.dart`, `verify_otp.dart` | phone OTP | Supabase Auth OTP | bool, exceptions печатаются/превращаются в false | критический; client logging и abuse/rate-limit требуют отдельного Auth audit |

## RPC и внешние API wrappers

Все Supabase RPC ниже вызываются не через `client.rpc`, а вручную через REST в `backend/api_requests/api_calls.dart`.

| RPC / caller | Операция и параметры | Ожидаемый ответ / Dart | Null и error | SQL/RLS | Риск |
|---|---|---|---|---|---|
| `get_parkings_by_viewport`; caller не найден, wrapper только объявлен | POST: `min_lng`, `min_lat`, `max_lng`, `max_lat`, `zoom_level` | JSON list; accessors ожидают `lat: double`, `lng: double`, `count: int`, `id: String`, `is_cluster: bool`; outer type `ApiCallResponse` | accessors nullable и отбрасывают null; реального caller error flow нет | invoker; approved+active; clusters до zoom 8, затем markers, limit 500 | высокий, но сейчас dormant |
| `get_filtered_parkings`; `map/home_page/home_page_widget.dart`, `create_parking2/select_parking/select_parking_widget.dart` | POST: `center_lat/lng`, `radius_meters`, capacity bounds, viewport bounds, six amenity flags, `zoom_level`, lower-case `search_query`, `is_filter_active` | `ApiCallResponse.jsonBody` → `dynamic/List<dynamic>`; map ожидает `lat/lng/is_cluster/count/id` | caller местами использует `succeeded ?? true`; parsing typed validation нет; map silently skips malformed item | SECURITY DEFINER; approved/admin filter; custom distance math + zoom grid; no hard result limit | критический |
| `delete_user_account`; `profile/log_out_dialog_copy/log_out_dialog_copy_widget.dart` | POST `{confirm: true}`, Bearer current JWT | `ApiCallResponse`; body не валидируется | при `succeeded ?? true` выполняются sign-out/navigation; failure UI не виден | SECURITY DEFINER; `confirm` игнорируется; удаляет только `auth.uid()`; cascades по FK | критический |
| `process_referral`; `auth/registration/registration_widget.dart` | `p_ref_code`, `p_referee_id`, `p_device_id` | JSON, helper ожидает map `{success: true}` | пустой/invalid JSON → false; HTTP проверяется через nullable succeeded | SECURITY DEFINER, доступен anon; не проверяет `p_referee_id=auth.uid()`; unique device/referee | P0 authorization |
| Google Geocoding; Home/SelectParking | `lat`, `lng`; language `en` | `results[0].formatted_address` через JSONPath | индекс/field не проверены typed; при nullable succeeded может выполниться parsing | не Supabase | высокий для UX/config, не DB |

## Загрузка парковок, геопоиск и фильтры

1. `CustomGoogleMap` получает visible region и zoom от Google Maps.
2. Home/SelectParking вычисляют center как midpoint viewport, не как GPS пользователя.
3. `FFAppState.filterRadius` — индекс slider; `getMetersFromIndex` переводит его в 5, 10, 50, 100 или 150 км. Если nearest выключен, передаётся `0.0`.
4. Capacity defaults: 0..100. Amenity flags: gas, shower, laundry, hotel, shop, recreation.
5. Search использует debounce 500 ms, lower-case query и принудительный zoom 20, сохраняя остальные filter/bounds params.
6. Ответ RPC напрямую передаётся в map/search UI как dynamic JSON.
7. Клиент не задаёт `limit`, `range`, page/cursor. В generated table adapter limit существует, но эти RPC wrappers его не передают.
8. RPC использует zoom grid clustering и spherical distance formula; сортировки по расстоянию и hard result limit в `get_filtered_parkings` нет. Typed contract fixtures обязательны перед рефакторингом.

## Tables и views: фактические callers

Точные policies приведены в backend reference. Главные cross-cutting риски: public `users SELECT *`, unrestricted own sensitive-column update, broad parking update и broad photo insert/delete.

| Flutter-файл / сценарий | Entity | Операция и параметры | Dart-результат | Null/error handling | Риск |
|---|---|---|---|---|---|
| `auth/validate_sms_code/validate_sms_code_widget.dart` / после OTP | `users` | select where `id = currentUserUid` | `List<UsersRow>` | `firstOrNull`; без catch; выбирает Home или Registration | критический |
| `auth/registration/registration_widget.dart` / завершение профиля | `users` | update by id: `full_name`, optional `avatar_url`, `last_device_id` | generated update result не используется | upload length check; DB error не показана | критический |
| `profile/profile/profile_widget.dart` / header | `users` | querySingle where id | `List<UsersRow>` max 1 | empty → nullable row/default name; FutureBuilder error не отделён от loading | высокий |
| `profile/profile/profile_widget.dart` / referral | `users` | select by id → `referral_code` | `List<UsersRow>` | force unwrap first row/code | высокий |
| `profile/edit_profile/edit_profile_widget.dart` | `users` | querySingle; update `full_name`, optional `avatar_url`, `updated_at` by id | `UsersRow` list / update rows | FutureBuilder spinner; no explicit DB catch | высокий |
| `features/favorites/application/FavoritesController` → `features/favorites/data/favorites_service.dart` / favorites list | `view_user_favorites` | select where `user_id = currentUserUid` | `FavoritesState.items: List<FavoriteParking>` | empty state есть; empty/invalid user id → empty list; load failure хранится в state, UI пока сохраняет старый spinner-only behavior | средний |
| `features/favorites/data/favorites_service.dart` / details initial toggle | `favorites` | select where `parking_id` and `user_id`, limit 1 | `bool` | empty/invalid ids → false | средний |
| `features/favorites/application/FavoriteToggleController` -> details toggle | `favorites` | delete by `parking_id` + `user_id`; insert `user_id`, `parking_id` | `FavoriteToggleState.isFavorite` | controller uses optimistic state with rollback; UI snackbar on failure; action gated by `AppConfig.canPerformWrite(AppWriteOperation.favoriteToggle)` | средний |
| тот же / details | `view_full_parking_details` | querySingle where `id = parkingId` | `List<ViewFullParkingDetailsRow>` | spinner on no data; nullable row handling частичное | высокий |
| `features/parking_photos/data/parking_photos_service.dart` -> `parkings_details/parkings_details` и request detail screens | `parking_photos` | select where `parking_id`, request detail screens keep `order('created_at')` | `List<ParkingPhoto>` | empty/invalid parking id -> empty list; empty supported; error not distinct | средний |
| `features/reviews/data/reviews_service.dart` / parking details info tab and request detail screens | `reviews` | select where `parking_id` | `int` review count | aggregate/display defaults; empty/invalid parking id → 0; error not distinct | средний |
| `features/reviews/data/reviews_service.dart` / parking details reviews tab | `view_reviews_with_users` | select by parking id, order `created_at` | `List<ParkingReview>` | empty state; empty/invalid parking id → empty list; error spins | средний |
| `features/reviews/data/reviews_service.dart` -> `reviews/reviews_and_complaints/reviews_and_complaints_widget.dart` | `view_reviews_with_users` | select `user_id = currentUserUid`, order `created_at` | `List<ParkingReview>` | empty/invalid user id -> empty list; empty state; error spins | средний |
| `features/reports/data/reports_service.dart` -> `reviews/reviews_and_complaints/reviews_and_complaints_widget.dart` | `view_reports_detailed` | select `reporter_id = currentUserUid`, order `report_date` | `List<UserReport>` | empty/invalid user id -> empty list; empty state; error spins | средний |
| `features/reports/data/reports_service.dart` / `reviews/report_create/report_create_widget.dart` | `reports` | insert `parking_id`, `user_id`, comment, `status = approved`, report enum name, `created_at` | `CreatedReport` | button validation; capability-gated by `AppWriteOperation.reportCreate`; service validates ids/report/status; UI shows snackbar on failure | высокий |
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
| registration, edit profile | `avatars/users/<uid>/...` | upload, public URL stored in `users.avatar_url` | upload list length проверяется; DB update отдельно | bucket public, 5 MiB images; локальная migration ограничивает write/delete owner path, production не изменялась |
| create parking flows | `parking_content/parkings/<parkingId>/<index>/<timestamp>.<ext>` | upload, then insert `parking_photos` | нет transaction/compensation; orphan object/partial rows возможны | bucket public, 5 MiB images; локальная migration ограничивает direct content владельцем парковки |
| create review | `parking_content/parkings/<parkingId>/reviews/<reviewId>/<index>/<timestamp>.<ext>` | upload, then insert row | review создаётся до uploads; partial state возможен | локальные DB/Storage migrations ограничивают row owner и review-author path |
| marker asset | public `assets` URL hardcoded в Home | read | fallback default marker on load error | bucket подтверждён public; это часть текущего UI contract |

Helper `deleteSupabaseFileFromPublicUrl` существует; фактические callers в production widgets не найдены. Signed URLs не используются. Uploaded objects предполагаются public.

## Realtime и Edge Functions

- Realtime channels/table streams во Flutter не найдены. В publication находятся `favorites`, `parkings`, `reports`, `reviews`; сейчас это dormant backend contract.
- `functions.invoke` и callers Edge Functions не найдены.
- Packages `realtime_client` и `functions_client` присутствуют транзитивно/явно, но feature usage не подтверждено.

## Generated, но неиспользуемые table wrappers

`geography_columns`, `geometry_columns`, `spatial_ref_sys`, `referral_stats` экспортированы в generated database layer, но прямых callers в `lib/` нет. Это не доказывает, что server-side SQL их не использует.

## Security и масштабирование: обязательные следующие артефакты

До миграции data-heavy features добавить в version control:

1. baseline migration history вместо зависимости от разового dump;
2. RLS tests для anon/owner/cross-user/admin;
3. Storage owner/path tests;
4. contract fixtures для map RPC;
5. query plan и load limits;
6. hardening `users`, `parkings`, `process_referral`, photos и SECURITY DEFINER grants по отдельным этапам.

Repository/service слой должен вводиться на зафиксированных контрактах из backend reference и не должен маскировать P0/P1 findings.
