# План пилотного рефакторинга

## Выбранный модуль

`Language` — экран выбора языка (`/language`).

## Почему он выбран

- один экран и пустой `LanguageModel`;
- нет Supabase, Auth, Storage, RPC, Realtime, геолокации, карты, подписки и writes;
- не является центральной навигацией и не участвует в splash/auth redirect;
- route name/path и вход/выход можно сохранить без изменения router;
- поведение сводится к двум callback и визуально проверяется;
- нет найденного UI-caller: экран зарегистрирован в router, но `LanguageWidget` используется только `nav.dart`, `index.dart` и собственным model. Это уменьшает blast radius;
- откат возможен одним feature-коммитом;
- пилот проверяет рабочий шаблон feature-first + compatibility shim, не заставляя заранее проектировать repository/domain.

Он безопаснее favorites/profile/settings-подобных кандидатов: те уже зависят от current user, RLS, Storage, delete-account/referral или глобального guest/premium state.

## Текущее поведение

- Route constants: `routeName = 'Language'`, `routePath = '/language'`.
- Экран без AppBar/back button, с primary background и centered vertical column.
- Две full-width кнопки высотой 40, gap 16, radius 8, primary color, white Roboto titleSmall.
- Tap вне controls снимает focus.
- Tap `En` вызывает `setAppLanguage(context, 'en')`; tap `Ru` — `'ru'`.
- `setAppLanguage` вызывает `MyApp.of(context).setLocale`; `MyApp` меняет locale и `FFLocalizations.storeLocale` сохраняет его в SharedPreferences.
- Экран остаётся открыт; отдельной loading/error state нет.
- В generated translations `En`/`Ru` заполнены только для locale `en`; для `ru` обе строки пустые. Это выглядит как дефект, но пилот обязан его сохранить и вынести исправление переводов в отдельное функциональное задание.
- `LanguageModel` не содержит state/controllers и нужен только для generated lifecycle.

## Все связанные файлы

### Прямые

- `lib/language/language_widget.dart` — текущий UI и route constants.
- `lib/language/language_model.dart` — пустой `FlutterFlowModel`.
- `lib/index.dart` — export `LanguageWidget`.
- `lib/flutter_flow/nav/nav.dart` — route registration.
- `lib/main.dart` — owner locale, `setLocale`, `MaterialApp.router` supported locales/delegates.
- `lib/flutter_flow/flutter_flow_util.dart` — `setAppLanguage`, `divide`, exports localization/navigation/model.
- `lib/flutter_flow/internationalization.dart` — translations, delegate, locale persistence.
- `lib/flutter_flow/flutter_flow_theme.dart` — background/color/text style.
- `lib/flutter_flow/flutter_flow_widgets.dart` — buttons/loading behavior.
- `pubspec.yaml` — Flutter, Provider, Google Fonts, SharedPreferences и текущие UI dependencies.
- `test/widget_test.dart` — текущий некорректный template smoke test.

### Платформенные/косвенные

- `ios/Runner/en.lproj/InfoPlist.strings`, `ios/Runner/ru.lproj/InfoPlist.strings` — platform strings, но не UI translation map.
- `android/`, прочие `ios/`, `web/` — отдельной language screen wiring не найдено.

## Все Supabase-зависимости пилота

Нет. Экран не должен и после пилота импортировать `backend/supabase`, Auth, table rows, RPC, Storage или Supabase client. Widget tests должны быть hermetic и подтверждать отсутствие network/Supabase initialization.

Косвенно полный `MyApp` и router зависят от Supabase Auth, поэтому pilot tests не должны pump-ить production `MyApp` без dependency injection. Именно из-за этого текущий template smoke test некорректен.

## Все FlutterFlow-зависимости пилота

Текущий экран использует:

- `FlutterFlowModel`, `createModel`, `safeSetState` — пустой lifecycle;
- `FlutterFlowTheme` и text-style `.override`;
- `FFButtonWidget`/`FFButtonOptions`;
- `FFLocalizations.getText` с keys `xjjh7yvz`, `kcik5mmw`;
- `setAppLanguage`;
- `Iterable.divide`;
- route contract через generated nav/index;
- лишние imports `dart:ui`, Provider и model boilerplate.

На пилоте удалить только model/lifecycle dependency из активного screen. Theme, button, localization, route и util оставить: их одновременная замена создала бы UI/functional change и большой diff.

## Предлагаемая новая структура

Пилотный минимальный вариант:

