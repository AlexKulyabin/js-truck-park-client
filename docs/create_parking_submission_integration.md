# Интеграция submission service в CreateParking

Дата: 2026-07-24

Ветка: `agent/fix-map-panel-gestures`

## Выбранный модуль

Основной новый экран создания парковки:
`lib/create_parking2/create_parking/create_parking_widget.dart`.

## Что изменено

- `CreateParkingWidget` получил optional `ParkingSubmissionRepository` для
  тестов и будущей composition boundary;
- submission state вынесен в `ParkingSubmissionController`: `idle`,
  `submitting`, `success`, `failure`;
- повторный submit во время активной отправки игнорируется controller-ом, а
  кнопка `Add` временно disabled;
- typed failures больше не обрабатываются напрямую в widget и остаются в
  application state через `ParkingSubmissionFailureKind`;
- submit button теперь собирает `ParkingSubmissionDraft` из тех же legacy
  sources: capacity field, checkbox values, `FFAppState.tempAddress/tempLat/tempLng`
  и local uploaded photos;
- прямые вызовы `ParkingsTable().insert`, `ParkingPhotosTable().insert` и
  `uploadSupabaseStorageFiles` удалены из widget;
- successful path по-прежнему открывает `SubmittedModerationWidget`;
- generated visual layout, route name/path, photo picker, form fields и dialogs
  не менялись.

## Что осталось без изменений

- старый parallel flow `lib/create_parking/add_parking/add_parking_widget.dart`
  не тронут;
- Supabase schema/RLS/Storage policies/backend contracts не менялись;
- compensation cleanup для partial photo failures не добавлен;
- видимое локализованное failure-сообщение не добавлено в этом refactor-only
  этапе, чтобы не менять UX вместе с переносом state-management;
- production write-команды во время проверки не выполнялись.

## Связанные файлы

- `lib/create_parking2/create_parking/create_parking_widget.dart`;
- `lib/create_parking2/create_parking/create_parking_model.dart`;
- `lib/features/parking_submission/application/parking_submission_controller.dart`;
- `lib/features/parking_submission/domain/parking_submission_draft.dart`;
- `lib/features/parking_submission/domain/parking_submission_repository.dart`;
- `lib/features/parking_submission/data/supabase_parking_submission_repository.dart`;
- `test/features/parking_submission/application/parking_submission_controller_test.dart`;
- `test/features/parking_submission/presentation/create_parking_widget_boundary_test.dart`.

## Проверки этапа

```bash
dart format lib/create_parking2/create_parking lib/features/parking_submission test/features/parking_submission
flutter analyze --no-fatal-infos --no-fatal-warnings lib/create_parking2/create_parking lib/features/parking_submission test/features/parking_submission
flutter test test/features/parking_submission
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

## Следующий этап

Добавить безопасное локализованное failure-сообщение для
`ParkingSubmissionFailureKind` или отдельно подтвердить usage старого
`create_parking/add_parking` перед миграцией/удалением legacy flow.
