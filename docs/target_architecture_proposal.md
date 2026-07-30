# Предложение целевой архитектуры

## Цель

Цель миграции — масштабируемое, тестируемое и безопасное Flutter-приложение, а не механическое переименование FlutterFlow-файлов. Архитектура должна:

- сохранять пользовательское поведение и backend-контракты на каждом этапе;
- позволять командам менять одну feature без каскада по всему `lib/`;
- иметь typed boundaries для Supabase, plugins и dynamic JSON;
- обеспечивать security-by-design: server-side authorization, безопасную конфигурацию, минимальные права, redacted diagnostics;
- оставаться достаточно простой для текущего размера проекта.

## Предлагаемая структура

```text
lib/
  app/
    bootstrap/
    router/
    app.dart
  core/
    config/                 # environment-specific publishable config
    errors/                 # AppFailure / mapping, без sensitive payloads
    logging/                # redaction-aware interface
    supabase/               # client factory/session adapter, не feature queries
    design_system/          # tokens and shared primitives
    localization/           # generated l10n + locale persistence
  features/
    onboarding/
    auth/
    language/
    parking_discovery/      # map, viewport search, filters
    parking_submission/     # both current create flows converge here later
    parking_details/
    favorites/
    reviews/
    reports/
    profile/
    referrals/
    parking_requests/
    subscription/
  shared/
    presentation/           # only truly cross-feature UI; keep small
```

Типичная feature, только если все слои нужны:

```text
features/<feature>/
  data/
    <feature>_repository.dart
    supabase_<feature>_repository.dart
    dto/
  domain/                   # optional; only real rules/entities
  application/
    <feature>_controller.dart
    <feature>_state.dart
  presentation/
    <feature>_page.dart
    widgets/
```

Не каждая feature обязана иметь четыре папки. Для language pilot достаточно `application` + `presentation` и небольшого locale port; Supabase repository/domain там избыточны.

## Реальные feature-границы

| Feature | Текущие screens/files | Правила и данные | Зависимости | Независимая миграция |
|---|---|---|---|---|
| Language | `language/*`, locale owner в `main.dart`, translations | en/ru, persistence, update app locale | FlutterFlow localization/theme/button | да; лучший пилот |
| Onboarding | splash + onboard1..3 | first-run, referral wait, auth/guest branching | auth, deep links, device id, app state | только после auth/link characterization |
| Auth | phone entry, OTP, registration | session, new/existing user, guest, profile completion | Supabase Auth/users/avatars/referral | нет на раннем этапе; критический |
| Parking discovery | Home, custom map, filter, legacy Map | viewport, clustering, filters, search, location | Google Maps/Geolocator/RPC/FFAppState | после получения SQL/RPC fixtures |
| Parking submission | `create_parking` и `create_parking2` | 500 m rule, form, moderation status, media | map/geocode/parkings/storage | сначала сравнить и выбрать canonical flow |
| Parking details | details + info/photos/reviews tabs/viewers | aggregate display, routes, favorites, share | views/tables/storage/map route | средне; разделить read model и actions |
| Favorites | list + toggle | current user ownership, optimistic toggle | favorites + view | да после RLS/rollback contract |
| Reviews | create/list/cards | rating invariants, one review rule if server-backed, photos | reviews/views/storage | после SQL/RLS/transaction design |
| Reports | create/list/complaint cards | category/comment/status | reports/view | да после RLS validation |
| Profile | view/edit/logout/delete | identity, avatar, theme, account deletion | users/auth/storage/RPC | высокий риск; разделить settings/profile/account |
| Referrals | invite + deep link processing | code/device/idempotency/eligibility | Chottu/RPC/users | отдельная security-sensitive feature |
| Parking requests | three status lists/details | pending/approved/rejected | parkings/photos/reviews | да после typed status/read repository |
| Subscription | paywall/dialogs | offerings, eligibility, entitlement, restore | RevenueCat/auth/global state | критический; отдельный entitlement service |

## Dependency rules

```text
presentation -> application -> repository port
                              -> platform/service port
data adapters -> Supabase / plugins
app -> wires dependencies and routes
core -> contains no feature business rules
feature A -> feature B only through an explicit small public contract
```

Запрещённые целевые связи:

- widget → `SupaFlow.client` / generated table напрямую;
- widget → RevenueCat/Geolocator/Chottu plugin напрямую;
- repository → `BuildContext`;
- feature state → singleton `FFAppState` после миграции этой feature;
- server authorization, premium or ownership decisions только в UI.

## Где нужен repository

Repository нужен, когда feature читает/пишет persistent remote data и должна скрыть transport/generated rows:

- auth profile (`users`) после отделения Supabase Auth service;
- parking discovery RPC;
- parking submission/details;
- favorites;
- reviews/reports;
- parking requests.

