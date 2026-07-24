import 'package:flutter_test/flutter_test.dart';
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
