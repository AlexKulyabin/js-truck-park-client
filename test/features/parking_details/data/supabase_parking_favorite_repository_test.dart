import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/parking_details/data/supabase_parking_favorite_repository.dart';
import 'package:j_s_truck_park/features/parking_details/domain/parking_favorite_repository.dart';
import 'package:postgrest/postgrest.dart';

class _FakeDataSource implements ParkingFavoriteDataSource {
  final calls = <({String action, String userId, String parkingId})>[];
  Object? error;

  @override
  Future<void> delete({
    required String userId,
    required String parkingId,
  }) async {
    calls.add((action: 'delete', userId: userId, parkingId: parkingId));
    if (error case final error?) {
      throw error;
    }
  }

  @override
  Future<void> insert({
    required String userId,
    required String parkingId,
  }) async {
    calls.add((action: 'insert', userId: userId, parkingId: parkingId));
    if (error case final error?) {
      throw error;
    }
  }
}

void main() {
  test('adds a favorite for the authenticated user and requested parking',
      () async {
    final dataSource = _FakeDataSource();
    final repository = SupabaseParkingFavoriteRepository(
      dataSource: dataSource,
      userIdProvider: () => 'user-1',
    );

    await repository.setFavorite(parkingId: 'parking-1', isFavorite: true);

    expect(
      dataSource.calls,
      [(action: 'insert', userId: 'user-1', parkingId: 'parking-1')],
    );
  });

  test('deletes using both authenticated user and parking identifiers',
      () async {
    final dataSource = _FakeDataSource();
    final repository = SupabaseParkingFavoriteRepository(
      dataSource: dataSource,
      userIdProvider: () => 'user-1',
    );

    await repository.setFavorite(parkingId: 'parking-1', isFavorite: false);

    expect(
      dataSource.calls,
      [(action: 'delete', userId: 'user-1', parkingId: 'parking-1')],
    );
  });

  test('rejects an empty parking identifier before calling the transport',
      () async {
    final dataSource = _FakeDataSource();
    final repository = SupabaseParkingFavoriteRepository(
      dataSource: dataSource,
      userIdProvider: () => 'user-1',
    );

    await expectLater(
      repository.setFavorite(parkingId: '', isFavorite: true),
      throwsA(
        isA<ParkingFavoriteMutationException>().having(
          (error) => error.kind,
          'kind',
          ParkingFavoriteFailureKind.invalidInput,
        ),
      ),
    );
    expect(dataSource.calls, isEmpty);
  });

  test('rejects a missing authenticated user before calling the transport',
      () async {
    final dataSource = _FakeDataSource();
    final repository = SupabaseParkingFavoriteRepository(
      dataSource: dataSource,
      userIdProvider: () => '',
    );

    await expectLater(
      repository.setFavorite(parkingId: 'parking-1', isFavorite: true),
      throwsA(
        isA<ParkingFavoriteMutationException>().having(
          (error) => error.kind,
          'kind',
          ParkingFavoriteFailureKind.unauthenticated,
        ),
      ),
    );
    expect(dataSource.calls, isEmpty);
  });

  test('treats a duplicate insert as an idempotent success', () async {
    final dataSource = _FakeDataSource()
      ..error = const PostgrestException(
        message: 'raw duplicate details',
        code: '23505',
      );
    final repository = SupabaseParkingFavoriteRepository(
      dataSource: dataSource,
      userIdProvider: () => 'user-1',
    );

    await repository.setFavorite(parkingId: 'parking-1', isFavorite: true);

    expect(dataSource.calls, hasLength(1));
  });

  test('maps an RLS rejection to a redacted forbidden failure', () async {
    final dataSource = _FakeDataSource()
      ..error = const PostgrestException(
        message: 'raw policy details',
        code: '42501',
      );
    final repository = SupabaseParkingFavoriteRepository(
      dataSource: dataSource,
      userIdProvider: () => 'user-1',
    );

    await expectLater(
      repository.setFavorite(parkingId: 'parking-1', isFavorite: false),
      throwsA(
        isA<ParkingFavoriteMutationException>()
            .having(
              (error) => error.kind,
              'kind',
              ParkingFavoriteFailureKind.forbidden,
            )
            .having(
              (error) => error.toString(),
              'redacted message',
              isNot(contains('raw policy details')),
            ),
      ),
    );
  });

  test('maps unknown transport errors to a redacted unavailable failure',
      () async {
    final dataSource = _FakeDataSource()
      ..error = StateError('raw transport details');
    final repository = SupabaseParkingFavoriteRepository(
      dataSource: dataSource,
      userIdProvider: () => 'user-1',
    );

    await expectLater(
      repository.setFavorite(parkingId: 'parking-1', isFavorite: true),
      throwsA(
        isA<ParkingFavoriteMutationException>()
            .having(
              (error) => error.kind,
              'kind',
              ParkingFavoriteFailureKind.unavailable,
            )
            .having(
              (error) => error.toString(),
              'redacted message',
              isNot(contains('raw transport details')),
            ),
      ),
    );
  });
}
