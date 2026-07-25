import '../database.dart';

class PrivateProfilesTable extends SupabaseTable<PrivateProfilesRow> {
  @override
  String get tableName => 'private_profiles';

  @override
  PrivateProfilesRow createRow(Map<String, dynamic> data) =>
      PrivateProfilesRow(data);
}

class PrivateProfilesRow extends SupabaseDataRow {
  PrivateProfilesRow(super.data);

  @override
  SupabaseTable get table => PrivateProfilesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get fullName => getField<String>('full_name');
  set fullName(String? value) => setField<String>('full_name', value);

  String? get avatarUrl => getField<String>('avatar_url');
  set avatarUrl(String? value) => setField<String>('avatar_url', value);

  String? get phone => getField<String>('phone');
  set phone(String? value) => setField<String>('phone', value);

  bool? get isPremium => getField<bool>('is_premium');
  set isPremium(bool? value) => setField<bool>('is_premium', value);

  String? get referralCode => getField<String>('referral_code');
  set referralCode(String? value) => setField<String>('referral_code', value);

  String? get theme => getField<String>('theme');
  set theme(String? value) => setField<String>('theme', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  bool? get isAdmin => getField<bool>('is_admin');
  set isAdmin(bool? value) => setField<bool>('is_admin', value);

  String? get referredById => getField<String>('referred_by_id');
  set referredById(String? value) => setField<String>('referred_by_id', value);

  String? get lastDeviceId => getField<String>('last_device_id');
  set lastDeviceId(String? value) => setField<String>('last_device_id', value);
}
