import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/parking_requests/domain/parking_request_summary.dart';
import 'package:j_s_truck_park/features/parking_requests/domain/parking_requests_repository.dart';
import 'package:j_s_truck_park/flutter_flow/internationalization.dart';
import 'package:j_s_truck_park/requests/requests/requests_widget.dart';

class _FakeRepository implements ParkingRequestsRepository {
  final calls = <({String userId, ParkingRequestStatus status})>[];

  @override
  Future<List<ParkingRequestSummary>> fetchOwnedRequests({
    required String userId,
    required ParkingRequestStatus status,
  }) async {
    calls.add((userId: userId, status: status));
    return [];
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
      home: RequestsWidget(
        repository: repository,
        userId: 'user-1',
      ),
    );

void main() {
  test('keeps the public route contract', () {
    expect(RequestsWidget.routeName, 'Requests');
    expect(RequestsWidget.routePath, '/requests');
  });

  testWidgets('loads all tabs through the injected repository boundary',
      (tester) async {
    final repository = _FakeRepository();
    await tester.pumpWidget(_buildSubject(repository));
    await tester.pumpAndSettle();

    expect(
      repository.calls,
      [(userId: 'user-1', status: ParkingRequestStatus.pending)],
    );

    await tester.tap(find.text('Accepted'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rejected'));
    await tester.pumpAndSettle();

    expect(
      repository.calls,
      [
        (userId: 'user-1', status: ParkingRequestStatus.pending),
        (userId: 'user-1', status: ParkingRequestStatus.approved),
        (userId: 'user-1', status: ParkingRequestStatus.rejected),
      ],
    );
    expect(tester.takeException(), isNull);
  });
}
