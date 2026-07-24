import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/core/config/app_config.dart';
import 'package:j_s_truck_park/features/profile/data/user_profile_service.dart';

void main() {
  group('UserProfileService', () {
    test('returns empty list without querying when user id is missing',
        () async {
      final gateway = _FakeUserProfileGateway();
      final service = UserProfileService(gateway: gateway);

      final result = await service.listProfilesByUserId(userId: ' ');

      expect(result, isEmpty);
      expect(gateway.calls, isEmpty);
    });

    test('loads profile with normalized user id', () async {
      final gateway = _FakeUserProfileGateway(
        profiles: const [
          UserProfile(
            id: 'user-1',
            fullName: 'Driver One',
            avatarUrl: 'https://example.test/avatar.jpg',
            phone: '+10000000000',
            isPremium: true,
            referralCode: 'ABC123',
            theme: 'light',
            status: 'active',
            isAdmin: false,
          ),
        ],
      );
      final service = UserProfileService(gateway: gateway);

      final result = await service.getProfileByUserId(userId: ' user-1 ');

      expect(result?.fullName, 'Driver One');
      expect(result?.referralCode, 'ABC123');
      expect(gateway.calls, ['list:user-1']);
    });

    test('reports profile completion from full name', () async {
      final service = UserProfileService(
        gateway: _FakeUserProfileGateway(
          profiles: const [
            UserProfile(
              id: 'user-1',
              fullName: 'Driver One',
              avatarUrl: null,
              phone: null,
              isPremium: null,
              referralCode: null,
              theme: null,
              status: null,
              isAdmin: null,
            ),
          ],
        ),
      );

      final result = await service.hasCompletedProfile(userId: 'user-1');

      expect(result, isTrue);
    });

    test('treats absent or empty full name as incomplete profile', () async {
      final gateway = _FakeUserProfileGateway(
        profiles: const [
          UserProfile(
            id: 'user-1',
            fullName: '',
            avatarUrl: null,
            phone: null,
            isPremium: null,
            referralCode: null,
            theme: null,
            status: null,
            isAdmin: null,
          ),
        ],
      );
      final service = UserProfileService(gateway: gateway);

      final result = await service.hasCompletedProfile(userId: 'user-1');

      expect(result, isFalse);
    });

    test('prepares profile update while preserving current name behavior', () {
      final service = UserProfileService(gateway: _FakeUserProfileGateway());

      final update = service.prepareUpdate(
        UpdateUserProfileCommand(
          userId: ' user-1 ',
          fullName: '  Driver One  ',
          updatedAt: DateTime(2026, 7, 25),
          avatar: const UserAvatarDraft(
            fileName: 'avatar.jpg',
            byteLength: 512,
            mimeType: 'image/jpeg',
          ),
        ),
      );

      expect(update.userId, 'user-1');
      expect(update.fullName, '  Driver One  ');
      expect(update.requiresAvatarHandling, isTrue);
    });

    test('rejects missing owner and invalid avatar drafts', () {
      final service = UserProfileService(gateway: _FakeUserProfileGateway());

      expect(
        () => service.prepareUpdate(
          UpdateUserProfileCommand(
            userId: ' ',
            fullName: 'Driver One',
            updatedAt: DateTime(2026, 7, 25),
          ),
        ),
        throwsA(
          isA<UserProfileUpdateException>().having(
            (error) => error.failure,
            'failure',
            UserProfileUpdateFailure.invalidIdentity,
          ),
        ),
      );
      expect(
        () => service.prepareUpdate(
          UpdateUserProfileCommand(
            userId: 'user-1',
            fullName: 'Driver One',
            updatedAt: DateTime(2026, 7, 25),
            avatar: const UserAvatarDraft(fileName: '', byteLength: 1),
          ),
        ),
        throwsA(
          isA<UserProfileUpdateException>().having(
            (error) => error.failure,
            'failure',
            UserProfileUpdateFailure.invalidAvatar,
          ),
        ),
      );
    });

    test('disabled capability prevents every profile update gateway write',
        () async {
      final updateGateway = _FakeUserProfileUpdateGateway();
      final service = UserProfileService(
        gateway: _FakeUserProfileGateway(),
        updateGateway: updateGateway,
        config: AppConfig.resolve(isReleaseMode: false),
      );

      await expectLater(
        service.updateProfile(
          UpdateUserProfileCommand(
            userId: 'user-1',
            fullName: 'Driver One',
            updatedAt: DateTime(2026, 7, 25),
          ),
        ),
        throwsA(
          isA<UserProfileUpdateException>().having(
            (error) => error.failure,
            'failure',
            UserProfileUpdateFailure.disabled,
          ),
        ),
      );
      expect(updateGateway.calls, 0);
    });
  });
}

class _FakeUserProfileGateway implements UserProfileGateway {
  _FakeUserProfileGateway({
    this.profiles = const [],
  });

  final calls = <String>[];
  final List<UserProfile> profiles;

  @override
  Future<List<UserProfile>> listProfilesByUserId({
    required String userId,
  }) async {
    calls.add('list:$userId');
    return profiles;
  }
}

class _FakeUserProfileUpdateGateway implements UserProfileUpdateGateway {
  int calls = 0;

  @override
  Future<UserProfile> updateProfileAtomically({
    required PreparedUserProfileUpdate update,
  }) async {
    calls += 1;
    return UserProfile(
      id: update.userId,
      fullName: update.fullName,
      avatarUrl: null,
      phone: null,
      isPremium: null,
      referralCode: null,
      theme: null,
      status: null,
      isAdmin: null,
    );
  }
}
