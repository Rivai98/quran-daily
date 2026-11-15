create extension if not exists pgtap with schema extensions;

\i helpers/seed_members.sql

begin;
select plan(27);

-- Seed three users
select tests_seed_user('aa000000-0000-0000-0000-000000000001', 'us2-owner@test.local', 'مالك يو2');
select tests_seed_user('aa000000-0000-0000-0000-000000000002', 'us2-m2@test.local', 'عضو اثنان');
select tests_seed_user('aa000000-0000-0000-0000-000000000003', 'us2-m3@test.local', 'عضو ثلاثة');

-- Log in as the owner for the RPC calls (tests.* wrappers run as definer,
-- but the RPCs read auth.uid()).
select set_config('request.jwt.claims',
  json_build_object('sub', 'aa000000-0000-0000-0000-000000000001', 'role', 'authenticated')::text, true);

-- ---------------------------------------------------------------------------
-- create_group: validation, owner seat 1, 3-group limit
-- ---------------------------------------------------------------------------
select throws_ok(
  'select public.create_group(''ab'', ''''::text, ''Africa/Cairo'', ''00:00''::time, ''private''::public.group_visibility, ''approval''::public.join_mode)',
  'validation_failed',
  'name shorter than 3 chars rejected');

select throws_ok(
  'select public.create_group(repeat(''ط'', 61), ''''::text, ''Africa/Cairo'', ''00:00''::time, ''private''::public.group_visibility, ''approval''::public.join_mode)',
  'validation_failed',
  'name longer than 60 chars rejected');

select throws_ok(
  'select public.create_group(''حلقة صالحة'', ''''::text, ''Not/AZone'', ''00:00''::time, ''private''::public.group_visibility, ''approval''::public.join_mode)',
  'validation_failed',
  'invalid timezone rejected');

select lives_ok(
  'select public.create_group(''حلقة يو2'', ''وصف'', ''Africa/Cairo'', ''00:00''::time, ''private''::public.group_visibility, ''approval''::public.join_mode)',
  'create_group succeeds with valid input');

select is(
  (select count(*) from public.group_memberships
   where group_id = (select id from public.groups where name = 'حلقة يو2')
     and role = 'owner' and status = 'active' and seat_number = 1),
  1::bigint,
  'creator becomes owner occupying seat 1');

select is(
  (select status from public.groups where name = 'حلقة يو2'),
  'forming'::public.group_status,
  'new group starts forming');

-- owner 3-group limit
insert into public.groups (id, name, owner_id, timezone, invite_code, status)
values
  ('ac000000-0000-0000-0000-000000000001', 'مجموعة ثانية',
   'aa000000-0000-0000-0000-000000000001', 'Africa/Cairo', 'U2TWX345', 'forming'),
  ('ac000000-0000-0000-0000-000000000002', 'مجموعة ثالثة',
   'aa000000-0000-0000-0000-000000000001', 'Africa/Cairo', 'U2THR678', 'forming'),
  ('ac000000-0000-0000-0000-000000000003', 'مجموعة رابعة',
   'aa000000-0000-0000-0000-000000000001', 'Africa/Cairo', 'U2FR9ABC', 'forming');

select throws_ok(
  'select public.create_group(''مجموعة خامسة'', ''''::text, ''Africa/Cairo'', ''00:00''::time, ''private''::public.group_visibility, ''approval''::public.join_mode)',
  'owner_group_limit',
  'fourth owned group rejected (limit 3 non-archived)');

-- archived groups do not count: archive two of the three extras so the
-- owner is back to 2 non-archived (plus the new one = 3, allowed)
update public.groups set status = 'archived'
where id in ('ac000000-0000-0000-0000-000000000002',
             'ac000000-0000-0000-0000-000000000003');
select lives_ok(
  'select public.create_group(''مجموعة خامسة'', ''''::text, ''Africa/Cairo'', ''00:00''::time, ''private''::public.group_visibility, ''approval''::public.join_mode)',
  'archived groups do not count toward the limit');

-- non-owner call is unauthenticated (claims cleared)
select set_config('request.jwt.claims', '', true);
select throws_ok(
  'select public.create_group(''حلقة بلا جلسة'', ''''::text, ''Africa/Cairo'', ''00:00''::time, ''private''::public.group_visibility, ''approval''::public.join_mode)',
  'unauthenticated',
  'create_group without a session raises unauthenticated');
select set_config('request.jwt.claims',
  json_build_object('sub', 'aa000000-0000-0000-0000-000000000001', 'role', 'authenticated')::text, true);

-- ---------------------------------------------------------------------------
-- start_khatma: forming only, >= 1 member, 30 assignments, empty seats
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims',
  json_build_object('sub', 'aa000000-0000-0000-0000-000000000002', 'role', 'authenticated')::text, true);
