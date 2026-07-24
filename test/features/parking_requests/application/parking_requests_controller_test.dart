import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/backend/schema/enums/enums.dart';
import 'package:j_s_truck_park/backend/supabase/database/database.dart';
import 'package:j_s_truck_park/features/parking_requests/application/parking_requests_controller.dart';
import 'package:j_s_truck_park/features/parking_requests/data/parking_requests_service.dart';

void main() {
  group('ParkingRequestsController', () {
    test('starts on moderation with an empty loading state', () {
      final controller = ParkingRequestsController();

      expect(controller.state.status, ParkingRequestsLoadStatus.initial);
      expect(controller.state.selectedStatus, StatusParking.pending);
      expect(controller.state.items, isEmpty);
      expect(controller.state.showsLoadingIndicator, isTrue);
    });

    test('loads selected request status through the service', () async {
      final controller = ParkingRequestsController(
        service: ParkingRequestsService(
          gateway: _FakeParkingRequestsGateway(
            requestsByStatus: {
              StatusParking.approved: [
                ParkingsRow({
                  'id': 'parking-1',
                  'status': StatusParking.approved.name,
                }),
              ],
            },
          ),
        ),
      );

      await controller.load(
        userId: 'user-1',
        status: StatusParking.approved,
      );

      expect(controller.state.status, ParkingRequestsLoadStatus.loaded);
      expect(controller.state.selectedStatus, StatusParking.approved);
      expect(controller.state.items.single.id, 'parking-1');
      expect(controller.state.errorMessage, isNull);
    });

    test('exposes failure while preserving spinner-only UI behavior', () async {
      final controller = ParkingRequestsController(
        service: ParkingRequestsService(
          gateway: _FakeParkingRequestsGateway(shouldThrow: true),
        ),
      );

      await controller.load(
        userId: 'user-1',
        status: StatusParking.rejected,
      );

      expect(controller.state.status, ParkingRequestsLoadStatus.failure);
      expect(controller.state.selectedStatus, StatusParking.rejected);
      expect(controller.state.errorMessage, isNotNull);
      expect(controller.state.showsLoadingIndicator, isTrue);
    });

    test('ignores stale results after a fast tab switch', () async {
      final gateway = _FakeParkingRequestsGateway(holdPending: true);
      final controller = ParkingRequestsController(
        service: ParkingRequestsService(gateway: gateway),
      );

      final pendingLoad = controller.load(
        userId: 'user-1',
        status: StatusParking.pending,
      );
      await controller.load(
        userId: 'user-1',
        status: StatusParking.approved,
      );
      gateway.completePending([
        ParkingsRow({'id': 'stale-pending'}),
      ]);
      await pendingLoad;

      expect(controller.state.selectedStatus, StatusParking.approved);
      expect(controller.state.items, isEmpty);
    });
  });
}

class _FakeParkingRequestsGateway implements ParkingRequestsGateway {
  _FakeParkingRequestsGateway({
    this.requestsByStatus = const {},
    this.shouldThrow = false,
    this.holdPending = false,
  });

  final Map<StatusParking, List<ParkingsRow>> requestsByStatus;
  final bool shouldThrow;
  final bool holdPending;
  Completer<List<ParkingsRow>>? _pendingCompleter;

  @override
  Future<List<ParkingsRow>> listUserRequests({
    required String userId,
    required StatusParking status,
  }) async {
    if (shouldThrow) {
      throw StateError('load failed');
    }
    if (holdPending && status == StatusParking.pending) {
      _pendingCompleter = Completer<List<ParkingsRow>>();
      return _pendingCompleter!.future;
    }
    return requestsByStatus[status] ?? const [];
  }

  void completePending(List<ParkingsRow> requests) {
    _pendingCompleter?.complete(requests);
  }
}
