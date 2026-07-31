import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/favorites/data/supabase_favorites_repository.dart';
import 'package:j_s_truck_park/features/favorites/domain/favorite_parking_summary.dart';
import 'package:j_s_truck_park/features/favorites/domain/favorites_repository.dart';

class _FakeDataSource implements FavoritesDataSource {
  final userIds = <String>[];
  List<Map<String, dynamic>> rows = [];
  Object? error;

  @override
  Future<List<Map<String, dynamic>>> fetchOwnedRows(String userId) async {
    userIds.add(userId);
    if (error case final error?) {
      throw error;
    }
    return rows;
  }
}

void main() {
  test('filters by owner and maps the bounded favorite summary', () async {
    final dataSource = _FakeDataSource()
      ..rows = [
        {
          'favorite_record_id': 10,
          'user_id': 'user-1',
          'parking_id': 'parking-1',
          'address': 'Test address',
          'latitude': 52.1,
          'longitude': 21.2,
          'photos': ['https://example.com/first.jpg', 'second.jpg'],
          'rating': 4.8,
          'reviews_count': 12,
        },
      ];
    final repository = SupabaseFavoritesRepository(dataSource: dataSource);

    final result = await repository.fetchOwnedFavorites('user-1');

    expect(dataSource.userIds, ['user-1']);
    expect(
      result,
      const [
        FavoriteParkingSummary(
          favoriteRecordId: 10,
          parkingId: 'parking-1',
          address: 'Test address',
          latitude: 52.1,
          longitude: 21.2,
          thumbnailUrl: 'https://example.com/first.jpg',
        ),
      ],
    );
  });

  test('does not perform an unfiltered query without an authenticated user',
      () async {
    final dataSource = _FakeDataSource();
    final repository = SupabaseFavoritesRepository(dataSource: dataSource);

    final result = await repository.fetchOwnedFavorites('');

    expect(result, isEmpty);
    expect(dataSource.userIds, isEmpty);
  });

  test('rejects a row that belongs to another user', () async {
    final dataSource = _FakeDataSource()
      ..rows = [
        {
          'favorite_record_id': 10,
          'user_id': 'user-2',
          'parking_id': 'parking-1',
          'address': 'Test address',
          'latitude': 52.1,
          'longitude': 21.2,
          'photos': null,
        },
      ];
    final repository = SupabaseFavoritesRepository(dataSource: dataSource);

    await expectLater(
      repository.fetchOwnedFavorites('user-1'),
      throwsA(
        isA<FavoritesReadException>().having(
          (error) => error.kind,
          'kind',
          FavoritesFailureKind.invalidData,
        ),
      ),
    );
  });

  test('rejects malformed or empty photo values', () async {
    final dataSource = _FakeDataSource()
      ..rows = [
        {
          'favorite_record_id': 10,
          'user_id': 'user-1',
          'parking_id': 'parking-1',
          'address': 'Test address',
          'latitude': 52.1,
          'longitude': 21.2,
          'photos': [''],
        },
      ];
    final repository = SupabaseFavoritesRepository(dataSource: dataSource);

    await expectLater(
      repository.fetchOwnedFavorites('user-1'),
      throwsA(
        isA<FavoritesReadException>().having(
          (error) => error.kind,
          'kind',
          FavoritesFailureKind.invalidData,
        ),
      ),
    );
  });

  test('rejects coordinates outside the map contract', () async {
    final dataSource = _FakeDataSource()
      ..rows = [
        {
          'favorite_record_id': 10,
          'user_id': 'user-1',
          'parking_id': 'parking-1',
          'address': 'Test address',
          'latitude': 91,
          'longitude': 21.2,
          'photos': null,
        },
      ];
    final repository = SupabaseFavoritesRepository(dataSource: dataSource);

    await expectLater(
      repository.fetchOwnedFavorites('user-1'),
      throwsA(
        isA<FavoritesReadException>().having(
          (error) => error.kind,
          'kind',
          FavoritesFailureKind.invalidData,
        ),
      ),
    );
  });

  test('redacts data-source failures', () async {
    final dataSource = _FakeDataSource()
      ..error = StateError('raw database details');
    final repository = SupabaseFavoritesRepository(dataSource: dataSource);

    await expectLater(
      repository.fetchOwnedFavorites('user-1'),
      throwsA(
        isA<FavoritesReadException>()
            .having(
              (error) => error.kind,
              'kind',
              FavoritesFailureKind.unavailable,
            )
            .having(
              (error) => error.toString(),
              'redacted message',
              isNot(contains('raw database details')),
            ),
      ),
    );
  });
}