select throws_ok(
  'select public.start_khatma((select id from public.groups where name = ''حلقة يو2''), 1)',
  'forbidden',
  'non-owner cannot start the khatma');
select set_config('request.jwt.claims',
  json_build_object('sub', 'aa000000-0000-0000-0000-000000000001', 'role', 'authenticated')::text, true);

-- add a second member (seat 2) so we can check occupied vs empty seats
insert into public.group_memberships (id, group_id, user_id, role, status, seat_number)
values ('ad000000-0000-0000-0000-000000000001',
        (select id from public.groups where name = 'حلقة يو2'),
        'aa000000-0000-0000-0000-000000000002', 'member', 'active', 2);

select throws_ok(
  'select public.start_khatma((select id from public.groups where name = ''حلقة يو2''), 31)',
  'validation_failed',
  'start juz above 30 rejected');

select lives_ok(
  'select public.start_khatma((select id from public.groups where name = ''حلقة يو2''), 1)',
  'owner starts the khatma with 2 members');

select is(
  (select status from public.groups where name = 'حلقة يو2'),
  'active'::public.group_status,
  'group becomes active');

select is(
  (select count(*) from public.assignments a
   join public.group_days d on d.id = a.group_day_id
   where d.group_id = (select id from public.groups where name = 'حلقة يو2')),
  30::bigint,
  'start day has exactly 30 assignments');

select is(
  (select count(*) from public.assignments a
   join public.group_days d on d.id = a.group_day_id
   where d.group_id = (select id from public.groups where name = 'حلقة يو2')
     and a.kind = 'seat' and a.status = 'pending'),
  2::bigint,
  'occupied seats produce seat/pending rows');

select is(
  (select count(*) from public.assignments a
   join public.group_days d on d.id = a.group_day_id
   where d.group_id = (select id from public.groups where name = 'حلقة يو2')
     and a.kind = 'unassigned' and a.status = 'available'),
  28::bigint,
  'empty seats produce unassigned/available rows');

select is(
  (select a.juz from public.assignments a
   join public.group_days d on d.id = a.group_day_id
   where d.group_id = (select id from public.groups where name = 'حلقة يو2')
     and a.seat_number = 1),
  1::smallint,
  'seat 1 reads juz 1 on start day');

select throws_ok(
  'select public.start_khatma((select id from public.groups where name = ''حلقة يو2''), 1)',
  'group_not_forming',
  'start_khatma on an active group rejected');

-- ---------------------------------------------------------------------------
-- generate_due_group_days: rotation +1, idempotent, backfill
-- ---------------------------------------------------------------------------
select lives_ok(
  'select public.generate_due_group_days()',
  'generate_due_group_days runs for the current date');

select is(
  (select count(*) from public.group_days
   where group_id = (select id from public.groups where name = 'حلقة يو2')),
  1::bigint,
  'no duplicate day for the same group-local date');

-- simulate the next day: move day 0 to yesterday (group-local date) and
-- shift start_date so the index math stays 0; generation must create today
update public.group_days
set group_date = current_date - 1,
    opens_at = now() - interval '24 hours',
    ends_at = now() - interval '1 second',
    closes_at = now() + interval '24 hours'
where group_id = (select id from public.groups where name = 'حلقة يو2')
  and day_index = 0;

update public.groups
set start_date = current_date - 1
where name = 'حلقة يو2';

select lives_ok(
  'select public.generate_due_group_days()',
  'generation creates the next day');

select is(
  (select count(*) from public.group_days
   where group_id = (select id from public.groups where name = 'حلقة يو2')),
  2::bigint,
  'day 1 created');

select is(
  (select a.juz from public.assignments a
   join public.group_days d on d.id = a.group_day_id
   where d.group_id = (select id from public.groups where name = 'حلقة يو2')
     and d.day_index = 1 and a.seat_number = 1),
  2::smallint,
  'seat 1 advances to juz 2');

select is(
  (select a.juz from public.assignments a
   join public.group_days d on d.id = a.group_day_id
   where d.group_id = (select id from public.groups where name = 'حلقة يو2')
     and d.day_index = 1 and a.seat_number = 30),
  1::smallint,
  'seat 30 wraps from 30 back to juz 1');

select is(
  (select count(distinct a.juz) from public.assignments a
   join public.group_days d on d.id = a.group_day_id
   where d.group_id = (select id from public.groups where name = 'حلقة يو2')
     and d.day_index = 1),
  30::bigint,
  'day 1 still has 30 distinct juz');

select lives_ok(
  'select public.generate_due_group_days()',
  'generation is idempotent');

select is(
  (select count(*) from public.group_days
   where group_id = (select id from public.groups where name = 'حلقة يو2')),
  2::bigint,
  'idempotent: still 2 days');

select * from finish();
rollback;
