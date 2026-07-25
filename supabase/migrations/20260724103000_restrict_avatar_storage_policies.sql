-- Restrict avatar object mutations to the authenticated owner's path.
--
-- Public reads and bucket settings remain unchanged. The Flutter client already
-- uploads avatars to avatars/users/<auth.uid()>/...

begin;

drop policy if exists "Avatar_Upload"
  on storage.objects;

drop policy if exists "Avatar_Update"
  on storage.objects;

drop policy if exists "Avatar_Delete"
  on storage.objects;

drop policy if exists "avatars_insert_own"
  on storage.objects;

create policy "avatars_insert_own"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = 'users'
    and (storage.foldername(name))[2] = (select auth.uid()::text)
  );

drop policy if exists "avatars_update_own"
  on storage.objects;

create policy "avatars_update_own"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = 'users'
    and (storage.foldername(name))[2] = (select auth.uid()::text)
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = 'users'
    and (storage.foldername(name))[2] = (select auth.uid()::text)
  );

drop policy if exists "avatars_delete_own"
  on storage.objects;

create policy "avatars_delete_own"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = 'users'
    and (storage.foldername(name))[2] = (select auth.uid()::text)
  );

commit;

-- Manual rollback (do not run automatically):
-- drop policy if exists "avatars_insert_own" on storage.objects;
-- drop policy if exists "avatars_update_own" on storage.objects;
-- drop policy if exists "avatars_delete_own" on storage.objects;
-- create policy "Avatar_Upload" on storage.objects for insert
--   to authenticated with check (bucket_id = 'avatars');
-- create policy "Avatar_Update" on storage.objects for update
--   to authenticated using (bucket_id = 'avatars')
--   with check (bucket_id = 'avatars');
-- create policy "Avatar_Delete" on storage.objects for delete
--   to authenticated using (bucket_id = 'avatars');
