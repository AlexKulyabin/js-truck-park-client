# Parking filter state characterization

## Scope

This document records the parking discovery filter state contract after moving
the filter out of `FFAppState`. It is a characterization note, not a behavior
change.

## Current owner

Filter values are owned by `ParkingFilterController`, provided through
Provider, and edited by `FilterWidget`. Home Map and Select Parking convert the
controller state into a `MapFilterSnapshot`, then into `MapParkingQuery` for
`get_filtered_parkings`.

The former filter fields have been removed from `FFAppState`; that global state
is no longer a source or mirror for map filters.

Current controller fields:

- `capacityFrom`, default `0`
- `capacityTo`, default `100`
- `hasGas`, default `false`
- `hasShower`, default `false`
- `hasLaundry`, default `false`
- `hasHotel`, default `false`
- `hasShop`, default `false`
- `hasRecreation`, default `false`
- `showNearest`, default `false`
- `radiusIndex`, default `0.0`
- `isApplied`, default `false`

## Query behavior

- Capacity and service flags are always copied into the map query.
- `radiusIndex` is converted through the preserved radius scale.
- Radius is sent as `0.0` unless `showNearest` is `true`.
- `isApplied` is sent as `is_filter_active`.
- The search query is passed through separately by the map/search flow.

## UI actions

- `Reset` restores controller defaults, clears `isApplied`, resets local field
  and checkbox controls, and closes the filter screen with `true`.
- `Apply` sets `isApplied` to `true` and closes the filter screen with
  `true`.
- Back navigation closes the filter screen without setting `isApplied`.

These behaviors are covered by
`test/features/map/application/parking_filter_controller_test.dart` and
`test/features/map/presentation/parking_filter_widget_controller_test.dart`.
