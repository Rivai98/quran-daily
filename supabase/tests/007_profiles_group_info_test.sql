create extension if not exists pgtap with schema extensions;

\i helpers/seed_members.sql

begin;
select plan(43);

-- Spec 007 fixtures (b7 prefix, Q7 invite codes).
-- 11 owner (seat 1), 12 supervisor (seat 2), 13 member (seat 3),
-- 14 former member (left), 16 member (seat 6), 15 outsider.
select tests_seed_user('b7000000-0000-0000-0000-000000000011', 's7i-owner@test.local', 'مالك معلومات');
select tests_seed_user('b7000000-0000-0000-0000-000000000012', 's7i-sup@test.local', 'مشرف معلومات');
select tests_seed_user('b7000000-0000-0000-0000-000000000013', 's7i-m13@test.local', 'خالد عبد الرحمن');
select tests_seed_user('b7000000-0000-0000-0000-000000000014', 's7i-old@test.local', 'عضو سابق');
select tests_seed_user('b7000000-0000-0000-0000-000000000015', 's7i-out@test.local', 'خارجي معلومات');
select tests_seed_user('b7000000-0000-0000-0000-000000000016', 's7i-m16@test.local', 'زيد');
update public.profiles set bio = 'أقرأ بعد الفجر' where id = 'b7000000-0000-0000-0000-000000000013';

select tests_seed_group('b7000000-0000-0000-0000-000000000030', 'حلقة معلومات سبعة',
  'b7000000-0000-0000-0000-000000000011', 'Africa/Cairo', 'Q7NFCCCC');
update public.groups set short_description = 'وصف الحلقة'
where id = 'b7000000-0000-0000-0000-000000000030';
select tests_seed_member('b7000000-0000-0000-0000-000000000030', 'b7000000-0000-0000-0000-000000000011', 1::smallint, 'owner'::public.group_role);
select tests_seed_member('b7000000-0000-0000-0000-000000000030', 'b7000000-0000-0000-0000-000000000012', 2::smallint, 'supervisor'::public.group_role);
select tests_seed_member('b7000000-0000-0000-0000-000000000030', 'b7000000-0000-0000-0000-000000000013', 3::smallint);
select tests_seed_member('b7000000-0000-0000-0000-000000000030', 'b7000000-0000-0000-0000-000000000016', 6::smallint);
insert into public.group_memberships (group_id, user_id, role, status, seat_number, joined_at, ended_at)
values ('b7000000-0000-0000-0000-000000000030', 'b7000000-0000-0000-0000-000000000014',
  'member', 'left', null, now() - interval '20 days', now() - interval '10 days');

-- Four recent closed days. Member 13: d1 completed, d2 late (+ a volunteer
-- completion), d3 missed, d4 completed. d4 completes a khatma.
insert into public.group_days (id, group_id, group_date, day_index, opens_at, ends_at, closes_at,
  state, full_khatma)
select ('b7000000-0000-0000-0000-0000000000e' || i)::uuid, 'b7000000-0000-0000-0000-000000000030',
  current_date - (5 - i), i - 1, now() - make_interval(days => 6 - i), now() - make_interval(days => 5 - i),
  now() - make_interval(days => 4 - i), 'closed', i = 4
from generate_series(1, 4) i;

insert into public.assignments (group_day_id, juz, seat_number, kind, reader_membership_id, status, completed_at)
select ('b7000000-0000-0000-0000-0000000000e' || x.d)::uuid, x.juz::smallint, x.seat::smallint,
  x.kind::public.assignment_kind,
  (select id from public.group_memberships where group_id = 'b7000000-0000-0000-0000-000000000030'
     and user_id = 'b7000000-0000-0000-0000-000000000013'),
  x.status::public.assignment_status,
  case when x.status in ('completed', 'late') then now() - make_interval(days => 5 - x.d) end
from (values (1, 3, 3, 'seat', 'completed'), (2, 3, 3, 'seat', 'late'),
             (2, 5, 5, 'volunteer', 'completed'), (3, 3, 3, 'seat', 'missed'),
             (4, 3, 3, 'seat', 'completed')) as x(d, juz, seat, kind, status);

-- ---------------------------------------------------------------------------
-- get_group_info
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '', true);
select throws_ok(
  'select public.get_group_info(''b7000000-0000-0000-0000-000000000030'')',
  'unauthenticated', 'get_group_info requires auth');

