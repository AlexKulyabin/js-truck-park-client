# Контракт draft для создания парковки

Дата: 2026-07-24

Ветка: `agent/fix-map-panel-gestures`

## Выбранный модуль

Первый service-layer срез для parking submission: typed draft, service flags,
photo metadata и validation issues перед любыми Supabase/Storage writes.

## Что зафиксировано

- capacity сохраняет legacy parsing через `int.tryParse`;
- `address_lower` повторяет текущую lowercase fallback-семантику;
- nullable checkbox values нормализуются в безопасные `false`;
- координаты и address описаны как typed поля draft;
- фото знает существующий Storage path contract:
  `parkings/<parkingId>/<index>`;
- validation issues фиксируют пустой/legacy `null` address и невозможные
  координаты до write-boundary.

## Что не изменено

- production `CreateParkingWidget` пока не подключён к draft;
- `ParkingsTable`, `ParkingPhotosTable` и `uploadSupabaseStorageFiles` не
  вызывались в тестах;
- Supabase schema, RLS, Storage policies, bucket names и status values не
  менялись;
- оба legacy create flows остаются функционально прежними.

## Связанные файлы

- `lib/features/parking_submission/domain/parking_submission_draft.dart`;
- `test/features/parking_submission/domain/parking_submission_draft_test.dart`;
- `lib/create_parking2/create_parking/create_parking_widget.dart`;
- `lib/create_parking/add_parking/add_parking_widget.dart`.

## Проверки этапа

```bash
dart format lib/features/parking_submission test/features/parking_submission
flutter test test/features/parking_submission
```

## Следующий этап

Repository/use-case boundary добавлен следующим отдельным этапом:
`SupabaseParkingSubmissionRepository` собирает текущий insert payload, загружает
фото в `parking_content` по existing path convention и вставляет `parking_photos`
rows через injectable data source. Production write UI подключать только
следующим отдельным коммитом после тестов.
