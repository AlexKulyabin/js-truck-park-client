import '../database.dart';

class ViewUserFavoritesTable extends SupabaseTable<ViewUserFavoritesRow> {
  @override
  String get tableName => 'view_user_favorites';

  @override
  ViewUserFavoritesRow createRow(Map<String, dynamic> data) =>
      ViewUserFavoritesRow(data);
}

class ViewUserFavoritesRow extends SupabaseDataRow {
  ViewUserFavoritesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ViewUserFavoritesTable();

  int? get favoriteRecordId => getField<int>('favorite_record_id');
  set favoriteRecordId(int? value) =>
      setField<int>('favorite_record_id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get parkingId => getField<String>('parking_id');
  set parkingId(String? value) => setField<String>('parking_id', value);

  String? get address => getField<String>('address');
  set address(String? value) => setField<String>('address', value);

  double? get latitude => getField<double>('latitude');
  set latitude(double? value) => setField<double>('latitude', value);

  double? get longitude => getField<double>('longitude');
  set longitude(double? value) => setField<double>('longitude', value);

  double? get rating => getField<double>('rating');
  set rating(double? value) => setField<double>('rating', value);

  int? get reviewsCount => getField<int>('reviews_count');
  set reviewsCount(int? value) => setField<int>('reviews_count', value);

  dynamic? get photos => getField<dynamic>('photos');
  set photos(dynamic? value) => setField<dynamic>('photos', value);
}
