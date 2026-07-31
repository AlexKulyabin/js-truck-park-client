import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/favourites/favourites/favourites_widget.dart';
import 'package:j_s_truck_park/features/favorites/domain/favorite_parking_summary.dart';
import 'package:j_s_truck_park/features/favorites/domain/favorites_repository.dart';
import 'package:j_s_truck_park/features/favorites/presentation/favorites_list.dart';
import 'package:j_s_truck_park/flutter_flow/internationalization.dart';

class _FakeRepository implements FavoritesRepository {
  final userIds = <String>[];
  List<FavoriteParkingSummary> result = [];

  @override
  Future<List<FavoriteParkingSummary>> fetchOwnedFavorites(
    String userId,
  ) async {
    userIds.add(userId);
    return result;
  }
}

Widget _buildSubject(_FakeRepository repository) => MaterialApp(
      localizationsDelegates: const [
        FFLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ru')],
      locale: const Locale('en'),
      theme: ThemeData(brightness: Brightness.light, useMaterial3: false),
      home: FavouritesWidget(
        repository: repository,
        userId: 'user-1',
      ),
    );

void main() {
  test('keeps the public route contract', () {
    expect(FavouritesWidget.routeName, 'Favourites');
    expect(FavouritesWidget.routePath, '/favourites');
  });

  testWidgets('loads the screen through the injected owner boundary',
      (tester) async {
    final repository = _FakeRepository();

    await tester.pumpWidget(_buildSubject(repository));
    await tester.pumpAndSettle();

    expect(repository.userIds, ['user-1']);
    expect(find.byKey(FavoritesList.emptyKey), findsOneWidget);
    expect(find.text('Favourites'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
