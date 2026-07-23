# Этап рефакторинга: read-only данные публичной парковки

## Статус

Реализовано и проверено в ветке `agent/public-parking-details-read-slice` после
двух этапов feature `parking_requests`. Публичная карточка парковки продолжает
открываться как modal bottom sheet с карты, избранного и hosting deep link.
Supabase schema/RLS/RPC/Storage, карта, Chottu и production data не менялись.

## State management

Глобальный state manager не менялся. `Provider`, `FFAppState`, generated models
и FlutterFlow navigation остаются совместимыми.

Для read-only данных bottom sheet добавлен локальный `ChangeNotifier` controller
с immutable state. Он принадлежит одной открытой карточке парковки, независимо
хранит состояние деталей и отзывов, загружает отзывы только при открытии вкладки
и уничтожается вместе с bottom sheet.

## Выбранный модуль

Read-only часть публичной карточки парковки:

- основная запись `view_full_parking_details`;
- агрегированные фотографии и counters из той же view;
- favorite flag из `is_favorited` той же view;
- список отзывов `view_reviews_with_users`;
- hosting share URL парковки;
- compatibility с generated info/reviews/photos tabs и photo viewers.

## Почему он выбран

- это центральный read-only сценарий после выбора marker на карте;
- экран используется также входящей hosting-ссылкой и избранным;
- direct Supabase reads были распределены между parent и tabs;
- экран содержит чувствительные navigation/deep-link контракты, которые нужно
  зафиксировать тестами до дальнейшего рефакторинга;
- детали и отзывы можно изолировать без изменения favorite/review/report writes;
- feature даёт repository/controller boundary для последующих безопасных
  write-этапов.

## Поведение до этапа

- `ParkingsDetailsWidget` выполнял `querySingleRow` к
  `view_full_parking_details` прямо в `FutureBuilder`;
- generated helper при ошибке печатал exception и превращал результат в empty;
- nullable `parkingId` проходил через `eqOrNull`; при null фильтр мог исчезнуть;
- отдельный запрос `favorites` определял состояние кнопки, хотя view уже
  содержит `is_favorited` для текущего пользователя;
- photo counter оборачивался в лишний SELECT всех `parking_photos`, хотя число
  уже содержится в view;
- Info tab загружал все `reviews` только ради count, хотя `reviews_count`
  поддерживается database trigger и находится в view;
- Reviews tab напрямую запрашивал `view_reviews_with_users`;
- loading и error визуально не различались;
- raw generated rows передавались между parent и tabs;
- hosting share URL формировался inline внутри UI.

## Новая структура

```text
Map / Favorites / hosted deep link
  -> HomePage(targetParkingId, targetLat, targetLng)
       -> ParkingsDetailsWidget (совместимый bottom sheet shell)
            -> ParkingDetailsController (local immutable state)
                 -> ParkingDetailsRepository (domain port)
                      -> SupabaseParkingDetailsRepository
                           -> ParkingDetailsDataSource
                                -> generated Supabase views

typed ParkingDetails / ParkingReview
  -> narrow legacy adapters
       -> existing FlutterFlow tabs/photo/review cards
```

Направление зависимостей:

```text
presentation shell -> application -> domain repository port
data adapter        -> domain + generated Supabase views
domain/application  -X-> Supabase / FlutterFlow rows
```

## Созданные файлы

- `lib/features/parking_details/domain/parking_details.dart`;
- `lib/features/parking_details/domain/parking_details_repository.dart`;
- `lib/features/parking_details/data/supabase_parking_details_repository.dart`;
- `lib/features/parking_details/data/legacy_parking_details_adapter.dart`;
- `lib/features/parking_details/application/parking_details_controller.dart`;
- `lib/features/parking_details/presentation/parking_details_links.dart`;
- `test/features/parking_details/data/supabase_parking_details_repository_test.dart`;
- `test/features/parking_details/application/parking_details_controller_test.dart`;
- `test/features/parking_details/presentation/parking_details_links_test.dart`;
- `test/features/parking_details/presentation/parkings_details_widget_boundary_test.dart`;
- `docs/public_parking_details_read_slice.md`.

