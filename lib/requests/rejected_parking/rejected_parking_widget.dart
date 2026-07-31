import '/backend/supabase/supabase.dart';
import '/features/parking_requests/data/legacy_parking_request_route_adapter.dart';
import '/features/parking_requests/data/supabase_parking_request_details_repository.dart';
import '/features/parking_requests/domain/parking_request_details_repository.dart';
import '/features/parking_requests/domain/parking_request_summary.dart';
import '/features/parking_requests/presentation/parking_request_details_view.dart';
import 'package:flutter/material.dart';

export 'rejected_parking_model.dart';

class RejectedParkingWidget extends StatelessWidget {
  const RejectedParkingWidget({
    super.key,
    required this.parkingRow,
    this.detailsRepository,
  });

  final ParkingsRow? parkingRow;
  final ParkingRequestDetailsRepository? detailsRepository;

  static String routeName = 'RejectedParking';
  static String routePath = '/rejectedParking';

  @override
  Widget build(BuildContext context) => ParkingRequestDetailsView(
        request: parkingRequestFromLegacyRow(
          parkingRow,
          expectedStatus: ParkingRequestStatus.rejected,
        ),
        repository:
            detailsRepository ?? SupabaseParkingRequestDetailsRepository(),
      );
}
