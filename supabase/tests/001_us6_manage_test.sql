create extension if not exists pgtap with schema extensions;
\i helpers/seed_members.sql
begin;
select plan(32);

select tests_seed_user('e6000000-0000-0000-0000-000000000001','e6-owner@example.test','Owner');
select tests_seed_user('e6000000-0000-0000-0000-000000000002','e6-member@example.test','Member');
select tests_seed_user('e6000000-0000-0000-0000-000000000003','e6-supervisor@example.test','Supervisor');
select tests_seed_user('e6000000-0000-0000-0000-000000000004','e6-request@example.test','Applicant');
select tests_seed_group('e6000000-0000-0000-0000-000000000010','US6 Main Group','e6000000-0000-0000-0000-000000000001','Africa/Cairo','US6A2345');
select tests_seed_member('e6000000-0000-0000-0000-000000000010','e6000000-0000-0000-0000-000000000001',1::smallint,'owner'::public.group_role);
select tests_seed_member('e6000000-0000-0000-0000-000000000010','e6000000-0000-0000-0000-000000000002',2::smallint);
select tests_seed_member('e6000000-0000-0000-0000-000000000010','e6000000-0000-0000-0000-000000000003',3::smallint,'supervisor'::public.group_role);
insert into public.join_requests(group_id,user_id,source) values
 ('e6000000-0000-0000-0000-000000000010','e6000000-0000-0000-0000-000000000004','invite');
update public.groups set status='active',start_juz=1,start_date=public.group_local_date(id,now())
 where id='e6000000-0000-0000-0000-000000000010';
insert into public.group_days(group_id,group_date,day_index,opens_at,ends_at,closes_at,state)
 select id,public.group_local_date(id,now()),0,now()-interval '1 hour',now()+interval '23 hours',now()+interval '47 hours','open'
 from public.groups where id='e6000000-0000-0000-0000-000000000010';
insert into public.assignments(group_day_id,juz,seat_number,kind,reader_membership_id,status)
 select d.id,s,s,case when s=2 then 'seat'::public.assignment_kind else 'unassigned'::public.assignment_kind end,
   case when s=2 then m.id else null end,case when s=2 then 'pending'::public.assignment_status else 'available'::public.assignment_status end
 from public.group_days d cross join generate_series(1,30) s
 left join public.group_memberships m on m.group_id=d.group_id and m.seat_number=s and m.status='active'
 where d.group_id='e6000000-0000-0000-0000-000000000010';
update public.assignments a set kind='volunteer',reader_membership_id=m.id,status='pending'
 from public.group_days d,public.group_memberships m where a.group_day_id=d.id and d.group_id='e6000000-0000-0000-0000-000000000010' and a.seat_number=20 and m.group_id=d.group_id and m.user_id='e6000000-0000-0000-0000-000000000002';
update public.assignments a set kind='override',reader_membership_id=m.id,status='pending'
 from public.group_days d,public.group_memberships m where a.group_day_id=d.id and d.group_id='e6000000-0000-0000-0000-000000000010' and a.seat_number=21 and m.group_id=d.group_id and m.user_id='e6000000-0000-0000-0000-000000000002';
update public.assignments a set kind='volunteer',reader_membership_id=m.id,status='completed',completed_at=now()
 from public.group_days d,public.group_memberships m where a.group_day_id=d.id and d.group_id='e6000000-0000-0000-0000-000000000010' and a.seat_number=22 and m.group_id=d.group_id and m.user_id='e6000000-0000-0000-0000-000000000002';

