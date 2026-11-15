create extension if not exists pgtap with schema extensions;

\i helpers/seed_members.sql

begin;
select plan(10);

select tests_seed_user('c5000000-0000-0000-0000-000000000001', 'us5-owner@test.local', 'مالك يو5');
select tests_seed_user('c5000000-0000-0000-0000-000000000002', 'us5-reader@test.local', 'قارئ يو5');
select tests_seed_user('c5000000-0000-0000-0000-000000000003', 'us5-outsider@test.local', 'خارج يو5');
select tests_seed_group('c5000000-0000-0000-0000-000000000011', 'حلقة يو5',
                        'c5000000-0000-0000-0000-000000000001', 'Africa/Cairo', 'US5ABCD2');
select tests_seed_member('c5000000-0000-0000-0000-000000000011',
                         'c5000000-0000-0000-0000-000000000001', 1::smallint, 'owner'::public.group_role);
select tests_seed_member('c5000000-0000-0000-0000-000000000011',
                         'c5000000-0000-0000-0000-000000000002', 2::smallint);
select set_config('request.jwt.claims',
  json_build_object('sub', 'c5000000-0000-0000-0000-000000000001', 'role', 'authenticated')::text, true);
select public.start_khatma('c5000000-0000-0000-0000-000000000011', 1);
select throws_ok(
  'select public.volunteer_for_juz(gen_random_uuid())',
  'P0001', null, 'missing assignment is rejected');

select set_config('request.jwt.claims',
  json_build_object('sub', 'c5000000-0000-0000-0000-000000000002', 'role', 'authenticated')::text, true);
select is(
  (public.volunteer_for_juz((select a.id from public.assignments a join public.group_days d on d.id = a.group_day_id
    where d.group_id = 'c5000000-0000-0000-0000-000000000011' and a.seat_number = 3))->>'kind'),
  'volunteer', 'active member claims an available juz');
select is(
  (select reader_membership_id from public.assignments a join public.group_days d on d.id = a.group_day_id
   where d.group_id = 'c5000000-0000-0000-0000-000000000011' and a.seat_number = 3),
  (select id from public.group_memberships where group_id = 'c5000000-0000-0000-0000-000000000011'
   and user_id = 'c5000000-0000-0000-0000-000000000002'),
  'volunteer assignment is owned by the caller membership');
select is(
  (select pending_count::int from public.group_days where group_id = 'c5000000-0000-0000-0000-000000000011'),
  3, 'volunteering updates pending count');
select throws_ok(
  'select public.volunteer_for_juz((select a.id from public.assignments a join public.group_days d on d.id = a.group_day_id where d.group_id = ''c5000000-0000-0000-0000-000000000011'' and a.seat_number = 3))',
  'P0001', null, 'a second claimant loses the atomic claim');
select is(
  (public.volunteer_for_juz((select a.id from public.assignments a join public.group_days d on d.id = a.group_day_id
    where d.group_id = 'c5000000-0000-0000-0000-000000000011' and a.seat_number = 4))->>'kind'),
  'volunteer', 'a member may volunteer for multiple juz');

select set_config('request.jwt.claims',
  json_build_object('sub', 'c5000000-0000-0000-0000-000000000003', 'role', 'authenticated')::text, true);
select throws_ok(
  'select public.volunteer_for_juz((select a.id from public.assignments a join public.group_days d on d.id = a.group_day_id where d.group_id = ''c5000000-0000-0000-0000-000000000011'' and a.seat_number = 5))',
  'P0001', null, 'non-member cannot volunteer');
select set_config('request.jwt.claims',
  json_build_object('sub', 'c5000000-0000-0000-0000-000000000001', 'role', 'authenticated')::text, true);
update public.group_days set state = 'grace'
where group_id = 'c5000000-0000-0000-0000-000000000011';
select throws_ok(
  'select public.volunteer_for_juz((select a.id from public.assignments a join public.group_days d on d.id = a.group_day_id where d.group_id = ''c5000000-0000-0000-0000-000000000011'' and a.seat_number = 5))',
  'P0001', null, 'volunteering is limited to open days');

-- Materialize a fresh local day. Volunteer claims belong only to their day.
update public.group_days
set group_date = public.group_local_date(group_id, now()) - 1,
    ends_at = now() - interval '1 minute', closes_at = now() + interval '1 day', state = 'closed'
where group_id = 'c5000000-0000-0000-0000-000000000011';
update public.groups
set start_date = public.group_local_date(id, now()) - 1
where id = 'c5000000-0000-0000-0000-000000000011';
select public.ensure_current_group_day('c5000000-0000-0000-0000-000000000011');
select is(
  (select count(*)::int from public.assignments a join public.group_days d on d.id = a.group_day_id
   where d.group_id = 'c5000000-0000-0000-0000-000000000011' and d.group_date = public.group_local_date(d.group_id, now())
     and a.kind = 'volunteer'),
  0, 'volunteer claims do not carry into the next day');
select is(
  (select count(*)::int from public.assignments a join public.group_days d on d.id = a.group_day_id
   where d.group_id = 'c5000000-0000-0000-0000-000000000011' and d.group_date = public.group_local_date(d.group_id, now())
     and a.status = 'available'),
  28, 'next day resets empty seats to available');

select * from finish();
rollback;
