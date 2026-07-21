import '../database.dart';

class ViewReportsDetailedTable extends SupabaseTable<ViewReportsDetailedRow> {
  @override
  String get tableName => 'view_reports_detailed';

  @override
  ViewReportsDetailedRow createRow(Map<String, dynamic> data) =>
      ViewReportsDetailedRow(data);
}

class ViewReportsDetailedRow extends SupabaseDataRow {
  ViewReportsDetailedRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ViewReportsDetailedTable();

  int? get reportId => getField<int>('report_id');
  set reportId(int? value) => setField<int>('report_id', value);

  String? get reporterId => getField<String>('reporter_id');
  set reporterId(String? value) => setField<String>('reporter_id', value);

  DateTime? get reportDate => getField<DateTime>('report_date');
  set reportDate(DateTime? value) => setField<DateTime>('report_date', value);

  String? get reportType => getField<String>('report_type');
  set reportType(String? value) => setField<String>('report_type', value);

  String? get reportComment => getField<String>('report_comment');
  set reportComment(String? value) => setField<String>('report_comment', value);

  String? get parkingId => getField<String>('parking_id');
  set parkingId(String? value) => setField<String>('parking_id', value);

  String? get parkingAddress => getField<String>('parking_address');
  set parkingAddress(String? value) =>
      setField<String>('parking_address', value);

  dynamic? get parkingPhotos => getField<dynamic>('parking_photos');
  set parkingPhotos(dynamic? value) =>
      setField<dynamic>('parking_photos', value);

  int? get photosCount => getField<int>('photos_count');
  set photosCount(int? value) => setField<int>('photos_count', value);

  String? get reporterName => getField<String>('reporter_name');
  set reporterName(String? value) => setField<String>('reporter_name', value);

  String? get reporterPhone => getField<String>('reporter_phone');
  set reporterPhone(String? value) => setField<String>('reporter_phone', value);
}
