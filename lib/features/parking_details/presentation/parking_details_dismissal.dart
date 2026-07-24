bool shouldDismissParkingDetails({required double? primaryVelocity}) {
  return (primaryVelocity ?? 0) > 0;
}
