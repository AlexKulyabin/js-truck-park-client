import 'package:flutter/foundation.dart';

import '/backend/schema/enums/enums.dart';
import '/backend/supabase/database/database.dart';
import '../data/parking_requests_service.dart';

enum ParkingRequestsLoadStatus {
  initial,
  loading,
  loaded,
  failure,
}

class ParkingRequestsState {
  const ParkingRequestsState({
    this.status = ParkingRequestsLoadStatus.initial,
    this.selectedStatus = StatusParking.pending,
    this.items = const [],
    this.errorMessage,
  });

  final ParkingRequestsLoadStatus status;
  final StatusParking selectedStatus;
  final List<ParkingsRow> items;
  final String? errorMessage;

  bool get showsLoadingIndicator =>
      status == ParkingRequestsLoadStatus.initial ||
      status == ParkingRequestsLoadStatus.loading ||
      status == ParkingRequestsLoadStatus.failure;
}

class ParkingRequestsController extends ChangeNotifier {
  ParkingRequestsController({
    ParkingRequestsService? service,
  }) : _service = service ?? ParkingRequestsService();

  final ParkingRequestsService _service;

  ParkingRequestsState _state = const ParkingRequestsState();
  int _loadGeneration = 0;

  ParkingRequestsState get state => _state;

  Future<void> load({
    required String? userId,
    required StatusParking status,
  }) async {
    final generation = ++_loadGeneration;
    _setState(
      ParkingRequestsState(
        status: ParkingRequestsLoadStatus.loading,
        selectedStatus: status,
        items: _state.selectedStatus == status ? _state.items : const [],
      ),
    );

    try {
      final items = await _service.listUserRequests(
        userId: userId,
        status: status,
      );
      if (generation != _loadGeneration) {
        return;
      }

      _setState(
        ParkingRequestsState(
          status: ParkingRequestsLoadStatus.loaded,
          selectedStatus: status,
          items: List.unmodifiable(items),
        ),
      );
    } catch (_) {
      if (generation != _loadGeneration) {
        return;
      }

      _setState(
        ParkingRequestsState(
          status: ParkingRequestsLoadStatus.failure,
          selectedStatus: status,
          items: _state.items,
          errorMessage: 'Could not load parking requests.',
        ),
      );
    }
  }

  void _setState(ParkingRequestsState state) {
    _state = state;
    notifyListeners();
  }
}
