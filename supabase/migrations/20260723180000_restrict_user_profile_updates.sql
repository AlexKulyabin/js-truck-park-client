-- Restrict direct profile updates to fields used by the Flutter client.
--
-- This migration intentionally does not change RLS policies, SELECT access,
-- service_role access, triggers, RPCs, table definitions, or data.

begin;

revoke update on table public.users from anon, authenticated;

grant update (
  full_name,
  avatar_url,
  updated_at,
  last_device_id
) on table public.users to authenticated;

-- Keep the administrative backend contract explicit.
grant all privileges on table public.users to service_role;

commit;

-- Manual rollback (do not run automatically):
-- revoke update (full_name, avatar_url, updated_at, last_device_id)
--   on table public.users from authenticated;
-- grant update on table public.users to anon, authenticated;
