create extension if not exists pgtap with schema extensions;

\i helpers/seed_members.sql

begin;
select plan(20);

-- ---------------------------------------------------------------------------
-- Seed users
-- ---------------------------------------------------------------------------
select tests_seed_user('a6000000-0000-0000-0000-000000000001', 'p6-user1@test.local', 'قارئ يو6 الأول');
select tests_seed_user('a6000000-0000-0000-0000-000000000002', 'p6-user2@test.local', 'قارئ يو6 الثاني');

-- Seed groups
select tests_seed_group('a6000000-0000-0000-0000-000000000010', 'مجموعة النور a6', 'a6000000-0000-0000-0000-000000000001', 'Africa/Cairo', 'TESTA622');
select tests_seed_group('a6000000-0000-0000-0000-000000000020', 'مجموعة الهدى a6', 'a6000000-0000-0000-0000-000000000002', 'Africa/Cairo', 'TESTA633');

-- Seed members
select tests_seed_member('a6000000-0000-0000-0000-000000000010', 'a6000000-0000-0000-0000-000000000001', 1::smallint, 'owner'::public.group_role);
select tests_seed_member('a6000000-0000-0000-0000-000000000020', 'a6000000-0000-0000-0000-000000000002', 1::smallint, 'owner'::public.group_role);

-- ---------------------------------------------------------------------------
-- 1. Unauthenticated check
-- ---------------------------------------------------------------------------
select throws_ok(
  'select public.get_my_profile()',
  'P0001',
  'unauthenticated',
  'unauthenticated caller is rejected'
);

-- ---------------------------------------------------------------------------
-- 2. Authenticated user with no reading history (User 2)
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims',
  json_build_object('sub', 'a6000000-0000-0000-0000-000000000002', 'role', 'authenticated')::text,
  true);

select is((public.get_my_profile()->>'display_name')::text, 'قارئ يو6 الثاني', 'profile returns display_name');
select ok(public.get_my_profile() ? 'member_since', 'profile returns member_since');
select is((public.get_my_profile()->>'streak')::int, 0, 'empty profile has 0 streak');
select is((public.get_my_profile()->>'best_streak')::int, 0, 'empty profile has 0 best_streak');
select is((public.get_my_profile()->>'portions_read')::int, 0, 'empty profile has 0 portions_read');
select is((public.get_my_profile()->>'portions_late')::int, 0, 'empty profile has 0 portions_late');
select is(jsonb_array_length(public.get_my_profile()->'khatmas'), 0, 'empty profile has empty khatmas');
select is(jsonb_array_length(public.get_my_profile()->'badges'), 0, 'empty profile has empty badges');

-- ---------------------------------------------------------------------------
-- 3. Seed history for User 1:
-- 7 consecutive days ending yesterday (6 on time + 1 late):
-- Streak = 7, Best = 7, Portions read = 7, Portions late = 1.
-- Day 7 has full_khatma = true -> Khatma count = 1, first_khatma badge, streak_7 badge.
-- ---------------------------------------------------------------------------
do $$
declare
  v_m1 uuid;
  v_day_id uuid;
  v_dt date;
  i int;
  v_st public.assignment_status;
begin
  select id into v_m1 from public.group_memberships
  where group_id = 'a6000000-0000-0000-0000-000000000010' and user_id = 'a6000000-0000-0000-0000-000000000001';

  for i in 1..7 loop
    v_dt := current_date - (8 - i);
    v_day_id := gen_random_uuid();

    insert into public.group_days (
      id, group_id, group_date, day_index, opens_at, ends_at, closes_at,
      state, completed_count, late_count, missed_count, unread_count, pending_count, available_count,
      full_khatma, portion_unit, cycle_number, cycle_day, cycle_length
    ) values (
      v_day_id,
      'a6000000-0000-0000-0000-000000000010',
      v_dt,
      i - 1,
      v_dt + time '00:00',
      v_dt + interval '1 day',
      v_dt + interval '2 days',
      'closed',
      case when i = 3 then 0 else 1 end,
      case when i = 3 then 1 else 0 end,
      0, 0, 0, 0,
      (i = 7), -- 7th day completed a khatma
      'juz',
      i - 1,
      0,
      1
    );

    v_st := case when i = 3 then 'late'::public.assignment_status else 'completed'::public.assignment_status end;

    insert into public.assignments (
      id, group_day_id, juz, portion_index, seat_number, kind, reader_membership_id, status, completed_at
    ) values (
      gen_random_uuid(),
      v_day_id,
      1,
      1,
      1,
      'seat',
      v_m1,
      v_st,
      now()
    );
  end loop;
end;
$$;

