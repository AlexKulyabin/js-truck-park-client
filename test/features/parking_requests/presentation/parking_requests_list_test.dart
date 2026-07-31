import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/parking_requests/application/parking_requests_controller.dart';
import 'package:j_s_truck_park/features/parking_requests/domain/parking_request_summary.dart';
import 'package:j_s_truck_park/features/parking_requests/domain/parking_requests_repository.dart';
import 'package:j_s_truck_park/features/parking_requests/presentation/parking_request_card.dart';
import 'package:j_s_truck_park/features/parking_requests/presentation/parking_requests_list.dart';
import 'package:j_s_truck_park/flutter_flow/internationalization.dart';

Widget _buildSubject({
  required ParkingRequestsState state,
  ValueChanged<ParkingRequestSummary>? onSelected,
  VoidCallback? onRetry,
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
      home: Scaffold(
        body: ParkingRequestsList(
          state: state,
          onRequestSelected: onSelected ?? (_) {},
          onRetry: onRetry ?? () {},
        ),
      ),
    );

void main() {
  testWidgets('preserves the generated loading indicator geometry',
      (tester) async {
    await tester.pumpWidget(
      _buildSubject(
        state: const ParkingRequestsState(
          status: ParkingRequestStatus.pending,
          phase: ParkingRequestsLoadPhase.loading,
          requests: [],
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(ParkingRequestsList.loadingKey)),
      const Size(50.0, 50.0),
    );
  });

  testWidgets('renders a typed request with the existing card geometry',
      (tester) async {
    const request = ParkingRequestSummary(
      id: 'parking-1',
      status: ParkingRequestStatus.pending,
      address: 'Test address',
    );
    await tester.pumpWidget(
      _buildSubject(
        state: const ParkingRequestsState(
          status: ParkingRequestStatus.pending,
          phase: ParkingRequestsLoadPhase.loaded,
          requests: [request],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Under moderation'), findsOneWidget);
    expect(find.text('Test address'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(ParkingRequestCard.cardKey)).height,
      55.0,
    );
  });

  testWidgets('reports the selected typed request', (tester) async {
    const request = ParkingRequestSummary(
      id: 'parking-1',
      status: ParkingRequestStatus.approved,
      address: 'Test address',
    );
    ParkingRequestSummary? selected;
    await tester.pumpWidget(
      _buildSubject(
        state: const ParkingRequestsState(
          status: ParkingRequestStatus.approved,
          phase: ParkingRequestsLoadPhase.loaded,
          requests: [request],
        ),
        onSelected: (request) => selected = request,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ParkingRequestCard.cardKey));
    await tester.pump();

    expect(selected, request);
  });

  testWidgets('keeps the existing empty message for each status',
      (tester) async {
    const expectations = {
      ParkingRequestStatus.pending:
          'Applications awaiting moderation will \nbe shown here',
      ParkingRequestStatus.approved: 'Approved applications will be shown here',
      ParkingRequestStatus.rejected: 'Rejected applications will be shown here',
    };

    for (final entry in expectations.entries) {
      await tester.pumpWidget(
        _buildSubject(
          state: ParkingRequestsState(
            status: entry.key,
            phase: ParkingRequestsLoadPhase.loaded,
            requests: const [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(ParkingRequestsList.emptyKey), findsOneWidget);
      expect(find.text(entry.value), findsOneWidget);
    }
  });

  testWidgets('does not render a raw failure and allows a retry tap',
      (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      _buildSubject(
        state: const ParkingRequestsState(
          status: ParkingRequestStatus.pending,
          phase: ParkingRequestsLoadPhase.failure,
          requests: [],
          failureKind: ParkingRequestsFailureKind.unavailable,
        ),
        onRetry: () => retries++,
      ),
    );

    expect(find.textContaining('backend'), findsNothing);
    await tester.tap(find.byKey(ParkingRequestsList.failureKey));
    await tester.pump();
    expect(retries, 1);
  });

  testWidgets('renders the card in dark mode without an exception',
      (tester) async {
    await tester.pumpWidget(
      _buildSubject(
        themeMode: ThemeMode.dark,
        state: const ParkingRequestsState(
          status: ParkingRequestStatus.rejected,
          phase: ParkingRequestsLoadPhase.loaded,
          requests: [
            ParkingRequestSummary(
              id: 'parking-1',
              status: ParkingRequestStatus.rejected,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Rejected'), findsOneWidget);
  });
}
