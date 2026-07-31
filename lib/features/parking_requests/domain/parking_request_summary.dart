enum ParkingRequestStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  const ParkingRequestStatus(this.storageValue);

  final String storageValue;

  static ParkingRequestStatus? tryParse(String? value) {
    for (final status in values) {
      if (status.storageValue == value) {
        return status;
      }
    }
    return null;
  }
}

class ParkingRequestSummary {
  const ParkingRequestSummary({
    required this.id,
    required this.status,
    this.address,
    this.totalSpaces,
    this.rating,
    this.hasGasStation = false,
    this.hasShower = false,
    this.hasLaundry = false,
    this.hasHotel = false,
    this.hasShop = false,
    this.hasRecreationArea = false,
  });

  final String id;
  final ParkingRequestStatus status;
  final String? address;
  final int? totalSpaces;
  final double? rating;
  final bool hasGasStation;
  final bool hasShower;
  final bool hasLaundry;
  final bool hasHotel;
  final bool hasShop;
  final bool hasRecreationArea;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParkingRequestSummary &&
          id == other.id &&
          status == other.status &&
          address == other.address &&
          totalSpaces == other.totalSpaces &&
          rating == other.rating &&
          hasGasStation == other.hasGasStation &&
          hasShower == other.hasShower &&
          hasLaundry == other.hasLaundry &&
          hasHotel == other.hasHotel &&
          hasShop == other.hasShop &&
          hasRecreationArea == other.hasRecreationArea;

  @override
  int get hashCode => Object.hash(
        id,
        status,
        address,
        totalSpaces,
        rating,
        hasGasStation,
        hasShower,
        hasLaundry,
        hasHotel,
        hasShop,
        hasRecreationArea,
      );
}