-- Switch auth to User 1
select set_config('request.jwt.claims',
  json_build_object('sub', 'a6000000-0000-0000-0000-000000000001', 'role', 'authenticated')::text,
  true);

select is((public.get_my_profile()->>'streak')::int, 7, 'user1 has 7-day streak');
select is((public.get_my_profile()->>'best_streak')::int, 7, 'user1 has 7-day best_streak');
select is((public.get_my_profile()->>'portions_read')::int, 7, 'user1 read 7 portions');
select is((public.get_my_profile()->>'portions_late')::int, 1, 'user1 has 1 late portion');
select is((public.get_my_profile()->'khatmas'->0->>'completed')::int, 1, 'group1 has 1 completed khatma');

-- Check badges: first_khatma and streak_7
select ok(
  exists (
    select 1 from jsonb_to_recordset(public.get_my_profile()->'badges') as b(code text, earned_at date)
    where b.code = 'first_khatma'
  ),
  'first_khatma badge is earned'
);

select ok(
  exists (
    select 1 from jsonb_to_recordset(public.get_my_profile()->'badges') as b(code text, earned_at date)
    where b.code = 'streak_7'
  ),
  'streak_7 badge is earned'
);

-- ---------------------------------------------------------------------------
-- 4. Break streak with a missed assignment today
-- ---------------------------------------------------------------------------
do $$
declare
  v_m1 uuid;
  v_day_id uuid;
begin
  select id into v_m1 from public.group_memberships
  where group_id = 'a6000000-0000-0000-0000-000000000010' and user_id = 'a6000000-0000-0000-0000-000000000001';

  v_day_id := gen_random_uuid();
  insert into public.group_days (
    id, group_id, group_date, day_index, opens_at, ends_at, closes_at,
    state, completed_count, late_count, missed_count, unread_count, pending_count, available_count,
    full_khatma, portion_unit, cycle_number, cycle_day, cycle_length
  ) values (
    v_day_id,
    'a6000000-0000-0000-0000-000000000010',
    current_date,
    7,
    current_date + time '00:00',
    current_date + interval '1 day',
    current_date + interval '2 days',
    'closed',
    0, 0, 1, 0, 0, 0,
    false, 'juz', 7, 0, 1
  );

  insert into public.assignments (
    id, group_day_id, juz, portion_index, seat_number, kind, reader_membership_id, status, completed_at
  ) values (
    gen_random_uuid(),
    v_day_id,
    1,
    1,
    1,
    'seat',
    v_m1,
    'missed',
    null
  );
end;
$$;

select is((public.get_my_profile()->>'streak')::int, 0, 'missed day breaks current streak to 0');
select is((public.get_my_profile()->>'best_streak')::int, 7, 'best_streak remains 7 after break');

-- ---------------------------------------------------------------------------
-- 5. Seed 93 more portions across 93 older days to reach 100 total portions -> portions_100 badge
-- ---------------------------------------------------------------------------
do $$
declare
  v_m1 uuid;
  v_day_id uuid;
  v_dt date;
  k int;
begin
  select id into v_m1 from public.group_memberships
  where group_id = 'a6000000-0000-0000-0000-000000000010' and user_id = 'a6000000-0000-0000-0000-000000000001';

  for k in 1..93 loop
    v_day_id := gen_random_uuid();
    v_dt := current_date - 100 - k;

    insert into public.group_days (
      id, group_id, group_date, day_index, opens_at, ends_at, closes_at,
      state, completed_count, late_count, missed_count, unread_count, pending_count, available_count,
      full_khatma, portion_unit, cycle_number, cycle_day, cycle_length
    ) values (
      v_day_id,
      'a6000000-0000-0000-0000-000000000010',
      v_dt,
      100 + k,
      v_dt + time '00:00',
      v_dt + interval '1 day',
      v_dt + interval '2 days',
      'closed',
      1, 0, 0, 0, 0, 0,
      false, 'juz', 100 + k, 0, 1
    );

    insert into public.assignments (
      id, group_day_id, juz, portion_index, seat_number, kind, reader_membership_id, status, completed_at
    ) values (
      gen_random_uuid(),
      v_day_id,
      1,
      1,
      1,
      'seat',
      v_m1,
      'completed',
      v_dt + time '12:00'
    );
  end loop;
end;
$$;

select is((public.get_my_profile()->>'portions_read')::int, 100, 'user1 has 100 total portions read');
select ok(
  exists (
    select 1 from jsonb_to_recordset(public.get_my_profile()->'badges') as b(code text, earned_at date)
    where b.code = 'portions_100'
  ),
  'portions_100 badge is earned'
);

select * from finish();
rollback;
