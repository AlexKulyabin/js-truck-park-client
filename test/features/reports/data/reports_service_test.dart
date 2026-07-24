import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/reports/data/reports_service.dart';

void main() {
  group('ReportsService', () {
    test('rejects incomplete identifiers without writing', () async {
      final gateway = _FakeReportsGateway();
      final service = ReportsService(gateway: gateway);

      expect(
        service.createReport(
          CreateReportRequest(
            parkingId: ' ',
            userId: 'user-1',
            comment: 'Comment',
            status: 'approved',
            report: 'Report1',
            createdAt: DateTime(2026, 1, 1),
          ),
        ),
        throwsA(isA<ReportCreateException>()),
      );
      expect(gateway.requests, isEmpty);
    });

    test('rejects missing report type without writing', () async {
      final gateway = _FakeReportsGateway();
      final service = ReportsService(gateway: gateway);

      expect(
        service.createReport(
          CreateReportRequest(
            parkingId: 'parking-1',
            userId: 'user-1',
            comment: 'Comment',
            status: 'approved',
            report: null,
            createdAt: DateTime(2026, 1, 1),
          ),
        ),
        throwsA(isA<ReportCreateException>()),
      );
      expect(gateway.requests, isEmpty);
    });

    test('creates report with normalized owner and parking ids', () async {
      final gateway = _FakeReportsGateway();
      final service = ReportsService(gateway: gateway);
      final createdAt = DateTime(2026, 1, 1, 12);

      final result = await service.createReport(
        CreateReportRequest(
          parkingId: ' parking-1 ',
          userId: ' user-1 ',
          comment: 'Comment',
          status: ' approved ',
          report: ' Report2 ',
          createdAt: createdAt,
        ),
      );

      expect(result.id, 1);
      expect(gateway.requests.single.parkingId, 'parking-1');
      expect(gateway.requests.single.userId, 'user-1');
      expect(gateway.requests.single.status, 'approved');
      expect(gateway.requests.single.report, 'Report2');
      expect(gateway.requests.single.createdAt, createdAt);
    });

    test('returns empty user reports without querying when user id is empty',
        () async {
      final gateway = _FakeReportsGateway();
      final service = ReportsService(gateway: gateway);

      final result = await service.listUserReports(userId: null);

      expect(result, isEmpty);
      expect(gateway.reportUserIds, isEmpty);
    });

    test('loads user reports for normalized user id', () async {
      final gateway = _FakeReportsGateway(
        reports: [
          UserReport(
            reportId: 1,
            reporterId: 'user-1',
            reportDate: DateTime(2026, 1, 1),
            reportType: 'Report1',
            reportComment: 'Missing',
            parkingId: 'parking-1',
            parkingAddress: 'Address 1',
            parkingPhotos: const ['https://example.test/parking.jpg'],
            photosCount: 1,
            reporterName: 'Driver',
            reporterPhone: '+1',
          ),
        ],
      );
      final service = ReportsService(gateway: gateway);

      final result = await service.listUserReports(userId: ' user-1 ');

      expect(result.single.parkingAddress, 'Address 1');
      expect(gateway.reportUserIds, [
        'user-1',
      ]);
    });
  });
}

class _FakeReportsGateway implements ReportsGateway {
  _FakeReportsGateway({
    this.reports = const [],
  });

  final List<UserReport> reports;
  final requests = <CreateReportRequest>[];
  final reportUserIds = <String>[];

  @override
  Future<CreatedReport> createReport({
    required CreateReportRequest request,
  }) async {
    requests.add(request);
    return CreatedReport(
      id: 1,
      parkingId: request.parkingId,
      userId: request.userId,
      comment: request.comment,
      status: request.status,
      report: request.report,
      createdAt: request.createdAt,
    );
  }

  @override
  Future<List<UserReport>> listUserReports({
    required String userId,
  }) async {
    reportUserIds.add(userId);
    return reports;
  }
}
