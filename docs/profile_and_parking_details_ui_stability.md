# Profile and parking details UI stability

Дата этапа: 30 July 2026.

## Контекст

В сборке повторно проявились две FlutterFlow UI-регрессии:

- профиль на время загрузки public profile занимал только высоту спиннера, а
  после загрузки аватара раскрывался до полной карточки и сдвигал кнопки вниз;
- parking details bottom sheet пересоздавал future при переключении вкладок,
  из-за чего sheet моргал loading-состоянием, а вертикальные gestures в
  области handle/photo мешали протягивать sheet через фотографию и могли
  закрывать его свайпом.

## Решение

- Loading-состояние профиля теперь рисует карточку высотой `170.0`, как и
  готовый header.
- Parking details кэширует `parkingDetailsFuture` в модели компонента и не
  пересоздаёт его при обычном переключении вкладок.
- Из handle/photo/no-photo зон удалены vertical drag handlers. Закрытие
  остаётся через явную кнопку закрытия и текущий внешний tap-layer.
- Счётчик фото в tab header больше не запускает отдельный future, так как число
  уже есть в загруженной модели parking details.

## Границы этапа

Этап не меняет Supabase-контракты, Storage, deep links, права записи или данные
парковок. Изменения ограничены UI-стабильностью профиля и parking details
bottom sheet.

## Регрессионная защита

Добавлен source-level тест `profile_and_parking_details_test.dart`, который
ловит повторное появление inline future в parking details, вертикальных drag
handlers в photo/header-зонах и нестабильного loading header в профиле.