## Изменённые файлы

- `lib/parkings_details/parkings_details/parkings_details_widget.dart` —
  direct SELECT заменены controller/repository boundary; favorite writes и UI
  сохранены;
- `lib/parkings_details/parkings_details/parkings_details_model.dart` — удалён
  ставший ненужным favorite query output и unused imports;
- `lib/parkings_details/info_tab/info_tab_widget.dart` — review count читается из
  подтверждённого view aggregate вместо загрузки всех review rows;
- `lib/parkings_details/info_tab/info_tab_model.dart` — только cleanup imports;
- `lib/parkings_details/reviews_tab/reviews_tab_widget.dart` — отзывы загружаются
  через общий controller и repository;
- `lib/parkings_details/reviews_tab/reviews_tab_model.dart` — только cleanup
  imports;
- `lib/parkings_details/photo_detailed/photo_detailed_widget.dart` — photo share
  URL строится проверенным pure builder без изменения hosting-контракта.

## Все связанные файлы

Navigation и точки входа:

- `lib/map/home_page/home_page_widget.dart`;
- `lib/create_parking2/select_parking/select_parking_widget.dart`;
- `lib/favourites/favourites/favourites_widget.dart`;
- `lib/flutter_flow/nav/nav.dart`;
- `lib/custom_code/actions/listen_chottu_link.dart`;
- hosting `https://js-truck-park.web.app/deeplink.html`.

Presentation и photo flows:

- `lib/parkings_details/photos_tab/photos_tab_widget.dart`;
- `lib/parkings_details/photo_detailed/photo_detailed_widget.dart`;
- `lib/parkings_details/photo_detailed_reviews/photo_detailed_reviews_widget.dart`;
- `lib/parkings_details/shared_photo_view/shared_photo_view_widget.dart`;
- `lib/reviews/review_card_parking_details/review_card_parking_details_widget.dart`;
- `lib/reviews/review_create/review_create_widget.dart`;
- `lib/reviews/report_create/report_create_widget.dart`.

Generated transport contracts:

- `lib/backend/supabase/database/tables/view_full_parking_details.dart`;
- `lib/backend/supabase/database/tables/view_reviews_with_users.dart`;
- `lib/backend/supabase/database/tables/favorites.dart`;
- `lib/backend/supabase/database/tables/parkings.dart`;
- `lib/backend/supabase/database/tables/parking_photos.dart`;
- `lib/backend/supabase/database/tables/reviews.dart`.

## Supabase-зависимости

### Read path после этапа

```text
public.view_full_parking_details
  operation: SELECT
  filter: id = <non-empty selected parking id>
  limit: 1
  use: address, coordinates, rating/stars, capacity, amenities,
       reviews_count, all_photos, photos_count, is_favorited

public.view_reviews_with_users
  operation: SELECT
  filter: parking_id = <non-empty selected parking id>
  order: created_at ascending (существующее поведение)
  use: review content, author display fields, review photos
```

Обе view имеют `security_invoker=true` и выполняются с правами вызывающего
пользователя. `view_full_parking_details` на backend ограничена approved
парковками либо admin access. Client repository дополнительно отклоняет detail
или review row, если row parking ID не совпадает с запрошенным.

`parkings.reviews_count` обновляется trigger
`tr_2_aggregate_parkings` после INSERT/UPDATE/DELETE review, поэтому Info tab
больше не загружает все review rows для повторного подсчёта.

### Write path, намеренно оставленный без изменений

```text
public.favorites
  INSERT: user_id + parking_id
  DELETE: existing generated matching predicate

review/report modals
  existing writes are outside this read-only stage
```

Production write-команды в ходе проверки не выполнялись. RPC, Storage,
Realtime, migrations, grants и RLS не менялись.

## Security improvements

- пустой parking ID возвращает `null`/`[]` без transport query;
- `eqOrNull` больше не может убрать фильтр details/reviews;
- querySingle helper, печатавший backend exception, не используется;
- raw Supabase exception и row payload не сохраняются и не показываются;
- malformed/mismatched rows преобразуются в typed `invalidData` failure;
- details/reviews responses после dispose или более нового request игнорируются;
- UI получает минимальные domain objects, а generated rows создаются только в
  narrow compatibility adapter;
