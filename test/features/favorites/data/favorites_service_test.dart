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
  final calls = <String>[];

  @override
  Future<void> addFavorite({
    required String parkingId,
    required String userId,
  }) async {
    calls.add('add:$parkingId:$userId');
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
