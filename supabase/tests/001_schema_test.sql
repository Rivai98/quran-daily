create extension if not exists pgtap with schema extensions;

-- test-only seeding helpers (direct superuser inserts)
\i supabase/tests/helpers/seed_members.sql

begin;
select plan(24);

-- ---------------------------------------------------------------------------
-- juz_for_seat: rotation = ((start_juz - 1) + (seat - 1) + day_index) % 30 + 1
-- ---------------------------------------------------------------------------
select is(
  public.juz_for_seat(1, 1, 0), 1,
  'day 0 seat 1 start 1 -> juz 1');
select is(
  public.juz_for_seat(30, 1, 0), 30,
  'day 0 seat 30 start 1 -> juz 30');
select is(
  public.juz_for_seat(1, 1, 1), 2,
  'next day every seat advances by one');
select is(
  public.juz_for_seat(30, 1, 1), 1,
  'juz 30 wraps to 1');
select is(
  public.juz_for_seat(1, 15, 0), 15,
  'start juz 15 seeds seat 1 at juz 15');
select is(
  public.juz_for_seat(2, 15, 0), 16,
  'seat k reads one further');
select is(
  public.juz_for_seat(1, 30, 1), 1,
  'start 30 wraps after one day');
select is(
  public.juz_for_seat(30, 15, 0), 14,
  'seat 30 wraps mid-cycle (15+29 -> 14)');

-- 30 distinct juz for any day index (structural property, starts 1 and 30)
select is(
  (select count(distinct public.juz_for_seat(seat, 1, 7)) from generate_series(1, 30) seat)::int,
  30::int, '30 distinct juz per day (start 1, day 7)');
select is(
  (select count(distinct public.juz_for_seat(seat, 30, 13)) from generate_series(1, 30) seat)::int,
  30::int, '30 distinct juz per day (start 30, day 13)');

-- ---------------------------------------------------------------------------
-- Tables exist
-- ---------------------------------------------------------------------------
select has_table('public', 'groups', 'groups table');
select has_table('public', 'group_memberships', 'group_memberships table');
select has_table('public', 'join_requests', 'join_requests table');
select has_table('public', 'group_days', 'group_days table');
select has_table('public', 'assignments', 'assignments table');
select has_table('public', 'completion_records', 'completion_records table');

-- ---------------------------------------------------------------------------
-- Constraints: one owner per group, seat uniqueness/range, <=30 active
-- (seeding via the test-only helper; direct inserts as the test superuser)
-- ---------------------------------------------------------------------------
select tests_seed_user('a0000000-0000-0000-0000-000000000001', 'owner1@test.local', 'مالك');
select tests_seed_user('a0000000-0000-0000-0000-000000000002', 'member1@test.local', 'عضو');
select tests_seed_group('b0000000-0000-0000-0000-000000000001', 'حلقة اختبار',
                        'a0000000-0000-0000-0000-000000000001', 'Africa/Cairo', 'TEST2345');
select tests_seed_member('b0000000-0000-0000-0000-000000000001',
                         'a0000000-0000-0000-0000-000000000001',
                         1::smallint, 'owner'::public.group_role);

select lives_ok(
  'insert into public.group_memberships (id, group_id, user_id, role, status, seat_number) values (''c0000000-0000-0000-0000-000000000002'', ''b0000000-0000-0000-0000-000000000001'', ''a0000000-0000-0000-0000-000000000002'', ''member'', ''active'', 2)',
  'second member occupies a free seat');

select throws_ok(
  'insert into public.group_memberships (id, group_id, user_id, role, status, seat_number) values (''c0000000-0000-0000-0000-000000000003'', ''b0000000-0000-0000-0000-000000000001'', ''a0000000-0000-0000-0000-000000000002'', ''member'', ''active'', 1)',
  23505);
-- desc: occupied seat rejected (unique index)

select throws_ok(
  'insert into public.group_memberships (id, group_id, user_id, role, status, seat_number) values (''c0000000-0000-0000-0000-000000000003'', ''b0000000-0000-0000-0000-000000000001'', ''a0000000-0000-0000-0000-000000000002'', ''member'', ''active'', 31)',
  23514);
-- desc: seat number above 30 rejected

select throws_ok(
  'insert into public.group_memberships (id, group_id, user_id, role, status, seat_number) values (''c0000000-0000-0000-0000-000000000003'', ''b0000000-0000-0000-0000-000000000001'', ''a0000000-0000-0000-0000-000000000002'', ''owner'', ''active'', 5)',
  23505);
-- desc: a second owner membership is rejected (unique index)

select throws_ok(
  'insert into public.groups (id, name, owner_id, timezone, invite_code) values (''b0000000-0000-0000-0000-000000000002'', ''مكرر'', ''a0000000-0000-0000-0000-000000000001'', ''Africa/Cairo'', ''TEST2345'')',
  23505);
-- desc: duplicate invite code among non-archived groups rejected

-- ---------------------------------------------------------------------------
-- group_local_date: group-local date of an instant (timezone + start time)
-- ---------------------------------------------------------------------------
select is(
  public.group_local_date('b0000000-0000-0000-0000-000000000001',
                          '2026-11-14 23:30:00+00'::timestamptz)::text,
  '2026-11-15',
  '23:30 UTC = 01:30 Cairo local next day (start 00:00)');

select is(
  public.group_local_date('b0000000-0000-0000-0000-000000000001',
                          '2026-11-14 21:30:00+00'::timestamptz)::text,
  '2026-11-14',
  '21:30 UTC in Cairo (+02, 23:30 local) stays the same day');

select throws_ok(
  'select public.group_local_date(''b0000000-0000-0000-0000-000000000999'', now())',
  'group_not_found',
  'unknown group raises group_not_found');

select * from finish();
rollback;
