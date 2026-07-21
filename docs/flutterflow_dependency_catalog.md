# Каталог FlutterFlow-зависимостей

## Сводка

| Маркер | Файлов | Вхождений |
|---|---:|---:|
| `FlutterFlowModel` | 48 | 52 |
| `createModel` | 49 | 51 |
| `wrapWithModel` | 2 | 4 |
| `FlutterFlowTheme` | 51 | 2195 |
| `FFAppState` | 21 | 239 |
| `safeSetState` | 49 | 293 |
| `valueOrDefault` | 17 | 52 |
| `context.pushNamed` | 17 | 24 |
| `context.goNamed` | 13 | 15 |
| `serializeParam` | 10 | 39 |
| `getJsonField` | 9 | 25 |
| imports `backend/schema` | 38 | 59 |

Почти каждый экран зависит от generated theme/model/util. Удаление `lib/flutter_flow/` целиком невозможно до завершения всех feature-этапов.

## UI и тема

| Зависимость | Где | Назначение | Замена в чистом Flutter | Сложность / независимость | Затрагиваемые модули |
|---|---|---|---|---|---|
| `FlutterFlowTheme.of(context)` и `.override()` | 51 файл; все screen/widget directories, `main.dart`, upload dialog | colors, typography, light/dark tokens | `ThemeData`, `ColorScheme`, `TextTheme`, ThemeExtension для product tokens | высокая глобально; низкая по одному leaf screen при visual regression tests | все UI features |
| `FFButtonWidget`, `FFButtonOptions` | большинство форм/диалогов; определены в `flutter_flow_widgets.dart` | единый button + loading behavior | design-system `AppButton` на Material buttons | средняя; заменять по feature | auth, language, profile, parking, reviews, subscription, dialogs |
| `FFIcons` / custom fonts | `flutter_flow/custom_icons.dart`, assets/fonts, UI files | generated icon font mappings | audited SVG/IconData assets через design system | средняя; нужна pixel/icon audit | map/search/filter/profile/navigation |
| generated layout extensions (`divide`, responsive helpers) | через `flutter_flow_util.dart` | spacing и responsive helpers | стандартные `SizedBox`, `MediaQuery`, локальные extensions | низкая по feature | почти все screens |
| `FlutterFlowGoogleMap` | `map/map`; определён в `flutter_flow_google_map.dart` | generated Google Map wrapper | собственный typed map adapter | высокая; legacy route сначала классифицировать | legacy map |
| upload widgets/data | `flutter_flow/upload_data.dart`, `uploaded_file.dart`, form screens | picker state, preview, selected files | feature media service + typed upload state | высокая из-за Storage и permissions | auth/profile/parking/reviews |

## Навигация

| Зависимость | Где | Назначение | Чистая замена | Сложность / независимость |
|---|---|---|---|---|
| `FFRoute`, `createRouter`, `AppStateNotifier` | `flutter_flow/nav/nav.dart`, `main.dart` | route registry, auth refresh, splash gate | обычный GoRouter config в `app/`, typed redirects | критическая; не пилотировать первой |
| `context.pushNamed`, `goNamed`, `safePop` | route screens и dialogs | imperative navigation | GoRouter напрямую или feature navigator interface | средняя; leaf feature можно мигрировать независимо при сохранении names/paths |
| `goNamedAuth`, `pushNamedAuth`, `prepareAuthEvent` | auth/logout flows | синхронизация auth change и redirect | централизованный auth redirect/coordinator | высокая |
| `serializeParam` / `deserializeParam` | `serialization_util.dart`, 10 callers | query params, enums, SupabaseRow через `extra` | typed route data/codegen или explicit DTO | высокая для row routes; средняя для primitives |
| `lib/index.dart` exports | `nav.dart` и screen imports | глобальный page registry | прямые feature imports | низкая технически, но массовая; менять инкрементально |

## Управление состоянием

| Зависимость | Где | Назначение | Чистая замена | Сложность / независимость |
|---|---|---|---|---|
| `FFAppState` | `app_state.dart` + 20 consumers | глобальные map/filter/auth guest/onboarding/premium/referral/temp form values | сначала feature-scoped ChangeNotifier/controller; persisted settings service; immutable state | высокая; делить по owner, не заменять целиком |
| Provider для `FFAppState` | `main.dart`, generated imports | rebuild через `context.watch` | Provider можно сохранить на переходный период; позже DI/provider strategy | низкая сама по себе |
| `FlutterFlowModel<T>` | 48 model classes | lifecycle, controllers, local/API outputs | State class/controller/ViewModel по необходимости | средняя; empty model легко убрать в leaf feature |
| `createModel` | 49 widgets | model lifecycle через Provider | обычный `State.initState/dispose` или injected controller | средняя; независимо по screen |
| `wrapWithModel` | parking details + implementation | child tab model ownership | явная передача controller/state | высокая внутри parking details |
| `safeSetState` | 49 files | mounted-aware setState | `if (mounted) setState(...)`; controller notifications | низкая механически, но async flows требуют тестов |

