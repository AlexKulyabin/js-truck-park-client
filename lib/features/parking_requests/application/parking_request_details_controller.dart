import 'package:flutter/foundation.dart';

import '../domain/parking_request_details.dart';
import '../domain/parking_request_details_repository.dart';
import '../domain/parking_requests_repository.dart';
import 'parking_requests_controller.dart';

@immutable
class ParkingRequestDetailsState {
  const ParkingRequestDetailsState({
    required this.photosPhase,
    required this.photos,
    required this.reviewCountPhase,
    required this.reviewCount,
    this.photosFailureKind,
    this.reviewCountFailureKind,
  });

  const ParkingRequestDetailsState.initial()
      : photosPhase = ParkingRequestsLoadPhase.idle,
        photos = const [],
        reviewCountPhase = ParkingRequestsLoadPhase.idle,
        reviewCount = 0,
        photosFailureKind = null,
        reviewCountFailureKind = null;

  final ParkingRequestsLoadPhase photosPhase;
  final List<ParkingRequestPhoto> photos;
  final ParkingRequestsLoadPhase reviewCountPhase;
  final int reviewCount;
  final ParkingRequestsFailureKind? photosFailureKind;
  final ParkingRequestsFailureKind? reviewCountFailureKind;
}

class ParkingRequestDetailsController extends ChangeNotifier {
  ParkingRequestDetailsController({
    required ParkingRequestDetailsRepository repository,
    required String parkingId,
  })  : _repository = repository,
        _parkingId = parkingId;

  final ParkingRequestDetailsRepository _repository;
  final String _parkingId;

  ParkingRequestDetailsState _state =
      const ParkingRequestDetailsState.initial();
  int _photosGeneration = 0;
  int _reviewCountGeneration = 0;
  bool _disposed = false;

  ParkingRequestDetailsState get state => _state;

  Future<void> load() async {
    await Future.wait([loadPhotos(), loadReviewCount()]);
  }

  Future<void> loadPhotos() async {
    final generation = ++_photosGeneration;
    _publish(
      ParkingRequestDetailsState(
        photosPhase: ParkingRequestsLoadPhase.loading,
        photos: const [],
        reviewCountPhase: _state.reviewCountPhase,
        reviewCount: _state.reviewCount,
        reviewCountFailureKind: _state.reviewCountFailureKind,
      ),
    );

    try {
      final photos = await _repository.fetchPhotos(_parkingId);
      if (generation != _photosGeneration || _disposed) {
        return;
      }
      _publish(
        ParkingRequestDetailsState(
          photosPhase: ParkingRequestsLoadPhase.loaded,
          photos: List.unmodifiable(photos),
          reviewCountPhase: _state.reviewCountPhase,
          reviewCount: _state.reviewCount,
          reviewCountFailureKind: _state.reviewCountFailureKind,
        ),
      );
    } on ParkingRequestsReadException catch (error) {
      _publishPhotosFailure(generation, error.kind);
    } catch (_) {
      _publishPhotosFailure(
        generation,
        ParkingRequestsFailureKind.unavailable,
      );
    }
  }

  Future<void> loadReviewCount() async {
    final generation = ++_reviewCountGeneration;
    _publish(
      ParkingRequestDetailsState(
        photosPhase: _state.photosPhase,
        photos: _state.photos,
        photosFailureKind: _state.photosFailureKind,
        reviewCountPhase: ParkingRequestsLoadPhase.loading,
        reviewCount: 0,
      ),
    );

    try {
      final count = await _repository.fetchReviewCount(_parkingId);
      if (generation != _reviewCountGeneration || _disposed) {
        return;
      }
      _publish(
        ParkingRequestDetailsState(
          photosPhase: _state.photosPhase,
          photos: _state.photos,
          photosFailureKind: _state.photosFailureKind,
          reviewCountPhase: ParkingRequestsLoadPhase.loaded,
          reviewCount: count,
        ),
      );
    } on ParkingRequestsReadException catch (error) {
      _publishReviewCountFailure(generation, error.kind);
    } catch (_) {
      _publishReviewCountFailure(
        generation,
        ParkingRequestsFailureKind.unavailable,
      );
    }
  }

  void _publishPhotosFailure(
    int generation,
    ParkingRequestsFailureKind kind,
  ) {
    if (generation != _photosGeneration || _disposed) {
      return;
    }
    _publish(
      ParkingRequestDetailsState(
        photosPhase: ParkingRequestsLoadPhase.failure,
        photos: const [],
        photosFailureKind: kind,
        reviewCountPhase: _state.reviewCountPhase,
        reviewCount: _state.reviewCount,
        reviewCountFailureKind: _state.reviewCountFailureKind,
      ),
    );
  }

  void _publishReviewCountFailure(
    int generation,
    ParkingRequestsFailureKind kind,
  ) {
    if (generation != _reviewCountGeneration || _disposed) {
      return;
    }
    _publish(
      ParkingRequestDetailsState(
        photosPhase: _state.photosPhase,
        photos: _state.photos,
        photosFailureKind: _state.photosFailureKind,
        reviewCountPhase: ParkingRequestsLoadPhase.failure,
        reviewCount: 0,
        reviewCountFailureKind: kind,
      ),
    );
  }

  void _publish(ParkingRequestDetailsState state) {
    if (_disposed) {
      return;
    }
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _photosGeneration++;
    _reviewCountGeneration++;
    super.dispose();
  }
}
