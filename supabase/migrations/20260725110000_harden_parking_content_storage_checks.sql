-- Evaluate parking-content ownership without requiring direct table grants.
--
-- Storage RLS policies run as the caller. Direct subqueries against parkings
-- and reviews therefore fail before ownership can be evaluated when the caller
-- intentionally has no SELECT grant on those base tables.

begin;

create schema if not exists private;

revoke all on schema private from public, anon;
grant usage on schema private to authenticated, service_role;

create or replace function private.can_manage_parking_content(
  object_name text
) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when auth.uid() is null
      or split_part(object_name, '/', 1) <> 'parkings'
      or split_part(object_name, '/', 2) = ''
    then false
    when split_part(object_name, '/', 3) = 'reviews'
    then
      split_part(object_name, '/', 4) <> ''
      and split_part(object_name, '/', 5) <> ''
      and exists (
        select 1
        from public.reviews review_row
        where review_row.parking_id::text = split_part(object_name, '/', 2)
          and review_row.id::text = split_part(object_name, '/', 4)
          and review_row.user_id = auth.uid()
      )
    else
      split_part(object_name, '/', 3) <> ''
      and exists (
        select 1
        from public.parkings parking
        where parking.id::text = split_part(object_name, '/', 2)
          and parking.created_by = auth.uid()
      )
  end;
$$;

revoke all on function private.can_manage_parking_content(text)
  from public, anon;
grant execute on function private.can_manage_parking_content(text)
  to authenticated, service_role;

drop policy if exists "avatars_select_own"
  on storage.objects;

create policy "avatars_select_own"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = 'users'
    and (storage.foldername(name))[2] = (select auth.uid()::text)
  );

drop policy if exists "parking_content_select_own"
  on storage.objects;

create policy "parking_content_select_own"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'parking_content'
    and private.can_manage_parking_content(name)
  );

drop policy if exists "parking_content_insert_own"
  on storage.objects;

create policy "parking_content_insert_own"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'parking_content'
    and private.can_manage_parking_content(name)
  );

drop policy if exists "parking_content_update_own"
  on storage.objects;

create policy "parking_content_update_own"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'parking_content'
    and private.can_manage_parking_content(name)
  )
  with check (
    bucket_id = 'parking_content'
    and private.can_manage_parking_content(name)
  );

drop policy if exists "parking_content_delete_own"
  on storage.objects;

create policy "parking_content_delete_own"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'parking_content'
    and private.can_manage_parking_content(name)
  );

commit;

-- Manual rollback (do not run automatically):
-- Recreate the policy bodies from
-- 20260724104000_restrict_parking_content_storage_policies.sql, then:
-- drop policy if exists "avatars_select_own" on storage.objects;
-- drop policy if exists "parking_content_select_own" on storage.objects;
-- drop function if exists private.can_manage_parking_content(text);
