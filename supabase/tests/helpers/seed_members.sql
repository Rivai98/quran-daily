-- Test-only helper (runs as the test superuser in pgTAP transactions).
-- Seeds auth users + profiles + active memberships directly.
-- The profiles trigger provisions profile rows from user metadata.

create or replace function tests_seed_user(p_id uuid, p_email text, p_name text)
returns void
language plpgsql
as $$
begin
  insert into auth.users (
    id, instance_id, aud, role, email,
    encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, confirmation_token, recovery_token
  ) values (
    p_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', p_email,
    'test-only', now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('display_name', p_name),
    now(), now(), '', ''
  )
  on conflict (id) do nothing;
end;
$$;

create or replace function tests_seed_group(
  p_id uuid, p_name text, p_owner uuid, p_tz text default 'Africa/Cairo',
  p_code text default 'TEST0001')
returns void
language plpgsql
as $$
begin
  insert into public.profiles (id, display_name)
  values (p_owner, 'مالك المجموعة')
  on conflict (id) do nothing;

  insert into public.groups (id, name, owner_id, timezone, invite_code)
  values (p_id, p_name, p_owner, p_tz, p_code)
  on conflict (id) do nothing;
end;
$$;

create or replace function tests_seed_member(
  p_group uuid, p_user uuid, p_seat smallint,
  p_role public.group_role default 'member')
returns void
language plpgsql
as $$
declare
  v_name text;
begin
  select display_name into v_name from public.profiles where id = p_user;
  if v_name is null then
    raise exception 'seed the user first (tests_seed_user)';
  end if;

  insert into public.group_memberships (id, group_id, user_id, role, status, seat_number)
  values (gen_random_uuid(), p_group, p_user, p_role, 'active', p_seat)
  on conflict do nothing;
end;
$$;
