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
}

class SupabaseReportsGateway implements ReportsGateway {
  SupabaseReportsGateway({
    ReportsTable? table,
  }) : _table = table ?? ReportsTable();

  final ReportsTable _table;

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
}
