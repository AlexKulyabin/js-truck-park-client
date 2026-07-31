import '../../../flutter_flow/flutter_flow_util.dart';
import '../domain/favorite_parking_summary.dart';

Map<String, String> buildFavoriteParkingQueryParameters(
  FavoriteParkingSummary favorite,
) =>
    {
      'targetParkingId': serializeParam(
        favorite.parkingId,
        ParamType.String,
      )!,
      'targetLat': serializeParam(
        favorite.latitude,
        ParamType.double,
      )!,
      'targetLng': serializeParam(
        favorite.longitude,
        ParamType.double,
      )!,
    };
