# Выделение панели поиска Home

Дата: 2026-07-24

Ветка: `agent/extract-map-search-panel`

## Выбранный модуль

Визуальная search/filter/profile панель в нижней части `HomePageWidget` и её
типизированная связь с владельцем map/search state.

## Почему он выбран

После типизации marker и search result contracts Home всё ещё содержал более
500 строк presentation-разметки панели. В одном generated widget были
смешаны:

- геометрия карты и панели;
- debounce поля поиска;
- список результатов;
- кнопки filter/profile;
- query building и controller state;
- открытие parking details и filter dialogs.

Это затрудняло тестирование и расширение Home. Безопасный этап — вынести только
UI и debounce, оставив query, navigation, dialogs, Supabase и state ownership
на экране.

## Текущее поведение до этапа

- панель выровнена по нижнему краю и ограничена
  `searchPanelMaxHeight`;
- без клавиатуры высота не больше 80% экрана, с клавиатурой — видимая высота
  минус safe-area и небольшой верхний gutter, чтобы результаты не прилипали к
  status bar;
- drag по handle или result очищает поиск;
- результаты показываются только при `isSearching`;
- nullable address отображается как `No address`;
- search debounce равен 500 ms;
- clear очищает text и controller state;
- filter сначала очищает поиск, затем открывает `FilterWidget`;
- активный filter меняет цвет и после закрытия перезагружает markers;
- profile button открывает существующий route;
- tap результата перемещает карту и открывает parking details.

## Предлагаемая и реализованная структура

```text
HomePageWidget (composition/state owner)
  ├─ builds MapParkingQuery
  ├─ owns ParkingMapController
  ├─ opens FilterWidget / ParkingsDetailsWidget
  ├─ performs route navigation
  └─ passes typed values and callbacks
                    │
                    v
HomeMapSearchPanel (presentation only)
  ├─ geometry and styles
  ├─ 500 ms debounce
  ├─ List<MapSearchResultItem>
  ├─ clear/filter/profile controls
  └─ typed callbacks
```

Component не импортирует Supabase repository, controller, `FFAppState`,
parking details, filter dialog или router.

## Typed component API

- `double maxHeight`;
- `TextEditingController textController`;
- `FocusNode focusNode`;
- `bool isSearching`;
- `List<MapSearchResultItem> results`;
- `bool isFilterApplied`;
- `Future<void> Function(String) onQueryChanged`;
- `VoidCallback onClear`;
- `Future<void> Function(MapSearchResultItem) onResultSelected`;
- `Future<void> Function() onFilterSelected`;
- `VoidCallback onProfileSelected`;
- optional typed form validator.

## Сохранённое поведение

- размеры, paddings, borders, colors и icons панели сохранены;
- result address font size `17`, divider thickness `2` сохранены;
- field height `40`, filter button `40x40`, profile `36x36` сохранены;
- debounce остаётся 500 ms;
- lower-case normalization и query zoom `20.0` остаются в Home;
- result selection sequence и parking ID не меняются;
- filter result reload semantics не меняются;
- `FFAppState` остаётся source of truth для filter state;
- Supabase/RPC, reverse geocoding, marker renderer и deep links не меняются;
- production write-команды не выполнялись.

## Все связанные файлы

Presentation:

- `lib/features/map/presentation/home_map_search_panel.dart`;
- `lib/features/map/presentation/map_search_result_item.dart`;
- `lib/map/home_page/search_panel_layout.dart`;
- `lib/map/home_page/home_page_widget.dart`;
- `lib/map/home_page/home_page_model.dart`.

Business/application dependencies, без изменений:

- `lib/features/map/application/parking_map_controller.dart`;
- `lib/features/map/domain/map_parking_query.dart`;
- `lib/features/map/domain/parking_map_repository.dart`;
- `lib/features/map/data/supabase_parking_map_repository.dart`.

Existing flows, без изменений:

- `lib/filter/filter/filter_widget.dart`;
- `lib/parkings_details/parkings_details/parkings_details_widget.dart`;
- `lib/profile/profile/profile_widget.dart` через route index;
- `lib/custom_code/widgets/bottom_spacer.dart`.

Tests:

- `test/features/map/presentation/home_map_search_panel_test.dart`;
- `test/features/map/presentation/home_map_read_boundary_test.dart`;
- `test/map/home_page/search_panel_layout_test.dart`;
- остальные map tests.

## Supabase-зависимости

- search использует существующий `public.get_filtered_parkings`;
- query продолжает содержать те же 18 parameters;
- repository/controller/parser не изменяются;
- schema, SQL, RLS, grants и migrations не изменяются;
- новый panel component не знает о Supabase.

