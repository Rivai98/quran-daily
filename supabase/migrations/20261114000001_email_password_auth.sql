-- 001_email_password_auth (spec 002)
-- profiles + provisioning trigger + owner-only RLS + private admin tables.
-- This is the FIRST migration: 002_core_schema references profiles.

create schema if not exists private;

-- ---------------------------------------------------------------------------
-- public.profiles: one row per auth user (spec 002 data model)
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null
    check (length(btrim(display_name)) between 1 and 100),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.profiles is
  'App-visible profile, 1:1 with auth.users; no email/password/roles here.';

alter table public.profiles enable row level security;

-- updated_at is maintained by trigger; clients cannot forge it.
create or replace function public.profiles_touch_updated_at()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger profiles_touch_updated_at
  before update on public.profiles
  for each row
  execute function public.profiles_touch_updated_at();

-- ---------------------------------------------------------------------------
-- Provisioning: every created auth user gets exactly one profile, or the
-- account creation fails cleanly (spec 002: FR-004, edge case "profile-
-- creation failure does not leave the user signed-in with a missing profile")
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_display_name text;
begin
  v_display_name := btrim(coalesce(new.raw_user_meta_data ->> 'display_name', ''));

  if new.raw_user_meta_data is null
     or not (new.raw_user_meta_data ? 'display_name')
     or v_display_name = ''
     or length(v_display_name) > 100 then
    raise exception 'profile not provisioned'
      using errcode = '23502';
  end if;

  insert into public.profiles (id, display_name)
  values (new.id, v_display_name);

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_auth_user();

-- ---------------------------------------------------------------------------
-- Owner-only policies (spec 002 FR-015): read + update own; no client
-- insert/delete.
-- ---------------------------------------------------------------------------
create policy profiles_select_own
  on public.profiles
  for select
  to authenticated
  using (id = (select auth.uid()));

create policy profiles_update_own
  on public.profiles
  for update
  to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

grant select, update on public.profiles to authenticated;

-- ---------------------------------------------------------------------------
-- private.app_admins / private.admin_auth_audit: unreachable by API roles;
-- written only by trusted server-side code (Edge Functions).
-- ---------------------------------------------------------------------------
create table private.app_admins (
  user_id uuid primary key references auth.users (id) on delete cascade,
  granted_at timestamptz not null default now(),
  granted_by uuid references auth.users (id) on delete set null
);

create table private.admin_auth_audit (
  id uuid primary key default gen_random_uuid(),
  action text not null check (action in ('create_user', 'reset_password')),
  actor_user_id uuid not null references auth.users (id) on delete cascade,
  target_user_id uuid references auth.users (id) on delete set null,
  result text not null,
  correlation_id uuid not null,
  created_at timestamptz not null default now()
);

alter table private.app_admins enable row level security;
alter table private.admin_auth_audit enable row level security;

revoke all on schema private from anon, authenticated;
revoke all on private.app_admins from anon, authenticated;
revoke all on private.admin_auth_audit from anon, authenticated;

-- The FIRST administrator is seeded manually by the project owner:
--   insert into private.app_admins (user_id)
--   values ('<owner-auth-user-uuid>');
-- (Trusted migration/dashboard operation only; never exposed to clients.)
