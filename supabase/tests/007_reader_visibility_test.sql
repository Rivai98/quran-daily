create extension if not exists pgtap with schema extensions;

\i helpers/seed_members.sql

begin;
select plan(31);

-- Spec 007 fixtures use the b7 prefix and Q7 invite codes.
-- Owner (seat 1), supervisor (seat 2), member A = viewer (seat 3),
-- member B (seat 4), and an outsider.
select tests_seed_user('b7000000-0000-0000-0000-000000000001', 's7-owner@test.local', 'مالك سبعة');
select tests_seed_user('b7000000-0000-0000-0000-000000000002', 's7-sup@test.local', 'مشرف سبعة');
select tests_seed_user('b7000000-0000-0000-0000-000000000003', 's7-a@test.local', 'عمر');
select tests_seed_user('b7000000-0000-0000-0000-000000000004', 's7-b@test.local', 'محمد عبد الله');
select tests_seed_user('b7000000-0000-0000-0000-000000000005', 's7-out@test.local', 'خارجي سبعة');

-- ---------------------------------------------------------------------------
-- Initials helper (spec 007 edge case: first + last significant word)
-- ---------------------------------------------------------------------------
select is(public.display_initials('محمد عبد الله'), 'م ع', 'compound last name uses عبد');
select is(public.display_initials('عمر'), 'ع', 'single word gives one letter');
select is(public.display_initials('  أحمد   مصطفى  '), 'أ م', 'extra whitespace is ignored');

-- ---------------------------------------------------------------------------
-- Dashboard group (active, today)
-- ---------------------------------------------------------------------------
select tests_seed_group('b7000000-0000-0000-0000-000000000010', 'حلقة سبعة',
  'b7000000-0000-0000-0000-000000000001', 'Africa/Cairo', 'Q7RDRAAA');
select tests_seed_member('b7000000-0000-0000-0000-000000000010', 'b7000000-0000-0000-0000-000000000001', 1::smallint, 'owner'::public.group_role);
select tests_seed_member('b7000000-0000-0000-0000-000000000010', 'b7000000-0000-0000-0000-000000000002', 2::smallint, 'supervisor'::public.group_role);
select tests_seed_member('b7000000-0000-0000-0000-000000000010', 'b7000000-0000-0000-0000-000000000003', 3::smallint);
select tests_seed_member('b7000000-0000-0000-0000-000000000010', 'b7000000-0000-0000-0000-000000000004', 4::smallint);

select set_config('request.jwt.claims',
  json_build_object('sub', 'b7000000-0000-0000-0000-000000000001', 'role', 'authenticated')::text, true);
select public.start_khatma('b7000000-0000-0000-0000-000000000010', 1);

-- Shape today's statuses: 1 completed (owner), 2 late (sup), 3 missed (viewer A),
-- 4 missed (B), 5 volunteered + completed by A, 6.. available.
update public.assignments a set status = 'completed', completed_at = now()
from public.group_days d where d.id = a.group_day_id
  and d.group_id = 'b7000000-0000-0000-0000-000000000010' and a.seat_number = 1;
update public.assignments a set status = 'late', completed_at = now()
from public.group_days d where d.id = a.group_day_id
  and d.group_id = 'b7000000-0000-0000-0000-000000000010' and a.seat_number = 2;
update public.assignments a set status = 'missed'
from public.group_days d where d.id = a.group_day_id
  and d.group_id = 'b7000000-0000-0000-0000-000000000010' and a.seat_number in (3, 4);
update public.assignments a set status = 'completed', kind = 'volunteer', completed_at = now(),
  reader_membership_id = (select id from public.group_memberships
    where group_id = 'b7000000-0000-0000-0000-000000000010' and seat_number = 3)
from public.group_days d where d.id = a.group_day_id
  and d.group_id = 'b7000000-0000-0000-0000-000000000010' and a.seat_number = 5;

create temp table s7_dash (viewer text, data jsonb);
grant select, insert on s7_dash to authenticated;

-- Viewer A (regular member)
select set_config('request.jwt.claims',
  json_build_object('sub', 'b7000000-0000-0000-0000-000000000003', 'role', 'authenticated')::text, true);
insert into s7_dash select 'a', public.get_dashboard('b7000000-0000-0000-0000-000000000010');
-- Owner
select set_config('request.jwt.claims',
  json_build_object('sub', 'b7000000-0000-0000-0000-000000000001', 'role', 'authenticated')::text, true);
