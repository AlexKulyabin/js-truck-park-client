# Parking filter state characterization

## Scope

This document records the legacy filter state contract before moving parking
discovery filters out of `FFAppState`. It is a characterization note, not a
behavior change.

## Current owner

Filter values are stored globally in `FFAppState` and are edited by
`FilterWidget`. Home Map and Select Parking convert those fields into a
`MapFilterSnapshot`, then into `MapParkingQuery` for `get_filtered_parkings`.

`ParkingFilterController` has been added as the next feature-scoped owner and
is available through Provider. The current UI still reads and writes
`FFAppState` until the migration stages move the screen and map consumers.

Current legacy fields:

- `filterCapacityFrom`, default `0`
- `filterCapacityTo`, default `100`
- `isFilterHasGas`, default `false`
- `isFilterHasShower`, default `false`
- `isFilterHasLaundry`, default `false`
- `isFilterHasHotel`, default `false`
- `isFilterHasShop`, default `false`
- `isFilterHasRecreation`, default `false`
- `isFilterShowNearest`, default `false`
- `filterRadius`, default `0.0`
- `isFilterApplied`, default `false`

## Query behavior

- Capacity and service flags are always copied into the map query.
- `filterRadius` is converted through `getMetersFromIndex`.
- Radius is sent as `0.0` unless `isFilterShowNearest` is `true`.
- `isFilterApplied` is sent as `is_filter_active`.
- The search query is passed through separately by the map/search flow.

## UI actions

- `Reset` restores legacy defaults, clears `isFilterApplied`, resets local
  field and checkbox controls, and closes the filter screen with `true`.
- `Apply` sets `isFilterApplied` to `true` and closes the filter screen with
  `true`.
- Back navigation closes the filter screen without setting
  `isFilterApplied`.

These behaviors are covered by
`test/features/map/legacy/legacy_filter_state_contract_test.dart` so the next
controller migration can be checked against the current app behavior.
