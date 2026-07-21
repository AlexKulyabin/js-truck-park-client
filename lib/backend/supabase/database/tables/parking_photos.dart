import '../database.dart';

class ParkingPhotosTable extends SupabaseTable<ParkingPhotosRow> {
  @override
  String get tableName => 'parking_photos';

  @override
  ParkingPhotosRow createRow(Map<String, dynamic> data) =>
      ParkingPhotosRow(data);
}

class ParkingPhotosRow extends SupabaseDataRow {
  ParkingPhotosRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ParkingPhotosTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String get url => getField<String>('url')!;
  set url(String value) => setField<String>('url', value);

  String get parkingId => getField<String>('parking_id')!;
  set parkingId(String value) => setField<String>('parking_id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  int? get reviewId => getField<int>('review_id');
  set reviewId(int? value) => setField<int>('review_id', value);
}
