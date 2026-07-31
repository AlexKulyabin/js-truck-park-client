import '../domain/parking_details.dart';

const parkingShareHost = 'https://js-truck-park.web.app';

String buildParkingShareUrl(ParkingDetails details) =>
    '$parkingShareHost/deeplink.html'
    '?targetParkingId=${details.id}'
    '&targetLat=${details.latitude}'
    '&targetLng=${details.longitude}';

String buildSharedPhotoUrl({
  required String? photoUrl,
  required String? address,
  required String? date,
}) =>
    '$parkingShareHost/deeplink.html'
    '?route=sharedPhotoView'
    '&photoUrl=${Uri.encodeComponent(photoUrl ?? '')}'
    '&address=${Uri.encodeComponent(address ?? '')}'
    '&date=${Uri.encodeComponent(date ?? '')}';
