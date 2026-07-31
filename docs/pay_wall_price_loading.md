# Pay wall price loading

Дата этапа: 30 July 2026.

## Контекст

PayWall получает smart subscription prices через RevenueCat после открытия
экрана. Пока `_model.smartPrices` ещё не заполнен, monthly/yearly price labels
раньше не отображались вообще, поэтому пользователь видел пустое место вместо
цен.

## Решение

- Monthly и yearly price labels теперь всегда занимают место в карточках плана.
- До завершения `getSmartSubscriptionPrices()` отображается компактный
  `CircularProgressIndicator`.
- После загрузки спиннер заменяется фактической ценой без изменения RevenueCat
  логики покупки и без изменения тарифных значений.

## Границы этапа

Этап не меняет RevenueCat configuration, продукты, referral eligibility,
Supabase-контракты или purchase flow. Это только UI loading state на PayWall.
