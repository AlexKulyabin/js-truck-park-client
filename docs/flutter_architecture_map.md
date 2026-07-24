# Карта Flutter-архитектуры

## Общая схема

`main.dart` последовательно инициализирует Supabase, FlutterFlow theme, локализацию, persisted `FFAppState` и RevenueCat, затем создаёт `ChangeNotifierProvider<FFAppState>` и `MaterialApp.router`.

```text
main.dart
  ├─ SupaFlow.initialize() ── Supabase Auth / PostgREST / Storage
  ├─ FlutterFlowTheme + FFLocalizations + FFAppState
  ├─ RevenueCat
  └─ MyApp
      ├─ AppStateNotifier ── auth stream + 1-second splash gate
      ├─ GoRouter / FFRoute / serialization_util
      └─ screens and dialogs
          ├─ direct generated Supabase tables/views
          ├─ REST RPC wrappers in api_calls.dart
          ├─ custom actions/widgets
          └─ global mutable FFAppState
```

Текущая архитектура screen-first: UI, запросы, сериализация, правила и навигация обычно находятся в одном `*_widget.dart`. Generated `*_model.dart` хранит controllers, flags и результаты API. Отдельного repository/service слоя нет.

## Bootstrap, сессия и навигация

- Точка входа: `lib/main.dart`.
- Supabase: `lib/backend/supabase/supabase.dart`; singleton `SupaFlow.client`, implicit auth flow.
- Сессия: `lib/auth/supabase_auth/supabase_user_provider.dart` слушает `onAuthStateChange`; `lib/auth/supabase_auth/auth_util.dart` отдельно слушает JWT.
- Splash gate: `AppStateNotifier.loading` зависит от первого auth user и флага `showSplashImage`; флаг снимается через одну секунду.
- Реальная splash-логика: `lib/onboarding/splash/splash_widget.dart` инициализирует Chottu Link/device id, восстанавливает referral, затем выбирает onboarding/auth/home.
- Маршрутизация: `lib/flutter_flow/nav/nav.dart`, 24 именованных route; сериализация параметров — `lib/flutter_flow/nav/serialization_util.dart`; page exports — `lib/index.dart`.
- Deep links: Chottu Link custom actions и query `ref` у `SplashWidget`. Прямого использования `app_links` в `lib/` не найдено.
- Push notifications: Flutter/Dart-обработчик не найден. В iOS есть `ios/ImageNotification/NotificationService.swift`, но связанный Dart-flow не обнаружен.

## Состояние

- Глобальное: singleton `FFAppState` в `lib/app_state.dart`, предоставленный через Provider. Persisted: `places`, `isReadPolicy`, `isOnboarding`, `tempReferralCode`. Остальные значения живут в памяти.
- Auth/router: singleton `AppStateNotifier`.
- Локальное: 48 generated `FlutterFlowModel` subclasses; controllers, upload flags, API outputs, tab/filter state.
- Loading: преимущественно `FutureBuilder` со spinner при `!snapshot.hasData`.
- Error handling: у многих generated table operations нет `try/catch`; `FutureBuilder` редко различает error и loading. REST wrappers возвращают `ApiCallResponse`, но некоторые проверки используют `succeeded ?? true`, что потенциально трактует отсутствие результата как успех.
- Null safety: analyzer нашёл 197 лишних `!` и 41 бессмысленное null-сравнение. Есть force unwrap route/data/API values.

## Функциональные модули

