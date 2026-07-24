# Read-срез отзывов и жалоб профиля

Дата: 2026-07-24

Ветка: `agent/fix-map-panel-gestures`

## Выбранный модуль

Экран `ReviewsAndComplaints` (`/reviewsAndComplaints`) из профиля: список своих
отзывов и список своих жалоб.

## Scope

- сохранены route name/path и вход из существующей навигации;
- Supabase schema, RLS, grants, Storage, RPC и production data не менялись;
- write-экраны создания отзыва и жалобы не трогались;
- старые component widgets/cards оставлены для rollback/export parity;
- экран теперь читает данные через typed repository/controller boundary.

## Supabase-контракты

`public.view_reviews_with_users`:

- `SELECT`;
- обязательный фильтр `user_id = currentUserUid`;
- сортировка `created_at`;
- пустой user ID возвращает пустой список без transport query;
- repository отклоняет cross-user row и malformed `review_photos`.

`public.view_reports_detailed`:

- `SELECT`;
- обязательный фильтр `reporter_id = currentUserUid`;
- сортировка `report_date`;
- пустой user ID возвращает пустой список без transport query;
- repository отклоняет cross-user row и malformed `parking_photos`.

## Новая структура

```text
reviews route wrapper
  -> UserReviewsController
    -> UserReviewsRepository
      -> SupabaseUserReviewsRepository
        -> generated view tables
  -> ReviewsAndComplaintsView
    -> UserReviewCard / UserComplaintCard
```

## Поведение

- стартовая вкладка Reviews сохранена;
- segmented control, header, back button, spinner, empty states, labels and
  list spacing сохранены;
- failure выглядит как прежний spinner, но tap запускает retry;
- review/complaint cards получают typed summaries, а не generated rows;
- complaint photo navigation сохраняет прежние query parameters
  `photoPath`, `index`, `address`, `photoCount`, `photoRef`, `data`;
- null comment больше не приводит к UI crash, отображаясь как отсутствие текста.

## Проверка этапа

Обязательные команды:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze lib/features/reviews lib/reviews/reviews_and_complaints test/features/reviews
flutter test test/features/reviews
flutter test
flutter analyze --no-fatal-infos --no-fatal-warnings
git diff --check
```

## Rollback

Откатить этот коммит, если route contract изменился, вкладки перестали
переключаться, owner filter не передаётся в оба view-запроса, complaint photo
открывается с другими query parameters, либо экран начинает выполнять write/API
операции.
