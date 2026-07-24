import '../../../flutter_flow/flutter_flow_util.dart';
import '../domain/user_complaint_summary.dart';

Map<String, String> buildComplaintPhotoQueryParameters(
  UserComplaintSummary complaint,
) {
  final firstPhotoUrl = complaint.firstParkingPhotoUrl;
  if (firstPhotoUrl == null) {
    return const {};
  }

  return {
    'photoPath': serializeParam(firstPhotoUrl, ParamType.String)!,
    'index': serializeParam(0, ParamType.int)!,
    'address': serializeParam(complaint.parkingAddress, ParamType.String)!,
    if (complaint.photosCount case final photosCount?)
      'photoCount': serializeParam(photosCount, ParamType.int)!,
    'photoRef': serializeParam(firstPhotoUrl, ParamType.String)!,
    if (complaint.reportDate case final reportDate?)
      'data': serializeParam(reportDate.toString(), ParamType.String)!,
  };
}
