-- Spec 006: group reminder schedules (owner-set, members read).
-- Fixtures use the b6 UUID prefix and Q6 invite codes; every count is
-- scoped to these fixtures because the hosted DB holds real data.
create extension if not exists pgtap with schema extensions;
\i helpers/seed_members.sql
begin;
select plan(39);

select tests_seed_user('b6000000-0000-0000-0000-000000000001','rem-owner@test.local','مالك التذكير');
select tests_seed_user('b6000000-0000-0000-0000-000000000002','rem-member@test.local','عضو التذكير');
select tests_seed_user('b6000000-0000-0000-0000-000000000003','rem-outsider@test.local','غريب التذكير');
select tests_seed_user('b6000000-0000-0000-0000-000000000004','rem-supervisor@test.local','مشرف التذكير');
select tests_seed_group('b6100000-0000-0000-0000-000000000001','حلقة التذكير','b6000000-0000-0000-0000-000000000001','Africa/Cairo','Q6REMNDA');
select tests_seed_member('b6100000-0000-0000-0000-000000000001','b6000000-0000-0000-0000-000000000001',1::smallint,'owner');
select tests_seed_member('b6100000-0000-0000-0000-000000000001','b6000000-0000-0000-0000-000000000002',2::smallint,'member');
select tests_seed_member('b6100000-0000-0000-0000-000000000001','b6000000-0000-0000-0000-000000000004',3::smallint,'supervisor');

-- Structure and privileges
select has_table('public','group_reminder_schedules','reminder schedule table exists');
select has_function('public','set_group_reminder_schedule',
  array['uuid','boolean','integer','boolean','integer','boolean','text','text'],
  'set_group_reminder_schedule RPC exists');
select ok(coalesce((select relrowsecurity from pg_class where oid=to_regclass('public.group_reminder_schedules')),false),
  'RLS is enabled on group_reminder_schedules');
select ok(coalesce((select has_function_privilege('authenticated',p.oid,'execute') from pg_proc p
  where p.oid=to_regprocedure('public.set_group_reminder_schedule(uuid,boolean,integer,boolean,integer,boolean,text,text)')),false),
  'authenticated may execute the RPC');
select ok(coalesce((select not has_function_privilege('anon',p.oid,'execute') from pg_proc p
  where p.oid=to_regprocedure('public.set_group_reminder_schedule(uuid,boolean,integer,boolean,integer,boolean,text,text)')),false),
  'anon may not execute the RPC');

-- Unauthenticated
select set_config('request.jwt.claims','',true);
select throws_ok($$select public.set_group_reminder_schedule('b6100000-0000-0000-0000-000000000001',true,20,true,20,true,'22:30',null)$$,
  'P0001','unauthenticated','unauthenticated caller is rejected');

-- Owner: no schedule yet -> dashboard carries an explicit null
select set_config('request.jwt.claims',json_build_object('sub','b6000000-0000-0000-0000-000000000001','role','authenticated')::text,true);
select ok(public.get_dashboard('b6100000-0000-0000-0000-000000000001') ? 'reminder_schedule',
  'dashboard always has reminder_schedule key');
select is(public.get_dashboard('b6100000-0000-0000-0000-000000000001')->'reminder_schedule','null'::jsonb,
  'reminder_schedule is null before the owner sets one');

select lives_ok($$select public.set_group_reminder_schedule('b6100000-0000-0000-0000-000000000001',true,30,false,15,true,'21:30','  لا تنسوا ورد اليوم  ')$$,
  'owner can set the group schedule');
select is((select count(*)::int from public.group_reminder_schedules where group_id='b6100000-0000-0000-0000-000000000001'),1,
  'one schedule row per group');
select is((select fajr_offset_min::int from public.group_reminder_schedules where group_id='b6100000-0000-0000-0000-000000000001'),30,
  'fajr offset stored');
select is((select asr_on from public.group_reminder_schedules where group_id='b6100000-0000-0000-0000-000000000001'),false,
  'asr toggle stored');
select is((select night_time from public.group_reminder_schedules where group_id='b6100000-0000-0000-0000-000000000001'),'21:30'::time,
  'night time stored');
select is((select message from public.group_reminder_schedules where group_id='b6100000-0000-0000-0000-000000000001'),'لا تنسوا ورد اليوم',
  'message stored trimmed');
select is((select updated_by from public.group_reminder_schedules where group_id='b6100000-0000-0000-0000-000000000001'),'b6000000-0000-0000-0000-000000000001'::uuid,
  'updated_by records the owner');
select is(public.set_group_reminder_schedule('b6100000-0000-0000-0000-000000000001',true,0,true,180,false,'05:00:00','')
    - 'updated_at',
  '{"group_id":"b6100000-0000-0000-0000-000000000001","fajr_on":true,"fajr_offset_min":0,"asr_on":true,"asr_offset_min":180,"night_on":false,"night_time":"05:00","message":null}'::jsonb,
  'second save upserts and returns the schedule shape (offset bounds 0 and 180 accepted, blank message -> null)');
select is((select count(*)::int from public.group_reminder_schedules where group_id='b6100000-0000-0000-0000-000000000001'),1,
  'second save keeps a single row');

-- Validation
select throws_ok($$select public.set_group_reminder_schedule('b6100000-0000-0000-0000-000000000001',true,-1,true,20,true,'22:30',null)$$,
  'P0001','validation_failed','negative fajr offset rejected');
