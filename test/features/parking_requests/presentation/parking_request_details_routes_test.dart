import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/backend/supabase/database/tables/parkings.dart';
import 'package:j_s_truck_park/features/parking_requests/domain/parking_request_details.dart';
import 'package:j_s_truck_park/features/parking_requests/domain/parking_request_details_repository.dart';
import 'package:j_s_truck_park/flutter_flow/internationalization.dart';
import 'package:j_s_truck_park/requests/accepted_parking/accepted_parking_widget.dart';
import 'package:j_s_truck_park/requests/moderation_parking/moderation_parking_widget.dart';
import 'package:j_s_truck_park/requests/rejected_parking/rejected_parking_widget.dart';

class _FakeRepository implements ParkingRequestDetailsRepository {
  @override
  Future<List<ParkingRequestPhoto>> fetchPhotos(String parkingId) async => [];

  @override
  Future<int> fetchReviewCount(String parkingId) async => 0;
}

Widget _app(Widget home) => MaterialApp(
      localizationsDelegates: const [
        FFLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ru')],
      locale: const Locale('en'),
      theme: ThemeData(brightness: Brightness.light, useMaterial3: false),
      home: home,
    );

void main() {
  test('keeps all public route contracts and compatibility parameter types',
      () {
    expect(ModerationParkingWidget.routeName, 'ModerationParking');
    expect(ModerationParkingWidget.routePath, '/moderationParking');
    expect(AcceptedParkingWidget.routeName, 'AcceptedParking');
    expect(AcceptedParkingWidget.routePath, '/acceptedParking');
    expect(RejectedParkingWidget.routeName, 'RejectedParking');
    expect(RejectedParkingWidget.routePath, '/rejectedParking');

    final row = ParkingsRow({'id': 'parking-1'});
    expect(
      ModerationParkingWidget(parkingRow: row).parkingRow,
      isA<ParkingsRow>(),
    );
    expect(AcceptedParkingWidget(parkingRow: row), isA<StatelessWidget>());
    expect(RejectedParkingWidget(parkingRow: row), isA<StatelessWidget>());
  });

  testWidgets('wrappers map their route status into the shared view',
      (tester) async {
    final row = ParkingsRow({
      'id': 'parking-1',
      'address': 'Test address',
      'has_gas_station': false,
      'has_shower': false,
      'has_laundry': false,
      'has_hotel': false,
      'has_shop': false,
      'has_recreation_area': false,
    });
    final repository = _FakeRepository();

    await tester.pumpWidget(
      _app(
        ModerationParkingWidget(
          parkingRow: row,
          detailsRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Request under moderation'), findsOneWidget);

    await tester.pumpWidget(
      _app(
        AcceptedParkingWidget(
          parkingRow: row,
          detailsRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Request under moderation'), findsNothing);

    await tester.pumpWidget(
      _app(
        RejectedParkingWidget(
          parkingRow: row,
          detailsRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Request was rejected\nIncomplete information'),
      findsOneWidget,
    );
  });
}
