-- 008 admin console (T003): admin guard, admin audit log, profile suspension.
-- Admin status lives ONLY in private.app_admins (spec 002); every admin RPC
-- calls public.require_app_admin() first. The private schema stays
-- unreachable by API roles; audit rows are read only via admin_list_audit.

-- ---------------------------------------------------------------------------
-- profiles.suspended_at: set/cleared only by trusted server code
-- ---------------------------------------------------------------------------
alter table public.profiles add column if not exists suspended_at timestamptz;

comment on column public.profiles.suspended_at is
  'Set while an app admin has suspended the account (auth ban is applied by '
  'the admin-user-action Edge Function). Never writable by clients.';

create or replace function public.profiles_guard_suspension()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  -- SECURITY DEFINER functions run as their owner, so current_user is an API
  -- role only for direct client writes (profiles_update_own policy).
  if new.suspended_at is distinct from old.suspended_at
     and current_user in ('authenticated', 'anon') then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_guard_suspension on public.profiles;
create trigger profiles_guard_suspension
  before update on public.profiles
  for each row
  execute function public.profiles_guard_suspension();

revoke all on function public.profiles_guard_suspension() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- private.admin_audit: every admin action (auth-level and data-level).
-- No FKs to auth.users so entries survive account and group deletion;
-- target_label keeps a human-readable name snapshot.
-- ---------------------------------------------------------------------------
create table if not exists private.admin_audit (
  id uuid primary key default gen_random_uuid(),
  action text not null check (action in (
    'create_user', 'reset_password',
    'suspend_user', 'unsuspend_user', 'delete_user',
    'grant_admin', 'revoke_admin',
    'archive_group', 'restore_group', 'delete_group',
    'remove_member', 'transfer_ownership', 'regenerate_invite',
    'suspend_cleanup', 'clear_suspension', 'prepare_user_delete')),
  actor_user_id uuid not null,
  target_user_id uuid,
  target_group_id uuid,
  target_label text check (target_label is null or char_length(target_label) <= 200),
  result text not null check (char_length(result) between 1 and 60),
  details jsonb not null default '{}'::jsonb,
  correlation_id uuid not null default gen_random_uuid(),
  created_at timestamptz not null default now()
);

create index if not exists admin_audit_created_idx
  on private.admin_audit (created_at desc);
create index if not exists admin_audit_action_created_idx
  on private.admin_audit (action, created_at desc);

alter table private.admin_audit enable row level security;
revoke all on schema private from anon, authenticated;
revoke all on private.admin_audit from anon, authenticated;

-- Carry over spec 002 rows so the console shows one log.
insert into private.admin_audit
  (id, action, actor_user_id, target_user_id, result, correlation_id, created_at)
select id, action, actor_user_id, target_user_id, result, correlation_id, created_at
from private.admin_auth_audit
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- Audit writers
-- ---------------------------------------------------------------------------
create or replace function public.write_admin_audit(
  p_action text,
  p_actor_user_id uuid,
  p_target_user_id uuid,
  p_target_group_id uuid,
  p_target_label text,
  p_result text,
  p_details jsonb,
  p_correlation_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
begin
  if p_actor_user_id is null then
    raise exception 'validation_failed' using errcode = 'P0001';
  end if;
  insert into private.admin_audit (action, actor_user_id, target_user_id,
    target_group_id, target_label, result, details, correlation_id)
  values (p_action, p_actor_user_id, p_target_user_id, p_target_group_id,
    left(p_target_label, 200), p_result, coalesce(p_details, '{}'::jsonb),
    coalesce(p_correlation_id, gen_random_uuid()))
  returning id into v_id;
  return v_id;
end;
$$;

-- Spec 002 Edge Functions (admin-create-user, admin-reset-password) call
-- this signature through the service role; it now writes the unified log.
create or replace function public.write_admin_auth_audit(
  p_action text,
  p_actor_user_id uuid,
  p_target_user_id uuid,
  p_result text,
  p_correlation_id uuid)
returns uuid
language sql
security definer
set search_path = ''
as $$
  select public.write_admin_audit(p_action, p_actor_user_id, p_target_user_id,
    null, null, p_result, '{}'::jsonb, p_correlation_id);
$$;

revoke all on function public.write_admin_audit(text, uuid, uuid, uuid, text, text, jsonb, uuid)
  from public, anon, authenticated;
revoke all on function public.write_admin_auth_audit(text, uuid, uuid, text, uuid)
  from public, anon, authenticated;
grant execute on function public.write_admin_audit(text, uuid, uuid, uuid, text, text, jsonb, uuid)
  to service_role;
grant execute on function public.write_admin_auth_audit(text, uuid, uuid, text, uuid)
  to service_role;

-- ---------------------------------------------------------------------------
-- Admin checks
-- ---------------------------------------------------------------------------
create or replace function public.admin_is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null and exists (
    select 1 from private.app_admins a where a.user_id = auth.uid());
$$;

-- Used by the spec 002 Edge Functions' requireAdmin() (caller's token).
create or replace function public.is_app_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.admin_is_admin();
$$;

create or replace function public.require_app_admin()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
begin
  v_uid := public.require_auth_uid();
  if not exists (select 1 from private.app_admins a where a.user_id = v_uid) then
    raise exception 'not_admin' using errcode = 'P0001';
  end if;
  return v_uid;
end;
$$;

revoke all on function public.require_app_admin() from public, anon, authenticated;
revoke all on function public.admin_is_admin() from public, anon;
revoke all on function public.is_app_admin() from public, anon;
grant execute on function public.admin_is_admin() to authenticated;
grant execute on function public.is_app_admin() to authenticated;
