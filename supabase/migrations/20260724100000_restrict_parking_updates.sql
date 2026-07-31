-- Restrict direct parking updates to owner-maintained fields.
--
-- This removes the broad authenticated UPDATE policy and prevents client-side
-- moderation/ownership changes by relying on column-level grants.

begin;

drop policy if exists "Allow authenticated users to update parkings"
  on public.parkings;

drop policy if exists "parkings_update"
  on public.parkings;

create policy "parkings_update"
  on public.parkings
  for update
  to authenticated
  using ((auth.uid() = created_by) or public.is_admin())
  with check ((auth.uid() = created_by) or public.is_admin());

revoke update on table public.parkings from anon, authenticated;

grant update (
  address,
  latitude,
  longitude,
  parking_type,
  total_spaces,
  price,
  is_free,
  has_gas_station,
  has_shower,
  has_laundry,
  has_hotel,
  has_shop,
  has_recreation_area,
  updated_at,
  address_lower,
  photos
) on table public.parkings to authenticated;

grant all privileges on table public.parkings to service_role;

commit;

-- Manual rollback (do not run automatically):
-- revoke update (
--   address,
--   latitude,
--   longitude,
--   parking_type,
--   total_spaces,
--   price,
--   is_free,
--   has_gas_station,
--   has_shower,
--   has_laundry,
--   has_hotel,
--   has_shop,
--   has_recreation_area,
--   updated_at,
--   address_lower,
--   photos
-- ) on table public.parkings from authenticated;
-- grant update on table public.parkings to anon, authenticated;
-- drop policy if exists "parkings_update" on public.parkings;
-- create policy "parkings_update" on public.parkings for update
--   to authenticated
--   using (((auth.uid() = created_by) or public.is_admin()));
-- create policy "Allow authenticated users to update parkings"
--   on public.parkings for update to authenticated
--   using (true) with check (true);