```text
lib/features/language/
  presentation/
    language_page.dart

lib/language/
  language_widget.dart       # compatibility export
  language_model.dart        # пока оставить как legacy, не импортировать

test/features/language/presentation/
  language_page_test.dart
```

`LanguageWidget` в новом файле становится `StatelessWidget`, сохраняет имя, constructor, route constants и точное дерево UI. Добавляется необязательный test seam `ValueChanged<String>? onLanguageSelected`; production default вызывает существующий `setAppLanguage`, tests передают fake callback. Новый repository/domain/controller на этом этапе не нужен.

Будущая, не пилотная стадия может добавить `features/language/application/language_controller.dart` и `core/localization/locale_store.dart`, затем перейти на `gen_l10n`. Она требует отдельного design/behavior задания.

## Prerequisite: зелёная toolchain baseline

До feature-коммита нужен отдельный infrastructure-коммит. Диагностика во временной копии доказала forward-compatible вариант на Flutter 3.44.1:

1. обновить `page_transition` 2.1.0 → 2.2.2;
2. заменить единственный fallback `FaIcon(widget.iconData)` на стандартный `Icon(widget.iconData)` в `FFButtonWidget`;
3. удалить неиспользуемый import/dependency `font_awesome_flutter` — иных imports/callers в `lib/` нет, а `iconData:` ни один `FFButtonWidget` caller не передаёт;
4. создать и commit-ить `pubspec.lock`;
5. заменить template test на безопасный compile smoke, который конструирует `MyApp`, но не pump-ит его без инициализированных Supabase/localization services.

Во временной копии эквивалентное обновление (`page_transition 2.2.2`, совместимый button fallback; там для диагностики был установлен `font_awesome_flutter 11`) успешно собрало debug APK. Это исправление не применено в рабочем проекте.

Альтернатива — pin Flutter 3.41.9, где старые API существуют, но это откладывает совместимость и требует отдельного manager/CI setup. Для масштабируемого продукта предпочтителен forward fix выше, если его полный regression checklist зелёный.

## Файлы, которые будут созданы во второй сессии

Infrastructure commit:

- `pubspec.lock`.

Pilot commit:

- `lib/features/language/presentation/language_page.dart`;
- `test/features/language/presentation/language_page_test.dart`.

## Файлы, которые будут изменены во второй сессии

Infrastructure commit:

- `pubspec.yaml` — удалить `font_awesome_flutter`, обновить только `page_transition`;
- `lib/flutter_flow/flutter_flow_widgets.dart` — удалить Font Awesome import, заменить один fallback на `Icon`;
- `test/widget_test.dart` — превратить invalid pump test в hermetic compile smoke с корректным названием.

Pilot commit:

- `lib/language/language_widget.dart` — заменить implementation на compatibility export нового `LanguageWidget`.

## Файлы, которые нельзя менять в pilot commit

- `lib/main.dart`;
- `lib/index.dart`;
- `lib/flutter_flow/nav/nav.dart` и `serialization_util.dart`;
- `lib/flutter_flow/internationalization.dart`;
- `lib/flutter_flow/flutter_flow_theme.dart`;
- `lib/flutter_flow/flutter_flow_widgets.dart` (его prerequisite fix уже должен быть отдельным commit);
- `lib/language/language_model.dart` — оставить для отдельной cleanup-проверки;
- `lib/app_state.dart`;
- весь `lib/backend/`, `lib/auth/`, `lib/map/`, `lib/filter/` и остальные features;
- `android/`, `ios/`, `web/`;
- Supabase schema/RPC/RLS/Storage contracts;
- asset/fonts и translation strings.

## Последовательность изменений

### Этап 0 — отдельный infrastructure commit

1. Убедиться, что проект находится в Git worktree; текущая рабочая папка `.git/` не содержит.
2. Создать baseline branch/commit до production edits.
3. Применить три минимальные compatibility-правки и создать lockfile.
4. Исправить только invalid template test harness.
5. Выполнить format/analyze/test/APK и route/button smoke checks.
6. Commit infrastructure; не добавлять language changes.

### Этап 1 — characterization

1. Зафиксировать screenshot/размеры старого screen для light/dark и en/ru.
2. Зафиксировать route constants, focus behavior, callbacks и locale persistence.
3. Написать tests, которые сначала проходят против выбранного behavior contract.

### Этап 2 — feature boundary

1. Создать `language_page.dart` с тем же `LanguageWidget` API.
2. Перенести UI без форматирования соседних файлов.
3. Убрать активное использование `LanguageModel/createModel/safeSetState/Provider/dart:ui`.
4. Добавить optional callback seam; default строго сохраняет `setAppLanguage`.
5. Превратить legacy widget file в export, чтобы `index.dart` и router не менялись.

