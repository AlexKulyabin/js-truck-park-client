import '../database.dart';

class ReferralStatsTable extends SupabaseTable<ReferralStatsRow> {
  @override
  String get tableName => 'referral_stats';

  @override
  ReferralStatsRow createRow(Map<String, dynamic> data) =>
      ReferralStatsRow(data);
}

class ReferralStatsRow extends SupabaseDataRow {
  ReferralStatsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ReferralStatsTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get referrerId => getField<String>('referrer_id');
  set referrerId(String? value) => setField<String>('referrer_id', value);

  String? get refereeId => getField<String>('referee_id');
  set refereeId(String? value) => setField<String>('referee_id', value);

  String? get deviceId => getField<String>('device_id');
  set deviceId(String? value) => setField<String>('device_id', value);

  String? get ipAddress => getField<String>('ip_address');
  set ipAddress(String? value) => setField<String>('ip_address', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
