import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'auth/supabase_auth/supabase_user_provider.dart';
import 'auth/supabase_auth/auth_util.dart';

import '/backend/supabase/supabase.dart';
import '/core/config/app_config.dart';
import '/core/localization/shared_preferences_locale_store.dart';
import '/core/theme/shared_preferences_theme_store.dart';
import '/features/language/application/language_controller.dart';
import '/features/deep_links/application/incoming_app_link_coordinator.dart';
import '/features/map/application/parking_filter_controller.dart';
import '/features/settings/application/theme_controller.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/internationalization.dart';
import 'flutter_flow/nav/nav.dart';
import 'index.dart';
import 'custom_code/actions/index.dart' as actions;
import 'flutter_flow/revenue_cat_util.dart' as revenue_cat;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  await SupaFlow.initialize();

  final themeStore = await SharedPreferencesThemeStore.create();
  await FlutterFlowTheme.initialize(themeStore: themeStore);
  final themeController = ThemeController(themeStore: themeStore);

  final localeStore = await SharedPreferencesLocaleStore.create();
  await FFLocalizations.initialize(localeStore: localeStore);
  final languageController = LanguageController(localeStore: localeStore);
  final parkingFilterController = ParkingFilterController();

  final appState = FFAppState(); // Initialize FFAppState
  await appState.initializePersistedState();

  if (AppConfig.current.enableDeepLinks) {
    try {
      await actions.initChottuLink();
      await actions.listenChottuLink();
      await actions.recoverChottuReferral();
    } catch (error) {
      debugPrint('Chottu Link initialization failed: $error');
    }
  }

  if (AppConfig.current.enableRevenueCat) {
    await revenue_cat.initialize(
      "appl_NrPQbuBOcXtTLrzaVOxuHSGJpCU",
      "goog_QUrXVRyuoRQRgEdSZJiRuvMfhcp",
      loadDataAfterLaunch: true,
    );
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => appState),
        ChangeNotifierProvider(create: (_) => languageController),
        ChangeNotifierProvider(create: (_) => parkingFilterController),
        ChangeNotifierProvider(create: (_) => themeController),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class MyAppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class _MyAppState extends State<MyApp> {
  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  IncomingAppLinkCoordinator? _incomingAppLinks;
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.path;
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();
  late Stream<BaseAuthUser> userStream;

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    userStream = jSTruckParkSupabaseUserStream()
      ..listen((user) {
        _appStateNotifier.update(user);
      });
    jwtTokenStream.listen((_) {});
    Future.delayed(
      Duration(milliseconds: 1000),
      () => _appStateNotifier.stopShowingSplashImage(),
    );
    if (AppConfig.current.enableDeepLinks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _incomingAppLinks = IncomingAppLinkCoordinator(
          links: AppLinks().uriLinkStream,
          openLocation: _router.go,
          persistReferralCode: (referralCode) {
            FFAppState().update(() {
              FFAppState().tempReferralCode = referralCode;
            });
          },
          onError: (error, _) {
            debugPrint('Incoming app link failed: ${error.runtimeType}');
          },
        )..start();
      });
    }
  }

  @override
  void dispose() {
    _incomingAppLinks?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LanguageController>().state.locale;
    final themeMode = context.watch<ThemeController>().state.themeMode;

    return MaterialApp.router(
      debugShowCheckedModeBanner: AppConfig.current.isIntegration,
      title: AppConfig.current.appDisplayName,
      builder: (context, child) {
        final app = child ?? const SizedBox.shrink();
        if (!AppConfig.current.integrationReadOnly) {
          return app;
        }
        return Banner(
          message: 'READ ONLY',
          location: BannerLocation.topStart,
          child: app,
        );
      },
      scrollBehavior: MyAppScrollBehavior(),
      localizationsDelegates: [
        FFLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FallbackMaterialLocalizationDelegate(),
        FallbackCupertinoLocalizationDelegate(),
      ],
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ru'),
      ],
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: false,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: false,
      ),
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
