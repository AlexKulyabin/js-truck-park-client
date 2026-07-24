import 'package:flutter/foundation.dart';

enum ParkingFilterService {
  gas,
  shower,
  laundry,
  hotel,
  shop,
  recreation,
}

@immutable
class ParkingFilterState {
  const ParkingFilterState({
    required this.capacityFrom,
    required this.capacityTo,
    required this.hasGas,
    required this.hasShower,
    required this.hasLaundry,
    required this.hasHotel,
    required this.hasShop,
    required this.hasRecreation,
    required this.showNearest,
    required this.radiusIndex,
    required this.isApplied,
  });

  const ParkingFilterState.initial()
      : capacityFrom = 0,
        capacityTo = 100,
        hasGas = false,
        hasShower = false,
        hasLaundry = false,
        hasHotel = false,
        hasShop = false,
        hasRecreation = false,
        showNearest = false,
        radiusIndex = 0.0,
        isApplied = false;

  final int capacityFrom;
  final int capacityTo;
  final bool hasGas;
  final bool hasShower;
  final bool hasLaundry;
  final bool hasHotel;
  final bool hasShop;
  final bool hasRecreation;
  final bool showNearest;
  final double radiusIndex;
  final bool isApplied;

  double get radiusMeters =>
      showNearest ? metersFromRadiusIndex(radiusIndex) : 0;

  ParkingFilterState copyWith({
    int? capacityFrom,
    int? capacityTo,
    bool? hasGas,
    bool? hasShower,
    bool? hasLaundry,
    bool? hasHotel,
    bool? hasShop,
    bool? hasRecreation,
    bool? showNearest,
    double? radiusIndex,
    bool? isApplied,
  }) =>
      ParkingFilterState(
        capacityFrom: capacityFrom ?? this.capacityFrom,
        capacityTo: capacityTo ?? this.capacityTo,
        hasGas: hasGas ?? this.hasGas,
        hasShower: hasShower ?? this.hasShower,
        hasLaundry: hasLaundry ?? this.hasLaundry,
        hasHotel: hasHotel ?? this.hasHotel,
        hasShop: hasShop ?? this.hasShop,
        hasRecreation: hasRecreation ?? this.hasRecreation,
        showNearest: showNearest ?? this.showNearest,
        radiusIndex: radiusIndex ?? this.radiusIndex,
        isApplied: isApplied ?? this.isApplied,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParkingFilterState &&
          runtimeType == other.runtimeType &&
          capacityFrom == other.capacityFrom &&
          capacityTo == other.capacityTo &&
          hasGas == other.hasGas &&
          hasShower == other.hasShower &&
          hasLaundry == other.hasLaundry &&
          hasHotel == other.hasHotel &&
          hasShop == other.hasShop &&
          hasRecreation == other.hasRecreation &&
          showNearest == other.showNearest &&
          radiusIndex == other.radiusIndex &&
          isApplied == other.isApplied;

  @override
  int get hashCode => Object.hash(
        capacityFrom,
        capacityTo,
        hasGas,
        hasShower,
        hasLaundry,
        hasHotel,
        hasShop,
        hasRecreation,
        showNearest,
        radiusIndex,
        isApplied,
      );
}

class ParkingFilterController extends ChangeNotifier {
  ParkingFilterState _state = const ParkingFilterState.initial();

  ParkingFilterState get state => _state;

  void setCapacityFrom(int value) {
    _publish(_state.copyWith(capacityFrom: value));
  }

  void setCapacityTo(int value) {
    _publish(_state.copyWith(capacityTo: value));
  }

  void setService(ParkingFilterService service, bool enabled) {
    switch (service) {
      case ParkingFilterService.gas:
        _publish(_state.copyWith(hasGas: enabled));
      case ParkingFilterService.shower:
        _publish(_state.copyWith(hasShower: enabled));
      case ParkingFilterService.laundry:
        _publish(_state.copyWith(hasLaundry: enabled));
      case ParkingFilterService.hotel:
        _publish(_state.copyWith(hasHotel: enabled));
      case ParkingFilterService.shop:
        _publish(_state.copyWith(hasShop: enabled));
      case ParkingFilterService.recreation:
        _publish(_state.copyWith(hasRecreation: enabled));
    }
  }

  void setShowNearest(bool enabled) {
    _publish(_state.copyWith(showNearest: enabled));
  }

  void disableNearestAndResetRadius() {
    _publish(_state.copyWith(showNearest: false, radiusIndex: 0.0));
  }

  void setRadiusIndex(double value) {
    _publish(_state.copyWith(radiusIndex: value.roundToDouble()));
  }

  void apply() {
    _publish(_state.copyWith(isApplied: true));
  }

  void reset() {
    _publish(const ParkingFilterState.initial());
  }

  void restore(ParkingFilterState state) {
    _publish(state);
  }

  void _publish(ParkingFilterState state) {
    if (state == _state) {
      return;
    }
    _state = state;
    notifyListeners();
  }
}

double metersFromRadiusIndex(double radiusIndex) {
  switch (radiusIndex.round()) {
    case 0:
      return 5000.0;
    case 1:
      return 10000.0;
    case 2:
      return 50000.0;
    case 3:
      return 100000.0;
    case 4:
      return 150000.0;
    default:
      return 5000.0;
  }
}
