-- Allow authenticated users to manage only their own review content.
--
-- Public review reads and owner inserts remain unchanged. This stage adds
-- owner/admin updates for mutable review content and owner/admin deletes,
-- while keeping identity, parking, timestamp and calculated score immutable
-- for direct client writes.

begin;

drop policy if exists "Allow authenticated users to insert reviews"
  on public.reviews;

drop policy if exists "Allow public select of reviews"
  on public.reviews;

drop policy if exists "Allow public select on reviews"
  on public.reviews;

drop policy if exists "reviews_select"
  on public.reviews;

create policy "reviews_select"
  on public.reviews
  for select
  using (true);

drop policy if exists "reviews_insert"
  on public.reviews;

create policy "reviews_insert"
  on public.reviews
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "reviews_update"
  on public.reviews;

create policy "reviews_update"
  on public.reviews
  for update
  to authenticated
  using ((auth.uid() = user_id) or public.is_admin())
  with check ((auth.uid() = user_id) or public.is_admin());

drop policy if exists "reviews_delete"
  on public.reviews;

create policy "reviews_delete"
  on public.reviews
  for delete
  to authenticated
  using ((auth.uid() = user_id) or public.is_admin());

grant select on table public.reviews to anon, authenticated;
grant insert on table public.reviews to authenticated;
grant delete on table public.reviews to authenticated;

revoke update on table public.reviews from anon, authenticated;

grant update (
  comment,
  rating_impression,
  rating_arrival,
  rating_security,
  rating_infrastructure,
  rating_comfort
) on table public.reviews to authenticated;

grant all privileges on table public.reviews to service_role;
grant usage, select on sequence public.reviews_id_seq to authenticated, service_role;

commit;

-- Manual rollback (do not run automatically):
-- revoke update (
--   comment,
--   rating_impression,
--   rating_arrival,
--   rating_security,
--   rating_infrastructure,
--   rating_comfort
-- ) on table public.reviews from authenticated;
-- revoke delete on table public.reviews from authenticated;
-- drop policy if exists "reviews_update" on public.reviews;
-- drop policy if exists "reviews_delete" on public.reviews;
-- create policy "reviews_delete" on public.reviews for delete
--   to authenticated using (public.is_admin());
