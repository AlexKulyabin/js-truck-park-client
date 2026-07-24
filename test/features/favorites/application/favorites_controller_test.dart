import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/favorites/application/favorites_controller.dart';
import 'package:j_s_truck_park/features/favorites/data/favorites_service.dart';

void main() {
  group('FavoritesController', () {
    test('starts with an immutable empty loading state', () {
      final controller = FavoritesController();

      expect(controller.state.status, FavoritesLoadStatus.initial);
      expect(controller.state.items, isEmpty);
      expect(controller.state.errorMessage, isNull);
    });

    test('loads favorites through the service', () async {
      final controller = FavoritesController(
        service: FavoritesService(
          gateway: _FakeFavoritesGateway(
            favorites: const [
              FavoriteParking(
                favoriteRecordId: 1,
                userId: 'user-1',
                parkingId: 'parking-1',
                address: 'Address 1',
                latitude: 10,
                longitude: 20,
                rating: 4.5,
                reviewsCount: 2,
                photoUrls: [],
              ),
            ],
          ),
        ),
      );

      await controller.load(userId: 'user-1');

      expect(controller.state.status, FavoritesLoadStatus.loaded);
      expect(controller.state.items.single.parkingId, 'parking-1');
      expect(controller.state.errorMessage, isNull);
    });

    test('exposes failure state on load error', () async {
      final controller = FavoritesController(
        service: FavoritesService(
          gateway: _FakeFavoritesGateway(
            shouldThrowOnList: true,
            favorites: const [
              FavoriteParking(
                favoriteRecordId: 1,
                userId: 'user-1',
                parkingId: 'parking-1',
                address: 'Address 1',
                latitude: 10,
                longitude: 20,
                rating: 4.5,
                reviewsCount: 2,
                photoUrls: [],
              ),
            ],
          ),
        ),
      );

      await controller.load(userId: 'user-1');

      expect(controller.state.status, FavoritesLoadStatus.failure);
      expect(controller.state.items, isEmpty);
      expect(controller.state.errorMessage, isNotNull);
    });
  });
}

class _FakeFavoritesGateway implements FavoritesGateway {
  _FakeFavoritesGateway({
    this.favorites = const [],
    this.shouldThrowOnList = false,
  });

  final List<FavoriteParking> favorites;
  final bool shouldThrowOnList;

  @override
  Future<void> addFavorite({
    required String parkingId,
    required String userId,
  }) async {}

  @override
  Future<List<FavoriteParking>> listFavorites({
    required String userId,
  }) async {
    if (shouldThrowOnList) {
      throw StateError('list failed');
    }
    return favorites;
  }

  @override
  Future<bool> isFavorite({
    required String parkingId,
    required String userId,
  }) async {
    return false;
  }

  @override
  Future<void> removeFavorite({
    required String parkingId,
    required String userId,
  }) async {}
}