insert into s7_dash select 'owner', public.get_dashboard('b7000000-0000-0000-0000-000000000010');
-- Supervisor
select set_config('request.jwt.claims',
  json_build_object('sub', 'b7000000-0000-0000-0000-000000000002', 'role', 'authenticated')::text, true);
insert into s7_dash select 'sup', public.get_dashboard('b7000000-0000-0000-0000-000000000010');

create temp view s7_rows as
  select d.viewer, (e.value->>'seat_number')::int seat, e.value row
  from s7_dash d, jsonb_array_elements(d.data->'assignments') e(value);

select is(
  (select row->'reader'->>'display_name' from s7_rows where viewer = 'a' and seat = 1),
  'مالك سبعة', 'member sees who completed a portion');
select is(
  (select row->'reader'->>'user_id' from s7_rows where viewer = 'a' and seat = 1),
  'b7000000-0000-0000-0000-000000000001', 'reader carries a stable user id');
select is(
  (select row->'reader'->>'initials' from s7_rows where viewer = 'a' and seat = 1),
  'م س', 'reader carries initials');
select ok(
  (select row->>'completed_at' from s7_rows where viewer = 'a' and seat = 1) is not null,
  'completed portion carries completed_at');
select is(
  (select row->'reader'->>'display_name' from s7_rows where viewer = 'a' and seat = 2),
  'مشرف سبعة', 'member sees who read late');
select is(
  (select row->>'status' from s7_rows where viewer = 'a' and seat = 2),
  'late', 'late status is kept for members');
select is(
  (select row->>'kind' || '|' || (row->'reader'->>'display_name') from s7_rows where viewer = 'a' and seat = 5),
  'volunteer|عمر', 'volunteer portion shows the volunteer and kind');
select is(
  (select row->'reader' from s7_rows where viewer = 'a' and seat = 4),
  'null'::jsonb, 'member does not see who missed another portion');
select is(
  (select row->>'reader_display_name' from s7_rows where viewer = 'a' and seat = 4),
  null, 'legacy reader_display_name is hidden too for another member''s miss');
select is(
  (select row->>'status' from s7_rows where viewer = 'a' and seat = 4),
  'unread', 'another member''s miss shows a neutral status');
select is(
  (select row->>'status' || '|' || (row->'reader'->>'display_name') from s7_rows where viewer = 'a' and seat = 3),
  'missed|عمر', 'member always sees their own status');
select is(
  (select e.value->'reader'->>'display_name' from s7_dash d, jsonb_array_elements(d.data->'my_assignments') e(value)
   where d.viewer = 'a' and (e.value->>'seat_number')::int = 3),
  'عمر', 'my_assignments carry reader');
select is(
  (select row->>'status' || '|' || (row->'reader'->>'display_name') from s7_rows where viewer = 'owner' and seat = 4),
  'missed|محمد عبد الله', 'owner sees who missed');
select is(
  (select row->'reader'->>'initials' from s7_rows where viewer = 'owner' and seat = 4),
  'م ع', 'owner sees missed reader initials');
select is(
  (select row->>'status' || '|' || (row->'reader'->>'display_name') from s7_rows where viewer = 'sup' and seat = 4),
  'missed|محمد عبد الله', 'supervisor sees who missed');
select is(
  (select row->'reader' from s7_rows where viewer = 'a' and seat = 6),
  'null'::jsonb, 'empty seat has no reader');
select is(
  (select count(*)::int from s7_dash where data::text like '%@test.local%' or data::text like '%"email"%'),
  0, 'dashboard never returns email');

-- ---------------------------------------------------------------------------
-- History group (past closed day)
-- ---------------------------------------------------------------------------
select tests_seed_group('b7000000-0000-0000-0000-000000000020', 'حلقة سبعة تاريخ',
  'b7000000-0000-0000-0000-000000000001', 'Africa/Cairo', 'Q7RDRBBB');
select tests_seed_member('b7000000-0000-0000-0000-000000000020', 'b7000000-0000-0000-0000-000000000001', 1::smallint, 'owner'::public.group_role);
select tests_seed_member('b7000000-0000-0000-0000-000000000020', 'b7000000-0000-0000-0000-000000000002', 2::smallint, 'supervisor'::public.group_role);
select tests_seed_member('b7000000-0000-0000-0000-000000000020', 'b7000000-0000-0000-0000-000000000003', 3::smallint);
select tests_seed_member('b7000000-0000-0000-0000-000000000020', 'b7000000-0000-0000-0000-000000000004', 4::smallint);

