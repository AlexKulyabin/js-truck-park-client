import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/favorites/data/favorites_service.dart';

void main() {
  group('FavoritesService', () {
    test('returns false without querying when ids are incomplete', () async {
      final gateway = _FakeFavoritesGateway();
      final service = FavoritesService(gateway: gateway);

      final result = await service.isFavorite(
        parkingId: null,
        userId: 'user-1',
      );

      expect(result, isFalse);
      expect(gateway.calls, isEmpty);
    });

    test('returns empty favorites list without querying when user id is empty',
        () async {
      final gateway = _FakeFavoritesGateway();
      final service = FavoritesService(gateway: gateway);

      final result = await service.listFavorites(userId: ' ');

      expect(result, isEmpty);
      expect(gateway.calls, isEmpty);
    });

    test('loads favorites for normalized current user id', () async {
      final gateway = _FakeFavoritesGateway(
        favorites: const [
          FavoriteParking(
            favoriteRecordId: 1,
            userId: 'user-1',
            parkingId: 'parking-1',
            address: 'Address 1',
            latitude: 10,
            longitude: 20,
            rating: 4.5,
            reviewsCount: 3,
            photoUrls: ['https://example.test/photo.jpg'],
          ),
        ],
      );
      final service = FavoritesService(gateway: gateway);

      final result = await service.listFavorites(userId: ' user-1 ');

      expect(result.single.parkingId, 'parking-1');
      expect(result.single.primaryPhotoUrl, 'https://example.test/photo.jpg');
      expect(gateway.calls, [
        'list:user-1',
      ]);
    });

    test('adds favorite for the current user and parking', () async {
      final gateway = _FakeFavoritesGateway();
      final service = FavoritesService(gateway: gateway);

      final result = await service.toggleFavorite(
        parkingId: 'parking-1',
        userId: 'user-1',
        currentlyFavorite: false,
      );

      expect(result, isTrue);
      expect(gateway.calls, [
        'add:parking-1:user-1',
      ]);
    });

    test('removes favorite for the current user and parking', () async {
      final gateway = _FakeFavoritesGateway();
      final service = FavoritesService(gateway: gateway);

      final result = await service.toggleFavorite(
        parkingId: 'parking-1',
        userId: 'user-1',
        currentlyFavorite: true,
      );

      expect(result, isFalse);
      expect(gateway.calls, [
        'remove:parking-1:user-1',
      ]);
    });

    test('rejects writes with empty identifiers', () async {
      final gateway = _FakeFavoritesGateway();
      final service = FavoritesService(gateway: gateway);

      expect(
        service.toggleFavorite(
          parkingId: ' ',
          userId: 'user-1',
          currentlyFavorite: false,
        ),
        throwsA(isA<FavoriteActionException>()),
      );
      expect(gateway.calls, isEmpty);
    });
  });
}

class _FakeFavoritesGateway implements FavoritesGateway {
  _FakeFavoritesGateway({
    this.favorites = const [],
  });

  final calls = <String>[];
  final List<FavoriteParking> favorites;

  @override
  Future<void> addFavorite({
    required String parkingId,
    required String userId,
  }) async {
    calls.add('add:$parkingId:$userId');
  }

  @override
  Future<List<FavoriteParking>> listFavorites({
    required String userId,
  }) async {
    calls.add('list:$userId');
    return favorites;
  }

  @override
  Future<bool> isFavorite({
    required String parkingId,
    required String userId,
  }) async {
    calls.add('query:$parkingId:$userId');
    return true;
  }

  @override
  Future<void> removeFavorite({
    required String parkingId,
    required String userId,
  }) async {
    calls.add('remove:$parkingId:$userId');
  }
}
