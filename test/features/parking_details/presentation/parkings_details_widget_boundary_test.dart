import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/app_state.dart';
import 'package:j_s_truck_park/features/parking_details/domain/parking_details.dart';
import 'package:j_s_truck_park/features/parking_details/domain/parking_favorite_repository.dart';
import 'package:j_s_truck_park/features/parking_details/domain/parking_details_repository.dart';
import 'package:j_s_truck_park/flutter_flow/internationalization.dart';
import 'package:j_s_truck_park/parkings_details/parkings_details/parkings_details_widget.dart';
import 'package:provider/provider.dart';

class _FakeRepository implements ParkingDetailsRepository {
  ParkingDetails? details;
  List<ParkingReview> reviews = [];
  final detailsParkingIds = <String>[];
  final reviewsParkingIds = <String>[];

  @override
  Future<ParkingDetails?> fetchDetails(String parkingId) async {
    detailsParkingIds.add(parkingId);
    return details;
  }

  @override
  Future<List<ParkingReview>> fetchReviews(String parkingId) async {
    reviewsParkingIds.add(parkingId);
    return reviews;
  }
}

class _FakeFavoriteRepository implements ParkingFavoriteRepository {
  final calls = <({String parkingId, bool isFavorite})>[];
  Object? error;
  Completer<void>? pendingWrite;

  @override
  Future<void> setFavorite({
    required String parkingId,
    required bool isFavorite,
  }) async {
    calls.add((parkingId: parkingId, isFavorite: isFavorite));
    await pendingWrite?.future;
    if (error case final error?) {
      throw error;
    }
  }
}