## Утилиты и сериализация

| Зависимость | Где | Что делает | Предлагаемая замена | Риск |
|---|---|---|---|---|
| `valueOrDefault` | 17 files | null/empty fallback | `??`, explicit domain fallback | низкий, но empty-string semantics проверить |
| `getJsonField` | API/search/photos/referral callers | JSONPath over `dynamic` | typed DTO + `fromJson` validation | средне-высокий; boundary-by-boundary |
| `supaSerialize`, `getCurrentTimestamp` | writes | Postgres serialization/time | repository serializer + injected clock | средний |
| `getCurrentUserLocation` | home/create flow | permissions + geolocation + default | `LocationService` returning typed success/failure | высокий из-за permissions/map |
| `setAppLanguage`, `setDarkModeSetting` | language/profile | доступ к `MyApp.of(context)` | settings controller/service | низкий для language, средний для theme |
| date/number/url helpers | UI modules | formatting/launching | focused core utilities, injected launcher | низкий по одному helper |
| `flutter_flow/custom_functions.dart` | 39 imports | mixed business/display helpers | перенести к owning features; чистые функции тестировать | средний; файл нельзя удалять до последнего caller |

## Supabase-модели и backend schema

- `lib/backend/supabase/database/{row,table}.dart` — generated generic CRUD adapter.
- `lib/backend/supabase/database/tables/*.dart` — generated row/table classes для 9 tables/system tables и 4 views.
- `lib/backend/schema/structs/subscription_prices_struct_struct.dart` — FlutterFlow serializable struct.
- `lib/backend/schema/enums/enums.dart` — UI/domain-like enums, используемые parking/review/request flows.
- 38 файлов импортируют `backend/schema`, в том числе boilerplate custom code, даже когда symbols не используются.

Чистая замена: immutable DTO с проверяемым parsing; repositories должны скрыть PostgREST rows от presentation. Domain entity нужен только там, где есть устойчивые правила (parking, review, subscription); простому language/settings pilot он не нужен. Мигрировать по feature, сохраняя generated rows как adapter до завершения конкретного feature.

## Custom code

Custom actions:

- auth: `send_otp.dart`, `verify_otp.dart`;
- device/deep links/referral: `get_device_id.dart`, `init_chottu_link.dart`, `listen_chottu_link.dart`, `wait_for_referral_code.dart`, `create_referral_link.dart`;
- subscription: `fetch_premium_expiration_date.dart`, `get_smart_subscription_prices.dart`, `purchase_smart_package.dart`;
- platform/UI: `open_google_maps_route.dart`, `hide_keyboard.dart`.

Custom widgets: `custom_google_map.dart`, `map_shield.dart`, `bottom_spacer.dart`.

Почти весь custom code содержит автоматические FlutterFlow imports на schema/theme/util, часто неиспользуемые. Удалять boilerplate следует только при миграции owning feature. Чистая замена — typed services/adapters с constructor injection; platform plugins не должны вызываться напрямую из UI.

## Локализация

- `FFLocalizations`, delegate, translation map и locale persistence находятся в `flutter_flow/internationalization.dart`.
- UI вызывает `FFLocalizations.of(context).getText(<opaque id>)` и `getVariableText`.
- Чистая замена: Flutter `gen_l10n` + ARB, семантические keys, settings repository для locale.
- Глобальная замена высокорисковая; language pilot должен сначала сохранить `FFLocalizations`, изменяя только boundary самого экрана.

## Платформенная конфигурация

| Область | Зависимость от экспорта | Рекомендация |
|---|---|---|
| Android/iOS/web | generated project files, app identifiers, plugin setup | не менять вместе с feature refactor; platform upgrades отдельными commits |
| Google Maps | platform keys/config + Dart API key/URLs | вынести publishable config per environment, ограничить keys по bundle/application/API |
| Supabase | URL/publishable keys в Dart | compile-time environment config; server secrets только на backend; rotation plan |
| RevenueCat | platform keys в `main.dart` | environment config + entitlement service |
| Chottu Link | key/domain в custom actions | environment config + link service |
| Assets/fonts | FlutterFlow icon fonts и generated asset paths | не удалять до asset usage audit |

## Порядок безопасного удаления FlutterFlow

1. Зафиксировать зелёный baseline и security/config inventory.
2. Для leaf feature создать typed boundary и characterization tests.
3. Перенести UI/state feature, сохраняя route name/path и backend contract.
4. Оставить compatibility export/adapters для старых callers.
5. Удалять конкретную FlutterFlow-зависимость только когда `rg` не показывает callers.
6. `flutter_flow/`, global nav и `FFAppState` удалять последними отдельными этапами.
