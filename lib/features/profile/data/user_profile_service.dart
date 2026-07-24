import '/backend/supabase/database/database.dart';
import '/core/config/app_config.dart';

enum UserProfileUpdateFailure {
  disabled,
  invalidIdentity,
  invalidAvatar,
  missingGateway,
}

class UserProfileUpdateException implements Exception {
  const UserProfileUpdateException({
    required this.failure,
    required this.message,
  });

  final UserProfileUpdateFailure failure;
  final String message;

  @override
  String toString() => message;
}

class UpdateUserProfileCommand {
  const UpdateUserProfileCommand({
    required this.userId,
    required this.fullName,
    required this.updatedAt,
    this.avatar,
  });

  final String? userId;
  final String fullName;
  final DateTime updatedAt;
  final UserAvatarDraft? avatar;
}

class UserAvatarDraft {
  const UserAvatarDraft({
    required this.fileName,
    required this.byteLength,
    this.mimeType,
  });

  final String fileName;
  final int byteLength;
  final String? mimeType;
}

class PreparedUserProfileUpdate {
  const PreparedUserProfileUpdate({
    required this.userId,
    required this.fullName,
    required this.updatedAt,
    required this.avatar,
  });

  final String userId;
  final String fullName;
  final DateTime updatedAt;
  final UserAvatarDraft? avatar;

  bool get requiresAvatarHandling => avatar != null;
}

abstract interface class UserProfileGateway {
  Future<List<PublicUserProfile>> listPublicProfilesByUserId({
    required String userId,
  });

  Future<List<PrivateUserProfile>> listPrivateProfilesByUserId({
    required String userId,
  });
}

abstract interface class UserProfileUpdateGateway {
  // Implementations must update the user row and avatar object as one
  // server-owned operation, or compensate every completed step before failing.
  Future<PrivateUserProfile> updateProfileAtomically({
    required PreparedUserProfileUpdate update,
  });
}

class SupabaseUserProfileGateway implements UserProfileGateway {
  SupabaseUserProfileGateway({
    PublicProfilesTable? publicProfilesTable,
    PrivateProfilesTable? privateProfilesTable,
  })  : _publicProfilesTable = publicProfilesTable ?? PublicProfilesTable(),
        _privateProfilesTable = privateProfilesTable ?? PrivateProfilesTable();

  final PublicProfilesTable _publicProfilesTable;
  final PrivateProfilesTable _privateProfilesTable;

  @override
  Future<List<PublicUserProfile>> listPublicProfilesByUserId({
    required String userId,
  }) async {
    final rows = await _publicProfilesTable.querySingleRow(
      queryFn: (q) => q.eqOrNull(
        'id',
        userId,
      ),
    );
    return rows.map(PublicUserProfile.fromRow).toList();
  }

  @override
  Future<List<PrivateUserProfile>> listPrivateProfilesByUserId({
    required String userId,
  }) async {
    final rows = await _privateProfilesTable.querySingleRow(
      queryFn: (q) => q.eqOrNull(
        'id',
        userId,
      ),
    );
    return rows.map(PrivateUserProfile.fromRow).toList();
  }
}

class UserProfileService {
  UserProfileService({
    UserProfileGateway? gateway,
    UserProfileUpdateGateway? updateGateway,
    AppConfig? config,
  })  : _gateway = gateway ?? SupabaseUserProfileGateway(),
        _updateGateway = updateGateway,
        _config = config ?? AppConfig.current;

  final UserProfileGateway _gateway;
  final UserProfileUpdateGateway? _updateGateway;
  final AppConfig _config;

  Future<List<PublicUserProfile>> listPublicProfilesByUserId({
    required String? userId,
  }) async {
    final normalizedUserId = userId?.trim();
    if (normalizedUserId == null || normalizedUserId.isEmpty) {
      return const [];
    }

    return _gateway.listPublicProfilesByUserId(userId: normalizedUserId);
  }

  Future<PublicUserProfile?> getPublicProfileByUserId({
    required String? userId,
  }) async {
    final profiles = await listPublicProfilesByUserId(userId: userId);
    return profiles.isEmpty ? null : profiles.first;
  }

  Future<List<PrivateUserProfile>> listPrivateProfilesByUserId({
    required String? userId,
  }) async {
    final normalizedUserId = userId?.trim();
    if (normalizedUserId == null || normalizedUserId.isEmpty) {
      return const [];
    }

    return _gateway.listPrivateProfilesByUserId(userId: normalizedUserId);
  }

  Future<PrivateUserProfile?> getPrivateProfileByUserId({
    required String? userId,
  }) async {
    final profiles = await listPrivateProfilesByUserId(userId: userId);
    return profiles.isEmpty ? null : profiles.first;
  }

  Future<String?> getReferralCodeByUserId({
    required String? userId,
  }) async {
    final profile = await getPrivateProfileByUserId(userId: userId);
    return profile?.referralCode;
  }

  Future<bool> hasCompletedProfile({
    required String? userId,
  }) async {
    final profile = await getPublicProfileByUserId(userId: userId);
    return profile?.hasCompletedProfile ?? false;
  }

  PreparedUserProfileUpdate prepareUpdate(
    UpdateUserProfileCommand command,
  ) {
    final userId = command.userId?.trim();
    if (userId == null || userId.isEmpty) {
      throw const UserProfileUpdateException(
        failure: UserProfileUpdateFailure.invalidIdentity,
        message: 'Sign in again before updating your profile.',
      );
    }

    final avatar = command.avatar;
    if (avatar != null &&
        (avatar.fileName.trim().isEmpty || avatar.byteLength <= 0)) {
      throw const UserProfileUpdateException(
        failure: UserProfileUpdateFailure.invalidAvatar,
        message: 'Avatar must contain a file name and data.',
      );
    }

    return PreparedUserProfileUpdate(
      userId: userId,
      fullName: command.fullName,
      updatedAt: command.updatedAt,
      avatar: avatar,
    );
  }

  Future<PrivateUserProfile> updateProfile(
    UpdateUserProfileCommand command,
  ) async {
    if (!_config.canPerformWrite(AppWriteOperation.profileUpdate)) {
      throw const UserProfileUpdateException(
        failure: UserProfileUpdateFailure.disabled,
        message: 'Profile updates are not enabled for this build.',
      );
    }

    final gateway = _updateGateway;
    if (gateway == null) {
      throw const UserProfileUpdateException(
        failure: UserProfileUpdateFailure.missingGateway,
        message: 'Profile update gateway is not configured.',
      );
    }

    return gateway.updateProfileAtomically(update: prepareUpdate(command));
  }
}

class PublicUserProfile {
  const PublicUserProfile({
    required this.id,
    required this.fullName,
    required this.avatarUrl,
  });

  factory PublicUserProfile.fromRow(PublicProfilesRow row) {
    return PublicUserProfile(
      id: row.id,
      fullName: row.fullName,
      avatarUrl: row.avatarUrl,
    );
  }

  final String id;
  final String? fullName;
  final String? avatarUrl;

  bool get hasCompletedProfile => fullName != null && fullName!.isNotEmpty;
}

class PrivateUserProfile {
  const PrivateUserProfile({
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

  factory PrivateUserProfile.fromRow(PrivateProfilesRow row) {
    return PrivateUserProfile(
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
