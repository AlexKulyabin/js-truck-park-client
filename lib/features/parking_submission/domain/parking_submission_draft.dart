import 'dart:typed_data';

enum ParkingSubmissionValidationIssue {
  missingAddress,
  missingLatitude,
  missingLongitude,
  latitudeOutOfRange,
  longitudeOutOfRange,
}

class ParkingSubmissionServices {
  const ParkingSubmissionServices({
    this.hasGasStation = false,
    this.hasShower = false,
    this.hasLaundry = false,
    this.hasHotel = false,
    this.hasShop = false,
    this.hasRecreationArea = false,
  });

  factory ParkingSubmissionServices.fromLegacyValues({
    bool? hasGasStation,
    bool? hasShower,
    bool? hasLaundry,
    bool? hasHotel,
    bool? hasShop,
    bool? hasRecreationArea,
  }) =>
      ParkingSubmissionServices(
        hasGasStation: hasGasStation ?? false,
        hasShower: hasShower ?? false,
        hasLaundry: hasLaundry ?? false,
        hasHotel: hasHotel ?? false,
        hasShop: hasShop ?? false,
        hasRecreationArea: hasRecreationArea ?? false,
      );

  final bool hasGasStation;
  final bool hasShower;
  final bool hasLaundry;
  final bool hasHotel;
  final bool hasShop;
  final bool hasRecreationArea;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParkingSubmissionServices &&
          hasGasStation == other.hasGasStation &&
          hasShower == other.hasShower &&
          hasLaundry == other.hasLaundry &&
          hasHotel == other.hasHotel &&
          hasShop == other.hasShop &&
          hasRecreationArea == other.hasRecreationArea;

  @override
  int get hashCode => Object.hash(
        hasGasStation,
        hasShower,
        hasLaundry,
        hasHotel,
        hasShop,
        hasRecreationArea,
      );
}

class ParkingSubmissionPhoto {
  const ParkingSubmissionPhoto({
    required this.name,
    required this.bytes,
    this.originalFilename,
  });

  final String name;
  final Uint8List bytes;
  final String? originalFilename;

  bool get hasBytes => bytes.isNotEmpty;

  String storagePath({
    required String parkingId,
    required int index,
  }) =>
      'parkings/$parkingId/$index';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParkingSubmissionPhoto &&
          name == other.name &&
          _listEquals(bytes, other.bytes) &&
          originalFilename == other.originalFilename;

  @override
  int get hashCode => Object.hash(
        name,
        Object.hashAll(bytes),
        originalFilename,
      );
}

class ParkingSubmissionDraft {
  const ParkingSubmissionDraft({
    required this.totalSpaces,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.services,
    this.photos = const [],
  });

  factory ParkingSubmissionDraft.fromLegacyForm({
    required String capacityText,
    required String? address,
    required double? latitude,
    required double? longitude,
    bool? hasGasStation,
    bool? hasShower,
    bool? hasLaundry,
    bool? hasHotel,
    bool? hasShop,
    bool? hasRecreationArea,
    List<ParkingSubmissionPhoto> photos = const [],
  }) =>
      ParkingSubmissionDraft(
        totalSpaces: int.tryParse(capacityText),
        address: address,
        latitude: latitude,
        longitude: longitude,
        services: ParkingSubmissionServices.fromLegacyValues(
          hasGasStation: hasGasStation,
          hasShower: hasShower,
          hasLaundry: hasLaundry,
          hasHotel: hasHotel,
          hasShop: hasShop,
          hasRecreationArea: hasRecreationArea,
        ),
        photos: List.unmodifiable(photos),
      );

  final int? totalSpaces;
  final String? address;
  final double? latitude;
  final double? longitude;
  final ParkingSubmissionServices services;
  final List<ParkingSubmissionPhoto> photos;

  String get addressLower {
    final value = address;
    if (value == null || value.isEmpty) {
      return '';
    }
    return value.toLowerCase();
  }

  List<ParkingSubmissionValidationIssue> get validationIssues {
    final issues = <ParkingSubmissionValidationIssue>[];
    final addressValue = address;
    if (addressValue == null ||
        addressValue.isEmpty ||
        addressValue == 'null') {
      issues.add(ParkingSubmissionValidationIssue.missingAddress);
    }
    final latitudeValue = latitude;
    if (latitudeValue == null) {
      issues.add(ParkingSubmissionValidationIssue.missingLatitude);
    } else if (latitudeValue < -90 || latitudeValue > 90) {
      issues.add(ParkingSubmissionValidationIssue.latitudeOutOfRange);
    }
    final longitudeValue = longitude;
    if (longitudeValue == null) {
      issues.add(ParkingSubmissionValidationIssue.missingLongitude);
    } else if (longitudeValue < -180 || longitudeValue > 180) {
      issues.add(ParkingSubmissionValidationIssue.longitudeOutOfRange);
    }
    return List.unmodifiable(issues);
  }

  bool get isValid => validationIssues.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParkingSubmissionDraft &&
          totalSpaces == other.totalSpaces &&
          address == other.address &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          services == other.services &&
          _listEquals(photos, other.photos);

  @override
  int get hashCode => Object.hash(
        totalSpaces,
        address,
        latitude,
        longitude,
        services,
        Object.hashAll(photos),
      );
}

bool _listEquals<T>(List<T> first, List<T> second) {
  if (identical(first, second)) {
    return true;
  }
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) {
      return false;
    }
  }
  return true;
}