select throws_ok($$select public.set_group_reminder_schedule('b6100000-0000-0000-0000-000000000001',true,20,true,181,true,'22:30',null)$$,
  'P0001','validation_failed','asr offset above 180 rejected');
select throws_ok($$select public.set_group_reminder_schedule('b6100000-0000-0000-0000-000000000001',true,null,true,20,true,'22:30',null)$$,
  'P0001','validation_failed','null offset rejected');
select throws_ok($$select public.set_group_reminder_schedule('b6100000-0000-0000-0000-000000000001',null,20,true,20,true,'22:30',null)$$,
  'P0001','validation_failed','null toggle rejected');
select throws_ok($$select public.set_group_reminder_schedule('b6100000-0000-0000-0000-000000000001',true,20,true,20,true,'25:00',null)$$,
  'P0001','validation_failed','out-of-range night time rejected');
select throws_ok($$select public.set_group_reminder_schedule('b6100000-0000-0000-0000-000000000001',true,20,true,20,true,'ليلا',null)$$,
  'P0001','validation_failed','non-time night value rejected');
select throws_ok($$select public.set_group_reminder_schedule('b6100000-0000-0000-0000-000000000001',true,20,true,20,true,null,null)$$,
  'P0001','validation_failed','null night time rejected');
select throws_ok(format('select public.set_group_reminder_schedule(%L::uuid,true,20,true,20,true,%L,%L)',
    'b6100000-0000-0000-0000-000000000001','22:30',repeat('ذ',81)),
  'P0001','validation_failed','81-char message rejected');
select lives_ok(format('select public.set_group_reminder_schedule(%L::uuid,true,20,true,20,true,%L,%L)',
    'b6100000-0000-0000-0000-000000000001','21:30',repeat('ذ',80)),
  '80-char message accepted');
select throws_ok($$select public.set_group_reminder_schedule('b6100000-0000-0000-0000-0000000000ff',true,20,true,20,true,'22:30',null)$$,
  'P0001','group_not_found','unknown group rejected');

-- Members read via dashboard
select set_config('request.jwt.claims',json_build_object('sub','b6000000-0000-0000-0000-000000000002','role','authenticated')::text,true);
select is(public.get_dashboard('b6100000-0000-0000-0000-000000000001')->'reminder_schedule'->>'night_time','21:30',
  'member dashboard shows the owner night time as HH:MM');
select is(public.get_dashboard('b6100000-0000-0000-0000-000000000001')->'reminder_schedule'->>'fajr_offset_min','20',
  'member dashboard shows the fajr offset');
select is(char_length(public.get_dashboard('b6100000-0000-0000-0000-000000000001')->'reminder_schedule'->>'message'),80,
  'member dashboard shows the group message');

-- Only the owner may write
select throws_ok($$select public.set_group_reminder_schedule('b6100000-0000-0000-0000-000000000001',true,20,true,20,true,'22:30',null)$$,
  'P0001','forbidden','member cannot set the schedule');
select set_config('request.jwt.claims',json_build_object('sub','b6000000-0000-0000-0000-000000000004','role','authenticated')::text,true);
select throws_ok($$select public.set_group_reminder_schedule('b6100000-0000-0000-0000-000000000001',true,20,true,20,true,'22:30',null)$$,
  'P0001','forbidden','supervisor cannot set the schedule');
select set_config('request.jwt.claims',json_build_object('sub','b6000000-0000-0000-0000-000000000003','role','authenticated')::text,true);
select throws_ok($$select public.set_group_reminder_schedule('b6100000-0000-0000-0000-000000000001',true,20,true,20,true,'22:30',null)$$,
  'P0001','forbidden','outsider cannot set the schedule');

-- RLS: members read rows, outsiders see none, nobody writes directly
set role authenticated;
select set_config('request.jwt.claims',json_build_object('sub','b6000000-0000-0000-0000-000000000002','role','authenticated')::text,true);
select is((select count(*)::int from public.group_reminder_schedules where group_id='b6100000-0000-0000-0000-000000000001'),1,
  'member reads the group schedule row');
select throws_ok($$update public.group_reminder_schedules set night_time='20:00' where group_id='b6100000-0000-0000-0000-000000000001'$$,
  '42501',null,'member cannot update the table directly');
select set_config('request.jwt.claims',json_build_object('sub','b6000000-0000-0000-0000-000000000001','role','authenticated')::text,true);
select throws_ok($$delete from public.group_reminder_schedules where group_id='b6100000-0000-0000-0000-000000000001'$$,
  '42501',null,'owner cannot bypass the RPC with direct writes');
select set_config('request.jwt.claims',json_build_object('sub','b6000000-0000-0000-0000-000000000003','role','authenticated')::text,true);
select is((select count(*)::int from public.group_reminder_schedules where group_id='b6100000-0000-0000-0000-000000000001'),0,
  'outsider cannot read the group schedule row');
select throws_ok($$insert into public.group_reminder_schedules(group_id) values('b6100000-0000-0000-0000-000000000001')$$,
  '42501',null,'outsider cannot insert directly');
select throws_ok($$select public.get_dashboard('b6100000-0000-0000-0000-000000000001')$$,
  'P0001','not_member','outsider cannot read the dashboard');
reset role;

select * from finish();
rollback;