select set_config('request.jwt.claims',
  json_build_object('sub', 'b7000000-0000-0000-0000-000000000016', 'role', 'authenticated')::text, true);
create temp table s7_info as
  select public.get_group_info('b7000000-0000-0000-0000-000000000030') d;

select is((select d->>'name' from s7_info), 'حلقة معلومات سبعة', 'group info has the name');
select is((select d->>'description' from s7_info), 'وصف الحلقة', 'group info has the description');
select is((select (d->>'member_count')::int from s7_info), 4, 'member count counts active members only');
select is((select (d->>'seat_capacity')::int from s7_info), 30, 'seat capacity is reported');
select is((select (d->>'khatma_count')::int from s7_info), 1, 'khatma count counts completed khatmas');
select is((select d->>'portion_unit' from s7_info), 'juz', 'group info has the unit');
select ok((select d->>'created_at' from s7_info) is not null, 'group info has created_at');
select is((select d->>'invite_code' from s7_info), null, 'plain member gets no invite code');
select is((select jsonb_array_length(d->'members') from s7_info), 4, 'member list has active members');
select is(
  (select string_agg(e.value->>'role', ',' order by e.ordinality) from s7_info, jsonb_array_elements(d->'members') with ordinality e),
  'owner,supervisor,member,member', 'members are sorted by role then seat');
select is(
  (select e.value->>'initials' || '|' || (e.value->>'seat_number') from s7_info, jsonb_array_elements(d->'members') e
   where e.value->>'user_id' = 'b7000000-0000-0000-0000-000000000013'),
  'خ ع|3', 'member rows carry initials and seat');
select is((select count(*)::int from s7_info where d::text like '%@test.local%' or d::text like '%"email"%'),
  0, 'group info never returns email');

select set_config('request.jwt.claims',
  json_build_object('sub', 'b7000000-0000-0000-0000-000000000012', 'role', 'authenticated')::text, true);
select is(public.get_group_info('b7000000-0000-0000-0000-000000000030')->>'invite_code',
  'Q7NFCCCC', 'supervisor gets the invite code');

select set_config('request.jwt.claims',
  json_build_object('sub', 'b7000000-0000-0000-0000-000000000015', 'role', 'authenticated')::text, true);
select throws_ok(
  'select public.get_group_info(''b7000000-0000-0000-0000-000000000030'')',
  'not_member', 'outsider cannot read group info');

-- ---------------------------------------------------------------------------
-- get_member_profile
-- ---------------------------------------------------------------------------
select throws_ok(
  'select public.get_member_profile(''b7000000-0000-0000-0000-000000000013'', ''b7000000-0000-0000-0000-000000000030'')',
  'profile_not_accessible', 'outsider cannot open a member profile');

select set_config('request.jwt.claims',
  json_build_object('sub', 'b7000000-0000-0000-0000-000000000016', 'role', 'authenticated')::text, true);
select throws_ok(
  'select public.get_member_profile(''b7000000-0000-0000-0000-000000000015'', ''b7000000-0000-0000-0000-000000000030'')',
  'profile_not_accessible', 'member cannot open a non-member profile');

create temp table s7_prof as
  select public.get_member_profile('b7000000-0000-0000-0000-000000000013', 'b7000000-0000-0000-0000-000000000030') d;
select is((select d->>'display_name' || '|' || (d->>'initials') from s7_prof), 'خالد عبد الرحمن|خ ع', 'profile has name and initials');
select is((select d->>'bio' from s7_prof), 'أقرأ بعد الفجر', 'profile has bio');
select is((select d->>'role' || '|' || (d->>'seat_number') from s7_prof), 'member|3', 'profile has role and seat');
select ok((select d->>'member_since' from s7_prof) is not null, 'profile has member_since');
select is((select (d->>'current_streak')::int from s7_prof), 1, 'streak counts back to the last miss');
select is((select (d->>'completion_rate')::int from s7_prof), 75, 'completion rate over seat portions');
select is((select (d->>'portions_read')::int from s7_prof), 4, 'portions read includes volunteering');
select is((select jsonb_array_length(d->'recent_days') from s7_prof), 4, 'co-member does not see missed days');
select is((select count(*)::int from s7_prof where d::text like '%@test.local%' or d::text like '%"email"%'),
  0, 'profile never returns email');
