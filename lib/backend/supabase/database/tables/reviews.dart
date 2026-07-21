import '../database.dart';

class ReviewsTable extends SupabaseTable<ReviewsRow> {
  @override
  String get tableName => 'reviews';

  @override
  ReviewsRow createRow(Map<String, dynamic> data) => ReviewsRow(data);
}

class ReviewsRow extends SupabaseDataRow {
  ReviewsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ReviewsTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String get parkingId => getField<String>('parking_id')!;
  set parkingId(String value) => setField<String>('parking_id', value);

  String? get comment => getField<String>('comment');
  set comment(String? value) => setField<String>('comment', value);

  int get ratingImpression => getField<int>('rating_impression')!;
  set ratingImpression(int value) => setField<int>('rating_impression', value);

  int get ratingArrival => getField<int>('rating_arrival')!;
  set ratingArrival(int value) => setField<int>('rating_arrival', value);

  int get ratingSecurity => getField<int>('rating_security')!;
  set ratingSecurity(int value) => setField<int>('rating_security', value);

  int get ratingInfrastructure => getField<int>('rating_infrastructure')!;
  set ratingInfrastructure(int value) =>
      setField<int>('rating_infrastructure', value);

  int get ratingComfort => getField<int>('rating_comfort')!;
  set ratingComfort(int value) => setField<int>('rating_comfort', value);

  double? get averageScore => getField<double>('average_score');
  set averageScore(double? value) => setField<double>('average_score', value);
}
