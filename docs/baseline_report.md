# Baseline report

Дата диагностики: 2026-07-21. Рабочая копия: `/Users/a1/Projects/j_s_truck_park`.

## Ограничения проверки

- Production-код, `pubspec.yaml`, `android/`, `ios/` и Supabase не изменялись.
- Так как `pubspec.lock` отсутствует, команды, создающие служебные файлы, выполнялись на изолированной копии `/tmp/js_truck_park_diag.1T57BJ`. Исходники и платформенные файлы копии до запуска совпадали с рабочим проектом.
- В каталоге проекта есть `.gitignore`, но нет `.git/`. Поэтому нельзя установить историю ошибок, получить diff или подтвердить, какие предупреждения уже были в конкретном коммите FlutterFlow-экспорта.
- Каталогов `supabase/` и `docs/` до этой сессии не было. SQL, migrations, RLS, triggers и Edge Functions локально недоступны.
- Значения ключей и токенов, найденные в исходниках, намеренно не воспроизводятся в отчёте.

## Инструменты

| Инструмент | Версия |
|---|---|
| Flutter | 3.44.1 stable, revision `924134a44c`, 2026-05-29 |
| Dart | 3.12.1 |
| DevTools | 2.57.0 |

`.metadata` указывает revision Flutter 2.0.3 от 2021 года, но это значение явно устарело: `pubspec.yaml` требует Dart `>=3.0.0`, а Android-конфигурация использует современные AGP/Kotlin/SDK. Использовать `.metadata` как SDK pin нельзя.

## Результаты команд

| Команда | Результат | Статус |
|---|---|---|
| `flutter --version` | Flutter 3.44.1, Dart 3.12.1 | успешно |
| `flutter pub get` | разрешено 184 зависимости; `pubspec.lock` создан только во временной копии; 100 пакетов имеют более новые, несовместимые с текущими constraints версии | успешно |
| `dart format --output=none --set-exit-if-changed lib test` | 165 файлов, 0 изменений | успешно |
| `flutter analyze` | 2307 замечаний: 849 warning, 1458 info, 0 analyzer errors | неуспешно из-за замечаний |
| `flutter test` | единственный тест не скомпилировался | блокировано зависимостями |
| `flutter build apk --debug` | `assembleDebug` завершился ошибкой компиляции Dart | блокировано зависимостями |
| `flutter build ios --no-codesign` | CocoaPods и Xcode запускались, но сборка остановлена требованием Development Team / Provisioning Profile | блокировано конфигурацией подписи |

## Блокирующие проблемы

### B1. Flutter 3.44.1 несовместим с двумя закреплёнными пакетами

Ошибки теста и Android-сборки:

- `font_awesome_flutter 10.7.0` наследует `IconData`, который в Flutter 3.44 стал `final`;
- `page_transition 2.1.0` использует старое расположение/экспорт `CupertinoPageTransitionsBuilder`, недоступное в Flutter 3.44.

Классификация: несовместимость SDK и зависимостей, а не подтверждённая ошибка production-кода. Вероятнее всего появилась при запуске экспортированного проекта на более новом Flutter. Исторически подтвердить это нельзя из-за отсутствия Git metadata и SDK pin.

Предпочтительное отдельное исправление для масштабируемого приложения — forward-compatible infrastructure commit на Flutter 3.44.1:

1. обновить `page_transition` до 2.2.2;
2. заменить единственный fallback `FaIcon(widget.iconData)` на стандартный `Icon(widget.iconData)` и удалить Font Awesome import/dependency;
3. создать `pubspec.lock`.

Статический поиск подтвердил: иных imports `font_awesome_flutter` и callers `FFButtonWidget(iconData: ...)` в `lib/` нет. Диагностический эквивалент во временной копии успешно собрал debug APK на Flutter 3.44.1. Простое обновление `font_awesome_flutter` до 11.0.0 без правки wrapper недостаточно: новый `FaIcon` ожидает `FaIconData`, а generated API хранит обычный `IconData`.