select is(
  public.get_member_profile('b7000000-0000-0000-0000-000000000014', 'b7000000-0000-0000-0000-000000000030')->>'role',
  'former_member', 'former member profile is marked');

select set_config('request.jwt.claims',
  json_build_object('sub', 'b7000000-0000-0000-0000-000000000011', 'role', 'authenticated')::text, true);
select is(
  jsonb_array_length(public.get_member_profile('b7000000-0000-0000-0000-000000000013', 'b7000000-0000-0000-0000-000000000030')->'recent_days'),
  5, 'owner sees missed days too');

-- ---------------------------------------------------------------------------
-- update_my_profile
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims',
  json_build_object('sub', 'b7000000-0000-0000-0000-000000000016', 'role', 'authenticated')::text, true);
select is(
  public.update_my_profile('  زيد بن ثابت  ', '  نبذة قصيرة ')->>'display_name',
  'زيد بن ثابت', 'update_my_profile trims and saves the name');
select is((select bio from public.profiles where id = 'b7000000-0000-0000-0000-000000000016'),
  'نبذة قصيرة', 'update_my_profile saves the bio');
select throws_ok('select public.update_my_profile(''ز'', null)', 'invalid_display_name', 'name under 2 chars is refused');
select throws_ok('select public.update_my_profile(''   '', null)', 'invalid_display_name', 'blank name is refused');
select throws_ok(format('select public.update_my_profile(%L, null)', repeat('ز', 51)),
  'invalid_display_name', 'name over 50 chars is refused');
select throws_ok(format('select public.update_my_profile(%L, %L)', 'زيد', repeat('ن', 121)),
  'invalid_bio', 'bio over 120 chars is refused');
select lives_ok(format('select public.update_my_profile(%L, %L)', 'زيد', repeat('ن', 120)),
  'bio of 120 chars is accepted');

-- ---------------------------------------------------------------------------
-- update_group_details / set_group_photo (owner only)
-- ---------------------------------------------------------------------------
select throws_ok(
  'select public.update_group_details(''b7000000-0000-0000-0000-000000000030'', ''اسم آخر'', null)',
  'forbidden', 'member cannot edit group details');

select set_config('request.jwt.claims',
  json_build_object('sub', 'b7000000-0000-0000-0000-000000000012', 'role', 'authenticated')::text, true);
select throws_ok(
  'select public.set_group_photo(''b7000000-0000-0000-0000-000000000030'', ''b7000000-0000-0000-0000-000000000030/p.jpg'')',
  'forbidden', 'supervisor cannot set the group photo');

select set_config('request.jwt.claims',
  json_build_object('sub', 'b7000000-0000-0000-0000-000000000011', 'role', 'authenticated')::text, true);
select is(
  public.update_group_details('b7000000-0000-0000-0000-000000000030', ' حلقة الفجر ', ' وصف جديد ')->>'description',
  'وصف جديد', 'owner edits group details');
select throws_ok(
  'select public.set_group_photo(''b7000000-0000-0000-0000-000000000030'', ''b7000000-0000-0000-0000-000000000099/p.jpg'')',
  'invalid_photo_path', 'photo path must live under the group folder');
select throws_ok(
  'select public.set_group_photo(''b7000000-0000-0000-0000-000000000030'', ''b7000000-0000-0000-0000-000000000030/missing.jpg'')',
  'photo_not_found', 'photo must be uploaded first');

insert into storage.objects (bucket_id, name, owner, owner_id)
values ('group-photos', 'b7000000-0000-0000-0000-000000000030/p.jpg',
  'b7000000-0000-0000-0000-000000000011', 'b7000000-0000-0000-0000-000000000011');
select is(
  public.set_group_photo('b7000000-0000-0000-0000-000000000030', 'b7000000-0000-0000-0000-000000000030/p.jpg')->>'photo_path',
  'b7000000-0000-0000-0000-000000000030/p.jpg', 'owner sets the group photo');
select is(
  public.get_group_info('b7000000-0000-0000-0000-000000000030')->>'photo_path',
  'b7000000-0000-0000-0000-000000000030/p.jpg', 'group info shows the photo path');
select is(
  public.set_group_photo('b7000000-0000-0000-0000-000000000030', null)->>'photo_path',
  null, 'owner removes the group photo');

select * from finish();
rollback;