| Модуль | Экраны и основные файлы | Состояние | Supabase / RPC | Внешние зависимости | FlutterFlow-зависимости | Риск |
|---|---|---|---|---|---|---|
| Bootstrap/navigation | `main.dart`, `app_state.dart`, `flutter_flow/nav/*`, `index.dart` | `FFAppState`, `AppStateNotifier`, locale/theme | init, Auth stream | Provider, GoRouter, SharedPreferences, RevenueCat | theme, util, route serialization | критический |
| Onboarding/deep link | `onboarding/splash`, `onboard1..3`, `custom_code/actions/{init,listen,wait}_chottu_link.dart`, `get_device_id.dart` | model + onboarding/referral/device fields in `FFAppState` | Auth status; later referral RPC in registration | Chottu Link, device_info_plus | model/theme/util/widgets/navigation | высокий |
| Auth/registration | `auth/enter_phone_number`, `validate_sms_code`, `registration`, `auth/supabase_auth/*`, custom `send_otp`, `verify_otp` | models, phone/isGuest/referral in `FFAppState`, auth stream | Auth OTP; `users`; `avatars`; `process_referral` | Supabase Auth, image picker | generated auth manager, model/theme/util/upload/navigation | критический |
| Home map/search + SelectParking reads | `map/home_page`, `create_parking2/select_parking`, `features/map`, `custom_code/widgets/custom_google_map.dart`, legacy `map/map` | local stale-safe controllers + typed repository; filter fields пока в `FFAppState`; legacy marker adapter на UI boundary | REST RPC `get_filtered_parkings`; declared `get_parkings_by_viewport`; public Storage marker URL | Google Maps, Geolocator, Google Geocoding, RevenueCat | generated model/theme/util/custom map сохранены; прямой parking RPC из active widgets удалён | высокий; active reads изолированы, renderer и create write-flow ещё legacy |
| Filters | `filter/filter` | model controls + 10 filter fields in `FFAppState` | parameters consumed by `get_filtered_parkings` | none | model/theme/util/widgets | высокий из-за связи с картой/RPC |
| Parking creation | parallel flows `create_parking/*` and `create_parking2/*`; map long-press/select | form models + temporary address/lat/lng in `FFAppState` | insert `parkings`, insert `parking_photos`, bucket `parking_content`, Google geocode | Geolocator, image picker, Google Maps | model/theme/util/upload/custom functions | высокий |
| Parking details | `parkings_details/parkings_details`, tabs and photo viewers | parent/child models, guest/map flags | `view_full_parking_details`, `favorites`, `parking_photos`, `reviews`, `view_reviews_with_users` | Google Maps route launcher, network images/share | model/theme/util/widgets/row serialization | высокий |
| Favorites | `favourites/favourites`, `favourite_card`; toggle also in parking details | models; no global feature state | `view_user_favorites`; write `favorites` in details | network images | model/theme/util/widgets/navigation | средний |
| Reviews/reports | `reviews/review_create`, `report_create`, cards, `reviews_and_complaints` | form/tab/upload models | `reviews`, `reports`, `parking_photos`, views `view_reviews_with_users`, `view_reports_detailed`, bucket `parking_content` | image picker | model/theme/util/upload/enums | высокий |
| Profile/referrals | `profile/profile`, `edit_profile`, dialogs | model + theme/premium/guest fields in `FFAppState` | `users`, bucket `avatars`, `delete_user_account`; referral link creation | Chottu Link, share_plus | model/theme/util/upload/navigation | высокий |
| User parking requests | `requests/requests`, accepted/moderation/rejected, cards | tab model + global guest | `parkings`, `parking_photos`, `reviews` | network images | models/theme/util/enums/row route serialization | средне-высокий |
| Subscription | `subscription/pay_wall`, dialogs; RevenueCat util/actions | model + premium plan fields in `FFAppState` | user/session identity indirectly; direct DB call not found | purchases_flutter / RevenueCat | model/theme/util/revenue_cat_util | критический |
| Language | `language/language_widget.dart`, empty `language_model.dart`; locale owner in `main.dart` | locale in `MyApp`, persisted in `FFLocalizations` | нет | SharedPreferences, Google Fonts | model/theme/util/widgets/localization | низкий |

## Маршруты

