import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/parking_photos/data/parking_photos_service.dart';

void main() {
  group('ParkingPhotosService', () {
    test('returns empty list without querying when parking id is empty',
        () async {
      final gateway = _FakeParkingPhotosGateway();
      final service = ParkingPhotosService(gateway: gateway);

      final result = await service.listParkingPhotos(parkingId: ' ');

      expect(result, isEmpty);
      expect(gateway.calls, isEmpty);
    });

    test('loads photos for normalized parking id without ordering by default',
        () async {
      final gateway = _FakeParkingPhotosGateway(
        photos: [
          ParkingPhoto(
            id: 'photo-1',
            createdAt: DateTime(2026, 1, 1),
            url: 'https://example.test/parking.jpg',
            parkingId: 'parking-1',
            userId: 'user-1',
            reviewId: null,
          ),
        ],
      );
      final service = ParkingPhotosService(gateway: gateway);

      final result = await service.listParkingPhotos(parkingId: ' parking-1 ');

      expect(result.single.url, 'https://example.test/parking.jpg');
      expect(gateway.calls, [
        'parking-1:false',
      ]);
    });

    test('passes created_at ordering flag to the gateway', () async {
      final gateway = _FakeParkingPhotosGateway();
      final service = ParkingPhotosService(gateway: gateway);

      await service.listParkingPhotos(
        parkingId: 'parking-1',
        orderByCreatedAt: true,
      );

      expect(gateway.calls, [
        'parking-1:true',
      ]);
    });
  });
}

class _FakeParkingPhotosGateway implements ParkingPhotosGateway {
  _FakeParkingPhotosGateway({
    this.photos = const [],
  });

  final List<ParkingPhoto> photos;
  final calls = <String>[];

  @override
  Future<List<ParkingPhoto>> listParkingPhotos({
    required String parkingId,
    required bool orderByCreatedAt,
  }) async {
    calls.add('$parkingId:$orderByCreatedAt');
    return photos;
  }
}
