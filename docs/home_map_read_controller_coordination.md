# Координация чтения карты Home

Дата: 2026-07-24

Ветка: `agent/fix-map-panel-gestures`

## Выбранный модуль

Финальный небольшой срез state-management для `HomePage`: координация двух
независимых read-потоков карты, viewport markers и search results.

## Почему выбран этот этап

Нижний `ParkingMapController` уже защищает один поток от stale responses, а
Home после предыдущих этапов всё ещё создавал два таких controller напрямую и
сам проверял их state. Это оставляло orchestration в widget-слое. Новый
`HomeMapReadController` делает один feature-level boundary для Home, не меняя
RPC, фильтры, UI, навигацию или отображаемые модели.

## Реализованная структура

```text
HomePageWidget
  ├─ builds MapParkingQuery
  ├─ owns UI state, dialogs and navigation
  └─ HomeMapReadController
       ├─ ParkingMapController viewport
       └─ ParkingMapController search
            │
            v
       ParkingMapRepository
```

Home получает только актуальный successful список typed `MapParkingPoint`.
Если запрос был сброшен, устарел или завершился ошибкой, controller возвращает
`null`, а widget сохраняет прежнее поведение.

## Сохранённое поведение

- viewport и search остаются независимыми потоками;
- search reset не сбрасывает markers карты;
- stale search response не публикуется в panel;
- старые markers сохраняются во время loading/failure нижнего controller;
- conversion в `MapMarkerItem` и `MapSearchResultItem` остаётся в presentation;
- filter snapshot, query parameters, lower-case search и zoom `20.0` не
  изменены;
- `FilterWidget`, parking details sheet, profile route и long-press create
  flow не изменены;
- Supabase schema/RPC/headers и production writes не затрагивались.

## Связанные файлы

- `lib/features/map/application/home_map_read_controller.dart`;
- `lib/features/map/application/parking_map_controller.dart`;
- `lib/map/home_page/home_page_widget.dart`;
- `test/features/map/application/home_map_read_controller_test.dart`;
- `test/features/map/presentation/home_map_read_boundary_test.dart`.

## Проверки этапа

```bash
dart format lib/features/map/application/home_map_read_controller.dart lib/map/home_page/home_page_widget.dart test/features/map/application/home_map_read_controller_test.dart test/features/map/presentation/home_map_read_boundary_test.dart
flutter test test/features/map/application test/features/map/presentation/home_map_read_boundary_test.dart
```

Результат: 20 map/application/boundary tests passed.

## Следующий этап

После этого map state-management slice можно считать достаточно закрытым для
текущей фазы. Следующий более ценный контур — parking submission service layer:
сначала characterize create-parking write-flow тестами и fake boundaries, затем
вынести draft/validation/submission orchestration без production writes.