Repository возвращает typed DTO/entity или `Result<T, AppFailure>`, не `ApiCallResponse`, `dynamic` или `SupabaseDataRow`. Он сохраняет точные query parameters и server semantics.

Repository не нужен language page, статическим onboarding pages и простому UI-only dialog.

### Current migration notes

- Favorites toggle now uses `features/favorites/data/FavoritesService` for the
  write path. It validates `parkingId/userId`, checks
  `AppConfig.canPerformWrite(AppWriteOperation.favoriteToggle)`, and scopes
  deletes by both `parking_id` and `user_id`.
- Favorites list reads `view_user_favorites` through the same feature service
  and maps generated rows into the typed `FavoriteParking` read model before
  reaching FlutterFlow widgets.
- The favorites page now uses feature-scoped `FavoritesController` +
  immutable `FavoritesState` on top of the existing `provider` package for
  list loading state. This keeps the transitional state-management strategy
  local to one feature.
- Parking details favorite state now uses `FavoriteToggleController` with
  immutable `FavoriteToggleState`; the generated page no longer owns the
  initial favorite read or optimistic rollback.
- Parking details review reads now use `features/reviews/data/ReviewsService`.
  The details info tab receives a typed count and the reviews tab/card receive
  `ParkingReview`, while review creation remains outside this read-only stage.
- Report creation now uses `features/reports/data/ReportsService` with
  `AppWriteOperation.reportCreate`. The service preserves the current insert
  payload, validates the user/parking/report/status boundary and returns a
  typed `CreatedReport`.
- Profile reviews/complaints reads now go through `ReviewsService` and
  `ReportsService`. The UI receives typed `ParkingReview`/`UserReport`
  objects instead of querying generated Supabase views directly.
- Parking photo reads for details/request detail screens now use
  `features/parking_photos/data/ParkingPhotosService`. Photo uploads remain in
  the legacy create/review flows until a separate transactional write stage.
- Request detail review counts now use `ReviewsService`; accepted, rejected and
  moderation presentation no longer query the generated `reviews` table.
- Parking request list reads now use `ParkingRequestsService`, which owns the
  current-user and typed status filters. `ParkingsRow` remains temporarily as a
  route-compatible result until request state migration is complete.
- Request tab selection and loading now use `ParkingRequestsController` with
  immutable state and stale-response protection. The generated page model no
  longer owns three mutable tab booleans.
- Main parking detail reads now use `ParkingDetailsService`. The detail sheet
  and its info/reviews/photos tabs receive typed `ParkingDetails` and
  `ParkingDetailPhoto` data instead of the generated Supabase view row.
- Review submission now has a typed validation and gateway contract in
  `ReviewSubmissionService`. The Supabase gateway supports review inserts and
  staged photo uploads behind the guarded review-create capability, preserving
  FlutterFlow image constraints and compensating created review/object state on
  failure. The review-create UI now calls this service instead of the legacy
  direct insert/upload loop.
- Review owner updates are prepared in `ReviewsService.updateReview(...)`
  behind the guarded review-update capability. The service only accepts mutable
  review content (`comment` and five ratings) and scopes the Supabase update by
  both `id` and `user_id`; UI wiring remains a separate stage.
- Review owner deletion is prepared in `ReviewsService.deleteReview(...)`
  behind the guarded review-delete capability. It deletes the owner-scoped
  review row and performs best-effort cleanup of associated public Storage
  objects, reporting cleanup failures without reintroducing the deleted row.
- Profile header, edit initial form and post-OTP profile-completion check now
  consume `PublicUserProfile` (`id`, `fullName`, `avatarUrl`) through
  `features/profile/data/UserProfileService`. Invite referral lookup uses the
  explicit private profile boundary for `referralCode`. The Supabase gateway
  now reads `public_profiles` and `private_profiles` views instead of the
  legacy `users` table for profile reads.
- Profile and parking details UI stability guard is documented in
  `profile_and_parking_details_ui_stability.md`: profile loading reserves the
  final header height, while the parking details controller keeps loaded data
  stable across tab changes.
- Profile page local invite visibility state now lives in
  `features/profile/application/ProfileController` with immutable state. This is
  intentionally narrow and preserves the generated screen behavior while moving
  profile UI state out of `ProfileModel`.
- Edit profile initial form data now also uses `UserProfileService`, so profile
  read paths are behind the typed boundary. The save action is intentionally
  still legacy until the guarded profile update contract is introduced.
- Profile update now has a typed validation and atomic gateway contract in
  `UserProfileService`. `AppWriteOperation.profileUpdate` remains disabled, no
  Supabase update gateway exists and the legacy edit UI is not wired to it;
  activation prerequisites are recorded in `profile_update_contract.md`.

## Где нужен service

