-- Restrict parking photo row mutations to the authenticated owner.
--
-- Public reads remain unchanged. Storage object ownership is intentionally left
-- for a separate stage after storage policies are versioned in the baseline.

begin;

drop policy if exists "Authenticated can create parking photos"
  on public.parking_photos;

drop policy if exists "Authenticated can delete parking photos"
  on public.parking_photos;

drop policy if exists "photos_insert"
  on public.parking_photos;

create policy "photos_insert"
  on public.parking_photos
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "photos_delete"
  on public.parking_photos;

create policy "photos_delete"
  on public.parking_photos
  for delete
  to authenticated
  using (public.is_admin() or auth.uid() = user_id);

grant all privileges on table public.parking_photos to service_role;

commit;

-- Manual rollback (do not run automatically):
-- drop policy if exists "photos_insert" on public.parking_photos;
-- create policy "photos_insert" on public.parking_photos for insert
--   to authenticated with check (true);
-- drop policy if exists "photos_delete" on public.parking_photos;
-- create policy "photos_delete" on public.parking_photos for delete
--   to authenticated using ((public.is_admin() or (auth.uid() = user_id)));
-- create policy "Authenticated can create parking photos"
--   on public.parking_photos for insert to authenticated
--   with check (true);
-- create policy "Authenticated can delete parking photos"
--   on public.parking_photos for delete to authenticated
--   using (true);
