-- Bind referral application to the authenticated user.
--
-- The Flutter client may still pass p_referee_id for compatibility, but the
-- function now validates it against auth.uid() and rejects anonymous execution.

begin;

create or replace function public.process_referral(
  p_ref_code text,
  p_referee_id uuid,
  p_device_id text
) returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_referrer_id uuid;
  v_referee_id uuid := auth.uid();
begin
  if v_referee_id is null then
    return jsonb_build_object(
      'success', false,
      'message', 'Authentication required'
    );
  end if;

  if p_referee_id is null or p_referee_id <> v_referee_id then
    return jsonb_build_object(
      'success', false,
      'message', 'Referral user mismatch'
    );
  end if;

  if p_device_id is null or btrim(p_device_id) = '' then
    return jsonb_build_object(
      'success', false,
      'message', 'Invalid device id'
    );
  end if;

  select id
    into v_referrer_id
  from public.users
  where referral_code = p_ref_code
  limit 1;

  if v_referrer_id is null then
    return jsonb_build_object(
      'success', false,
      'message', 'Invalid referral code'
    );
  end if;

  if v_referrer_id = v_referee_id then
    return jsonb_build_object(
      'success', false,
      'message', 'You cannot refer yourself'
    );
  end if;

  if exists (
    select 1
    from public.referral_stats
    where device_id = p_device_id
       or referee_id = v_referee_id
  ) then
    return jsonb_build_object(
      'success', false,
      'message', 'Referral already applied'
    );
  end if;

  update public.users
  set referred_by_id = v_referrer_id
  where id = v_referee_id
    and referred_by_id is null;

  if not found then
    return jsonb_build_object(
      'success', false,
      'message', 'Referral already applied'
    );
  end if;

  insert into public.referral_stats (referrer_id, referee_id, device_id)
  values (v_referrer_id, v_referee_id, p_device_id);

  return jsonb_build_object(
    'success', true,
    'message', 'Referral applied successfully'
  );
exception
  when unique_violation then
    return jsonb_build_object(
      'success', false,
      'message', 'Referral already applied'
    );
  when others then
    return jsonb_build_object(
      'success', false,
      'message', 'Referral could not be applied'
    );
end;
$$;

revoke all on function public.process_referral(text, uuid, text)
  from public, anon;
grant execute on function public.process_referral(text, uuid, text)
  to authenticated, service_role;

commit;

-- Manual rollback (do not run automatically):
-- create or replace function public.process_referral(
--   p_ref_code text,
--   p_referee_id uuid,
--   p_device_id text
-- ) returns jsonb
-- language plpgsql
-- security definer
-- as $$
-- declare
--   v_referrer_id uuid;
-- begin
--   select id into v_referrer_id
--   from public.users
--   where referral_code = p_ref_code
--   limit 1;
--
--   if v_referrer_id is null then
--     return jsonb_build_object('success', false, 'message', 'Invalid referral code');
--   end if;
--
--   if v_referrer_id = p_referee_id then
--     return jsonb_build_object('success', false, 'message', 'You cannot refer yourself');
--   end if;
--
--   if exists (select 1 from public.referral_stats where device_id = p_device_id) then
--     return jsonb_build_object('success', false, 'message', 'Device already used for referral');
--   end if;
--
--   update public.users
--   set referred_by_id = v_referrer_id
--   where id = p_referee_id;
--
--   insert into public.referral_stats (referrer_id, referee_id, device_id)
--   values (v_referrer_id, p_referee_id, p_device_id);
--
--   return jsonb_build_object('success', true, 'message', 'Referral applied successfully');
-- exception when others then
--   return jsonb_build_object('success', false, 'message', SQLERRM);
-- end;
-- $$;
-- grant execute on function public.process_referral(text, uuid, text)
--   to anon, authenticated;