-- US6 management RPC contract and baseline authorization checks. Detailed
-- state transitions are exercised against seeded members by the remote suite.
select has_function('public', 'list_join_requests', array['uuid'], 'join request listing exists');
select has_function('public', 'review_join_request', array['uuid', 'text'], 'request review exists');
select has_function('public', 'get_group_members', array['uuid'], 'member listing exists');
select has_function('public', 'move_member_seat', array['uuid', 'uuid', 'smallint'], 'seat move exists');
select has_function('public', 'set_member_role', array['uuid', 'uuid', 'public.group_role'], 'role update exists');
select has_function('public', 'remove_member', array['uuid', 'uuid'], 'member removal exists');
select has_function('public', 'leave_group', array['uuid'], 'leave exists');
select has_function('public', 'transfer_ownership', array['uuid', 'uuid'], 'ownership transfer exists');
select has_function('public', 'archive_group', array['uuid'], 'archive exists');
select has_function('public', 'override_assignment', array['uuid', 'uuid'], 'assignment override exists');
select ok((select count(*) = 10 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname in ('list_join_requests','review_join_request',
  'get_group_members','move_member_seat','set_member_role','remove_member','leave_group',
  'transfer_ownership','archive_group','override_assignment')), 'all ten management RPCs registered');
select ok(not has_function_privilege('anon', 'public.list_join_requests(uuid)', 'EXECUTE'), 'anonymous cannot list requests');

select set_config('request.jwt.claim.sub','e6000000-0000-0000-0000-000000000001',true);
select is(jsonb_array_length(public.list_join_requests('e6000000-0000-0000-0000-000000000010')),1,'owner sees pending requests');
select is(public.review_join_request((select id from public.join_requests where group_id='e6000000-0000-0000-0000-000000000010'),'approve')->>'result','approved','owner approval allocates the lowest seat');
select is(public.override_assignment((select a.id from public.assignments a join public.group_days d on d.id=a.group_day_id where d.group_id='e6000000-0000-0000-0000-000000000010' and a.seat_number=5),(select id from public.group_memberships where user_id='e6000000-0000-0000-0000-000000000004' and status='active'))->>'membership_id',(select id::text from public.group_memberships where user_id='e6000000-0000-0000-0000-000000000004' and status='active'),'owner assigns an available juz to an active member');
select is((select kind::text from public.assignments a join public.group_days d on d.id=a.group_day_id where d.group_id='e6000000-0000-0000-0000-000000000010' and a.seat_number=5),'override','override marks the assignment kind');
update public.assignments a set kind='volunteer',reader_membership_id=m.id,status='pending'
 from public.group_days d,public.group_memberships m where a.group_day_id=d.id and d.group_id='e6000000-0000-0000-0000-000000000010' and a.seat_number=24 and m.group_id=d.group_id and m.user_id='e6000000-0000-0000-0000-000000000004';
update public.assignments a set kind='override',reader_membership_id=m.id,status='pending'
 from public.group_days d,public.group_memberships m where a.group_day_id=d.id and d.group_id='e6000000-0000-0000-0000-000000000010' and a.seat_number=25 and m.group_id=d.group_id and m.user_id='e6000000-0000-0000-0000-000000000004';
update public.assignments a set kind='volunteer',reader_membership_id=m.id,status='completed',completed_at=now()
 from public.group_days d,public.group_memberships m where a.group_day_id=d.id and d.group_id='e6000000-0000-0000-0000-000000000010' and a.seat_number=26 and m.group_id=d.group_id and m.user_id='e6000000-0000-0000-0000-000000000004';