Widget _buildSubject(
  _FakeRepository repository, {
  ParkingFavoriteRepository? favoriteRepository,
}) =>
    ChangeNotifierProvider.value(
      value: FFAppState(),
      child: MaterialApp(
        localizationsDelegates: const [
          FFLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ru')],
        locale: const Locale('en'),
        theme: ThemeData(brightness: Brightness.light, useMaterial3: false),
        home: Scaffold(
          body: ParkingsDetailsWidget(
            parkingId: 'parking-1',
            detailsRepository: repository,
            favoriteRepository: favoriteRepository,
          ),
        ),
      ),
    );

Widget _buildRoutedSubject(_FakeRepository repository) =>
    ChangeNotifierProvider.value(
      value: FFAppState(),
      child: MaterialApp(
        localizationsDelegates: const [
          FFLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ru')],
        locale: const Locale('en'),
        theme: ThemeData(brightness: Brightness.light, useMaterial3: false),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      body: ParkingsDetailsWidget(
                        parkingId: 'parking-1',
                        detailsRepository: repository,
                      ),
                    ),
                  ),
                ),
                child: const Text('Open details'),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  setUp(FFAppState.reset);

  test('does not intercept vertical drags over the photo gallery', () {
    final source = File(
      'lib/parkings_details/parkings_details/parkings_details_widget.dart',
    ).readAsStringSync();

    expect(
      source,
      isNot(contains('onVerticalDragEnd: (details) async {}')),
    );
    expect(
      source,
      contains('key: ParkingsDetailsWidget.photoGalleryKey'),
    );
  });

  testWidgets('scrolls details when dragging upward over the photo gallery',
      (tester) async {
    final repository = _FakeRepository()
      ..details = const ParkingDetails(
        id: 'parking-1',
        isFavorited: false,
        address: 'Photo drag parking',
        photos: [
          ParkingDetailsPhoto(url: 'https://example.test/parking.jpg'),
        ],
        stars1: 0,
        stars2: 0,
        stars3: 0,
        stars4: 0,
        stars5: 0,
      );

    await tester.pumpWidget(_buildSubject(repository));
    await tester.pumpAndSettle();

    final scrollView = tester.widget<SingleChildScrollView>(
      find.byKey(ParkingsDetailsWidget.scrollViewKey),
    );
    expect(scrollView.controller?.offset, 0.0);

    await tester.drag(
      find.byKey(ParkingsDetailsWidget.photoGalleryKey),
      const Offset(0.0, -180.0),
    );
    await tester.pumpAndSettle();

    expect(scrollView.controller?.offset, greaterThan(0.0));
    expect(find.text('Photo drag parking'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('renders review cards without the legacy Supabase row adapter', () {
    final source = File(
      'lib/parkings_details/reviews_tab/reviews_tab_widget.dart',
    ).readAsStringSync();

    expect(source, contains('ParkingReviewCard'));
    expect(source, isNot(contains('parkingReviewToLegacyRow')));
    expect(source, isNot(contains('legacy_parking_details_adapter')));
    expect(source, isNot(contains('ReviewCardParkingDetailsWidget')));
  });

  test('renders photo tab from the typed parking details model', () {
    final source = File(
      'lib/parkings_details/photos_tab/photos_tab_widget.dart',
    ).readAsStringSync();

    expect(source, contains('ParkingDetails'));
    expect(source, isNot(contains('ViewFullParkingDetailsRow')));
    expect(source, isNot(contains('getJsonField')));
    expect(source, isNot(contains('/backend/supabase/supabase.dart')));
  });

  test('renders info tab from the typed parking details model', () {
    final source = File(
      'lib/parkings_details/info_tab/info_tab_widget.dart',
    ).readAsStringSync();

    expect(source, contains('ParkingDetails'));
    expect(source, isNot(contains('ViewFullParkingDetailsRow')));
    expect(source, isNot(contains('/backend/supabase/supabase.dart')));
  });

  test('keeps the details shell on typed parking details without legacy rows',
      () {
    final source = File(
      'lib/parkings_details/parkings_details/parkings_details_widget.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('parkingDetailsToLegacyRow')));
    expect(source, isNot(contains('legacy_parking_details_adapter')));
    expect(source, isNot(contains('ViewFullParkingDetailsRow')));
    expect(source, isNot(contains('getJsonField')));
  });

  test('renders reviews tab summary from the typed parking details model', () {
    final source = File(
      'lib/parkings_details/reviews_tab/reviews_tab_widget.dart',
    ).readAsStringSync();

    expect(source, contains('ParkingDetails'));
    expect(source, isNot(contains('ViewFullParkingDetailsRow')));
    expect(source, isNot(contains('/backend/supabase/supabase.dart')));
  });

  testWidgets('loads the bottom sheet through the repository boundary',
      (tester) async {
    final repository = _FakeRepository()
      ..details = const ParkingDetails(
        id: 'parking-1',
        isFavorited: true,
        address: 'Test address',
        latitude: 52.1,
        longitude: 21.2,
        totalSpaces: 20,
        rating: 4.5,
        stars1: 0,
        stars2: 0,
        stars3: 0,
        stars4: 0,
        stars5: 1,
        reviewsCount: 3,
        photosCount: 0,
        hasGasStation: false,
        hasShower: false,
        hasLaundry: false,
        hasHotel: false,
        hasShop: false,
        hasRecreationArea: false,
      );

    await tester.pumpWidget(_buildSubject(repository));
    await tester.pumpAndSettle();

    expect(repository.detailsParkingIds, ['parking-1']);
    expect(find.text('Test address'), findsOneWidget);
    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('3 reviews'), findsOneWidget);
    expect(find.byKey(ParkingsDetailsWidget.loadingKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loads reviews lazily when the Reviews tab is opened',
      (tester) async {
    final repository = _FakeRepository()
      ..details = const ParkingDetails(
        id: 'parking-1',
        isFavorited: false,
        address: 'Stable tab parking',
        stars1: 0,
        stars2: 0,
        stars3: 0,
        stars4: 0,
        stars5: 0,
      )
      ..reviews = [
        ParkingReview(
          id: 1,
          parkingId: 'parking-1',
          createdAt: DateTime(2026, 1, 2),
          userId: 'user-1',
          authorName: 'Alex Driver',
          comment: 'Quiet place near the highway.',
          averageScore: 4.0,
        ),
      ];

    await tester.pumpWidget(_buildSubject(repository));
    await tester.pumpAndSettle();
    expect(repository.reviewsParkingIds, isEmpty);
    expect(repository.detailsParkingIds, ['parking-1']);

    await tester.ensureVisible(find.text('Reviews'));
    await tester.tap(find.text('Reviews'));
    await tester.pumpAndSettle();

    expect(repository.reviewsParkingIds, ['parking-1']);
    expect(repository.detailsParkingIds, ['parking-1']);
    expect(find.byKey(ParkingsDetailsWidget.loadingKey), findsNothing);
    expect(find.byKey(ParkingsDetailsWidget.dragHandleKey), findsOneWidget);
    expect(find.text('1  reviews '), findsOneWidget);
    expect(find.text('Alex Driver'), findsOneWidget);
    expect(find.text('Quiet place near the highway.'), findsOneWidget);

    await tester.ensureVisible(find.text('Photo'));
    await tester.tap(find.text('Photo'));
    await tester.pumpAndSettle();

    expect(repository.detailsParkingIds, ['parking-1']);
    expect(find.byKey(ParkingsDetailsWidget.loadingKey), findsNothing);
    expect(find.byKey(ParkingsDetailsWidget.dragHandleKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders a safe empty state for a missing parking',
      (tester) async {
    final repository = _FakeRepository();

    await tester.pumpWidget(_buildSubject(repository));
    await tester.pumpAndSettle();

    expect(find.byKey(ParkingsDetailsWidget.emptyKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the details shell visible while favorite write is pending',
      (tester) async {
    final detailsRepository = _FakeRepository()
      ..details = const ParkingDetails(
        id: 'parking-1',
        isFavorited: false,
        address: 'Stable favorite parking',
        stars1: 0,
        stars2: 0,
        stars3: 0,
        stars4: 0,
        stars5: 0,
      );
    final favoriteRepository = _FakeFavoriteRepository()
      ..pendingWrite = Completer<void>();

    await tester.pumpWidget(
      _buildSubject(
        detailsRepository,
        favoriteRepository: favoriteRepository,
      ),
    );
    await tester.pumpAndSettle();

    final button = find.byKey(ParkingsDetailsWidget.favoriteButtonKey);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();

    expect(
      favoriteRepository.calls,
      [(parkingId: 'parking-1', isFavorite: true)],
    );
    expect(detailsRepository.detailsParkingIds, ['parking-1']);
    expect(
        find.byKey(ParkingsDetailsWidget.favoriteUpdatingKey), findsOneWidget);
    expect(find.byKey(ParkingsDetailsWidget.loadingKey), findsNothing);
    expect(find.text('Stable favorite parking'), findsOneWidget);

    favoriteRepository.pendingWrite!.complete();
    await tester.pumpAndSettle();

    expect(detailsRepository.detailsParkingIds, ['parking-1']);
    expect(find.byKey(ParkingsDetailsWidget.favoriteUpdatingKey), findsNothing);
    expect(find.text('Stable favorite parking'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dismisses only when the drag handle is swiped down',
      (tester) async {
    final repository = _FakeRepository()
      ..details = const ParkingDetails(
        id: 'parking-1',
        isFavorited: false,
        address: 'Gesture test parking',
        stars1: 0,
        stars2: 0,
        stars3: 0,
        stars4: 0,
        stars5: 0,
      );

    await tester.pumpWidget(_buildRoutedSubject(repository));
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();

    final handle = find.byKey(ParkingsDetailsWidget.dragHandleKey);
    expect(handle, findsOneWidget);

    await tester.fling(handle, const Offset(0, -200), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Gesture test parking'), findsOneWidget);

    await tester.ensureVisible(handle);
    await tester.pumpAndSettle();
    await tester.fling(handle, const Offset(0, 200), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Gesture test parking'), findsNothing);
    expect(find.text('Open details'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
