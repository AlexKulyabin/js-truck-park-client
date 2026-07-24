import '/backend/supabase/database/database.dart';
import '/core/config/app_config.dart';

class ReportCreateException implements Exception {
  const ReportCreateException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CreateReportRequest {
  const CreateReportRequest({
    required this.parkingId,
    required this.userId,
    required this.comment,
    required this.status,
    required this.report,
    required this.createdAt,
  });

  final String? parkingId;
  final String userId;
  final String? comment;
  final String status;
  final String? report;
  final DateTime createdAt;
}

class CreatedReport {
  const CreatedReport({
    required this.id,
    required this.parkingId,
    required this.userId,
    required this.comment,
    required this.status,
    required this.report,
    required this.createdAt,
  });

  factory CreatedReport.fromRow(ReportsRow row) {
    return CreatedReport(
      id: row.id,
      parkingId: row.parkingId,
      userId: row.userId,
      comment: row.comment,
      status: row.status,
      report: row.report,
      createdAt: row.createdAt,
    );
  }

  final int id;
  final String? parkingId;
  final String? userId;
  final String? comment;
  final String? status;
  final String? report;
  final DateTime? createdAt;
}

abstract interface class ReportsGateway {
  Future<CreatedReport> createReport({
    required CreateReportRequest request,
  });

  Future<List<UserReport>> listUserReports({
    required String userId,
  });
}

class SupabaseReportsGateway implements ReportsGateway {
  SupabaseReportsGateway({
    ReportsTable? table,
    ViewReportsDetailedTable? reportsView,
  })  : _table = table ?? ReportsTable(),
        _reportsView = reportsView ?? ViewReportsDetailedTable();

  final ReportsTable _table;
  final ViewReportsDetailedTable _reportsView;

  @override
  Future<CreatedReport> createReport({
    required CreateReportRequest request,
  }) async {
    final row = await _table.insert({
      'parking_id': request.parkingId,
      'comment': request.comment,
      'user_id': request.userId,
      'status': request.status,
      'report': request.report,
      'created_at': supaSerialize<DateTime>(request.createdAt),
    });
    return CreatedReport.fromRow(row);
  }

  @override
  Future<List<UserReport>> listUserReports({
    required String userId,
  }) async {
    final rows = await _reportsView.queryRows(
      queryFn: (q) => q
          .eqOrNull(
            'reporter_id',
            userId,
          )
          .order('report_date'),
    );
    return rows.map(UserReport.fromRow).toList();
  }
}

class ReportsService {
  ReportsService({
    ReportsGateway? gateway,
    AppConfig? config,
  })  : _gateway = gateway ?? SupabaseReportsGateway(),
        _config = config ?? AppConfig.current;

  final ReportsGateway _gateway;
  final AppConfig _config;

  Future<CreatedReport> createReport(CreateReportRequest request) async {
    if (!_config.canPerformWrite(AppWriteOperation.reportCreate)) {
      throw const ReportCreateException(
        'Report creation is disabled for this build.',
      );
    }

    final normalizedParkingId = request.parkingId?.trim();
    final normalizedUserId = request.userId.trim();
    final normalizedStatus = request.status.trim();
    final normalizedReport = request.report?.trim();
    if (normalizedParkingId == null ||
        normalizedParkingId.isEmpty ||
        normalizedUserId.isEmpty ||
        normalizedStatus.isEmpty ||
        normalizedReport == null ||
        normalizedReport.isEmpty) {
      throw const ReportCreateException(
        'Sign in again before creating a report.',
      );
    }

    return _gateway.createReport(
      request: CreateReportRequest(
        parkingId: normalizedParkingId,
        userId: normalizedUserId,
        comment: request.comment,
        status: normalizedStatus,
        report: normalizedReport,
        createdAt: request.createdAt,
      ),
    );
  }

  Future<List<UserReport>> listUserReports({
    required String? userId,
  }) async {
    final normalizedUserId = userId?.trim();
    if (normalizedUserId == null || normalizedUserId.isEmpty) {
      return const [];
    }

    return _gateway.listUserReports(userId: normalizedUserId);
  }
}

class UserReport {
  const UserReport({
    required this.reportId,
    required this.reporterId,
    required this.reportDate,
    required this.reportType,
    required this.reportComment,
    required this.parkingId,
    required this.parkingAddress,
    required this.parkingPhotos,
    required this.photosCount,
    required this.reporterName,
    required this.reporterPhone,
  });

  factory UserReport.fromRow(ViewReportsDetailedRow row) {
    return UserReport(
      reportId: row.reportId,
      reporterId: row.reporterId,
      reportDate: row.reportDate,
      reportType: row.reportType,
      reportComment: row.reportComment,
      parkingId: row.parkingId,
      parkingAddress: row.parkingAddress,
      parkingPhotos: row.parkingPhotos,
      photosCount: row.photosCount,
      reporterName: row.reporterName,
      reporterPhone: row.reporterPhone,
    );
  }

  final int? reportId;
  final String? reporterId;
  final DateTime? reportDate;
  final String? reportType;
  final String? reportComment;
  final String? parkingId;
  final String? parkingAddress;
  final dynamic parkingPhotos;
  final int? photosCount;
  final String? reporterName;
  final String? reporterPhone;
}
