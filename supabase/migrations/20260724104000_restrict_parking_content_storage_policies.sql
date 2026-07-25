-- Restrict parking content object mutations to parking owners or review authors.
--
-- Public reads and bucket settings remain unchanged. The Flutter client uploads
-- parking images under parkings/<parkingId>/... and review images under
-- parkings/<parkingId>/reviews/<reviewId>/...

begin;

do $$
declare
  existing_policy record;
begin
  for existing_policy in
    select policyname
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and cmd in ('INSERT', 'UPDATE', 'DELETE', 'ALL')
      and policyname not in (
        'parking_content_insert_own',
        'parking_content_update_own',
        'parking_content_delete_own'
      )
      and (
        coalesce(qual, '') like '%parking_content%'
        or coalesce(with_check, '') like '%parking_content%'
        or coalesce(qual, '') like '%parking-images%'
        or coalesce(with_check, '') like '%parking-images%'
      )
  loop
    execute format(
      'drop policy if exists %I on storage.objects',
      existing_policy.policyname
    );
  end loop;
end $$;

drop policy if exists "parking_content_insert_own"
  on storage.objects;

create policy "parking_content_insert_own"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'parking_content'
    and split_part(name, '/', 1) = 'parkings'
    and (
      (
        split_part(name, '/', 2) <> ''
        and split_part(name, '/', 3) <> ''
        and split_part(name, '/', 3) <> 'reviews'
        and exists (
          select 1
          from public.parkings parking
          where parking.id::text = split_part(name, '/', 2)
            and parking.created_by = auth.uid()
        )
      )
      or (
        split_part(name, '/', 3) = 'reviews'
        and split_part(name, '/', 4) <> ''
        and split_part(name, '/', 5) <> ''
        and exists (
          select 1
          from public.reviews review_row
          where review_row.parking_id::text = split_part(name, '/', 2)
            and review_row.id::text = split_part(name, '/', 4)
            and review_row.user_id = auth.uid()
        )
      )
    )
  );

drop policy if exists "parking_content_update_own"
  on storage.objects;

create policy "parking_content_update_own"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'parking_content'
    and split_part(name, '/', 1) = 'parkings'
    and (
      (
        split_part(name, '/', 2) <> ''
        and split_part(name, '/', 3) <> ''
        and split_part(name, '/', 3) <> 'reviews'
        and exists (
          select 1
          from public.parkings parking
          where parking.id::text = split_part(name, '/', 2)
            and parking.created_by = auth.uid()
        )
      )
      or (
        split_part(name, '/', 3) = 'reviews'
        and split_part(name, '/', 4) <> ''
        and split_part(name, '/', 5) <> ''
        and exists (
          select 1
          from public.reviews review_row
          where review_row.parking_id::text = split_part(name, '/', 2)
            and review_row.id::text = split_part(name, '/', 4)
            and review_row.user_id = auth.uid()
        )
      )
    )
  )
  with check (
    bucket_id = 'parking_content'
    and split_part(name, '/', 1) = 'parkings'
    and (
      (
        split_part(name, '/', 2) <> ''
        and split_part(name, '/', 3) <> ''
        and split_part(name, '/', 3) <> 'reviews'
        and exists (
          select 1
          from public.parkings parking
          where parking.id::text = split_part(name, '/', 2)
            and parking.created_by = auth.uid()
        )
      )
      or (
        split_part(name, '/', 3) = 'reviews'
        and split_part(name, '/', 4) <> ''
        and split_part(name, '/', 5) <> ''
        and exists (
          select 1
          from public.reviews review_row
          where review_row.parking_id::text = split_part(name, '/', 2)
            and review_row.id::text = split_part(name, '/', 4)
            and review_row.user_id = auth.uid()
        )
      )
    )
  );

drop policy if exists "parking_content_delete_own"
  on storage.objects;

create policy "parking_content_delete_own"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'parking_content'
    and split_part(name, '/', 1) = 'parkings'
    and (
      (
        split_part(name, '/', 2) <> ''
        and split_part(name, '/', 3) <> ''
        and split_part(name, '/', 3) <> 'reviews'
        and exists (
          select 1
          from public.parkings parking
          where parking.id::text = split_part(name, '/', 2)
            and parking.created_by = auth.uid()
        )
      )
      or (
        split_part(name, '/', 3) = 'reviews'
        and split_part(name, '/', 4) <> ''
        and split_part(name, '/', 5) <> ''
        and exists (
          select 1
          from public.reviews review_row
          where review_row.parking_id::text = split_part(name, '/', 2)
            and review_row.id::text = split_part(name, '/', 4)
            and review_row.user_id = auth.uid()
        )
      )
    )
  );

commit;

-- Manual rollback (do not run automatically):
-- drop policy if exists "parking_content_insert_own" on storage.objects;
-- drop policy if exists "parking_content_update_own" on storage.objects;
-- drop policy if exists "parking_content_delete_own" on storage.objects;
-- Recreate the previous hosted Storage mutation policies only from a fresh
-- read-only policy snapshot for the target environment.
