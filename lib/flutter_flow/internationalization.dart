import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '/core/localization/app_locale.dart';
import '/core/localization/locale_store.dart';
import '/core/localization/shared_preferences_locale_store.dart';

class FFLocalizations {
  FFLocalizations(this.locale);

  final Locale locale;

  static FFLocalizations of(BuildContext context) =>
      Localizations.of<FFLocalizations>(context, FFLocalizations)!;

  static List<String> languages() => ['en', 'ru'];

  static late LocaleStore _localeStore;
  static Future<void> initialize({LocaleStore? localeStore}) async =>
      _localeStore = localeStore ?? await SharedPreferencesLocaleStore.create();
  static Future<void> storeLocale(String locale) =>
      _localeStore.writeLanguageCode(locale);
  static Locale? getStoredLocale() =>
      createStoredAppLocale(_localeStore.readLanguageCode());

  String get languageCode => locale.toString();
  String? get languageShortCode =>
      _languagesWithShortCode.contains(locale.toString())
          ? '${locale.toString()}_short'
          : null;
  int get languageIndex => languages().contains(languageCode)
      ? languages().indexOf(languageCode)
      : 0;

  String getText(String key) =>
      (kTranslationsMap[key] ?? {})[locale.toString()] ?? '';

  String getVariableText({
    String? enText = '',
    String? ruText = '',
  }) =>
      [enText, ruText][languageIndex] ?? '';

  static const Set<String> _languagesWithShortCode = {
    'ar',
    'az',
    'ca',
    'cs',
    'da',
    'de',
    'dv',
    'en',
    'es',
    'et',
    'fi',
    'fr',
    'gr',
    'he',
    'hi',
    'hu',
    'it',
    'km',
    'ku',
    'mn',
    'ms',
    'no',
    'pt',
    'ro',
    'ru',
    'rw',
    'sv',
    'th',
    'uk',
    'vi',
  };
}

/// Used if the locale is not supported by GlobalMaterialLocalizations.
class FallbackMaterialLocalizationDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) async =>
      SynchronousFuture<MaterialLocalizations>(
        const DefaultMaterialLocalizations(),
      );

  @override
  bool shouldReload(FallbackMaterialLocalizationDelegate old) => false;
}

/// Used if the locale is not supported by GlobalCupertinoLocalizations.
class FallbackCupertinoLocalizationDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture<CupertinoLocalizations>(
        const DefaultCupertinoLocalizations(),
      );

  @override
  bool shouldReload(FallbackCupertinoLocalizationDelegate old) => false;
}

class FFLocalizationsDelegate extends LocalizationsDelegate<FFLocalizations> {
  const FFLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<FFLocalizations> load(Locale locale) =>
      SynchronousFuture<FFLocalizations>(FFLocalizations(locale));

  @override
  bool shouldReload(FFLocalizationsDelegate old) => false;
}

Locale createLocale(String language) => createAppLocale(language);

bool _isSupportedLocale(Locale locale) {
  final language = locale.toString();
  return FFLocalizations.languages().contains(
    language.endsWith('_')
        ? language.substring(0, language.length - 1)
        : language,
  );
}

