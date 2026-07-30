class ParkingSheetDismissTracker {
  ParkingSheetDismissTracker({this.threshold = 72.0});

  final double threshold;
  double _downwardDrag = 0.0;

  bool registerDragDelta(double delta) {
    if (delta <= 0.0) {
      _downwardDrag = 0.0;
      return false;
    }

    _downwardDrag += delta;
    return _downwardDrag >= threshold;
  }

  void reset() {
    _downwardDrag = 0.0;
  }
}
