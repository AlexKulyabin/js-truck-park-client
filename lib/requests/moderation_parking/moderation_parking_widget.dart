import '/backend/supabase/supabase.dart';
import '/features/parking_requests/data/legacy_parking_request_route_adapter.dart';
import '/features/parking_requests/data/supabase_parking_request_details_repository.dart';
import '/features/parking_requests/domain/parking_request_details_repository.dart';
import '/features/parking_requests/domain/parking_request_summary.dart';
import '/features/parking_requests/presentation/parking_request_details_view.dart';
import 'package:flutter/material.dart';

export 'moderation_parking_model.dart';

class ModerationParkingWidget extends StatelessWidget {
  const ModerationParkingWidget({
    super.key,
    required this.parkingRow,
    this.detailsRepository,
  });

  final ParkingsRow? parkingRow;
  final ParkingRequestDetailsRepository? detailsRepository;

  static String routeName = 'ModerationParking';
  static String routePath = '/moderationParking';

  @override
  Widget build(BuildContext context) => ParkingRequestDetailsView(
        request: parkingRequestFromLegacyRow(
          parkingRow,
          expectedStatus: ParkingRequestStatus.pending,
        ),
        repository:
            detailsRepository ?? SupabaseParkingRequestDetailsRepository(),
      );
}