- удалены три лишних SELECT: favorite lookup, photo rows для counter и review
  rows для counter;
- hosting share URL вынесен в pure builder и защищён exact contract test.

## FlutterFlow-зависимости

- `ParkingsDetailsWidget(parkingId)` и modal bottom sheet contract сохранены;
- `HomePage` parameters `targetParkingId`, `targetLat`, `targetLng` не менялись;
- generated parent/tab models пока сохранены;
- `FlutterFlowTheme`, `FFLocalizations`, generated buttons, guest/subscription
  dialogs и navigation serialization продолжают использоваться;
- существующие `ViewFullParkingDetailsRow` и `ViewReviewsWithUsersRow` временно
  создаются compatibility adapters для tabs/review cards;
- photo parameters `photoPath`, `index`, `address`, `photoCount`, `photoRef`,
  `data` не менялись;
- FlutterFlow dependencies не удалялись, пока они используются.

## Deep-link и hosting зависимости

Сохранены без изменения:

- parking share:
  `https://js-truck-park.web.app/deeplink.html?targetParkingId=...&targetLat=...&targetLng=...`;
- inbound target: `HomePage` / `/homePage`;
- main photo viewer: `PhotoDetailed` / `/photoDetailed`;
- review photo viewer: `PhotoDetailedReviews` / `/photoDetailedReviews`;
- shared photo inbound viewer: `SharedPhotoView` / `/sharedPhotoView`;
- photo hosting URL с `route=sharedPhotoView`, encoded `photoUrl`, `address` и
  `date`;
- Chottu initialization/listener/referral handling.

## Файлы и контракты, которые нельзя менять в этом этапе

- `supabase/migrations/`, schema, RLS, policies, views и production data;
- `pubspec.yaml`, global state manager и dependency versions;
- `android/`, `ios/`, Maps keys, signing и build number;
- Google Maps marker/cluster callbacks, viewport RPC и search;
- HomePage route/path/query parameter names;
- hosting domain, deeplink page и query parameter names;
- Chottu/referral link implementation;
- all photo route names/paths/parameters;
- favorite insert/delete, review creation and report creation behavior;
- subscriptions, guest restrictions and external Google Maps navigation;
- translations, assets and visual layout.

## Сохранённое и уточнённое поведение

- marker tap открывает прежний bottom sheet;
- hosting parking link открывает HomePage и ту же карточку;
- favorite icon получает то же user-specific значение из уже существующей view;
- Info, Reviews и Photo tabs, counters и generated cards сохранены;
- reviews загружаются лениво при первом создании Reviews tab;
- фотографии продолжают открывать прежние photo viewers;
- parking/photo share URL contracts не меняются;
- loading/failure сохраняют progress indicator; tap по failure запускает retry;
- missing/empty ID теперь показывает безопасный empty state вместо потенциально
  неограниченного SELECT.

## Последовательность изменений

1. Инвентаризировать marker, favorites и hosted deep-link entry points.
2. Зафиксировать HomePage и photo route contracts тестами.
3. Сверить views, underlying tables, triggers и RLS по schema dump.
4. Добавить typed details/photo/review domain models и repository port.
5. Изолировать generated Supabase views в data source/adapter.
6. Запретить transport query для пустого ID и редактировать errors.
7. Добавить local immutable controller со stale-response protection.
8. Подключить parent bottom sheet через repository injection seam.
9. Перевести Reviews tab на lazy controller read.
10. Удалить redundant favorite/photo/review count SELECT.
11. Сохранить generated tabs/cards через narrow legacy adapters.
12. Добавить data/controller/widget/deep-link tests.
13. Выполнить format, analyze, full tests и platform builds.
14. Исключить Flutter platform template migrations из diff.
15. Зафиксировать этап отдельным rollbackable Git-коммитом.

## Необходимые тесты

