# Repository boundary создания парковки

Дата: 2026-07-24

Ветка: `agent/fix-map-panel-gestures`

## Выбранный модуль

Второй service-layer срез для parking submission: repository boundary между
typed draft и generated Supabase/Storage wrappers.

## Новая структура

```text
future CreateParkingWidget adapter
        |
        v
ParkingSubmissionDraft
        |
        v
ParkingSubmissionRepository
        |
        v
SupabaseParkingSubmissionRepository
        |
        v
ParkingSubmissionDataSource
  ├─ ParkingsTable.insert
  ├─ uploadSupabaseStorageFiles
  └─ ParkingPhotosTable.insert
```

`ParkingSubmissionDataSource`, current user provider и clock injectable. Unit
tests используют fake data source и не выполняют production writes.

## Зафиксированное поведение

- parking row создаётся до загрузки фото;
- parking payload сохраняет текущие поля, `created_by`, serialized
  `created_at` и status `pending`;
- фото загружаются в bucket `parking_content`;
- photo path остаётся `parkings/<parkingId>/<index>`;
- после каждого upload вставляется row `parking_photos` с `url`, `parking_id`
  и `user_id`;
- пустой authenticated user, invalid draft и пустые photo bytes отклоняются до
  первого write call;
- RLS/PostgREST `42501` до создания parking row мапится в redacted
  `forbidden`;
- failure после созданной parking row мапится в `partialFailure`, потому что
  Storage/DB state уже мог стать частичным.

## Что не изменено

- production `CreateParkingWidget` пока продолжает legacy generated code;
- Supabase schema, RLS, Storage policies, bucket names и backend contracts не
  менялись;
- компенсационное удаление orphan Storage objects не добавлено, это отдельный
  backend/client hardening этап;
- production write-команды во время проверки не выполнялись.

## Связанные файлы

- `lib/features/parking_submission/domain/parking_submission_repository.dart`;
- `lib/features/parking_submission/data/supabase_parking_submission_repository.dart`;
- `test/features/parking_submission/data/supabase_parking_submission_repository_test.dart`;
- `docs/parking_submission_draft_contract.md`.

## Проверки этапа

```bash
dart format lib/features/parking_submission test/features/parking_submission
flutter analyze --no-fatal-infos --no-fatal-warnings lib/features/parking_submission test/features/parking_submission
flutter test test/features/parking_submission
```

## Следующий этап

`create_parking2/CreateParkingWidget` подключён следующим отдельным этапом
через маленький UI adapter, с сохранением dialog/navigation и старой геометрии.
Старый `create_parking/add_parking` не тронут в том же коммите.
