import '/backend/supabase/database/database.dart';

abstract interface class UserProfileGateway {
  Future<List<UserProfile>> listProfilesByUserId({
    required String userId,
  });
}

class SupabaseUserProfileGateway implements UserProfileGateway {
  SupabaseUserProfileGateway({
    UsersTable? usersTable,
  }) : _usersTable = usersTable ?? UsersTable();

  final UsersTable _usersTable;

  @override
  Future<List<UserProfile>> listProfilesByUserId({
    required String userId,
  }) async {
    final rows = await _usersTable.queryRows(
      queryFn: (q) => q.eqOrNull(
        'id',
        userId,
      ),
    );
    return rows.map(UserProfile.fromRow).toList();
  }
}

class UserProfileService {
  UserProfileService({
    UserProfileGateway? gateway,
  }) : _gateway = gateway ?? SupabaseUserProfileGateway();

  final UserProfileGateway _gateway;

  Future<List<UserProfile>> listProfilesByUserId({
    required String? userId,
  }) async {
    final normalizedUserId = userId?.trim();
    if (normalizedUserId == null || normalizedUserId.isEmpty) {
      return const [];
    }

    return _gateway.listProfilesByUserId(userId: normalizedUserId);
  }

  Future<UserProfile?> getProfileByUserId({
    required String? userId,
  }) async {
    final profiles = await listProfilesByUserId(userId: userId);
    return profiles.isEmpty ? null : profiles.first;
  }

  Future<bool> hasCompletedProfile({
    required String? userId,
  }) async {
    final profile = await getProfileByUserId(userId: userId);
    return profile?.hasCompletedProfile ?? false;
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.avatarUrl,
    required this.phone,
    required this.isPremium,
    required this.referralCode,
    required this.theme,
    required this.status,
    required this.isAdmin,
  });

  factory UserProfile.fromRow(UsersRow row) {
    return UserProfile(
      id: row.id,
      fullName: row.fullName,
      avatarUrl: row.avatarUrl,
      phone: row.phone,
      isPremium: row.isPremium,
      referralCode: row.referralCode,
      theme: row.theme,
      status: row.status,
      isAdmin: row.isAdmin,
    );
  }

  final String id;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final bool? isPremium;
  final String? referralCode;
  final String? theme;
  final String? status;
  final bool? isAdmin;

  bool get hasCompletedProfile => fullName != null && fullName!.isNotEmpty;
}
