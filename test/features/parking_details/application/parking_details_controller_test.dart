import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/parking_details/application/parking_details_controller.dart';
import 'package:j_s_truck_park/features/parking_details/domain/parking_details.dart';
import 'package:j_s_truck_park/features/parking_details/domain/parking_details_repository.dart';

class _FakeRepository implements ParkingDetailsRepository {
  ParkingDetails? details;
  List<ParkingReview> reviews = [];
  Object? detailsError;
  Object? reviewsError;
  final detailLoads = <Completer<ParkingDetails?>>[];

  @override
  Future<ParkingDetails?> fetchDetails(String parkingId) {
    if (detailsError case final error?) {
      return Future.error(error);
    }
    if (detailLoads.isNotEmpty) {
      return detailLoads.removeAt(0).future;
    }
    return Future.value(details);
  }

  @override
  Future<List<ParkingReview>> fetchReviews(String parkingId) {
    if (reviewsError case final error?) {
      return Future.error(error);
    }
    return Future.value(reviews);
  }
}

void main() {
  test('loads details and reviews as independent state slices', () async {
    final repository = _FakeRepository()
      ..details = const ParkingDetails(
        id: 'parking-1',
        isFavorited: true,
      )
      ..reviews = const [ParkingReview(id: 1, parkingId: 'parking-1')];
    final controller = ParkingDetailsController(
      repository: repository,
      parkingId: 'parking-1',
    );

    await controller.loadDetails();
    expect(controller.state.detailsPhase, ParkingDetailsLoadPhase.loaded);
    expect(controller.state.details?.isFavorited, isTrue);
    expect(controller.state.reviewsPhase, ParkingDetailsLoadPhase.idle);

    await controller.loadReviews();
    expect(controller.state.details?.id, 'parking-1');
    expect(controller.state.reviewsPhase, ParkingDetailsLoadPhase.loaded);
    expect(controller.state.reviews.single.id, 1);
    controller.dispose();
  });

  test('ignores a stale details response after retry', () async {
    final first = Completer<ParkingDetails?>();
    final second = Completer<ParkingDetails?>();
    final repository = _FakeRepository()..detailLoads.addAll([first, second]);
    final controller = ParkingDetailsController(
      repository: repository,
      parkingId: 'parking-1',
    );

    final firstLoad = controller.loadDetails();
    final secondLoad = controller.loadDetails();
    second.complete(
      const ParkingDetails(id: 'parking-1', isFavorited: true),
    );
    await secondLoad;
    first.complete(
      const ParkingDetails(id: 'stale', isFavorited: false),
    );
    await firstLoad;

    expect(controller.state.details?.id, 'parking-1');
    expect(controller.state.details?.isFavorited, isTrue);
    controller.dispose();
  });

  test('publishes only typed redacted failure categories', () async {
    final repository = _FakeRepository()
      ..detailsError = StateError('raw details')
      ..reviewsError = StateError('raw reviews');
    final controller = ParkingDetailsController(
      repository: repository,
      parkingId: 'parking-1',
    );

    await controller.loadDetails();
    await controller.loadReviews();

    expect(controller.state.detailsPhase, ParkingDetailsLoadPhase.failure);
    expect(
      controller.state.detailsFailureKind,
      ParkingDetailsFailureKind.unavailable,
    );
    expect(controller.state.reviewsPhase, ParkingDetailsLoadPhase.failure);
    expect(
      controller.state.reviewsFailureKind,
      ParkingDetailsFailureKind.unavailable,
    );
    controller.dispose();
  });
}
