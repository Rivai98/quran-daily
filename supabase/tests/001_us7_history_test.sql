create extension if not exists pgtap with schema extensions;

\i helpers/seed_members.sql

begin;
select plan(15);

-- Seed users: owner, supervisor, member, non-member
select tests_seed_user('f7000000-0000-0000-0000-000000000001', 'us7-owner@test.local', 'مالك يو7');
select tests_seed_user('f7000000-0000-0000-0000-000000000002', 'us7-sup@test.local', 'مشرف يو7');
select tests_seed_user('f7000000-0000-0000-0000-000000000003', 'us7-mem@test.local', 'عضو يو7');
select tests_seed_user('f7000000-0000-0000-0000-000000000004', 'us7-non@test.local', 'غير عضو يو7');

-- Seed group and memberships
select tests_seed_group('f7000000-0000-0000-0000-000000000010', 'مجموعة تاريخ يو7', 'f7000000-0000-0000-0000-000000000001', 'Africa/Cairo', 'US7TEST2');
select tests_seed_member('f7000000-0000-0000-0000-000000000010', 'f7000000-0000-0000-0000-000000000001', 1::smallint, 'owner'::public.group_role);
select tests_seed_member('f7000000-0000-0000-0000-000000000010', 'f7000000-0000-0000-0000-000000000002', 2::smallint, 'supervisor'::public.group_role);
select tests_seed_member('f7000000-0000-0000-0000-000000000010', 'f7000000-0000-0000-0000-000000000003', 3::smallint, 'member'::public.group_role);

-- Seed past group days
-- Day 1: 2026-11-10, partial completion
insert into public.group_days (
  id, group_id, group_date, day_index, opens_at, ends_at, closes_at,
  state, completed_count, late_count, missed_count, unread_count, pending_count, available_count, full_khatma
) values (
  'f7000000-0000-0000-0000-0000000000d1',
  'f7000000-0000-0000-0000-000000000010',
  '2026-11-10'::date,
  0,
  '2026-11-10 00:00:00+02'::timestamptz,
  '2026-11-11 00:00:00+02'::timestamptz,
  '2026-11-12 00:00:00+02'::timestamptz,
  'closed'::public.day_state,
  20, 2, 5, 3, 0, 0, false
);

-- Day 2: 2026-11-11, full khatma (28 completed + 2 late = 30)
insert into public.group_days (
  id, group_id, group_date, day_index, opens_at, ends_at, closes_at,
  state, completed_count, late_count, missed_count, unread_count, pending_count, available_count, full_khatma
) values (
  'f7000000-0000-0000-0000-0000000000d2',
  'f7000000-0000-0000-0000-000000000010',
  '2026-11-11'::date,
  1,
  '2026-11-11 00:00:00+02'::timestamptz,
  '2026-11-12 00:00:00+02'::timestamptz,
  '2026-11-13 00:00:00+02'::timestamptz,
  'closed'::public.day_state,
  28, 2, 0, 0, 0, 0, true
);

-- Day 3: 2026-11-12, another day
insert into public.group_days (
  id, group_id, group_date, day_index, opens_at, ends_at, closes_at,
  state, completed_count, late_count, missed_count, unread_count, pending_count, available_count, full_khatma
) values (
  'f7000000-0000-0000-0000-0000000000d3',
  'f7000000-0000-0000-0000-000000000010',
  '2026-11-12'::date,
  2,
  '2026-11-12 00:00:00+02'::timestamptz,
  '2026-11-13 00:00:00+02'::timestamptz,
  '2026-11-14 00:00:00+02'::timestamptz,
  'closed'::public.day_state,
  25, 0, 5, 0, 0, 0, false
);

-- Seed 30 assignments for Day 1
do $$
declare
  s int;
  v_m_owner uuid;
  v_m_sup uuid;
  v_m_mem uuid;
  v_reader uuid;
  v_status public.assignment_status;
  v_kind public.assignment_kind;
begin
  select id into v_m_owner from public.group_memberships where group_id = 'f7000000-0000-0000-0000-000000000010' and seat_number = 1;
  select id into v_m_sup from public.group_memberships where group_id = 'f7000000-0000-0000-0000-000000000010' and seat_number = 2;
  select id into v_m_mem from public.group_memberships where group_id = 'f7000000-0000-0000-0000-000000000010' and seat_number = 3;

  for s in 1..30 loop
    if s = 1 then
      v_reader := v_m_owner;
      v_status := 'completed';
      v_kind := 'seat';
    elsif s = 2 then
      v_reader := v_m_sup;
      v_status := 'late';
      v_kind := 'seat';
    elsif s = 3 then
      v_reader := v_m_mem;
      v_status := 'completed';
      v_kind := 'seat';
    else
      v_reader := null;
      v_status := 'unread';
      v_kind := 'unassigned';
    end if;

    insert into public.assignments (
      id, group_day_id, juz, seat_number, kind, reader_membership_id, status, completed_at
    ) values (
      gen_random_uuid(),
      'f7000000-0000-0000-0000-0000000000d1',
      s::smallint,
      s::smallint,
      v_kind,
      v_reader,
      v_status,
      case when v_status in ('completed', 'late') then now() else null end
    );
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- 1. Unauthenticated checks
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '', true);

