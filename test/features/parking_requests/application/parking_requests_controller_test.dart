import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/parking_requests/application/parking_requests_controller.dart';
import 'package:j_s_truck_park/features/parking_requests/domain/parking_request_summary.dart';
import 'package:j_s_truck_park/features/parking_requests/domain/parking_requests_repository.dart';

class _FakeRepository implements ParkingRequestsRepository {
  final calls = <({String userId, ParkingRequestStatus status})>[];
  final responses =
      <ParkingRequestStatus, Completer<List<ParkingRequestSummary>>>{};

  @override
  Future<List<ParkingRequestSummary>> fetchOwnedRequests({
    required String userId,
    required ParkingRequestStatus status,
  }) {
    calls.add((userId: userId, status: status));
    return responses.putIfAbsent(status, Completer.new).future;
  }
}

void main() {
  test('loads pending requests for the authenticated user', () async {
    final repository = _FakeRepository();
    final controller = ParkingRequestsController(
      repository: repository,
      userId: 'user-1',
    );

    final loading = controller.load();

    expect(controller.state.status, ParkingRequestStatus.pending);
    expect(controller.state.phase, ParkingRequestsLoadPhase.loading);
    expect(
      repository.calls,
      [(userId: 'user-1', status: ParkingRequestStatus.pending)],
    );

    const request = ParkingRequestSummary(
      id: 'parking-1',
      status: ParkingRequestStatus.pending,
    );
    repository.responses[ParkingRequestStatus.pending]!.complete([request]);
    await loading;

    expect(controller.state.phase, ParkingRequestsLoadPhase.loaded);
    expect(controller.state.requests, [request]);
  });

  test('ignores a stale response after another status is selected', () async {
    final repository = _FakeRepository();
    final controller = ParkingRequestsController(
      repository: repository,
      userId: 'user-1',
    );

    final pendingLoad = controller.load();
    final approvedLoad = controller.selectStatus(ParkingRequestStatus.approved);
    const approved = ParkingRequestSummary(
      id: 'parking-2',
      status: ParkingRequestStatus.approved,
    );
    repository.responses[ParkingRequestStatus.approved]!.complete([approved]);
    await approvedLoad;

    repository.responses[ParkingRequestStatus.pending]!.complete(const []);
    await pendingLoad;

    expect(controller.state.status, ParkingRequestStatus.approved);
    expect(controller.state.requests, [approved]);
  });

  test('publishes only a redacted typed failure', () async {
    final repository = _ThrowingRepository();
    final controller = ParkingRequestsController(
      repository: repository,
      userId: 'user-1',
    );

    await controller.load();

    expect(controller.state.phase, ParkingRequestsLoadPhase.failure);
    expect(
      controller.state.failureKind,
      ParkingRequestsFailureKind.unavailable,
    );
    expect(controller.state.requests, isEmpty);
  });
}

class _ThrowingRepository implements ParkingRequestsRepository {
  @override
  Future<List<ParkingRequestSummary>> fetchOwnedRequests({
    required String userId,
    required ParkingRequestStatus status,
  }) {
    throw const ParkingRequestsReadException(
      ParkingRequestsFailureKind.unavailable,
    );
  }
}
