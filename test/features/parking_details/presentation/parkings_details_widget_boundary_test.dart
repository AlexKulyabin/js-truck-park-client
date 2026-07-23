import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/app_state.dart';
import 'package:j_s_truck_park/features/parking_details/domain/parking_details.dart';
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

Widget _buildSubject(_FakeRepository repository) =>
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
          ),
        ),
      ),
    );

void main() {
  setUp(FFAppState.reset);

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
        stars1: 0,
        stars2: 0,
        stars3: 0,
        stars4: 0,
        stars5: 0,
      );

    await tester.pumpWidget(_buildSubject(repository));
    await tester.pumpAndSettle();
    expect(repository.reviewsParkingIds, isEmpty);

    await tester.ensureVisible(find.text('Reviews'));
    await tester.tap(find.text('Reviews'));
    await tester.pumpAndSettle();

    expect(repository.reviewsParkingIds, ['parking-1']);
    expect(find.text('There are no reviews yet'), findsOneWidget);
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
}
