import 'package:flutter/foundation.dart';

import '../domain/parking_details.dart';
import '../domain/parking_details_repository.dart';

enum ParkingDetailsLoadPhase { idle, loading, loaded, failure }

@immutable
class ParkingDetailsState {
  const ParkingDetailsState({
    required this.detailsPhase,
    required this.reviewsPhase,
    required this.reviews,
    this.details,
    this.detailsFailureKind,
    this.reviewsFailureKind,
  });

  const ParkingDetailsState.initial()
      : detailsPhase = ParkingDetailsLoadPhase.idle,
        reviewsPhase = ParkingDetailsLoadPhase.idle,
        details = null,
        reviews = const [],
        detailsFailureKind = null,
        reviewsFailureKind = null;

  final ParkingDetailsLoadPhase detailsPhase;
  final ParkingDetailsLoadPhase reviewsPhase;
  final ParkingDetails? details;
  final List<ParkingReview> reviews;
  final ParkingDetailsFailureKind? detailsFailureKind;
  final ParkingDetailsFailureKind? reviewsFailureKind;
}

class ParkingDetailsController extends ChangeNotifier {
  ParkingDetailsController({
    required ParkingDetailsRepository repository,
    required String parkingId,
  })  : _repository = repository,
        _parkingId = parkingId;

  final ParkingDetailsRepository _repository;
  final String _parkingId;

  ParkingDetailsState _state = const ParkingDetailsState.initial();
  int _detailsGeneration = 0;
  int _reviewsGeneration = 0;
  bool _disposed = false;

  ParkingDetailsState get state => _state;

  Future<void> loadDetails() async {
    final generation = ++_detailsGeneration;
    _publish(
      ParkingDetailsState(
        detailsPhase: ParkingDetailsLoadPhase.loading,
        reviewsPhase: _state.reviewsPhase,
        reviews: _state.reviews,
        reviewsFailureKind: _state.reviewsFailureKind,
      ),
    );

    try {
      final details = await _repository.fetchDetails(_parkingId);
      if (_disposed || generation != _detailsGeneration) {
        return;
      }
      _publish(
        ParkingDetailsState(
          detailsPhase: ParkingDetailsLoadPhase.loaded,
          details: details,
          reviewsPhase: _state.reviewsPhase,
          reviews: _state.reviews,
          reviewsFailureKind: _state.reviewsFailureKind,
        ),
      );
    } on ParkingDetailsReadException catch (error) {
      _publishDetailsFailure(generation, error.kind);
    } catch (_) {
      _publishDetailsFailure(
        generation,
        ParkingDetailsFailureKind.unavailable,
      );
    }
  }

  Future<void> loadReviews() async {
    final generation = ++_reviewsGeneration;
    _publish(
      ParkingDetailsState(
        detailsPhase: _state.detailsPhase,
        details: _state.details,
        detailsFailureKind: _state.detailsFailureKind,
        reviewsPhase: ParkingDetailsLoadPhase.loading,
        reviews: const [],
      ),
    );

    try {
      final reviews = await _repository.fetchReviews(_parkingId);
      if (_disposed || generation != _reviewsGeneration) {
        return;
      }
      _publish(
        ParkingDetailsState(
          detailsPhase: _state.detailsPhase,
          details: _state.details,
          detailsFailureKind: _state.detailsFailureKind,
          reviewsPhase: ParkingDetailsLoadPhase.loaded,
          reviews: List.unmodifiable(reviews),
        ),
      );
    } on ParkingDetailsReadException catch (error) {
      _publishReviewsFailure(generation, error.kind);
    } catch (_) {
      _publishReviewsFailure(
        generation,
        ParkingDetailsFailureKind.unavailable,
      );
    }
  }

  void _publishDetailsFailure(
    int generation,
    ParkingDetailsFailureKind kind,
  ) {
    if (_disposed || generation != _detailsGeneration) {
      return;
    }
    _publish(
      ParkingDetailsState(
        detailsPhase: ParkingDetailsLoadPhase.failure,
        detailsFailureKind: kind,
        reviewsPhase: _state.reviewsPhase,
        reviews: _state.reviews,
        reviewsFailureKind: _state.reviewsFailureKind,
      ),
    );
  }

  void _publishReviewsFailure(
    int generation,
    ParkingDetailsFailureKind kind,
  ) {
    if (_disposed || generation != _reviewsGeneration) {
      return;
    }
    _publish(
      ParkingDetailsState(
        detailsPhase: _state.detailsPhase,
        details: _state.details,
        detailsFailureKind: _state.detailsFailureKind,
        reviewsPhase: ParkingDetailsLoadPhase.failure,
        reviews: const [],
        reviewsFailureKind: kind,
      ),
    );
  }

  void _publish(ParkingDetailsState state) {
    if (_disposed) {
      return;
    }
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _detailsGeneration++;
    _reviewsGeneration++;
    super.dispose();
  }
}
