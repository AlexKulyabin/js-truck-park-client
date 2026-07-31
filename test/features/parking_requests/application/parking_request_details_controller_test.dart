import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/parking_requests/application/parking_request_details_controller.dart';
import 'package:j_s_truck_park/features/parking_requests/application/parking_requests_controller.dart';
import 'package:j_s_truck_park/features/parking_requests/domain/parking_request_details.dart';
import 'package:j_s_truck_park/features/parking_requests/domain/parking_request_details_repository.dart';
import 'package:j_s_truck_park/features/parking_requests/domain/parking_requests_repository.dart';

class _FakeRepository implements ParkingRequestDetailsRepository {
  final photoReads = <String>[];
  final reviewReads = <String>[];
  final photoResponses = <Completer<List<ParkingRequestPhoto>>>[];
  final reviewResponses = <Completer<int>>[];

  @override
  Future<List<ParkingRequestPhoto>> fetchPhotos(String parkingId) {
    photoReads.add(parkingId);
    final response = Completer<List<ParkingRequestPhoto>>();
    photoResponses.add(response);
    return response.future;
  }

  @override
  Future<int> fetchReviewCount(String parkingId) {
    reviewReads.add(parkingId);
    final response = Completer<int>();
    reviewResponses.add(response);
    return response.future;
  }
}

void main() {
  test('loads photos and review count independently for one parking', () async {
    final repository = _FakeRepository();
    final controller = ParkingRequestDetailsController(
      repository: repository,
      parkingId: 'parking-1',
    );

    final loading = controller.load();

    expect(repository.photoReads, ['parking-1']);
    expect(repository.reviewReads, ['parking-1']);
    expect(controller.state.photosPhase, ParkingRequestsLoadPhase.loading);
    expect(
      controller.state.reviewCountPhase,
      ParkingRequestsLoadPhase.loading,
    );

    const photo = ParkingRequestPhoto(id: 'photo-1', url: 'photo-url');
    repository.photoResponses.single.complete([photo]);
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.photos, [photo]);
    expect(
      controller.state.reviewCountPhase,
      ParkingRequestsLoadPhase.loading,
    );

    repository.reviewResponses.single.complete(3);
    await loading;
    expect(controller.state.reviewCount, 3);
    expect(
      controller.state.reviewCountPhase,
      ParkingRequestsLoadPhase.loaded,
    );
  });

  test('ignores a stale photo response after retry', () async {
    final repository = _FakeRepository();
    final controller = ParkingRequestDetailsController(
      repository: repository,
      parkingId: 'parking-1',
    );

    final first = controller.loadPhotos();
    final second = controller.loadPhotos();
    const latest = ParkingRequestPhoto(id: 'latest', url: 'latest-url');
    repository.photoResponses[1].complete([latest]);
    await second;
    repository.photoResponses[0].complete(const []);
    await first;

    expect(controller.state.photos, [latest]);
  });

  test('publishes separate redacted failure categories', () async {
    final controller = ParkingRequestDetailsController(
      repository: _ThrowingRepository(),
      parkingId: 'parking-1',
    );

    await controller.load();

    expect(controller.state.photosPhase, ParkingRequestsLoadPhase.failure);
    expect(
      controller.state.reviewCountPhase,
      ParkingRequestsLoadPhase.failure,
    );
    expect(
      controller.state.photosFailureKind,
      ParkingRequestsFailureKind.unavailable,
    );
    expect(
      controller.state.reviewCountFailureKind,
      ParkingRequestsFailureKind.unavailable,
    );
  });
}

class _ThrowingRepository implements ParkingRequestDetailsRepository {
  @override
  Future<List<ParkingRequestPhoto>> fetchPhotos(String parkingId) {
    throw const ParkingRequestsReadException(
      ParkingRequestsFailureKind.unavailable,
    );
  }

  @override
  Future<int> fetchReviewCount(String parkingId) {
    throw const ParkingRequestsReadException(
      ParkingRequestsFailureKind.unavailable,
    );
  }
}