Service/adapter нужен для внешней capability, не являющейся CRUD aggregate:

- `AuthService` — session/OTP/sign-out;
- `LocationService` — permission + coordinate result;
- `MapService`/adapter — camera/viewport callbacks при необходимости;
- `GeocodingService`;
- `StorageService` — upload/delete с policy-aware paths;
- `DeepLinkService`;
- `DeviceIdentityService`;
- `PurchaseService`/`EntitlementService`;
- `LocaleStore`, `Clock`, `UrlLauncher`, `ShareService`.

Services передаются через constructor/provider, что позволяет fake implementations в tests.

## Где достаточно controller/provider

- language: `LanguageController` + immutable state/current locale + `LocaleStore`;
- filter UI: controller, но RPC остаётся в discovery repository;
- tabs/forms: local controller/state;
- theme/settings: settings controller после отделения от profile.

Controller управляет состоянием и orchestration, но не строит SQL, headers или Storage paths без отдельного policy/adapter.

## Нужен ли domain-слой

Нужен выборочно:

- parking filters/radius и coordinate/value objects;
- parking submission invariants/status;
- review rating and validation;
- subscription entitlement;
- referral decision/result, если правила подтверждены server contract.

Не нужен для language screen, простых DTO displays и wrappers над одним query. Интерфейсы на каждый класс, use case на каждый tap, generic base repositories и event bus будут избыточны.

## State management

На переходном этапе сохранить уже установленный `provider`, но заменить global mutable singleton на feature-scoped controllers, immutable state и constructor injection. Это:

- минимизирует cross-cutting change;
- позволяет мигрировать одну feature за commit;
- поддерживает unit/widget tests без `FFAppState`;
- не привязывает data layer к Flutter context.

Riverpod/BLoC можно оценить отдельным ADR после 2–3 пилотов. Немедленная глобальная замена state management нарушит ограничение, смешает инфраструктурную миграцию с features и не создаст ценность сама по себе. Масштабируемость здесь обеспечивают границы/immutability/DI, а не название библиотеки.

## Security-by-design

### Конфигурация

- Вынести URL и publishable client keys в typed environment config/flavors.
- Помнить, что `--dart-define` попадает в binary: там допустимы только publishable values. Service-role keys и backend secrets никогда не должны быть в Flutter.
- Ограничить Google keys по application id/bundle id и разрешённым APIs; предусмотреть rotation.
- Разделить dev/staging/prod projects и identifiers.

### Authorization и data access

- RLS и RPC authorization — обязательный server-side boundary; guest/premium UI flags не дают доступа.
- До repository migration добавить RLS contract tests: owner/cross-user/anonymous/admin cases.
- Не доверять `user_id`, `referee_id`, `created_by` из клиента без server validation against JWT.
- Account deletion/referral functions проверить на `SECURITY DEFINER`, `search_path`, idempotency и abuse controls.

### Input/output

- Dynamic RPC JSON заменить typed DTO с range/type/null validation.
- Coordinates/radius/capacity/search нормализовать и валидировать на client и server.
- Для compound writes parking/review + photos рассмотреть transactional server RPC или compensating cleanup отдельным backend заданием.
- Storage policies должны ограничивать owner path, MIME, size, write/delete; public buckets использовать только осознанно.

### Errors, logging, privacy

- Ввести `AppFailure` categories без JWT, phone, coordinates и raw server payload в пользовательских сообщениях/logs.
- Crash/analytics tooling подключать с consent и redaction policy отдельным этапом.
- Не печатать tokens, OTP, referral/device identifiers.
- Threat model обязателен для auth, referrals, subscription, geolocation и account deletion.

## Почему это лучше текущего

Текущий widget знает route, global state, SQL-shaped rows, API headers, JSONPath и UI одновременно. Новая граница делает presentation зависимой от typed feature API; transport, plugins и security policy можно тестировать/заменять независимо. Feature-first структура уменьшает радиус изменения, а совместимые exports/adapters позволяют постепенный переход без big-bang rewrite.

## Этапность

1. Infrastructure prerequisite: зафиксировать совместимый Flutter и получить зелёный baseline.
2. Language pilot: отделить пустой FlutterFlowModel и UI lifecycle при сохранении locale/theme/localization behavior.
3. Settings/localization foundation: typed locale store и позднее `gen_l10n`, отдельными commits.
4. Read-only, bounded feature: parking requests или favorites list после RLS/contracts.
5. Data-heavy writes: reviews/reports, затем parking submission с transactional plan.
6. Critical features: map/discovery, auth, subscription, global navigation/app state.
7. Удаление оставшихся FlutterFlow adapters только при нулевом usage.

Каждый этап включает characterization tests, security review соответствующей границы, format/analyze/test/build и отдельный rollbackable commit.
