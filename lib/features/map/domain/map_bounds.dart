class MapBounds {
  const MapBounds({
    required this.minLatitude,
    required this.minLongitude,
    required this.maxLatitude,
    required this.maxLongitude,
  });

  final double minLatitude;
  final double minLongitude;
  final double maxLatitude;
  final double maxLongitude;

  double get centerLatitude => (minLatitude + maxLatitude) / 2;
  double get centerLongitude => (minLongitude + maxLongitude) / 2;
  bool get crossesAntimeridian => minLongitude > maxLongitude;

  bool get isFinite =>
      minLatitude.isFinite &&
      minLongitude.isFinite &&
      maxLatitude.isFinite &&
      maxLongitude.isFinite;

  bool get hasValidCoordinateRanges =>
      minLatitude >= -90 &&
      minLatitude <= 90 &&
      maxLatitude >= -90 &&
      maxLatitude <= 90 &&
      minLongitude >= -180 &&
      minLongitude <= 180 &&
      maxLongitude >= -180 &&
      maxLongitude <= 180;

  bool get hasOrderedLatitudes => minLatitude <= maxLatitude;
}