final kTranslationsMap = <Map<String, Map<String, String>>>[
  // HomePage
  {
    '601bzdk7': {
      'en': 'Search Maps',
      'ru': 'Поиск по карте',
    },
    'zsoniyfw': {
      'en': 'Home',
      'ru': '',
    },
  },
  // Map
  {
    '592a7d9n': {
      'en': 'Page Title',
      'ru': '',
    },
    'g11stf3e': {
      'en': 'Home',
      'ru': '',
    },
  },
  // EnterPhoneNumber
  {
    'cbqlg4tc': {
      'en': 'Enter phone number',
      'ru': 'Введите номер телефона',
    },
    'lzvvdqvl': {
      'en': 'Enter the phone number for account registration',
      'ru': 'Введите номер телефона для регистрации аккаунта',
    },
    'a5oig4l7': {
      'en': 'Enter phone number',
      'ru': 'Введите номер телефона',
    },
    '7r8u7gz1': {
      'en': 'Login as a guest',
      'ru': 'Войти как гость',
    },
    'l1cafadn': {
      'en': 'I have read and agree with the',
      'ru': 'Я принимаю',
    },
    '07m9owfm': {
      'en': 'Terms of Use',
      'ru': 'Условия использования',
    },
    'p3d4ugno': {
      'en': 'and',
      'ru': 'и',
    },
    'r3qoyf46': {
      'en': 'Privacy Policy',
      'ru': 'Политика конфиденциальности',
    },
    'wml08ijk': {
      'en': 'Next',
      'ru': 'Далее',
    },
    'exj7yq4r': {
      'en': 'Home',
      'ru': '',
    },
  },
  // ValidateSmsCode
  {
    '36w7g675': {
      'en': 'Enter the code',
      'ru': 'Введите код',
    },
    'l0czy8q4': {
      'en': 'We’ve sent an SMS with an activation code to your phone ',
      'ru': 'Мы отправили SMS с кодом подтверждения на ваш телефон',
    },
    'xyi3e3ag': {
      'en': 'We’ve sent an SMS with an activation code to your phone',
      'ru': 'Мы отправили SMS с кодом подтверждения на ваш телефон',
    },
    'nwq373cc': {
      'en': 'Invalid code',
      'ru': 'Неверный код',
    },
    'klas1jy1': {
      'en': 'New code sent',
      'ru': 'Новый код отправлен',
    },
    'xoxpje3e': {
      'en': 'Resend code',
      'ru': 'Отправить код повторно',
    },
    '5knnvovj': {
      'en': 'Resend code',
      'ru': 'Отправить код повторно',
    },
    '2ufdmsou': {
      'en': 'Next',
      'ru': 'Далее',
    },
    'oa2b7ciu': {
      'en': 'Home',
      'ru': '',
    },
  },
  // Registration
  {
    '7txhp7v1': {
      'en': 'Registration',
      'ru': 'Регистрация\n',
    },
    '0inqa3r5': {
      'en': 'Fill in the information about yourself',
      'ru': 'Заполните информацию о себе',
    },
    'bt0z2i9a': {
      'en': 'Name ',
      'ru': 'Имя',
    },
    'addReferralLink': {
      'en': 'Add invite link',
      'ru': 'Добавить пригласительную ссылку',
    },
    'inviteLinkSheetTitle': {
      'en': 'Invite link',
      'ru': 'Пригласительная ссылка',
    },
    'inviteLinkSheetDescription': {
      'en': 'Paste the full link sent to you by a friend.',
      'ru': 'Вставьте полную ссылку, которую вам отправил друг.',
    },
    'referralLinkLabel': {
      'en': 'Invite link',
      'ru': 'Пригласительная ссылка',
    },
    'pasteReferralLink': {
      'en': 'Paste from clipboard',
      'ru': 'Вставить из буфера обмена',
    },
    'applyReferralLink': {
      'en': 'Apply',
      'ru': 'Применить',
    },
    'referralLinkRequired': {
      'en': 'Paste the invite link',
      'ru': 'Вставьте пригласительную ссылку',
    },
    'invalidReferralLink': {
      'en': 'The invite link is invalid',
      'ru': 'Неверная пригласительная ссылка',
    },
    'referralLinkSaved': {
      'en': 'Invite link saved',
      'ru': 'Пригласительная ссылка сохранена',
    },
    'haveReferralLink': {
      'en': 'Have an invite link?',
      'ru': 'Есть пригласительная ссылка?',
    },
    'referralDiscountHint': {
      'en': 'Paste it to receive a subscription discount.',
      'ru': 'Вставьте её, чтобы получить скидку на подписку.',
    },
    'referralLinkFound': {
      'en': 'Invite link found',
      'ru': 'Пригласительная ссылка найдена',
    },
    'referralAutomaticDetectedHint': {
      'en': 'It will be verified when you finish registration.',
      'ru': 'Она будет проверена после завершения регистрации.',
    },
    'referralLinkAdded': {
      'en': 'Invite link added',
      'ru': 'Пригласительная ссылка добавлена',
    },
    'referralManualPendingHint': {
      'en': 'Your discount will be verified after registration.',
      'ru': 'Скидка будет проверена после регистрации.',
    },
    'pasteReferralLinkAction': {
      'en': 'Paste invite link',
      'ru': 'Вставить пригласительную ссылку',
    },
    'changeReferralLink': {
      'en': 'Change link',
      'ru': 'Изменить ссылку',
    },
    'referralApplyFailed': {
      'en': 'Could not apply the invite. Try again',
      'ru': 'Не удалось применить приглашение. Повторите попытку',
    },
    'tmbsyxys': {
      'en': 'Done',
      'ru': 'Готово',
    },
    'omeg7thl': {
      'en': 'Home',
      'ru': '',
    },
  },
  // PhotoDetailed
  {
    'puek23vx': {
      'en': 'Home',
      'ru': '',
    },
  },
  // AddParking
  {
    'kay7la1p': {
      'en': 'Adding parking',
      'ru': 'Добавление парковки',
    },
    'zarntoc5': {
      'en': 'Photo',
      'ru': 'Фото',
    },
    '7tdpz89b': {
      'en': 'Capacity',
      'ru': 'Количество мест',
    },
    'uv9rvlq8': {
      'en': 'Up to',
      'ru': 'До',
    },
    'l08nhe6q': {
      'en': 'Additional services',
      'ru': 'Дополнительные услуги',
    },
    'a17vs0ke': {
      'en': 'Gas station',
      'ru': 'Заправка',
    },
    '7n5m1ni5': {
      'en': 'Shower',
      'ru': 'Душ',
    },
    'lfcpm68i': {
      'en': 'Laundry',
      'ru': 'Прачечная',
    },
    'ig3e2q75': {
      'en': 'Hotel',
      'ru': 'Гостиница',
    },
    'pffih8hu': {
      'en': 'Shop',
      'ru': 'Магазин',
    },
    '1z925wjh': {
      'en': 'Recreation area',
      'ru': 'Зона отдыха',
    },
    '068qon6a': {
      'en': 'Add',
      'ru': 'Добавить',
    },
    'ugdgs2gp': {
      'en': 'Home',
      'ru': '',
    },
  },
  // Profile
  {
    'fnyxkvgy': {
      'en': 'Profile',
      'ru': 'Профиль',
    },
    'qqeuggbw': {
      'en': 'Theme',
      'ru': 'Тема',
    },
    'bfsnc62n': {
      'en': 'Subscribe',
      'ru': 'Подписка',
    },
    '1t95nv13': {
      'en': 'Active',
      'ru': 'Активно',
    },
    'g1t3xffe': {
      'en': 'Subscribe',
      'ru': 'Подписка',
    },
    't4n3s0wf': {
      'en': 'Requests',
      'ru': 'Заявки',
    },
    'g6yb23nw': {
      'en': 'Reviews',
      'ru': 'Отзывы',
    },
    '1gndpcu6': {
      'en': 'Favorites',
      'ru': 'Избранное',
    },
    'b7mh2swm': {
      'en': 'Invite friends',
      'ru': 'Пригласить друзей',
    },
    'wop5bvbh': {
      'en': 'Log out',
      'ru': 'Выйти из аккаунта',
    },
    'kbvu8l0q': {
      'en': 'Delete account',
      'ru': 'Удалить аккаунт',
    },
    '4t59dhz7': {
      'en': 'Home',
      'ru': '',
    },
  },
  // ReviewsAndComplaints
  {
    '6evvc10q': {
      'en': 'Reviews',
      'ru': 'Отзывы',
    },
    '7qsaka2q': {
      'en': 'Reviews ',
      'ru': 'Отзывы',
    },
    '4tqqsecp': {
      'en': 'Reviews ',
      'ru': 'Отзывы',
    },
    '9kj8miy2': {
      'en': 'Complaints',
      'ru': 'Жалобы',
    },
    'mjvppaw8': {
      'en': 'Complaints',
      'ru': 'Жалобы',
    },
    'chbtvtci': {
      'en': 'List of your reviews will be displayed here',
      'ru': 'Здесь будет отображаться список ваших отзывов',
    },
    'pdmi0b47': {
      'en': 'A list of your complaints will be displayed here',
      'ru': 'Здесь будет отображаться список ваших жалоб',
    },
    'o15lv1hr': {
      'en': 'Home',
      'ru': '',
    },
  },
  // Language
  {
    'xjjh7yvz': {
      'en': 'En',
      'ru': '',
    },
    'kcik5mmw': {
      'en': 'Ru',
      'ru': '',
    },
    'wk64f10i': {
      'en': 'Home',
      'ru': '',
    },
  },
  // Requests
  {
    '1igu8gpi': {
      'en': 'Requests',
      'ru': 'Отзыв',
    },
    'hrlm5657': {
      'en': 'Moderation',
      'ru': 'Модерация',
    },
    'd1lnasex': {
      'en': 'Moderation',
      'ru': 'Модерация',
    },
    'k69whbic': {
      'en': 'Accepted ',
      'ru': 'Одобрено',
    },
    'u03x60r8': {
      'en': 'Accepted',
      'ru': 'Одобрено',
    },
    'mrnl6tz7': {
      'en': 'Rejected',
      'ru': 'Отклонено',
    },
    '6jp8eqpk': {
      'en': 'Rejected',
      'ru': 'Отклонено',
    },
    'kt10y4th': {
      'en': 'Applications awaiting moderation will \nbe shown here',
      'ru': 'Здесь появятся ваши заявки, ожидающие проверки',
    },
    'u04tu3wa': {
      'en': 'Approved applications will be shown here',
      'ru': 'Здесь появятся ваши одобренные заявки',
    },
    'd79wksx8': {
      'en': 'Rejected applications will be shown here',
      'ru': 'Здесь появятся ваши отклонённые заявки',
    },
    'n7blrrze': {
      'en': 'Add parking',
      'ru': 'Добавить парковку',
    },
    'yk1lpwc2': {
      'en': 'Home',
      'ru': '',
    },
  },
  // RejectedParking
  {
    'etzzmx5b': {
      'en': 'Request was rejected\nIncomplete information',
      'ru': '',
    },
    'keor7ie4': {
      'en': 'Capacity',
      'ru': 'Количество мест',
    },
    'lo8hjh4q': {
      'en': 'Additional services',
      'ru': 'Дополнительные услуги',
    },
    'oucn91nl': {
      'en': 'Gas station',
      'ru': 'Заправка',
    },
    't37c1t9b': {
      'en': 'Shower',
      'ru': 'Душ',
    },
    'pkntm941': {
      'en': 'Laundry',
      'ru': 'Прачечная',
    },
    'okjbagoe': {
      'en': 'Hotel',
      'ru': 'Гостиница',
    },
    'mc2100o5': {
      'en': 'Shop',
      'ru': 'Магазин',
    },
    'bo6l1893': {
      'en': 'Recreation area',
      'ru': 'Зона отдыха',
    },
    'ky4nkxsl': {
      'en': 'Home',
      'ru': '',
    },
  },
  // ModerationParking
  {
    'buuba128': {
      'en': 'Request under moderation',
      'ru': 'Заявка на модерации',
    },
    'qaii939u': {
      'en': 'Capacity',
      'ru': 'Количество мест',
    },
    '4pcnkj37': {
      'en': 'Additional services',
      'ru': 'Дополнительные услуги',
    },
    '8w0lya63': {
      'en': 'Gas station',
      'ru': 'Заправка',
    },
    'u4t7ah6v': {
      'en': 'Shower',
      'ru': 'Душ',
    },
    'ln71rckf': {
      'en': 'Laundry',
      'ru': 'Прачечная',
    },
    '5tg57khw': {
      'en': 'Hotel',
      'ru': 'Гостиница',
    },
    'okvhauwn': {
      'en': 'Shop',
      'ru': 'Магазин',
    },
    'f6mlhyp9': {
      'en': 'Recreation area',
      'ru': 'Зона отдыха',
    },
    'te4pzckh': {
      'en': 'Home',
      'ru': '',
    },
  },
  // AcceptedParking
  {
    'ddptkcow': {
      'en': 'Capacity',
      'ru': 'Количество мест',
    },
    'gea2j1pf': {
      'en': 'Additional services',
      'ru': 'Дополнительные услуги',
    },
    'o417beo6': {
      'en': 'Gas station',
      'ru': 'Заправка',
    },
    'aixmh7aq': {
      'en': 'Shower',
      'ru': 'Душ',
    },
    '1uh98xps': {
      'en': 'Laundry',
      'ru': 'Прачечная',
    },
    'qz5a0rvg': {
      'en': 'Hotel',
      'ru': 'Гостиница',
    },
    'r3l81vm2': {
      'en': 'Shop',
      'ru': 'Магазин',
    },
    '41rb59qv': {
      'en': 'Recreation area',
      'ru': 'Зона отдыха',
    },
    'byyrc76j': {
      'en': 'Home',
      'ru': '',
    },
  },
  // Favourites
  {
    'visdd4n6': {
      'en': 'Favourites',
      'ru': 'Избранное',
    },
    'u0idlh6r': {
      'en': 'Your favorite parking spots will be displayed \nhere',
      'ru': 'Здесь будут отображаться ваши избранные парковки',
    },
    'ojhgjye4': {
      'en': 'Home',
      'ru': '',
    },
  },
  // EditProfile
  {
    'tkshfa30': {
      'en': 'Edit ',
      'ru': 'Изменить',
    },
    'ogcoe3or': {
      'en': 'Name ',
      'ru': 'Имя',
    },
    'nbcba9lw': {
      'en': 'Save',
      'ru': 'Готово',
    },
    'ku28916x': {
      'en': 'Home',
      'ru': '',
    },
  },
  // CreateParking
  {
    'cxr3v492': {
      'en': 'Adding parking',
      'ru': 'Добавление парковки',
    },
    'ko5k4a79': {
      'en': 'Photo',
      'ru': 'Фото',
    },
    'j602dc4j': {
      'en': 'Capacity',
      'ru': 'Количество мест',
    },
    '2mcl1t0z': {
      'en': 'Up to',
      'ru': 'До',
    },
    'al0hw43m': {
      'en': 'Additional services',
      'ru': 'Дополнительные услуги',
    },
    'ev9hemgm': {
      'en': 'Gas station',
      'ru': 'Заправка',
    },
    'zv0o5fek': {
      'en': 'Shower',
      'ru': 'Душ',
    },
    'xxjzgart': {
      'en': 'Laundry',
      'ru': 'Прачечная',
    },
    'cvekryq6': {
      'en': 'Hotel',
      'ru': 'Гостиница',
    },
    'l80gcse8': {
      'en': 'Shop',
      'ru': 'Магазин',
    },
    'lxmsh23t': {
      'en': 'Recreation area',
      'ru': 'Зона отдыха',
    },
    '2np859v5': {
      'en': 'Add',
      'ru': 'Добавить',
    },
    'nmreu0o0': {
      'en': 'Home',
      'ru': '',
    },
  },
  // SelectParking
  {
    'nu5ik2xh': {
      'en': 'Press and hold on the map to select a parking location',
      'ru': 'Нажми и удерживай на карте, чтобы выбрать точку парковки',
    },
    'oizg2qhw': {
      'en': 'Home',
      'ru': '',
    },
  },
  // SharedPhotoView
  {
    'eimkno6c': {
      'en': 'To main',
      'ru': 'На главную',
    },
    '0rxd7wkr': {
      'en': 'Home',
      'ru': '',
    },
  },
  // Onboard1
  {
    'qhxsqena': {
      'en': 'Find Parking Nearby',
      'ru': 'Находите парковки рядом',
    },
    'zk6evu3e': {
      'en':
          'A convenient map with up-to-date truck parking spots — always at your fingertips',
      'ru':
          'Удобная карта с актуальными местами для парковки грузовиков — всегда под рукой',
    },
    'srmlymmv': {
      'en': 'Next',
      'ru': 'Далее',
    },
    'gijm6uwm': {
      'en': 'Home',
      'ru': '',
    },
  },
  // Splash
  {
    '5w85lmwf': {
      'en': 'Home',
      'ru': '',
    },
  },
  // Onboard2
  {
    'f3jjfeu7': {
      'en': 'All information in one place',
      'ru': 'Вся информация в одном месте',
    },
    'fe6dcq7p': {
      'en':
          'We collected all the information from the address to all the amenities',
      'ru': 'Мы собрали всю информацию, от адреса до всех удобств',
    },
    '0gvfbplb': {
      'en': 'Next',
      'ru': 'Далее',
    },
    'hjszxj8s': {
      'en': 'Home',
      'ru': '',
    },
  },
  // Onboard3
  {
    'f39xkzmy': {
      'en': 'Influence directly',
      'ru': 'Оказывайте прямое влияние',
    },
    'axjk8njs': {
      'en':
          'Add parking spots to the map and write reviews to help other drivers make the right decision',
      'ru':
          'Добавляйте парковочные места на карту и пишите отзывы, чтобы помочь другим водителям принять правильное решение',
    },
    '3egr8b63': {
      'en': 'Next',
      'ru': 'Далее',
    },
    'ydx7qko9': {
      'en': 'Home',
      'ru': '',
    },
  },
  // PayWall
  {
    'evs9vgg4': {
      'en': 'Subscribe',
      'ru': 'Подписка',
    },
    'wwnlg6u7': {
      'en': 'Choose your plan',
      'ru': 'Выбери свой план',
    },
    't9tpdjfr': {
      'en':
          'Route Planning — build direct routes to any selected parking lot directly inside the app',
      'ru':
          'Построение маршрутов — стройте точные маршруты до любой выбранной парковки прямо в приложении',
    },
    'deq1rgv5': {
      'en': 'Monthly',
      'ru': 'Ежемесячная',
    },
    'jv4oz2m2': {
      'en': 'Yearly',
      'ru': 'Годовая',
    },
    'itkyedka': {
      'en': 'Restore purchases',
      'ru': 'Восстановить покупки',
    },
    '2uoljomi': {
      'en': 'Subscribe',
      'ru': 'Подписаться',
    },
    'asy566cw': {
      'en': 'I have read and agree with the',
      'ru': 'Я принимаю',
    },
    '105g92ub': {
      'en': 'Terms of Use',
      'ru': 'Условия использования',
    },
    'z74am36a': {
      'en': 'and',
      'ru': 'и',
    },
    '2ilb0x4e': {
      'en': 'Privacy Policy',
      'ru': 'Политика конфиденциальности',
    },
    '30kl8lgu': {
      'en': 'Home',
      'ru': '',
    },
  },
  // PhotoDetailedReviews
  {
    '8y30yqql': {
      'en': '',
      'ru': '',
    },
    '3sw4tflq': {
      'en': '',
      'ru': '',
    },
    'ra7h14bv': {
      'en': '',
      'ru': '',
    },
    '6o6ujlkg': {
      'en': 'Home',
      'ru': '',
    },
  },
  // ParkingsDetails
  {
    'yt9sz7yw': {
      'en': 'Set a route',
      'ru': 'Построить маршрут',
    },
    '67t6qqlw': {
      'en': 'Info',
      'ru': 'Информация',
    },
    'ips08b2l': {
      'en': 'Reviews',
      'ru': 'Отзывы',
    },
    'xmtd8nx0': {
      'en': 'Photo',
      'ru': 'Фото',
    },
  },
  // InfoTab
  {
    '69t83dt2': {
      'en': 'Capacity',
      'ru': 'Количество мест',
    },
    '6qk95scx': {
      'en': 'Additional services',
      'ru': 'Дополнительные услуги',
    },
    'nh8khihp': {
      'en': 'Gas station',
      'ru': 'Заправка',
    },
    'pf7gi44l': {
      'en': 'Shower',
      'ru': 'Душ',
    },
    'q72lgolb': {
      'en': 'Laundry',
      'ru': 'Прачечная',
    },
    'nm5dy9gw': {
      'en': 'Hotel',
      'ru': 'Гостиница',
    },
    'p3xyj929': {
      'en': 'Shop',
      'ru': 'Магазин',
    },
    '3ani69on': {
      'en': 'Recreation area',
      'ru': 'Зона отдыха',
    },
  },
  // ReviewsTab
  {
    '0tc0742s': {
      'en': '50%',
      'ru': '',
    },
    'uh6eg426': {
      'en': '50%',
      'ru': '',
    },
    'g529tf0w': {
      'en': '50%',
      'ru': '',
    },
    'mpwx6x05': {
      'en': '50%',
      'ru': '',
    },
    '960y3ktl': {
      'en': 'Share your impressions',
      'ru': 'Поделитесь впечатлениями',
    },
    'p3wlf3ji': {
      'en':
          'Your opinion is important to us! Fill out a short questionnaire and tell us how you like parking',
      'ru':
          'Ваше мнение важно для нас! Ответьте на несколько вопросов и расскажите, как вам парковка',
    },
    '2jy1g9cx': {
      'en': 'Report a problem',
      'ru': 'Сообщить о проблеме',
    },
    'ms3fkz4k': {
      'en': 'Leave a review',
      'ru': 'Оставить отзыв',
    },
    '3ezk7f6o': {
      'en': 'All reviews',
      'ru': 'Все отзывы',
    },
    'eb2hek18': {
      'en': 'There are no reviews yet',
      'ru': 'Пока нет отзывов',
    },
  },
  // ReviewCardParkingDetails
  {
    '21sa87uf': {
      'en': 'Read more',
      'ru': 'Показать ещё',
    },
    'px2143v5': {
      'en': 'Show less',
      'ru': 'Скрыть',
    },
  },
  // CreateParkingDialog
  {
    'tar1bdul': {
      'en': 'Add parking here?',
      'ru': 'Добавить парковку здесь?',
    },
    'vsz1gqgd': {
      'en': 'Cancel',
      'ru': 'Выйти',
    },
    '0qsa3cyx': {
      'en': 'Add',
      'ru': 'Добавить',
    },
  },
  // WrongDistanceDialog
  {
    '31tyvod9': {
      'en': 'Too far from location',
      'ru': 'Вы слишком далеко',
    },
    'ecizywsu': {
      'en':
          'You are too far from the selected point. To ensure accuracy, you must be within 500 meters of the parking spot to add it.',
      'ru':
          'Вы находитесь слишком далеко от выбранной точки. Чтобы данные были точными, вы должны быть в радиусе 500 метров от места парковки.',
    },
    'lz19d27s': {
      'en': 'OK',
      'ru': 'Понятно',
    },
  },
  // ReviewCreate
  {
    'yic84jck': {
      'en': 'Review ',
      'ru': 'Отзыв',
    },
    'kfona9jf': {
      'en': 'The main impression',
      'ru': 'Общее впечатление',
    },
    'avi1yeu0': {
      'en': 'Great',
      'ru': 'Отлично',
    },
    'qry2rtou': {
      'en': 'Normally',
      'ru': 'Нормально',
    },
    '3hwql4dn': {
      'en': 'Medium',
      'ru': 'Средне',
    },
    '10yh9sv9': {
      'en': 'Badly',
      'ru': 'Плохо',
    },
    'r4txy348': {
      'en': 'Terribly',
      'ru': 'Ужасно',
    },
    '3olvlgur': {
      'en': 'Convenience of truck arrival',
      'ru': 'Удобство прибытия грузовика',
    },
    '299wqdvn': {
      'en': 'Very convenient',
      'ru': 'Очень удобно',
    },
    'p2equyce': {
      'en': 'Good',
      'ru': 'Хорошо',
    },
    'jeprgk4m': {
      'en': 'Normally',
      'ru': 'Нормально',
    },
    'lcqr3i06': {
      'en': 'Difficult',
      'ru': 'Сложно',
    },
    'l9zb3bqv': {
      'en': 'Very inconvenient',
      'ru': 'Очень неудобно',
    },
    'tjy6p461': {
      'en': 'Security level',
      'ru': 'Уровень безопасности',
    },
    'uohbegrq': {
      'en': 'Absolutely safe',
      'ru': 'Полностью безопасно',
    },
    'q3vjpcbk': {
      'en': 'Quietly',
      'ru': 'Спокойно',
    },
    '9ke2hg70': {
      'en': 'Normally',
      'ru': 'Нормально',
    },
    'c7w5yqey': {
      'en': 'Badly',
      'ru': 'Плохо',
    },
    'zuvh5erd': {
      'en': 'Dangerous',
      'ru': 'Опасно',
    },
    '5yqihed3': {
      'en': 'Infrastructure',
      'ru': 'Инфраструктура',
    },
    '48398mdd': {
      'en': 'Everything that was stated in the \ndescription',
      'ru': 'Всё, что было указано в описании',
    },
    'gd74l5sl': {
      'en': 'Almost everything that was stated',
      'ru': 'Почти всё, что было указано',
    },
    '7tnfdvtd': {
      'en': 'Only half of the services are\n available',
      'ru': 'Доступна только половина услуг',
    },
    '16rqzi7p': {
      'en': 'Almost nothing is available',
      'ru': 'Почти ничего не доступно',
    },
    'd81kyadc': {
      'en': 'Nothing but parking',
      'ru': 'Только парковка',
    },
    'c7jy878l': {
      'en': 'Comfort for relaxation',
      'ru': 'Комфорт для отдыха',
    },
    'ozjka1j2': {
      'en': 'Quiet and comfortable',
      'ru': 'Тихо и комфортно',
    },
    'blv3m8fe': {
      'en': 'Normally',
      'ru': 'Нормально',
    },
    'll5f8qcc': {
      'en': 'Medium',
      'ru': 'Средне',
    },
    '81npb4aw': {
      'en': 'Inconvenient',
      'ru': 'Неудобно',
    },
    '9qk1u6fz': {
      'en': 'Very inconvenient',
      'ru': 'Очень неудобно',
    },
    's9ueqwah': {
      'en': 'Comment',
      'ru': 'Комментарий',
    },
    '0kn246hn': {
      'en': 'Share your impressions',
      'ru': 'Поделитесь своими впечатлениями',
    },
    'jzrdiz9i': {
      'en': 'Photo',
      'ru': 'Фото',
    },
    'qmgfq1y4': {
      'en': 'Leave a review',
      'ru': 'Оставить отзыв',
    },
  },
  // Filter
  {
    'br8cc77z': {
      'en': 'Filter',
      'ru': 'Фильтр',
    },
    'u664zpud': {
      'en': 'Reset',
      'ru': 'Сброс',
    },
    'zkqa39b3': {
      'en': 'Show the nearest ones',
      'ru': 'Показать ближайшие',
    },
    '22fti48i': {
      'en': 'Less than ',
      'ru': 'Менее',
    },
    '2ykjvym9': {
      'en': ' km',
      'ru': 'км',
    },
    'qp57exhk': {
      'en': 'Less than 5 km',
      'ru': 'Менее 5 км',
    },
    'wqydklg8': {
      'en': 'Search radius',
      'ru': 'Радиус поиска',
    },
    'a665mkov': {
      'en': '>5 km',
      'ru': '>5 km',
    },
    'wjtk7cc1': {
      'en': '10 km',
      'ru': '10 km',
    },
    '46bnkutv': {
      'en': '50 km',
      'ru': '50 km',
    },
    'kskv1ggh': {
      'en': '100 km',
      'ru': '100 km',
    },
    '6uulvp4g': {
      'en': '<150 km',
      'ru': '<150 km',
    },
    'qmz3k8dt': {
      'en': 'Show the nearest ones',
      'ru': 'Показать ближайшие',
    },
    '4gdaeu83': {
      'en': 'Less than 5 km',
      'ru': 'Менее 5 км',
    },
    '2j0cag5z': {
      'en': 'Capasity',
      'ru': 'Вместимость',
    },
    'jbj6teql': {
      'en': 'From',
      'ru': 'От',
    },
    'wllbx6n1': {
      'en': 'Up to',
      'ru': 'До',
    },
    'vb4dqn42': {
      'en': 'Additional services',
      'ru': 'Дополнительные услуги',
    },
    'fl8fv2lo': {
      'en': 'Gas station',
      'ru': 'Заправка',
    },
    '0wj09hna': {
      'en': 'Shower',
      'ru': 'Душ\n',
    },
    'bs0rvsxu': {
      'en': 'Laundry',
      'ru': 'Прачечная',
    },
    'l5l75pgm': {
      'en': 'Hotel',
      'ru': 'Гостиница',
    },
    'mykrvvun': {
      'en': 'Shop',
      'ru': 'Магазин',
    },
    '719j3lon': {
      'en': 'Recreation area',
      'ru': 'Зона отдыха',
    },
    'm01ehi2e': {
      'en': 'Apply',
      'ru': 'Применить',
    },
  },
  // LogOutDialog
  {
    '0hkcumo5': {
      'en': 'Are you sure you want to log out of your account?',
      'ru': 'Вы уверены, что хотите выйти из аккаунта?',
    },
    'yxtx66p8': {
      'en': 'Cancel',
      'ru': 'Отмена',
    },
    'r1no8o8z': {
      'en': 'Log out',
      'ru': 'Выйти',
    },
  },
  // LogOutDialogCopy
  {
    'tt8urgxd': {
      'en': 'Delete account?',
      'ru': 'Удалить аккаунт',
    },
    'eyzhhtbp': {
      'en':
          'Are you sure you want to delete your account? All data will be lost',
      'ru':
          'Вы уверены, что хотите удалить свой аккаунт? Все данные будут потеряны',
    },
    '5d666boc': {
      'en': 'Cancel',
      'ru': 'Отмена',
    },
    'sbtelre8': {
      'en': 'Delete',
      'ru': 'Удалить',
    },
  },
  // ComplaintCard
  {
    'yiywuf5r': {
      'en': 'Read more',
      'ru': 'Показать ещё',
    },
    'rfovf3hg': {
      'en': 'Show less',
      'ru': 'Скрыть',
    },
  },
  // RequestCard
  {
    '5ascx5of': {
      'en': 'Under moderation',
      'ru': 'На модерации',
    },
    'b4fc9la0': {
      'en': 'Accepted',
      'ru': 'Одобрено',
    },
    'rq1fdjm3': {
      'en': 'Rejected',
      'ru': 'Отклонено',
    },
  },
  // CreateParkingDialog2
  {
    '478vh6e9': {
      'en': 'Add parking here?',
      'ru': 'Добавить парковку здесь?',
    },
    'lghtf3gy': {
      'en': 'Cancel',
      'ru': 'Выйти',
    },
    'i0ibkg9c': {
      'en': 'Add',
      'ru': 'Добавить',
    },
  },
  // WrongDistanceDialog2
  {
    '87ihyb2a': {
      'en': 'Too far from location',
      'ru': 'Вы слишком далеко',
    },
    '0v1xr4g3': {
      'en':
          'You are too far from the selected point. To ensure accuracy, you must be within 500 meters of the parking spot to add it.',
      'ru':
          'Вы находитесь слишком далеко от выбранной точки. Чтобы данные были точными, вы должны быть в радиусе 500 метров от места парковки.',
    },
    'zwzuecyn': {
      'en': 'OK',
      'ru': 'Понятно',
    },
  },
  // ReportCreate
  {
    '0pu9fn7m': {
      'en': 'Report a problem',
      'ru': 'Отзыв',
    },
    'pgz1qf23': {
      'en': 'Specify the reason for the complaint',
      'ru': 'Укажите причину жалобы',
    },
    'tggd36hm': {
      'en': 'Parking does not exist',
      'ru': 'Парковка не существует',
    },
    'hbbim1et': {
      'en': 'A dangerous place',
      'ru': 'Опасное место',
    },
    'xqoh5i72': {
      'en': 'Another problem',
      'ru': 'Друая проблема',
    },
    '5csvnj7g': {
      'en': 'Comment',
      'ru': 'Комментарий',
    },
    '47nkapwf': {
      'en': 'Describe the problem *',
      'ru': 'Поделитесь своими впечатлениями',
    },
    '8w12gudm': {
      'en': 'Report a problem',
      'ru': 'Сообщить о проблеме',
    },
  },
  // SubmittedModeration
  {
    'ncjyi7c5': {
      'en': 'Submitted for moderation',
      'ru': 'Отправлено на модерацию',
    },
    'gfn1rbvm': {
      'en':
          'As soon as the admin checks the info, the parking will be on the map',
      'ru': 'Как только админ проверит информацию, парковка появится на карте',
    },
    'ij86oq0k': {
      'en': 'Go to the main page ',
      'ru': 'Вернуться на главную страницу',
    },
  },
  // ReviewCardProfile
  {
    '5i8dq960': {
      'en': 'Read more',
      'ru': 'Показать ещё',
    },
    '5x70xto7': {
      'en': 'Show less',
      'ru': 'Скрыть',
    },
  },
  // SubscriptionDialog
  {
    '1ysko8yw': {
      'en': 'Navigator requires a subscription',
      'ru': 'Навигатор требует подписку',
    },
    'eihavtc5': {
      'en': 'To use the navigator, you need to subscribe',
      'ru': 'Чтобы использовать навигатор, оформите подписку',
    },
    'cpc8afp1': {
      'en': 'Cancel',
      'ru': 'Отмена',
    },
    'l71jnrfz': {
      'en': 'Subscribe',
      'ru': 'Подписаться',
    },
  },
  // InviteFriendsDialog
  {
    '0pjee4u7': {
      'en': 'Invite friends',
      'ru': 'Пригласить друзей',
    },
    'hr61a3eu': {
      'en': 'Invite a friend and get a discount on your next month',
      'ru': 'Отправьте ссылку другу и получите скидку на 1 месяц',
    },
    'fl7o38kq': {
      'en': 'Cancel',
      'ru': 'Отмена',
    },
    'j5yv5qwi': {
      'en': 'Share',
      'ru': 'Поделиться',
    },
  },
  // GuestDialog
  {
    'nom01bnj': {
      'en': 'Sign In Required',
      'ru': 'Войдите в аккаунт',
    },
    's6dogkw7': {
      'en':
          'To build routes to parking lots, leave reviews, and manage your profile, please complete a quick phone number verification. It takes less than a minute!',
      'ru':
          'Чтобы строить маршруты до парковок, оставлять отзывы и управлять своим профилем, пожалуйста, пройдите быструю авторизацию по номеру телефона. Это займет не больше минуты!',
    },
    'exky4uks': {
      'en': 'Continue',
      'ru': 'Продолжить',
    },
    '32lcz1y0': {
      'en': 'Register',
      'ru': 'Зарегистрироваться',
    },
  },
  // Miscellaneous
  {
    '316uksvu': {
      'en':
          'This app needs access to your location to show nearby truck parks on the map and calculate distances to them.',
      'ru': '',
    },
    'fzd895mc': {
      'en':
          'This app requires camera access so you can take and upload real-time photos of truck parks, amenities, and parking conditions directly to your reviews and reports, helping other drivers see the actual state of the facilities.',
      'ru': '',
    },
    'ovf58o3d': {
      'en': '',
      'ru': '',
    },
    '1igc4woz': {
      'en':
          'This app requires location access to show nearby truck parks on the map and calculate distances to them.',
      'ru': '',
    },
    '7hf3eu5x': {
      'en': '',
      'ru': '',
    },
    'z0pmyndc': {
      'en': '',
      'ru': '',
    },
    'g2hbqm56': {
      'en': '',
      'ru': '',
    },
    'pbcldlrw': {
      'en': '',
      'ru': '',
    },
    'zdfme5gq': {
      'en': '',
      'ru': '',
    },
    'eayb1141': {
      'en': '',
      'ru': '',
    },
    'lolu3tw8': {
      'en': '',
      'ru': '',
    },
    'hx36huzf': {
      'en': '',
      'ru': '',
    },
    'x5hgj59m': {
      'en': '',
      'ru': '',
    },
    '2q0qadlc': {
      'en': '',
      'ru': '',
    },
    'e3ob064o': {
      'en': '',
      'ru': '',
    },
    '9az13z5g': {
      'en': '',
      'ru': '',
    },
    '1bj5xu08': {
      'en': '',
      'ru': '',
    },
    'xrtefdtr': {
      'en': '',
      'ru': '',
    },
    'yi1t72pl': {
      'en': '',
      'ru': '',
    },
    'h0vt68xj': {
      'en': '',
      'ru': '',
    },
    'ddo6x0ec': {
      'en': '',
      'ru': '',
    },
    '407op4gm': {
      'en': '',
      'ru': '',
    },
    'l0hh2djj': {
      'en': '',
      'ru': '',
    },
    '7ai5s4sh': {
      'en': '',
      'ru': '',
    },
    '9ygp1rb1': {
      'en': '',
      'ru': '',
    },
    'auykt55i': {
      'en': '',
      'ru': '',
    },
    'zvd3x1zb': {
      'en': '',
      'ru': '',
    },
    'nw56zqsz': {
      'en': '',
      'ru': '',
    },
    '79ynhqen': {
      'en': '',
      'ru': '',
    },
  },
].reduce((a, b) => a..addAll(b));
