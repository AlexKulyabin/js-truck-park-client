-- Add narrow profile read contracts before closing broad users SELECT access.
--
-- This migration intentionally does not revoke SELECT on public.users. Flutter
-- must move to these projections first, then users SELECT can be closed in a
-- separate rollout.

begin;

create or replace view public.public_profiles
with (security_invoker = true) as
select
  id,
  full_name,
  avatar_url
from public.users;

create or replace view public.private_profiles
with (security_invoker = true) as
select
  id,
  full_name,
  avatar_url,
  phone,
  is_premium,
  referral_code,
  theme,
  updated_at,
  status,
  is_admin,
  referred_by_id,
  last_device_id
from public.users
where id = auth.uid()
   or public.is_admin();

revoke all on table public.public_profiles from public, anon, authenticated;
revoke all on table public.private_profiles from public, anon, authenticated;

grant select on table public.public_profiles to anon, authenticated, service_role;
grant select on table public.private_profiles to authenticated, service_role;

commit;

-- Manual rollback (do not run automatically):
-- drop view if exists public.private_profiles;
-- drop view if exists public.public_profiles;
