# План коротких ссылок на парковки и фотографии

Дата: 2026-07-24

Статус: отложено владельцем продукта 2026-07-24; вернуться после основных
этапов архитектурного рефакторинга. До отдельного подтверждения не менять и не
разворачивать Hosting, outbound URLs, App Links или Universal Links.

## Проблема

Текущая ссылка фотографии включает:

- путь `deeplink.html`;
- route name;
- полный percent-encoded публичный Storage URL;
- полный адрес;
- дату.

Поэтому одна фотография превращается в очень длинную строку в мессенджере.
Также display metadata становится частью URL и может устареть или быть
подменена получателем.

Ссылка парковки короче, но дублирует ID, latitude и longitude. Coordinates
могут устареть и не должны быть источником истины.

## Рекомендуемый контракт

```text
https://js-truck-park.web.app/p/<parking-uuid>
https://js-truck-park.web.app/ph/<photo-uuid>
```

Ссылка содержит только стабильный идентификатор. После открытия hosting/app
получает актуальные разрешённые данные по ID.

Внешний URL-shortener и Chottu для parking/photo не нужны. Chottu пока остаётся
только в существующем referral flow и меняется отдельным заданием.

## Почему это масштабируемее и безопаснее

- длина URL постоянна и не зависит от Storage path/address;
- Storage URL и пользовательский текст не передаются через messenger query;
- metadata берётся из одного backend source of truth;
- UUID сложно перебирать, но authorization всё равно обеспечивает RLS/RPC;
- route можно использовать для Open Graph preview и web fallback;
- provider lock-in отсутствует;
- analytics/expiry можно добавить позже без изменения public URL.

## Требуемые изменения

Backend/read contract:

- включить `parking_photos.id` в bounded public photo read model либо добавить
  отдельный security-invoker view/RPC `get_shared_photo(photo_id)`;
- возвращать только photo URL, safe date, parking ID/address для approved и
  active parking;
- добавить anon/auth/invalid/inactive negative tests;
- не отдавать owner/admin/private columns.

Flutter:

- добавить typed `SharedParkingLink` и `SharedPhotoLink` builders;
- передавать photo UUID в photo viewer;
- outbound share перевести на `/p/<id>` и `/ph/<id>`;
- inbound handler получать metadata по ID;
- сохранить legacy `deeplink.html?...` parser для уже отправленных ссылок;
- не менять referral `?ref=` в этом этапе.

Firebase Hosting:

- добавить rewrites/landing handler для `/p/**` и `/ph/**`;
- сохранить существующий `deeplink.html`;
- настроить Android App Links/iOS Universal Links и web fallback;
- добавить безопасный Open Graph preview без пользовательского raw HTML.

Hosting source/config в текущем Flutter-репозитории не найден. Для реализации
понадобится добавить его в version control либо предоставить отдельный hosting
repository/project deployment workflow. Без hosting rollout новый outbound URL
включать нельзя.

## Безопасная последовательность

1. Characterize legacy parking/photo URLs и cold/warm start.
2. Добавить photo ID в read model без изменения outbound share.
3. Добавить read-only backend lookup и authorization tests.
4. Развернуть hosting routes, сохранив legacy handler.
5. Добавить новый inbound parser и интеграционные tests.
6. Переключить outbound share на короткие URLs.
7. Проверить preview и открытие с приложением/без приложения.
8. Наблюдать legacy/new traffic; старые ссылки не удалять.

## Проверки

- парковка и фото открываются при установленном приложении;
- cold start и already-running app;
- Android/iOS/web fallback;
- invalid/deleted/inactive photo показывает безопасный not-found;
- URL не содержит Storage URL, address, date или user ID;
- старые длинные ссылки продолжают работать;
- referral link и скидка не получают регрессию;
- share text остаётся коротким в Telegram/WhatsApp/Viber/SMS;
- Open Graph не допускает HTML/script injection;
- никакой production write не требуется для открытия ссылки.

## Условия отката

Outbound builder возвращается на legacy URL, если новый hosting route,
App/Universal Link, backend lookup или preview нестабилен. Legacy handler не
удаляется, поэтому уже отправленные ссылки продолжают работать.

## Предлагаемые отдельные коммиты

```text
refactor(sharing): add id-based shared photo contract
feat(sharing): enable canonical short parking links
```
