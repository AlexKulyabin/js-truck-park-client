import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/favorites/application/favorites_controller.dart';
import 'package:j_s_truck_park/features/favorites/domain/favorite_parking_summary.dart';
import 'package:j_s_truck_park/features/favorites/presentation/favorites_list.dart';
import 'package:j_s_truck_park/flutter_flow/internationalization.dart';

const _favorite = FavoriteParkingSummary(
  favoriteRecordId: 10,
  parkingId: 'parking-1',
  address: 'Test address',
  latitude: 52.1,
  longitude: 21.2,
);

Widget _buildSubject({
  required FavoritesState state,
  ValueChanged<FavoriteParkingSummary>? onFavoriteSelected,
  VoidCallback? onRetry,
  Brightness brightness = Brightness.light,
}) =>
    MaterialApp(
      localizationsDelegates: const [
        FFLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ru')],
      locale: const Locale('en'),
      theme: ThemeData(brightness: brightness, useMaterial3: false),
      home: Scaffold(
        body: FavoritesList(
          state: state,
          onFavoriteSelected: onFavoriteSelected ?? (_) {},
          onRetry: onRetry ?? () {},
        ),
      ),
    );

void main() {
  testWidgets('renders the bounded loading state', (tester) async {
    await tester.pumpWidget(
      _buildSubject(state: const FavoritesState.initial()),
    );

    expect(find.byKey(FavoritesList.loadingKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the existing empty message', (tester) async {
    await tester.pumpWidget(
      _buildSubject(
        state: const FavoritesState(
          phase: FavoritesLoadPhase.loaded,
          favorites: [],
        ),
      ),
    );

    expect(find.byKey(FavoritesList.emptyKey), findsOneWidget);
    expect(
      find.text('Your favorite parking spots will be displayed \nhere'),
      findsOneWidget,
    );
  });

  testWidgets('retries a redacted failure without rendering raw details',
      (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      _buildSubject(
        state: const FavoritesState(
          phase: FavoritesLoadPhase.failure,
          favorites: [],
        ),
        onRetry: () => retries++,
      ),
    );

    await tester.tap(find.byKey(FavoritesList.failureKey));

    expect(retries, 1);
    expect(find.textContaining('database'), findsNothing);
  });

  testWidgets('renders a typed card and reports the selected parking',
      (tester) async {
    FavoriteParkingSummary? selected;
    await tester.pumpWidget(
      _buildSubject(
        state: const FavoritesState(
          phase: FavoritesLoadPhase.loaded,
          favorites: [_favorite],
        ),
        onFavoriteSelected: (favorite) => selected = favorite,
      ),
    );

    expect(find.byKey(FavoritesList.listKey), findsOneWidget);
    expect(find.text('Test address'), findsOneWidget);
    expect(find.byIcon(Icons.no_photography), findsOneWidget);

    await tester.tap(find.text('Test address'));
    expect(selected, _favorite);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the typed card in dark mode', (tester) async {
    await tester.pumpWidget(
      _buildSubject(
        brightness: Brightness.dark,
        state: const FavoritesState(
          phase: FavoritesLoadPhase.loaded,
          favorites: [_favorite],
        ),
      ),
    );

    expect(find.text('Test address'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
