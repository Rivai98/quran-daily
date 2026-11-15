create extension if not exists pgtap with schema extensions;

\i helpers/seed_members.sql

begin;
select plan(14);

-- Story-owned c1 identifiers keep this test isolated from parallel worktrees.
select tests_seed_user('c1000000-0000-0000-0000-000000000001', 'us1-owner@test.local', 'مالك يو1');
select tests_seed_user('c1000000-0000-0000-0000-000000000002', 'us1-m2@test.local', 'عضو يو1');
select tests_seed_user('c1000000-0000-0000-0000-000000000003', 'us1-out@test.local', 'خارجي');
select tests_seed_group('c1000000-0000-0000-0000-000000000011', 'حلقة يو1',
                        'c1000000-0000-0000-0000-000000000001', 'Africa/Cairo', 'US2ABCD2');
select tests_seed_member('c1000000-0000-0000-0000-000000000011',
                         'c1000000-0000-0000-0000-000000000001', 1::smallint, 'owner'::public.group_role);
select tests_seed_member('c1000000-0000-0000-0000-000000000011',
                         'c1000000-0000-0000-0000-000000000002', 5::smallint);

select set_config('request.jwt.claims',
  json_build_object('sub', 'c1000000-0000-0000-0000-000000000001', 'role', 'authenticated')::text, true);
select public.start_khatma('c1000000-0000-0000-0000-000000000011', 1);

-- Active snapshot shape, counts, and caller-specific assignments.
select is(
  (select count(*)::int from jsonb_array_elements(public.get_dashboard('c1000000-0000-0000-0000-000000000011')->'assignments')),
  30,
  'active dashboard has exactly 30 assignment rows');
select is(
  (select count(distinct (value->>'juz')::int)::int
   from jsonb_array_elements(public.get_dashboard('c1000000-0000-0000-0000-000000000011')->'assignments')),
  30,
  'active dashboard contains every juz exactly once');
select is(
  (select count(*)::int from jsonb_array_elements(public.get_dashboard('c1000000-0000-0000-0000-000000000011')->'assignments') where value->>'is_me' = 'true'),
  1,
  'exactly one assignment is flagged as mine');
select is(
  (public.get_dashboard('c1000000-0000-0000-0000-000000000011')->'today'->>'completed_count')::int,
  0,
  'completed count starts at zero');
select is(
  (public.get_dashboard('c1000000-0000-0000-0000-000000000011')->'today'->>'available_count')::int,
  28,
  'the 28 empty seats are available');
select is(
  (select count(*)::int from jsonb_array_elements(public.get_dashboard('c1000000-0000-0000-0000-000000000011')->'my_assignments')),
  1,
  'my_assignments contains my seat assignment');
select is(
  public.get_dashboard('c1000000-0000-0000-0000-000000000011')->>'status',
  'active',
  'active dashboard reports active status');
select is(
  public.get_dashboard('c1000000-0000-0000-0000-000000000011')->>'invite_code',
  'US2ABCD2',
  'active members receive the invite code');

-- The function must lazily create a missing current group day.
delete from public.assignments where group_day_id = (
  select id from public.group_days where group_id = 'c1000000-0000-0000-0000-000000000011');
delete from public.group_days where group_id = 'c1000000-0000-0000-0000-000000000011';
select public.get_dashboard('c1000000-0000-0000-0000-000000000011');
select is(
  (select count(*)::int from public.group_days where group_id = 'c1000000-0000-0000-0000-000000000011'),
  1,
  'get_dashboard ensures the current group day exists');

select set_config('request.jwt.claims',
  json_build_object('sub', 'c1000000-0000-0000-0000-000000000003', 'role', 'authenticated')::text, true);
select throws_ok(
  'select public.get_dashboard(''c1000000-0000-0000-0000-000000000011'')',
  'P0001', null, 'non-member cannot load dashboard');
select set_config('request.jwt.claims', '', true);
select throws_ok(
  'select public.get_dashboard(''c1000000-0000-0000-0000-000000000011'')',
  'P0001', null, 'unauthenticated caller cannot load dashboard');

-- Forming groups return the seat map instead of daily assignments.
select set_config('request.jwt.claims',
  json_build_object('sub', 'c1000000-0000-0000-0000-000000000001', 'role', 'authenticated')::text, true);
select public.create_group('حلقة تشكيل', '', 'Africa/Cairo', '00:00'::time,
                           'private'::public.group_visibility, 'approval'::public.join_mode);
select is(
  (public.get_dashboard((select id from public.groups where name = 'حلقة تشكيل'))->>'status'),
  'forming',
  'forming dashboard reports forming status');
select is(
  (select count(*)::int from jsonb_array_elements(public.get_dashboard(
    (select id from public.groups where name = 'حلقة تشكيل'))->'seats'->'members')),
  1,
  'forming dashboard returns the active member seat map');
select is(
  (public.get_dashboard((select id from public.groups where name = 'حلقة تشكيل'))->>'active_member_count')::int,
  1,
  'forming dashboard includes active member count');

select * from finish();
rollback;
