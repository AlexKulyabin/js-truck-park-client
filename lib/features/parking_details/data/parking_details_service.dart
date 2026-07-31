import '/backend/supabase/database/database.dart';

abstract interface class ParkingDetailsGateway {
  Future<ParkingDetails?> getParkingDetails({
    required String parkingId,
  });
}

class SupabaseParkingDetailsGateway implements ParkingDetailsGateway {
  SupabaseParkingDetailsGateway({
    ViewFullParkingDetailsTable? parkingDetailsView,
  }) : _parkingDetailsView =
            parkingDetailsView ?? ViewFullParkingDetailsTable();

  final ViewFullParkingDetailsTable _parkingDetailsView;

  @override
  Future<ParkingDetails?> getParkingDetails({
    required String parkingId,
  }) async {
    final rows = await _parkingDetailsView.querySingleRow(
      queryFn: (q) => q.eqOrNull(
        'id',
        parkingId,
      ),
    );
    return rows.isEmpty ? null : ParkingDetails.fromRow(rows.first);
  }
}

class ParkingDetailsService {
  ParkingDetailsService({
    ParkingDetailsGateway? gateway,
  }) : _gateway = gateway ?? SupabaseParkingDetailsGateway();

  final ParkingDetailsGateway _gateway;

  Future<ParkingDetails?> getParkingDetails({
    required String? parkingId,
  }) {
    final normalizedParkingId = parkingId?.trim();
    if (normalizedParkingId == null || normalizedParkingId.isEmpty) {
      return Future.value(null);
    }

    return _gateway.getParkingDetails(parkingId: normalizedParkingId);
  }
}

class ParkingDetails {
  const ParkingDetails({
    required this.id,
    required this.createdAt,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.parkingType,
    required this.totalSpaces,
    required this.price,
    required this.isFree,
    required this.hasGasStation,
    required this.hasShower,
    required this.hasLaundry,
    required this.hasHotel,
    required this.hasShop,
    required this.hasRecreationArea,
    required this.rating,
    required this.stars1,
    required this.stars2,
    required this.stars3,
    required this.stars4,
    required this.stars5,
    required this.createdBy,
    required this.updatedAt,
    required this.addressLower,
    required this.status,
    required this.photos,
    required this.isActive,
    required this.adminComment,
    required this.location,
    required this.reviewsCount,
    required this.rejectionReason,
    required this.allPhotos,
    required this.photosCount,
    required this.isFavorited,
    required this.creatorName,
    required this.creatorAvatar,
  });

  factory ParkingDetails.fromRow(ViewFullParkingDetailsRow row) {
    return ParkingDetails(
      id: row.id,
      createdAt: row.createdAt,
      address: row.address,
      latitude: row.latitude,
      longitude: row.longitude,
      parkingType: row.parkingType,
      totalSpaces: row.totalSpaces,
      price: row.price,
      isFree: row.isFree,
      hasGasStation: row.hasGasStation,
      hasShower: row.hasShower,
      hasLaundry: row.hasLaundry,
      hasHotel: row.hasHotel,
      hasShop: row.hasShop,
      hasRecreationArea: row.hasRecreationArea,
      rating: row.rating,
      stars1: row.stars1,
      stars2: row.stars2,
      stars3: row.stars3,
      stars4: row.stars4,
      stars5: row.stars5,
      createdBy: row.createdBy,
      updatedAt: row.updatedAt,
      addressLower: row.addressLower,
      status: row.status,
      photos: List.unmodifiable(row.photos),
      isActive: row.isActive,
      adminComment: row.adminComment,
      location: row.location,
      reviewsCount: row.reviewsCount,
      rejectionReason: row.rejectionReason,
      allPhotos: _parseParkingPhotos(row.allPhotos),
      photosCount: row.photosCount,
      isFavorited: row.isFavorited,
      creatorName: row.creatorName,
      creatorAvatar: row.creatorAvatar,
    );
  }

  final String? id;
  final DateTime? createdAt;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? parkingType;
  final int? totalSpaces;
  final double? price;
  final bool? isFree;
  final bool? hasGasStation;
  final bool? hasShower;
  final bool? hasLaundry;
  final bool? hasHotel;
  final bool? hasShop;
  final bool? hasRecreationArea;
  final double? rating;
  final int? stars1;
  final int? stars2;
  final int? stars3;
  final int? stars4;
  final int? stars5;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? addressLower;
  final String? status;
  final List<String> photos;
  final bool? isActive;
  final String? adminComment;
  final String? location;
  final int? reviewsCount;
  final String? rejectionReason;
  final List<ParkingDetailPhoto>? allPhotos;
  final int? photosCount;
  final bool? isFavorited;
  final String? creatorName;
  final String? creatorAvatar;
}

class ParkingDetailPhoto {
  const ParkingDetailPhoto({
    required this.url,
    required this.dateDisplay,
    required this.photoDate,
  });

  final String? url;
  final String? dateDisplay;
  final String? photoDate;
}

List<ParkingDetailPhoto>? _parseParkingPhotos(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is! Iterable) {
    return const [];
  }

  return List.unmodifiable(
    value.whereType<Map>().map(
          (photo) => ParkingDetailPhoto(
            url: photo['url']?.toString(),
            dateDisplay: photo['date_display']?.toString(),
            photoDate: photo['photo_date']?.toString(),
          ),
        ),
  );
}
