create extension if not exists pgtap with schema extensions;

\i helpers/seed_members.sql

begin;
select plan(20);

select tests_seed_user('c3000000-0000-0000-0000-000000000001', 'us3-owner@test.local', 'مالك يو3');
select tests_seed_user('c3000000-0000-0000-0000-000000000002', 'us3-reader@test.local', 'قارئ يو3');
select tests_seed_user('c3000000-0000-0000-0000-000000000003', 'us3-outsider@test.local', 'خارج يو3');
select tests_seed_group('c3000000-0000-0000-0000-000000000011', 'حلقة يو3',
                        'c3000000-0000-0000-0000-000000000001', 'Africa/Cairo', 'US3ABCD2');
select tests_seed_member('c3000000-0000-0000-0000-000000000011',
                         'c3000000-0000-0000-0000-000000000001', 1::smallint, 'owner'::public.group_role);
select tests_seed_member('c3000000-0000-0000-0000-000000000011',
                         'c3000000-0000-0000-0000-000000000002', 2::smallint);
select set_config('request.jwt.claims',
  json_build_object('sub', 'c3000000-0000-0000-0000-000000000001', 'role', 'authenticated')::text, true);
select public.start_khatma('c3000000-0000-0000-0000-000000000011', 1);

select throws_ok(
  'select public.mark_assignment_complete(gen_random_uuid(), now(), ''online''::public.completion_source)',
  'P0001', null, 'unknown assignment is rejected');

select set_config('request.jwt.claims',
  json_build_object('sub', 'c3000000-0000-0000-0000-000000000003', 'role', 'authenticated')::text, true);
select throws_ok(
  'select public.mark_assignment_complete((select a.id from public.assignments a join public.group_days d on d.id = a.group_day_id where d.group_id = ''c3000000-0000-0000-0000-000000000011'' and a.seat_number = 1), now(), ''online''::public.completion_source)',
  'P0001', null, 'non-reader cannot complete another member assignment');

select set_config('request.jwt.claims',
  json_build_object('sub', 'c3000000-0000-0000-0000-000000000001', 'role', 'authenticated')::text, true);
select is(
  (public.mark_assignment_complete(
    (select a.id from public.assignments a join public.group_days d on d.id = a.group_day_id where d.group_id = 'c3000000-0000-0000-0000-000000000011' and a.seat_number = 1),
    now() - interval '2 days', 'online')->>'status'),
  'completed', 'online completion uses server time and completes an open day');
select is(
  (select count(*)::int from public.completion_records r join public.assignments a on a.id = r.assignment_id
   join public.group_days d on d.id = a.group_day_id where d.group_id = 'c3000000-0000-0000-0000-000000000011'),
  1, 'completion writes one audit record');
select is(
  (select completed_count::int from public.group_days where group_id = 'c3000000-0000-0000-0000-000000000011'),
  1, 'completion updates the day count');
select public.mark_assignment_complete(
  (select a.id from public.assignments a join public.group_days d on d.id = a.group_day_id where d.group_id = 'c3000000-0000-0000-0000-000000000011' and a.seat_number = 1),
  now(), 'online');
select is(
  (select count(*)::int from public.completion_records r join public.assignments a on a.id = r.assignment_id
   join public.group_days d on d.id = a.group_day_id where d.group_id = 'c3000000-0000-0000-0000-000000000011'),
  1, 'duplicate completion is idempotent');

select is(
  (public.undo_assignment_completion(
    (select a.id from public.assignments a join public.group_days d on d.id = a.group_day_id where d.group_id = 'c3000000-0000-0000-0000-000000000011' and a.seat_number = 1))->>'status'),
  'pending', 'undo during open day restores pending');
select is(
  (select completed_count::int from public.group_days where group_id = 'c3000000-0000-0000-0000-000000000011'),
  0, 'undo recomputes completion counts');

-- Move the day into grace and advance remaining pending/available rows.
update public.group_days set ends_at = now() - interval '1 minute', closes_at = now() + interval '1 hour'
where group_id = 'c3000000-0000-0000-0000-000000000011';
select public.advance_day_states();
select is(
  (select state::text from public.group_days where group_id = 'c3000000-0000-0000-0000-000000000011'),
  'grace', 'open day advances to grace');
