import 'dart:async';

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

    test('loads detail favorite state through the service', () async {
      final controller = FavoriteToggleController(
        service: FavoritesService(
          gateway: _FakeFavoritesGateway(initialFavorite: true),
        ),
      );

      await controller.load(
        parkingId: 'parking-1',
        userId: 'user-1',
      );

      expect(controller.state.status, FavoriteToggleStatus.loaded);
      expect(controller.state.isFavorite, isTrue);
      expect(controller.state.errorMessage, isNull);
    });

    test('toggles detail favorite state optimistically', () async {
      final gateway = _FakeFavoritesGateway();
      final controller = FavoriteToggleController(
        service: FavoritesService(gateway: gateway),
      );

      final result = await controller.toggle(
        parkingId: 'parking-1',
        userId: 'user-1',
      );

      expect(result, isTrue);
      expect(controller.state.status, FavoriteToggleStatus.loaded);
      expect(controller.state.isFavorite, isTrue);
      expect(gateway.calls, [
        'add:parking-1:user-1',
      ]);
    });

    test('rolls detail favorite state back on toggle failure', () async {
      final gateway = _FakeFavoritesGateway(shouldThrowOnAdd: true);
      final controller = FavoriteToggleController(
        service: FavoritesService(gateway: gateway),
      );

      final result = await controller.toggle(
        parkingId: 'parking-1',
        userId: 'user-1',
      );

      expect(result, isFalse);
      expect(controller.state.status, FavoriteToggleStatus.failure);
      expect(controller.state.isFavorite, isFalse);
      expect(controller.state.errorMessage, isNotNull);
    });

    test('does not issue overlapping detail favorite toggles', () async {
      final gateway = _FakeFavoritesGateway(holdAdd: true);
      final controller = FavoriteToggleController(
        service: FavoritesService(gateway: gateway),
      );

      final firstToggle = controller.toggle(
        parkingId: 'parking-1',
        userId: 'user-1',
      );
      final secondToggle = await controller.toggle(
        parkingId: 'parking-1',
        userId: 'user-1',
      );

      expect(secondToggle, isFalse);
      expect(gateway.calls, [
        'add:parking-1:user-1',
      ]);

      gateway.completeAdd();
      expect(await firstToggle, isTrue);
    });
  });
}

class _FakeFavoritesGateway implements FavoritesGateway {
  _FakeFavoritesGateway({
    this.favorites = const [],
    this.shouldThrowOnList = false,
    this.shouldThrowOnAdd = false,
    this.initialFavorite = false,
    this.holdAdd = false,
  });

  final List<FavoriteParking> favorites;
  final bool shouldThrowOnList;
  final bool shouldThrowOnAdd;
  final bool initialFavorite;
  final bool holdAdd;
  final calls = <String>[];
  Completer<void>? _addCompleter;

  @override
  Future<void> addFavorite({
    required String parkingId,
    required String userId,
  }) async {
    calls.add('add:$parkingId:$userId');
    if (shouldThrowOnAdd) {
      throw StateError('add failed');
    }
    if (holdAdd) {
      _addCompleter = Completer<void>();
      await _addCompleter!.future;
    }
  }

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
    calls.add('query:$parkingId:$userId');
    return initialFavorite;
  }

  @override
  Future<void> removeFavorite({
    required String parkingId,
    required String userId,
  }) async {
    calls.add('remove:$parkingId:$userId');
  }

  void completeAdd() {
    _addCompleter?.complete();
  }
}