Альтернатива без production-кода — зафиксировать Flutter 3.41.9. В локальных исходниках этого SDK подтверждено, что `IconData` ещё не `final`, а `CupertinoPageTransitionsBuilder` остаётся доступен из Material. Этот путь откладывает совместимость и требует отдельного SDK/CI pin, поэтому рассматривается как rollback/fallback, а не целевое решение.

### B2. iOS signing

`flutter build ios --no-codesign` остановлен конфигурацией Xcode: для bundle id `com.mycompany.jstrackpark` не выбран Development Team / provisioning profile. Классификация: окружение/платформенная конфигурация. Безопасное исправление отдельно: настроить локальную команду сборки simulator либо signing для реального target; production-код не нужен.

## Анализатор: основные категории

| Правило | Количество | Оценка |
|---|---:|---|
| `prefer_const_constructors` | 1083 | неблокирующий generated-style debt |
| `unused_import` | 585 | неблокирующий generated-style debt |
| `unnecessary_non_null_assertion` | 197 | риск null-safety, проверять по feature |
| `use_build_context_synchronously` | 68 | риск async-навигации/диалогов |
| `unnecessary_import` | 61 | неблокирующий |
| `unnecessary_null_comparison` | 41 | возможная мёртвая/ошибочная ветка |
| `type_literal_in_constant_pattern` | 36 | совместимость/стиль |
| `non_constant_identifier_names` | 31 | generated naming |
| `avoid_print` | 23 | диагностика/логирование |
| `deprecated_member_use` | 13 | будущая совместимость |

Другие значимые единичные/малые категории: `dead_code`, `unused_element`, `unused_field`, `override_on_non_overriding_member`, `invalid_null_aware_operator`. Массово исправлять их нельзя: warning baseline следует снижать только в файлах текущей feature.

## Прочие предупреждения окружения

- Gradle 8.12.0 и Android Gradle Plugin 8.9.1 пока работают, но Flutter предупреждает о будущем прекращении поддержки; предлагаемые минимумы — Gradle 8.14 и AGP 8.11.1.
- Проект и несколько plugins применяют Kotlin Gradle Plugin; будущий Flutter потребует Built-in Kotlin.
- `app_links`, `sqflite`, `sign_in_with_apple`, `share_plus`, `google_maps_flutter_ios`, `device_info_plus` пока не поддерживают Swift Package Manager в используемых версиях.
- iOS сообщает о будущей обязательности UIScene lifecycle.
- В конфигурационных Dart-файлах находятся publishable Supabase credentials, Google Maps key, Chottu key и RevenueCat keys. Значения не приведены здесь; перенос конфигурации — отдельная security/configuration feature, не часть пилота.

## Тесты

Файл `test/widget_test.dart` существует, но содержит только `pumpWidget(MyApp())` с названием шаблонного counter smoke test. Он не инициализирует обязательные сервисы и не проверяет поведение. До compatibility fix тест не компилируется из-за B1. После диагностического fix во временной копии он компилируется, но падает сначала на неинициализированном `FFLocalizations`, а после его инициализации — на неинициализированном Supabase. Это дефект test harness, не доказанный дефект runtime `main()`, где обе инициализации выполняются до `runApp`.

## Команды воспроизведения

После выбора совместимого SDK выполнить из корня проекта:

```bash
flutter --version
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --no-codesign
```

Для iOS без signing предпочтительно дополнительно проверить simulator:

```bash
flutter build ios --simulator
```

## Вывод baseline

Проект на установленном Flutter 3.44.1 не собирается. Первичный блокер Android/test — совместимость SDK с закреплёнными FlutterFlow-зависимостями; iOS дополнительно блокирует signing. Формат исходников чистый, analyzer errors отсутствуют, но warning baseline очень высокий. До первого production-рефакторинга нужен отдельный зелёный baseline на зафиксированном SDK.
