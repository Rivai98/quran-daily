create extension if not exists pgtap with schema extensions;

begin;
select plan(21);

-- Test user helpers: insert directly into auth.users as the test superuser.
create or replace function tests_insert_auth_user(p_id uuid, p_email text, p_display_name text default null)
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
    case when p_display_name is null then '{}'::jsonb
         else jsonb_build_object('display_name', p_display_name) end,
    now(), now(), '', ''
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Structure
-- ---------------------------------------------------------------------------
select has_table('public', 'profiles', 'public.profiles exists');
select has_column('public', 'profiles', 'id', 'profiles.id');
select has_column('public', 'profiles', 'display_name', 'profiles.display_name');
select has_column('public', 'profiles', 'updated_at', 'profiles.updated_at maintained');

select has_table('private', 'app_admins', 'private.app_admins exists');
select has_table('private', 'admin_auth_audit', 'private.admin_auth_audit exists');

-- RLS enabled
select is(
  (select relrowsecurity from pg_class where oid = 'public.profiles'::regclass),
  true,
  'RLS enabled on profiles'
);

-- ---------------------------------------------------------------------------
-- Trigger provisions exactly one profile per auth user, with trimmed name
-- ---------------------------------------------------------------------------
select tests_insert_auth_user(
  '11111111-1111-1111-1111-111111111111'::uuid,
  'trigger-one@test.local',
  '  أحمد سالم  '
);

select is(
  count(*),
  1::bigint,
  'exactly one profile row provisioned'
)
from public.profiles
where id = '11111111-1111-1111-1111-111111111111'::uuid;

select is(
  display_name,
  'أحمد سالم',
  'profile display_name is trimmed'
)
from public.profiles
where id = '11111111-1111-1111-1111-111111111111'::uuid;

-- Missing display_name fails account creation cleanly
select throws_ok(
  'select tests_insert_auth_user(''22222222-2222-2222-2222-222222222222''::uuid, ''trigger-missing@test.local'')',
  'profile not provisioned',
  'auth user without display_name metadata fails creation'
);

-- Whitespace-only display_name fails account creation cleanly
select throws_ok(
  'select tests_insert_auth_user(''33333333-3333-3333-3333-333333333333''::uuid, ''trigger-blank@test.local'', ''   '')',
  'profile not provisioned',
  'whitespace-only display_name fails creation'
);

-- ---------------------------------------------------------------------------
-- updated_at cannot be forged by clients
-- ---------------------------------------------------------------------------
update public.profiles
set display_name = 'updated name', updated_at = now() - interval '10 days'
where id = '11111111-1111-1111-1111-111111111111'::uuid;

select is(
  updated_at > now() - interval '5 minutes',
  true,
  'updated_at is maintained by trigger, not client-supplied'
)
from public.profiles
where id = '11111111-1111-1111-1111-111111111111'::uuid;

-- ---------------------------------------------------------------------------
-- Owner-only RLS
-- ---------------------------------------------------------------------------
select tests_insert_auth_user(
  '44444444-4444-4444-4444-444444444444'::uuid,
  'owner-a@test.local',
  'مالك ا'
);
select tests_insert_auth_user(
  '55555555-5555-5555-5555-555555555555'::uuid,
  'owner-b@test.local',
  'مالك ب'
);

-- anon sees nothing
set role anon;
select is(
  count(*),
  0::bigint,
  'anon cannot read any profile'
) from public.profiles;
reset role;

-- authenticated user A sees only their own profile
set role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '44444444-4444-4444-4444-444444444444', 'role', 'authenticated')::text,
  true
);
select is(
  count(*),
  1::bigint,
  'authenticated user sees only their own profile'
) from public.profiles;
update public.profiles set display_name = 'اختراق'
where id = '55555555-5555-5555-5555-555555555555'::uuid;
select is(
  (select count(*) from public.profiles
   where id = '55555555-5555-5555-5555-555555555555'::uuid
     and display_name = 'اختراق'),
  0::bigint,
  'authenticated user cannot update another profile'
);
reset role;

-- clients cannot insert or delete profiles at all
set role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '44444444-4444-4444-4444-444444444444', 'role', 'authenticated')::text,
  true
);
select throws_ok(
  'insert into public.profiles (id, display_name) values (''66666666-6666-6666-6666-666666666666''::uuid, ''مزور'')',
  42501,
  null,
  'authenticated user cannot insert profiles'
);
-- RLS has no delete policy: a delete silently affects 0 rows (no exception),
-- so assert both profiles survive.
delete from public.profiles
where id in ('44444444-4444-4444-4444-444444444444'::uuid,
             '55555555-5555-5555-5555-555555555555'::uuid);
reset role;
select is(
  (select count(*) from public.profiles
   where id in ('44444444-4444-4444-4444-444444444444'::uuid,
                '55555555-5555-5555-5555-555555555555'::uuid)),
  2::bigint,
  'authenticated user cannot delete profiles'
);

-- ---------------------------------------------------------------------------
-- private.app_admins / private.admin_auth_audit are unreachable by API roles
-- ---------------------------------------------------------------------------
set role anon;
select throws_ok(
  'select * from private.app_admins',
  42501,
  null,
  'anon cannot read private.app_admins'
);
reset role;

set role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '44444444-4444-4444-4444-444444444444', 'role', 'authenticated')::text,
  true
);
select throws_ok(
  'select * from private.app_admins',
  42501,
  null,
  'authenticated user cannot read private.app_admins'
);
select throws_ok(
  'select * from private.admin_auth_audit',
  42501,
  null,
  'authenticated user cannot read private.admin_auth_audit'
);
select throws_ok(
  'insert into private.app_admins (user_id) values (''44444444-4444-4444-4444-444444444444''::uuid)',
  42501,
  null,
  'authenticated user cannot grant admin rights'
);
reset role;

select * from finish();
rollback;
