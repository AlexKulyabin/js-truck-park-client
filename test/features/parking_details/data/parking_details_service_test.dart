import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/backend/supabase/database/database.dart';
import 'package:j_s_truck_park/features/parking_details/data/parking_details_service.dart';

void main() {
  group('ParkingDetailsService', () {
    test('returns null without querying when parking id is empty', () async {
      final gateway = _FakeParkingDetailsGateway();
      final service = ParkingDetailsService(gateway: gateway);

      final result = await service.getParkingDetails(parkingId: ' ');

      expect(result, isNull);
      expect(gateway.calls, isEmpty);
    });

    test('loads details for normalized parking id', () async {
      final gateway = _FakeParkingDetailsGateway(
        details: _details(id: 'parking-1'),
      );
      final service = ParkingDetailsService(gateway: gateway);

      final result = await service.getParkingDetails(parkingId: ' parking-1 ');

      expect(result?.id, 'parking-1');
      expect(gateway.calls, ['parking-1']);
    });

    test('maps photo payload into typed immutable details', () {
      final details = ParkingDetails.fromRow(
        ViewFullParkingDetailsRow({
          'id': 'parking-1',
          'photos': ['legacy.jpg'],
          'all_photos': [
            {
              'url': 'photo.jpg',
              'date_display': '24.07.2026',
              'photo_date': '2026-07-24',
            },
          ],
        }),
      );

      expect(details.photos, ['legacy.jpg']);
      expect(details.allPhotos?.single.url, 'photo.jpg');
      expect(details.allPhotos?.single.dateDisplay, '24.07.2026');
      expect(
        () => details.photos.add('another.jpg'),
        throwsUnsupportedError,
      );
    });
  });
}

class _FakeParkingDetailsGateway implements ParkingDetailsGateway {
  _FakeParkingDetailsGateway({this.details});

  final ParkingDetails? details;
  final calls = <String>[];

  @override
  Future<ParkingDetails?> getParkingDetails({required String parkingId}) async {
    calls.add(parkingId);
    return details;
  }
}

ParkingDetails _details({required String id}) {
  return ParkingDetails.fromRow(
    ViewFullParkingDetailsRow({
      'id': id,
      'photos': <String>[],
    }),
  );
}
