class ParkingRequestPhoto {
  const ParkingRequestPhoto({
    required this.id,
    required this.url,
  });

  final String id;
  final String url;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParkingRequestPhoto && id == other.id && url == other.url;

  @override
  int get hashCode => Object.hash(id, url);
}
