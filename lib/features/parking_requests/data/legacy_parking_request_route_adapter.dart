import '../../../backend/supabase/supabase.dart';
import '../domain/parking_request_summary.dart';

ParkingsRow parkingRequestToLegacyRow(ParkingRequestSummary request) =>
    ParkingsRow({
      'id': request.id,
      'status': request.status.storageValue,
      'address': request.address,
      'total_spaces': request.totalSpaces,
      'rating': request.rating,
      'has_gas_station': request.hasGasStation,
      'has_shower': request.hasShower,
      'has_laundry': request.hasLaundry,
      'has_hotel': request.hasHotel,
      'has_shop': request.hasShop,
      'has_recreation_area': request.hasRecreationArea,
    });

ParkingRequestSummary parkingRequestFromLegacyRow(
  ParkingsRow? row, {
  required ParkingRequestStatus expectedStatus,
}) =>
    ParkingRequestSummary(
      id: row?.id ?? '',
      status: expectedStatus,
      address: row?.address,
      totalSpaces: row?.totalSpaces,
      rating: row?.rating,
      hasGasStation: row?.hasGasStation ?? true,
      hasShower: row?.hasShower ?? true,
      hasLaundry: row?.hasLaundry ?? true,
      hasHotel: row?.hasHotel ?? true,
      hasShop: row?.hasShop ?? true,
      hasRecreationArea: row?.hasRecreationArea ?? true,
    );