## FlutterFlow-зависимости

В presentation component сохранены:

- `FlutterFlowTheme`;
- `FFLocalizations` и существующий key `601bzdk7`;
- `FFIcons.kicnSearch` и `FFIcons.ksetting4`;
- `BottomSpacer` для system bottom inset;
- generated asset `assets/images/menu.svg`;
- Google Fonts и EasyDebounce.

В Home сохранены:

- `HomePageModel`, `createModel` и `safeSetState`;
- `FFAppState` filter values;
- generated navigation/dialog lifecycle;
- field controller/focus ownership и disposal.

## Файлы, которые создаются

- `lib/features/map/presentation/home_map_search_panel.dart`;
- `test/features/map/presentation/home_map_search_panel_test.dart`;
- `docs/home_map_search_panel_extraction.md`.

## Файлы, которые изменяются

- `lib/map/home_page/home_page_widget.dart`;
- `test/features/map/presentation/home_map_read_boundary_test.dart`;
- map architecture/integration documents.

## Файлы, которые нельзя менять

- `lib/features/map/data/**`;
- `lib/features/map/domain/**`;
- `lib/backend/api_requests/api_calls.dart`;
- `lib/filter/filter/filter_widget.dart`;
- parking details/create/auth/referral/subscription/sharing flows;
- `android/**`, `ios/**`, `pubspec.yaml`;
- `supabase/migrations/**` и production backend contracts.

## Последовательность изменений

1. Зафиксировать complete panel layout/actions.
2. Описать typed callback API.
3. Перенести layout, styles, debounce и controls.
4. Оставить query/dialog/navigation handlers в Home.
5. Подключить component через typed results и callbacks.
6. Удалить presentation imports/markup из Home.
7. Добавить widget tests и source boundary checks.
8. Выполнить format, analyze, regression и platform builds.

## Необходимые тесты

- typed results и `No address` fallback отображаются;
- tap сообщает точный `MapSearchResultItem`;
- callback не вызывается раньше 500 ms;
- clear очищает controller и сообщает owner;
- filter/profile actions передаются owner-у;
- Home содержит component и typed handlers;
- Home больше не содержит EasyDebounce/list presentation markup;
- max-height characterization продолжает проходить;
- полный regression suite.

Результаты scoped-проверки:

- component + Home boundary tests: 5 passed;
- полный map + layout suite: 40 passed;
- scoped analyzer: 0 errors, 0 warnings и 18 существующих generated info.

Результаты полной проверки:

- полный regression suite: 168 passed;
- полный analyzer: 0 errors, 686 существующих warnings и 1245 info;
- новых warnings не добавилось, info уменьшились на 44 после сокращения
  generated Home markup;
- Android debug APK: built;
- iOS simulator debug app: built;
- автоматические Flutter platform upgrades исключены из рабочего дерева.

## Команды проверки

```bash
dart format --output=none --set-exit-if-changed lib/features/map/presentation lib/map/home_page test/features/map test/map/home_page
flutter analyze --no-fatal-infos --no-fatal-warnings lib/features/map/presentation lib/map/home_page test/features/map test/map/home_page
flutter test test/features/map test/map/home_page
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --debug
flutter build ios --simulator --debug --no-codesign
git diff --check
git status --short
```

## Ручной чек-лист

- сравнить высоту/отступы панели с предыдущим APK;
- открыть и закрыть клавиатуру;
- проверить handle и вертикальный drag;
- ввести запрос и подтвердить 500 ms debounce визуально;
- проверить несколько результатов и длинный адрес;
- проверить `No address` fallback;
- очистить строку suffix-кнопкой;
- выбрать результат и открыть правильную парковку;
- открыть filter, применить и отменить;
- проверить цвет active filter icon;
- открыть profile;
- проверить marker/cluster tap, long press и deep links.

## Условия отката

Откатить один коммит этапа, если:

- изменились размеры/отступы или снова появился overflow;
- клавиатура перекрывает результаты;
- debounce, clear, filter или profile action изменились;
- result selection открывает неверную парковку;
- filter перестал обновлять markers;
- появился новый analyzer error/warning;
- regression suite или platform build не проходит.

Backend rollback не требуется.

## Следующий отдельный этап

После real-device visual smoke test можно выделить map floating controls
(add parking/current location) либо типизировать viewport callbacks
`CustomGoogleMap`. До проверки панели следующий UI extraction начинать не
следует.

## Предлагаемое сообщение Git-коммита

```text
refactor(map): extract typed search panel
```