### Этап 3 — verification

1. Проверить diff: никаких строк Supabase/routes/translations/theme.
2. Запустить tests и full commands.
3. Выполнить manual checklist.
4. Commit только language pilot.

## Необходимые тесты

- `LanguageWidget.routeName == 'Language'`, `routePath == '/language'`.
- В `en` отображаются ровно две кнопки `En` и `Ru`.
- Tap `En` вызывает callback ровно один раз с `en`.
- Tap `Ru` вызывает callback ровно один раз с `ru`.
- Default callback integration сохраняет locale после корректной test initialization либо проверяется отдельным focused integration test.
- UI contract: две full-width buttons, height 40, gap 16, radius 8; light/dark golden или screenshot comparison.
- Tap background unfocuses active focus.
- `ru` сохраняет текущий empty-label behavior; отдельный skipped/known-issue test или явная assertion не даёт случайно смешать bug fix с refactor.
- Новый page не импортирует Supabase/Auth/Storage и не вызывает network.
- Новый page не содержит `FlutterFlowModel`, `createModel`, `safeSetState`, `FFAppState`.
- Compatibility export позволяет старому `lib/index.dart` и router скомпилироваться без изменений.
- Full compile smoke для `MyApp` не требует production network.

## Команды проверки

```bash
flutter --version
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter test test/features/language/presentation/language_page_test.dart
flutter build apk --debug
flutter build ios --simulator
rg -n "FlutterFlowModel|createModel|safeSetState|FFAppState|SupaFlow|Supabase" lib/features/language test/features/language
rg -n "routeName = 'Language'|routePath = '/language'" lib/features/language lib/language lib/flutter_flow/nav/nav.dart
```

Так как global analyzer baseline содержит 2307 замечаний, критерий пилота: 0 errors и 0 новых warning в изменённых/новых файлах, а общее число не увеличивается. Полное обнуление analyzer — не scope пилота.

## Ручной чек-лист

- Запустить `/language` напрямую (`flutter run --route=/language` или эквивалент на test device).
- Сравнить старый/новый screenshot в light и dark.
- Проверить отсутствие AppBar/back button и прежнее системное back behavior.
- Проверить centered layout, размеры кнопок, gap, typography/colors.
- Нажать пустой фон при открытой клавиатуре/focus test field host — focus снимается.
- На locale en нажать En и Ru; приложение не закрывает screen и не меняет route.
- Перезапустить приложение и подтвердить сохранение выбранного locale.
- На locale ru подтвердить текущее поведение пустых labels; не исправлять в этом commit.
- Проверить, что Home/Auth/Map/Profile открываются как до prerequisite dependency update.
- Проверить button icon/widget callers после замены Font Awesome fallback; фактических `iconData:` callers быть не должно.
- Убедиться по network inspector/logs, что открытие и taps Language не вызывают Supabase/HTTP.
- Проверить отсутствие tokens/keys/phone/locale-sensitive data в новых logs.

## Условия отката

Немедленно откатить pilot commit, если:

- изменились route name/path, back behavior или визуальная геометрия;
- callback вызывается не один раз или locale не сохраняется после restart;
- появился Supabase/network вызов;
- добавились analyzer errors/warnings в pilot files;
- full tests/APK перестали проходить относительно prerequisite baseline;
- compatibility export ломает импорт `LanguageWidget`.

Откат: `git revert <pilot-commit>`; infrastructure commit оставить. Если regression вызван `page_transition`/button compatibility, отдельно `git revert <infrastructure-commit>` и вернуться к Flutter 3.41.9 diagnostic path. Не откатывать оба commits одним смешанным ручным edit.

## Предлагаемые сообщения Git-коммитов

Infrastructure prerequisite:

```text
build: restore Flutter 3.44 compatibility
```

Пилотный рефакторинг:

```text
refactor(language): move language screen behind feature boundary
```

## Точный scope следующей сессии

Два последовательных, отдельно коммитируемых этапа:

1. восстановить зелёный build/test baseline на Flutter 3.44.1 только минимальным forward compatibility diff;
2. только если этап 1 зелёный, выполнить Language pilot по указанным четырём production/test paths, без Supabase, router, locale engine, theme и UI changes.

Если Git worktree или зелёный baseline не восстановлены, второй этап не начинать: документировать blocker вместо рефакторинга вслепую.