select is(
  (select count(*)::int from public.assignments a join public.group_days d on d.id = a.group_day_id
   where d.group_id = 'c3000000-0000-0000-0000-000000000011' and a.status = 'missed'),
  2, 'grace changes pending assignments to missed');
select is(
  (select count(*)::int from public.assignments a join public.group_days d on d.id = a.group_day_id
   where d.group_id = 'c3000000-0000-0000-0000-000000000011' and a.status = 'unread'),
  28, 'grace changes available assignments to unread');

select is(
  (public.mark_assignment_complete(
    (select a.id from public.assignments a join public.group_days d on d.id = a.group_day_id where d.group_id = 'c3000000-0000-0000-0000-000000000011' and a.seat_number = 1),
    now(), 'online')->>'status'),
  'late', 'completion during grace is late');
select is(
  (select late_count::int from public.group_days where group_id = 'c3000000-0000-0000-0000-000000000011'),
  1, 'late completion updates late count');
select is(
  (public.undo_assignment_completion(
    (select a.id from public.assignments a join public.group_days d on d.id = a.group_day_id where d.group_id = 'c3000000-0000-0000-0000-000000000011' and a.seat_number = 1))->>'status'),
  'missed', 'undo during grace restores missed');

-- Offline device times are clamped on both sides of the valid interval.
update public.group_days set ends_at = now() + interval '1 hour', closes_at = now() + interval '2 hours', state = 'open'
where group_id = 'c3000000-0000-0000-0000-000000000011';
update public.assignments set status = 'pending'
where group_day_id = (select id from public.group_days where group_id = 'c3000000-0000-0000-0000-000000000011') and seat_number = 1;
select ok(
  (public.mark_assignment_complete(
    (select a.id from public.assignments a join public.group_days d on d.id = a.group_day_id where d.group_id = 'c3000000-0000-0000-0000-000000000011' and a.seat_number = 1),
    now() + interval '2 days', 'offline_sync')->>'completed_at')::timestamptz <= now(),
  'offline future timestamp is clamped to server time');
update public.group_days set opens_at = now() - interval '1 day',
  ends_at = now() + interval '1 hour', closes_at = now() + interval '2 hours'
where group_id = 'c3000000-0000-0000-0000-000000000011';
update public.assignments set status = 'pending'
where group_day_id = (select id from public.group_days where group_id = 'c3000000-0000-0000-0000-000000000011') and seat_number = 1;
select ok(
  (public.mark_assignment_complete(
    (select a.id from public.assignments a join public.group_days d on d.id = a.group_day_id where d.group_id = 'c3000000-0000-0000-0000-000000000011' and a.seat_number = 1),
    now() - interval '2 days', 'offline_sync')->>'completed_at')::timestamptz >=
    (select opens_at from public.group_days where group_id = 'c3000000-0000-0000-0000-000000000011'),
  'offline past timestamp is clamped to day open');
update public.assignments set status = case when seat_number = 1 then 'late'::public.assignment_status
  else 'completed'::public.assignment_status end
where group_day_id = (select id from public.group_days where group_id = 'c3000000-0000-0000-0000-000000000011');
select public.recompute_day_counts((select id from public.group_days where group_id = 'c3000000-0000-0000-0000-000000000011'));
select ok(
  (select full_khatma from public.group_days where group_id = 'c3000000-0000-0000-0000-000000000011'),
  'full khatma counts late assignments as completed');

update public.group_days set ends_at = now() - interval '2 seconds',
  closes_at = now() - interval '1 second', state = 'grace'
where group_id = 'c3000000-0000-0000-0000-000000000011';
select public.advance_day_states();
select is(
  (select state::text from public.group_days where group_id = 'c3000000-0000-0000-0000-000000000011'),
  'closed', 'grace day advances to closed');
select throws_ok(
  'select public.mark_assignment_complete((select a.id from public.assignments a join public.group_days d on d.id = a.group_day_id where d.group_id = ''c3000000-0000-0000-0000-000000000011'' and a.seat_number = 2), now(), ''online''::public.completion_source)',
  'P0001', null, 'closed day rejects completion');
select throws_ok(
  'select public.undo_assignment_completion((select a.id from public.assignments a join public.group_days d on d.id = a.group_day_id where d.group_id = ''c3000000-0000-0000-0000-000000000011'' and a.seat_number = 1))',
  'P0001', null, 'closed day rejects undo');

select * from finish();
rollback;