- details query всегда получает non-empty selected parking ID и limit 1;
- reviews query получает тот же parking ID и сохраняет created_at ordering;
- пустой ID никогда не вызывает data source;
- detail/review row другого parking отклоняется;
- malformed photo/review data не попадает в UI;
- backend errors становятся только typed failure category;
- details/reviews states независимы;
- stale response и updates after dispose игнорируются;
- reviews не загружаются до открытия Reviews tab;
- bottom sheet показывает address/rating/review count;
- missing parking показывает safe empty state;
- hosting parking URL совпадает посимвольно;
- HomePage и все photo route names/paths сохранены;
- полный существующий test suite проходит.

## Выполненные команды проверки

```bash
dart format lib/features/parking_details \
  lib/parkings_details/{parkings_details,info_tab,reviews_tab} \
  test/features/parking_details
flutter analyze lib/features/parking_details test/features/parking_details
flutter test test/features/parking_details
flutter test
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter build apk --debug --no-pub
flutter build ios --simulator --debug --no-pub \
  --dart-define=APP_ENV=integration
rg -n "queryRows|querySingleRow" lib/parkings_details
rg -n "ViewFullParkingDetailsTable|ViewReviewsWithUsersTable" \
  lib/features/parking_details lib/parkings_details
git diff --check
```

Результат:

- new feature/test analyze: 0 issues;
- parking details tests: 16 PASS;
- full test suite: 90 PASS, было 74;
- full analyzer: 2038 существующих замечаний generated FlutterFlow-кода, было
  2083; новых findings в feature layer нет;
- Android debug APK: успешно;
- iOS Simulator integration build: успешно;
- direct SELECT в `lib/parkings_details`: 0;
- SELECT transport dependencies находятся только в feature data adapter;
- production write/RPC/Storage operations в проверках: 0;
- Android/iOS template migrations полностью исключены из diff.

Существующие infrastructure warnings: будущие обновления Gradle/AGP/Kotlin,
Swift Package Manager support части plugins и iOS UIScene lifecycle. Они не
вызваны этим feature-этапом.

## Ручной чек-лист

- войти обычным authenticated пользователем;
- нажать marker на карте и проверить открытие/закрытие bottom sheet;
- проверить address, rating, reviews count, capacity и amenities;
- проверить парковку без фото и с несколькими фото;
- свайпнуть photo carousel и открыть каждую фотографию;
- открыть Photos tab и фотографию из grid;
- открыть Reviews tab, проверить rating distribution, cards и review photos;
- проверить парковку без отзывов;
- проверить favorite icon, но не выполнять writes в integration read-only mode;
- проверить parking share URL и открытие ссылки на втором устройстве;
- проверить photo share URL и SharedPhotoView;
- открыть карточку из Favourites;
- проверить deep link при cold start и уже запущенном приложении;
- проверить guest/subscription dialogs и Google Maps route button;
- проверить light/dark theme, маленький Android экран и iOS;
- отключить сеть, проверить failure indicator и retry;
- убедиться, что network requests всегда содержат parking ID;
- убедиться, что logs/UI не содержат JWT, raw exception или row payload.

## Условия отката

Откатить этап одним `git revert`, если:

- marker, Favorites или hosted parking link перестали открывать карточку;
- изменился HomePage/photo route либо query parameter contract;
- detail/review data отличается для того же parking ID;
- favorite initial icon отличается от production;
- фотография или shared photo viewer перестали открываться;
- появился SELECT без parking ID;
- появились regression, overflow, crash или чувствительные данные в UI/logs;
- Android/iOS build либо full tests перестали проходить.

Откат не требует backend migration: schema и production data не менялись.

## Предлагаемое сообщение Git-коммита

```text
refactor(parking): isolate public details reads
```

## Предлагаемый следующий этап

Следующий отдельный security/write-этап: favorite toggle. Вынести
insert/delete в repository/use-case, обязательно фильтровать delete по
`parking_id + current user_id`, добавить optimistic rollback, duplicate handling
для unique `(user_id, parking_id)`, typed/redacted errors и RLS contract tests.
Не менять review/report writes, backend schema или другие features в том же
коммите.