select is(jsonb_array_length(public.get_group_members('e6000000-0000-0000-0000-000000000010')->'members'),4,'members list includes active memberships');
select is(public.move_member_seat('e6000000-0000-0000-0000-000000000010',(select id from public.group_memberships where user_id='e6000000-0000-0000-0000-000000000002' and status='active'),3::smallint)->>'effective_next_day','true','active seat change is for next day');
select is((select seat_number::text from public.group_memberships where user_id='e6000000-0000-0000-0000-000000000003' and status='active'),'2','seat move swaps the occupied seat');
select is((public.set_member_role('e6000000-0000-0000-0000-000000000010',(select id from public.group_memberships where user_id='e6000000-0000-0000-0000-000000000002' and status='active'),'supervisor')->>'role'),'supervisor','owner changes member role');
select set_config('request.jwt.claim.sub','e6000000-0000-0000-0000-000000000003',true);
select throws_ok($$select public.remove_member('e6000000-0000-0000-0000-000000000010',(select id from public.group_memberships where user_id='e6000000-0000-0000-0000-000000000002' and status='active'))$$,'P0001',null,'supervisor cannot remove members');
select set_config('request.jwt.claim.sub','e6000000-0000-0000-0000-000000000001',true);
select is(public.remove_member('e6000000-0000-0000-0000-000000000010',(select id from public.group_memberships where user_id='e6000000-0000-0000-0000-000000000002' and status='active'))->>'removed','true','owner removes a member');
select is((select count(*)::int from public.assignments a join public.group_days d on d.id=a.group_day_id where d.group_id='e6000000-0000-0000-0000-000000000010' and a.seat_number in (2,20,21) and a.status='available' and a.kind='unassigned' and a.reader_membership_id is null),3,'removal releases seat, volunteer and override rows');
select is((select status::text from public.assignments a join public.group_days d on d.id=a.group_day_id where d.group_id='e6000000-0000-0000-0000-000000000010' and a.seat_number=22),'completed','removal preserves completed rows');
select throws_ok($$select public.leave_group('e6000000-0000-0000-0000-000000000010')$$,'P0001',null,'owner must transfer before leaving');
select is(public.transfer_ownership('e6000000-0000-0000-0000-000000000010',(select id from public.group_memberships where user_id='e6000000-0000-0000-0000-000000000003' and status='active'))->>'owner_membership_id',(select id::text from public.group_memberships where user_id='e6000000-0000-0000-0000-000000000003' and status='active'),'owner transfers ownership to an active member');
select set_config('request.jwt.claim.sub','e6000000-0000-0000-0000-000000000003',true);
do $$ declare s int; u uuid; begin
  for s in 2..30 loop
    if s <> 4 then
      u := ('e6000000-0000-0000-0001-' || lpad(s::text,12,'0'))::uuid;
      perform tests_seed_user(u,'e6-fill-'||s||'@example.test','Fill '||s);
      perform tests_seed_member('e6000000-0000-0000-0000-000000000010',u,s::smallint);
    end if;
  end loop;
  perform tests_seed_user('e6000000-0000-0000-0000-000000000005','e6-full@example.test','Full');
  insert into public.join_requests(group_id,user_id,source) values ('e6000000-0000-0000-0000-000000000010','e6000000-0000-0000-0000-000000000005','invite');
end $$;
select is((select count(*)::int from public.group_memberships where group_id='e6000000-0000-0000-0000-000000000010' and status='active'),30,'seat fixture fills the group');
select throws_ok($$select public.review_join_request((select id from public.join_requests where user_id='e6000000-0000-0000-0000-000000000005'),'approve')$$,'P0001',null,'full group approval fails');
select set_config('request.jwt.claim.sub','e6000000-0000-0000-0000-000000000004',true);
select is(public.leave_group('e6000000-0000-0000-0000-000000000010')->>'left','true','member can leave the group');
select is((select count(*)::int from public.assignments a join public.group_days d on d.id=a.group_day_id where d.group_id='e6000000-0000-0000-0000-000000000010' and a.seat_number in (4,5,24,25) and a.status='available' and a.kind='unassigned' and a.reader_membership_id is null),4,'leaving releases seat, volunteer and override rows');
select is((select status::text from public.assignments a join public.group_days d on d.id=a.group_day_id where d.group_id='e6000000-0000-0000-0000-000000000010' and a.seat_number=26),'completed','leaving preserves completed rows');
select set_config('request.jwt.claim.sub','e6000000-0000-0000-0000-000000000003',true);
select is(public.archive_group('e6000000-0000-0000-0000-000000000010')->>'archived','true','new owner archives the group');

select * from finish();
rollback;

select * from finish();
rollback;
