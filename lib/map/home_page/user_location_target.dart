import '/flutter_flow/lat_lng.dart';

bool isUsableUserLocation(LatLng? location) {
  if (location == null) {
    return false;
  }

  final latitude = location.latitude;
  final longitude = location.longitude;
  return latitude >= -90.0 &&
      latitude <= 90.0 &&
      longitude >= -180.0 &&
      longitude <= 180.0 &&
      !(latitude == 0.0 && longitude == 0.0);
}

bool shouldApplyFreshUserLocation({
  required LatLng? previous,
  required LatLng? fresh,
}) {
  if (!isUsableUserLocation(fresh)) {
    return false;
  }
  if (previous == null) {
    return true;
  }

  return previous.latitude != fresh!.latitude ||
      previous.longitude != fresh.longitude;
}
