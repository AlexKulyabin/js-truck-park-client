import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/map/application/parking_filter_controller.dart';

void main() {
  test('starts with the legacy filter defaults', () {
    final controller = ParkingFilterController();

    expect(controller.state, const ParkingFilterState.initial());
    expect(controller.state.capacityFrom, 0);
    expect(controller.state.capacityTo, 100);
    expect(controller.state.hasGas, isFalse);
    expect(controller.state.hasShower, isFalse);
    expect(controller.state.hasLaundry, isFalse);
    expect(controller.state.hasHotel, isFalse);
    expect(controller.state.hasShop, isFalse);
    expect(controller.state.hasRecreation, isFalse);
    expect(controller.state.showNearest, isFalse);
    expect(controller.state.radiusIndex, 0);
    expect(controller.state.radiusMeters, 0);
    expect(controller.state.isApplied, isFalse);
  });

  test('publishes immutable capacity, service and apply changes', () {
    final controller = ParkingFilterController();
    final states = <ParkingFilterState>[];
    controller.addListener(() => states.add(controller.state));

    controller
      ..setCapacityFrom(5)
      ..setCapacityTo(25)
      ..setService(ParkingFilterService.gas, true)
      ..setService(ParkingFilterService.shower, true)
      ..setService(ParkingFilterService.laundry, true)
      ..setService(ParkingFilterService.hotel, true)
      ..setService(ParkingFilterService.shop, true)
      ..setService(ParkingFilterService.recreation, true)
      ..apply();

    expect(states, hasLength(9));
    expect(
      controller.state,
      const ParkingFilterState(
        capacityFrom: 5,
        capacityTo: 25,
        hasGas: true,
        hasShower: true,
        hasLaundry: true,
        hasHotel: true,
        hasShop: true,
        hasRecreation: true,
        showNearest: false,
        radiusIndex: 0,
        isApplied: true,
      ),
    );
  });

  test('keeps nearest radius gated by the nearest switch', () {
    final controller = ParkingFilterController();

    controller.setRadiusIndex(3.2);
    expect(controller.state.radiusIndex, 3);
    expect(controller.state.radiusMeters, 0);

    controller.setShowNearest(true);
    expect(controller.state.radiusMeters, 100000);

    controller.disableNearestAndResetRadius();
    expect(controller.state.showNearest, isFalse);
    expect(controller.state.radiusIndex, 0);
    expect(controller.state.radiusMeters, 0);
  });

  test('preserves the legacy radius index mapping', () {
    expect(metersFromRadiusIndex(0), 5000);
    expect(metersFromRadiusIndex(1), 10000);
    expect(metersFromRadiusIndex(2), 50000);
    expect(metersFromRadiusIndex(3), 100000);
    expect(metersFromRadiusIndex(4), 150000);
    expect(metersFromRadiusIndex(99), 5000);
  });

  test('reset and restore publish whole state replacements', () {
    final controller = ParkingFilterController()
      ..setCapacityFrom(5)
      ..setService(ParkingFilterService.shop, true)
      ..apply();
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.reset();
    expect(controller.state, const ParkingFilterState.initial());

    controller.restore(
      const ParkingFilterState(
        capacityFrom: 1,
        capacityTo: 2,
        hasGas: true,
        hasShower: false,
        hasLaundry: false,
        hasHotel: false,
        hasShop: true,
        hasRecreation: false,
        showNearest: true,
        radiusIndex: 4,
        isApplied: true,
      ),
    );

    expect(controller.state.capacityFrom, 1);
    expect(controller.state.capacityTo, 2);
    expect(controller.state.hasGas, isTrue);
    expect(controller.state.hasShop, isTrue);
    expect(controller.state.radiusMeters, 150000);
    expect(controller.state.isApplied, isTrue);
    expect(notifications, 2);
  });

  test('silent restore replaces state without notifying listeners', () {
    final controller = ParkingFilterController();
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.restoreSilently(
      const ParkingFilterState(
        capacityFrom: 1,
        capacityTo: 2,
        hasGas: false,
        hasShower: true,
        hasLaundry: false,
        hasHotel: false,
        hasShop: false,
        hasRecreation: true,
        showNearest: true,
        radiusIndex: 2,
        isApplied: false,
      ),
    );

    expect(controller.state.capacityFrom, 1);
    expect(controller.state.hasShower, isTrue);
    expect(controller.state.hasRecreation, isTrue);
    expect(controller.state.radiusMeters, 50000);
    expect(notifications, 0);
  });

  test('does not notify when a command keeps the same state', () {
    final controller = ParkingFilterController();
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller
      ..setCapacityFrom(0)
      ..setService(ParkingFilterService.gas, false)
      ..reset();

    expect(notifications, 0);
  });
}
