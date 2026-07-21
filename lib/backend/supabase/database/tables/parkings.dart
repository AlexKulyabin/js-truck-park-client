import '../database.dart';

class ParkingsTable extends SupabaseTable<ParkingsRow> {
  @override
  String get tableName => 'parkings';

  @override
  ParkingsRow createRow(Map<String, dynamic> data) => ParkingsRow(data);
}

class ParkingsRow extends SupabaseDataRow {
  ParkingsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ParkingsTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get address => getField<String>('address');
  set address(String? value) => setField<String>('address', value);

  double? get latitude => getField<double>('latitude');
  set latitude(double? value) => setField<double>('latitude', value);

  double? get longitude => getField<double>('longitude');
  set longitude(double? value) => setField<double>('longitude', value);

  String? get parkingType => getField<String>('parking_type');
  set parkingType(String? value) => setField<String>('parking_type', value);

  int? get totalSpaces => getField<int>('total_spaces');
  set totalSpaces(int? value) => setField<int>('total_spaces', value);

  double? get price => getField<double>('price');
  set price(double? value) => setField<double>('price', value);

  bool? get isFree => getField<bool>('is_free');
  set isFree(bool? value) => setField<bool>('is_free', value);

  bool? get hasGasStation => getField<bool>('has_gas_station');
  set hasGasStation(bool? value) => setField<bool>('has_gas_station', value);

  bool? get hasShower => getField<bool>('has_shower');
  set hasShower(bool? value) => setField<bool>('has_shower', value);

  bool? get hasLaundry => getField<bool>('has_laundry');
  set hasLaundry(bool? value) => setField<bool>('has_laundry', value);

  bool? get hasHotel => getField<bool>('has_hotel');
  set hasHotel(bool? value) => setField<bool>('has_hotel', value);

  bool? get hasShop => getField<bool>('has_shop');
  set hasShop(bool? value) => setField<bool>('has_shop', value);

  bool? get hasRecreationArea => getField<bool>('has_recreation_area');
  set hasRecreationArea(bool? value) =>
      setField<bool>('has_recreation_area', value);

  double? get rating => getField<double>('rating');
  set rating(double? value) => setField<double>('rating', value);

  int? get stars1 => getField<int>('stars_1');
  set stars1(int? value) => setField<int>('stars_1', value);

  int? get stars2 => getField<int>('stars_2');
  set stars2(int? value) => setField<int>('stars_2', value);

  int? get stars3 => getField<int>('stars_3');
  set stars3(int? value) => setField<int>('stars_3', value);

  int? get stars4 => getField<int>('stars_4');
  set stars4(int? value) => setField<int>('stars_4', value);

  int? get stars5 => getField<int>('stars_5');
  set stars5(int? value) => setField<int>('stars_5', value);

  String? get createdBy => getField<String>('created_by');
  set createdBy(String? value) => setField<String>('created_by', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get addressLower => getField<String>('address_lower');
  set addressLower(String? value) => setField<String>('address_lower', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  List<String> get photos => getListField<String>('photos');
  set photos(List<String>? value) => setListField<String>('photos', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  String? get adminComment => getField<String>('admin_comment');
  set adminComment(String? value) => setField<String>('admin_comment', value);

  String? get location => getField<String>('location');
  set location(String? value) => setField<String>('location', value);

  int? get reviewsCount => getField<int>('reviews_count');
  set reviewsCount(int? value) => setField<int>('reviews_count', value);

  String? get rejectionReason => getField<String>('rejection_reason');
  set rejectionReason(String? value) =>
      setField<String>('rejection_reason', value);
}