Маршруты есть для HomePage, Map, трёх auth screens, AddParking/CreateParking/SelectParking, Profile/EditProfile, Language, Requests и трёх detail statuses, Favourites, reviews/complaints, трёх onboarding screens + Splash, PayWall и трёх photo viewers. Компоненты, tabs и dialogs открываются вложенно и не имеют route.

Guard не описан декларативно на каждом route. `AppStateNotifier` refresh-ит router при auth change, а конкретные screens часто сами выполняют `goNamed`/`pushNamed` и проверяют `FFAppState().isGuest`. Это повышает риск расхождения правил доступа.

## Карта, геопоиск и фильтрация

- `getCurrentUserLocation` находится в `flutter_flow_util.dart`; запрашивает service/permission и возвращает default при отказе.
- `CustomGoogleMap` получает visible bounds и zoom, затем вызывает callback.
- Home и SelectParking передают в `get_filtered_parkings`: bounds, midpoint как center, radius в метрах, capacity, service booleans, zoom, search query и `is_filter_active`.
- Slider radius преобразуется в 5/10/50/100/150 км функцией `getMetersFromIndex`.
- RPC response валидируется в `MapParkingPoint`, затем presentation adapter
  создаёт immutable `MapMarkerItem`; `CustomGoogleMap` больше не читает
  dynamic map keys. Search panel также использует immutable
  `MapSearchResultItem` и не разбирает JSONPath.
- Поиск lower-case, debounce 500 ms; результат представлен immutable
  `MapSearchResultItem`.
- Search panel выделен в `HomeMapSearchPanel`: он получает immutable typed
  results и callbacks, а query/controller/dialog/navigation ownership остаётся
  в Home.
- Клиентской пагинации/range нет. Schema snapshot подтвердил zoom-grid clustering, spherical radius filter, GiST geography index и отсутствие hard result limit/сортировки в `get_filtered_parkings`; подробности в `supabase_backend_reference.md`.
- Reverse geocode Home/SelectParking проходит через общий typed repository и application service; generated Google call из widgets удалён. Credential/config остаётся отдельным security debt, см. `docs/reverse_geocoding_read_integration.md`.
- Production Home/SelectParking используют typed repository/controller и
  typed marker renderer boundary; characterization и этапы миграции описаны
  в `map_read_contract_characterization.md` и
  `typed_map_marker_contract.md`.

## Локализация и темы

- Языки: `en`, `ru`.
- Переводы: большой generated map в `flutter_flow/internationalization.dart`.
- Выбор locale хранится в SharedPreferences под `__locale_key__`, owner — `MyApp`.
- Theme owner также в `MyApp`, реализация — `FlutterFlowTheme`; отдельный `FFAppState.isDarkThemeOn` создаёт вторую потенциальную source of truth.

## Security observations

Это наблюдения, не применённые изменения:

1. Publishable service keys и endpoint configuration захардкожены в Dart-коде. Publishable ключи не являются server secrets, но их смешение с кодом затрудняет environment separation, rotation и проверку конфигурации.
2. RPC вызываются через вручную собранные REST-запросы и Bearer headers. Нужен единый authenticated client и typed boundary; нельзя менять до проверки auth/RLS semantics.
3. RLS и Storage policies отсутствуют в репозитории, поэтому безопасность write/read операций не доказана. Клиентские проверки guest/premium не являются security boundary.
4. Возвращаемые dynamic JSON и force unwrap увеличивают риск malformed response/crash.
5. Не найдено централизованного redaction/logging/error mapping. Некоторые исключения печатаются напрямую.
6. Удаление аккаунта, referral и геопоиск — подтверждённые RPC-контракты с высоким security/abuse риском; перед рефакторингом нужны negative RLS tests и contract fixtures из `backend_security_audit.md`.

Целевой принцип: секреты остаются только на server side; publishable config инъецируется per environment; authorization обеспечивается RLS/RPC, а UI лишь отражает права; все сетевые границы typed, валидируемы и тестируемы.
