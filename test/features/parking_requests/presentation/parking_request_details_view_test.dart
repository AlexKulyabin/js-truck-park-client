import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/parking_requests/domain/parking_request_details.dart';
import 'package:j_s_truck_park/features/parking_requests/domain/parking_request_details_repository.dart';
import 'package:j_s_truck_park/features/parking_requests/domain/parking_request_summary.dart';
import 'package:j_s_truck_park/features/parking_requests/presentation/parking_request_details_view.dart';
import 'package:j_s_truck_park/flutter_flow/internationalization.dart';

class _FakeRepository implements ParkingRequestDetailsRepository {
  List<ParkingRequestPhoto> photos = [];
  int reviewCount = 0;

  @override
  Future<List<ParkingRequestPhoto>> fetchPhotos(String parkingId) async =>
      photos;

  @override
  Future<int> fetchReviewCount(String parkingId) async => reviewCount;
}

Widget _buildSubject({
  required ParkingRequestSummary request,
  required ParkingRequestDetailsRepository repository,
  ThemeMode themeMode = ThemeMode.light,
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
      theme: ThemeData(brightness: Brightness.light, useMaterial3: false),
      darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: false),
      themeMode: themeMode,
      home: ParkingRequestDetailsView(
        request: request,
        repository: repository,
      ),
    );

void main() {
  testWidgets('preserves pending details, geometry and service labels',
      (tester) async {
    final repository = _FakeRepository()..reviewCount = 2;
    const request = ParkingRequestSummary(
      id: 'parking-1',
      status: ParkingRequestStatus.pending,
      address: 'Test address',
      totalSpaces: 12,
      rating: 4.5,
      hasGasStation: true,
      hasShower: true,
    );

    await tester.pumpWidget(
      _buildSubject(request: request, repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Request under moderation'), findsOneWidget);
    expect(find.text('Test address'), findsOneWidget);
    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('2 reviews'), findsOneWidget);
    expect(find.text('Capacity'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Additional services'), findsOneWidget);
    expect(find.text('Gas station'), findsOneWidget);
    expect(find.text('Shower'), findsOneWidget);
    expect(find.text('Laundry'), findsNothing);
    expect(
      tester.getSize(find.byKey(ParkingRequestDetailsView.addressKey)).height,
      72.0,
    );
    expect(
      tester
          .getSize(find.byKey(ParkingRequestDetailsView.photosEmptyKey))
          .height,
      194.0,
    );
  });

  testWidgets('accepted details omit the status banner', (tester) async {
    await tester.pumpWidget(
      _buildSubject(
        request: const ParkingRequestSummary(
          id: 'parking-1',
          status: ParkingRequestStatus.approved,
        ),
        repository: _FakeRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(ParkingRequestDetailsView.statusBannerKey),
      findsNothing,
    );
    expect(find.text('Capacity'), findsOneWidget);
  });

  testWidgets('rejected details preserve the rejected status banner',
      (tester) async {
    await tester.pumpWidget(
      _buildSubject(
        request: const ParkingRequestSummary(
          id: 'parking-1',
          status: ParkingRequestStatus.rejected,
        ),
        repository: _FakeRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Request was rejected\nIncomplete information'),
      findsOneWidget,
    );
    expect(
      find.byKey(ParkingRequestDetailsView.statusBannerKey),
      findsOneWidget,
    );
  });

  testWidgets('renders in dark mode without an exception', (tester) async {
    await tester.pumpWidget(
      _buildSubject(
        themeMode: ThemeMode.dark,
        request: const ParkingRequestSummary(
          id: 'parking-1',
          status: ParkingRequestStatus.pending,
        ),
        repository: _FakeRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ParkingRequestDetailsView), findsOneWidget);
  });
}