select throws_ok(
  'select public.get_history(''f7000000-0000-0000-0000-000000000010''::uuid)',
  'unauthenticated',
  'get_history unauthenticated throws unauthenticated');

select throws_ok(
  'select public.get_history_day(''f7000000-0000-0000-0000-000000000010''::uuid, ''2026-11-10''::date)',
  'unauthenticated',
  'get_history_day unauthenticated throws unauthenticated');

-- ---------------------------------------------------------------------------
-- 2. Non-member checks
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims',
  json_build_object('sub', 'f7000000-0000-0000-0000-000000000004', 'role', 'authenticated')::text, true);

select throws_ok(
  'select public.get_history(''f7000000-0000-0000-0000-000000000010''::uuid)',
  'not_member',
  'get_history for non-member throws not_member');

select throws_ok(
  'select public.get_history_day(''f7000000-0000-0000-0000-000000000010''::uuid, ''2026-11-10''::date)',
  'not_member',
  'get_history_day for non-member throws not_member');

-- ---------------------------------------------------------------------------
-- 3. Non-existent group / day checks
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims',
  json_build_object('sub', 'f7000000-0000-0000-0000-000000000001', 'role', 'authenticated')::text, true);

select throws_ok(
  'select public.get_history(''f7000000-0000-0000-0000-000000000099''::uuid)',
  'group_not_found',
  'get_history for non-existent group throws group_not_found');

select throws_ok(
  'select public.get_history_day(''f7000000-0000-0000-0000-000000000010''::uuid, ''2026-11-01''::date)',
  'day_not_found',
  'get_history_day for non-existent day throws day_not_found');

-- ---------------------------------------------------------------------------
-- 4. Member view: get_history returns summaries ordered desc
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims',
  json_build_object('sub', 'f7000000-0000-0000-0000-000000000003', 'role', 'authenticated')::text, true);

select is(
  jsonb_array_length(public.get_history('f7000000-0000-0000-0000-000000000010'::uuid)),
  3,
  'get_history returns all 3 days');

select is(
  (public.get_history('f7000000-0000-0000-0000-000000000010'::uuid)->0->>'group_date'),
  '2026-11-12',
  'get_history orders descending (latest day first)');

select is(
  jsonb_array_length(public.get_history('f7000000-0000-0000-0000-000000000010'::uuid, '2026-11-12'::date, 10)),
  2,
  'get_history with before_date filters out later days');

-- ---------------------------------------------------------------------------
-- 5. Member view: get_history_day returns summary + own row only (per_juz is null)
-- ---------------------------------------------------------------------------
select is(
  (public.get_history_day('f7000000-0000-0000-0000-000000000010'::uuid, '2026-11-10'::date)->>'per_juz') is null,
  true,
  'regular member cannot see per_juz details');

select is(
  (public.get_history_day('f7000000-0000-0000-0000-000000000010'::uuid, '2026-11-10'::date)->'my_result'->>'seat_number')::int,
  3,
  'regular member sees their own assignment');

-- ---------------------------------------------------------------------------
-- 6. Supervisor & Owner views: get_history_day returns per_juz detail (30 assignments)
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims',
  json_build_object('sub', 'f7000000-0000-0000-0000-000000000002', 'role', 'authenticated')::text, true);

select is(
  jsonb_array_length(public.get_history_day('f7000000-0000-0000-0000-000000000010'::uuid, '2026-11-10'::date)->'per_juz'),
  30,
  'supervisor sees all 30 per_juz assignments in detail');

select set_config('request.jwt.claims',
  json_build_object('sub', 'f7000000-0000-0000-0000-000000000001', 'role', 'authenticated')::text, true);

select is(
  jsonb_array_length(public.get_history_day('f7000000-0000-0000-0000-000000000010'::uuid, '2026-11-10'::date)->'per_juz'),
  30,
  'owner sees all 30 per_juz assignments in detail');

-- ---------------------------------------------------------------------------
-- 7. Full khatma verification: Day 2 has full_khatma true
-- ---------------------------------------------------------------------------
select is(
  (public.get_history_day('f7000000-0000-0000-0000-000000000010'::uuid, '2026-11-11'::date)->>'full_khatma')::boolean,
  true,
  'day with completed + late = 30 is full_khatma true');

select is(
  (public.get_history_day('f7000000-0000-0000-0000-000000000010'::uuid, '2026-11-11'::date)->>'late_count')::int,
  2,
  'full khatma day includes late count');

rollback;