insert into public.group_days (
  id, group_id, group_date, day_index, opens_at, ends_at, closes_at,
  state, completed_count, late_count, missed_count, unread_count, pending_count, available_count, full_khatma
) values (
  'b7000000-0000-0000-0000-0000000000d1', 'b7000000-0000-0000-0000-000000000020',
  '2026-11-10'::date, 0, '2026-11-10 00:00:00+02', '2026-11-11 00:00:00+02', '2026-11-12 00:00:00+02',
  'closed', 2, 1, 2, 25, 0, 0, false);

insert into public.assignments (id, group_day_id, juz, seat_number, kind, reader_membership_id, status, completed_at)
select gen_random_uuid(), 'b7000000-0000-0000-0000-0000000000d1', s::smallint, s::smallint,
  (case when s = 5 then 'volunteer' when s <= 4 then 'seat' else 'unassigned' end)::public.assignment_kind,
  (select m.id from public.group_memberships m where m.group_id = 'b7000000-0000-0000-0000-000000000020'
     and m.seat_number = case when s = 5 then 3 when s <= 4 then s end),
  (case when s in (1, 5) then 'completed' when s = 2 then 'late' when s in (3, 4) then 'missed' else 'unread' end)::public.assignment_status,
  case when s in (1, 2, 5) then '2026-11-10 10:00:00+02'::timestamptz end
from generate_series(1, 30) s;

create temp table s7_hist (viewer text, data jsonb);
grant select, insert on s7_hist to authenticated;

select set_config('request.jwt.claims',
  json_build_object('sub', 'b7000000-0000-0000-0000-000000000003', 'role', 'authenticated')::text, true);
insert into s7_hist select 'a', public.get_history_day('b7000000-0000-0000-0000-000000000020', '2026-11-10');
select set_config('request.jwt.claims',
  json_build_object('sub', 'b7000000-0000-0000-0000-000000000001', 'role', 'authenticated')::text, true);
insert into s7_hist select 'owner', public.get_history_day('b7000000-0000-0000-0000-000000000020', '2026-11-10');

create temp view s7_hrows as
  select h.viewer, (e.value->>'seat_number')::int seat, e.value row
  from s7_hist h, jsonb_array_elements(h.data->'portions') e(value);

select is(
  (select count(*)::int from s7_hrows where viewer = 'a'),
  30, 'member gets every portion of a history day');
select is(
  (select row->'reader'->>'display_name' || '|' || (row->>'completed_at' is not null)::text from s7_hrows where viewer = 'a' and seat = 1),
  'مالك سبعة|true', 'member sees who completed a past portion and when');
select is(
  (select row->>'kind' || '|' || (row->'reader'->>'display_name') from s7_hrows where viewer = 'a' and seat = 5),
  'volunteer|عمر', 'history shows volunteer reader and kind');
select is(
  (select row->'reader' from s7_hrows where viewer = 'a' and seat = 4),
  'null'::jsonb, 'member does not see who missed a past portion');
select is(
  (select row->>'status' from s7_hrows where viewer = 'a' and seat = 4),
  'unread', 'past miss of another member is neutral for a member');
select is(
  (select row->>'status' || '|' || (row->'reader'->>'display_name') from s7_hrows where viewer = 'a' and seat = 3),
  'missed|عمر', 'member sees their own past miss');
select is(
  (select data->'my_result'->'reader'->>'display_name' from s7_hist where viewer = 'a'),
  'عمر', 'my_result carries reader');
select is(
  (select data->>'per_juz' from s7_hist where viewer = 'a'),
  null, 'per_juz stays manager-only for existing clients');
select is(
  (select row->>'status' || '|' || (row->'reader'->>'display_name') from s7_hrows where viewer = 'owner' and seat = 4),
  'missed|محمد عبد الله', 'owner sees who missed in history');
select is(
  (select e.value->'reader'->>'display_name' from s7_hist h, jsonb_array_elements(h.data->'per_juz') e(value)
   where h.viewer = 'owner' and (e.value->>'seat_number')::int = 4),
  'محمد عبد الله', 'per_juz rows carry reader for managers');
select is(
  (select count(*)::int from s7_hist where data::text like '%@test.local%' or data::text like '%"email"%'),
  0, 'history never returns email');

select * from finish();
rollback;
