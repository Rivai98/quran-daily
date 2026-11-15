-- Spec 008 (T002): admin overview, list/search, group actions, suspension
-- cleanup, account-delete preparation, admin role, audit rows, and the
-- self / last-admin protections. The hosted DB holds real data, so overview
-- numbers are asserted as deltas and lists are scoped to B8FIX fixtures.
create extension if not exists pgtap with schema extensions;
\i helpers/seed_members.sql
begin;
select plan(65);

-- ids: 01 admin A, 06 admin B, 02 owner, 03 member, 04 supervisor,
-- 05 suspend target (owns an empty group), 07 join applicant.
select tests_seed_user('b8000000-0000-0000-0000-000000000001','b8fix-admin@example.test','B8FIX Admin A');
insert into private.app_admins (user_id) values ('b8000000-0000-0000-0000-000000000001');
select set_config('request.jwt.claim.sub','b8000000-0000-0000-0000-000000000001',true);
create temp table b8_ov0 as select public.admin_overview() as j;

select tests_seed_user('b8000000-0000-0000-0000-000000000002','b8fix-owner@example.test','B8FIX Owner');
select tests_seed_user('b8000000-0000-0000-0000-000000000003','b8fix-member@example.test','B8FIX Member');
select tests_seed_user('b8000000-0000-0000-0000-000000000004','b8fix-supervisor@example.test','B8FIX Supervisor');
select tests_seed_user('b8000000-0000-0000-0000-000000000005','b8fix-target@example.test','B8FIX Target');
select tests_seed_user('b8000000-0000-0000-0000-000000000006','b8fix-admin-b@example.test','B8FIX Admin B');
select tests_seed_user('b8000000-0000-0000-0000-000000000007','b8fix-applicant@example.test','B8FIX Applicant');
-- G1 active with today's day; G2 forming (delete target); G3 owned by 05 alone.
select tests_seed_group('b8000000-0000-0000-0000-000000000010','B8FIX Fajr Circle','b8000000-0000-0000-0000-000000000002','Africa/Cairo','Q8AB2345');
select tests_seed_group('b8000000-0000-0000-0000-000000000020','B8FIX Delete Me','b8000000-0000-0000-0000-000000000002','Africa/Cairo','Q8CD2345');
select tests_seed_group('b8000000-0000-0000-0000-000000000030','B8FIX Lonely Owner','b8000000-0000-0000-0000-000000000005','Africa/Cairo','Q8EF2345');
select tests_seed_member('b8000000-0000-0000-0000-000000000010','b8000000-0000-0000-0000-000000000002',1::smallint,'owner'::public.group_role);
select tests_seed_member('b8000000-0000-0000-0000-000000000010','b8000000-0000-0000-0000-000000000004',2::smallint,'supervisor'::public.group_role);
select tests_seed_member('b8000000-0000-0000-0000-000000000010','b8000000-0000-0000-0000-000000000003',3::smallint);
select tests_seed_member('b8000000-0000-0000-0000-000000000010','b8000000-0000-0000-0000-000000000005',4::smallint);
select tests_seed_member('b8000000-0000-0000-0000-000000000020','b8000000-0000-0000-0000-000000000002',1::smallint,'owner'::public.group_role);
select tests_seed_member('b8000000-0000-0000-0000-000000000030','b8000000-0000-0000-0000-000000000005',1::smallint,'owner'::public.group_role);
insert into public.join_requests(group_id,user_id,source) values
 ('b8000000-0000-0000-0000-000000000010','b8000000-0000-0000-0000-000000000007','invite');
update public.groups set status='active',start_juz=1,start_date=public.group_local_date(id,now())
 where id='b8000000-0000-0000-0000-000000000010';
insert into public.group_days(group_id,group_date,day_index,opens_at,ends_at,closes_at,state,full_khatma)
 select id,public.group_local_date(id,now()),0,now()-interval '1 hour',now()+interval '23 hours',now()+interval '47 hours','open',true
 from public.groups where id='b8000000-0000-0000-0000-000000000010';
insert into public.assignments(group_day_id,juz,seat_number,kind,reader_membership_id,status,completed_at)
 select d.id,s,s,case when m.id is null then 'unassigned'::public.assignment_kind else 'seat'::public.assignment_kind end,
   m.id,case when s=3 then 'completed'::public.assignment_status when m.id is null then 'available'::public.assignment_status else 'pending'::public.assignment_status end,
   case when s=3 then now() else null end
 from public.group_days d cross join generate_series(1,30) s
 left join public.group_memberships m on m.group_id=d.group_id and m.seat_number=s and m.status='active'
 where d.group_id='b8000000-0000-0000-0000-000000000010';
insert into public.completion_records(assignment_id,actor_user_id,action,client_recorded_at)
 select a.id,'b8000000-0000-0000-0000-000000000003','completed',now()
 from public.assignments a join public.group_days d on d.id=a.group_day_id
 where d.group_id='b8000000-0000-0000-0000-000000000010' and a.seat_number=3;

-- ---------------------------------------------------------------- overview
create temp table b8_ov1 as select public.admin_overview() as j;
select is((select (b.j#>>'{users,total}')::int-(a.j#>>'{users,total}')::int from b8_ov0 a,b8_ov1 b),6,'overview: total users grows by the six fixtures');
select is((select (b.j#>>'{users,new_7d}')::int-(a.j#>>'{users,new_7d}')::int from b8_ov0 a,b8_ov1 b),6,'overview: new users (7 days)');
select is((select (b.j#>>'{users,new_30d}')::int-(a.j#>>'{users,new_30d}')::int from b8_ov0 a,b8_ov1 b),6,'overview: new users (30 days)');
select is((select (b.j#>>'{users,active_today}')::int-(a.j#>>'{users,active_today}')::int from b8_ov0 a,b8_ov1 b),1,'overview: one fixture user was active today');
select is((select (b.j#>>'{groups,total}')::int-(a.j#>>'{groups,total}')::int from b8_ov0 a,b8_ov1 b),3,'overview: three fixture groups');
select is((select (b.j#>>'{groups,active}')::int-(a.j#>>'{groups,active}')::int from b8_ov0 a,b8_ov1 b),1,'overview: one active fixture group');
select is((select (b.j#>>'{groups,forming}')::int-(a.j#>>'{groups,forming}')::int from b8_ov0 a,b8_ov1 b),2,'overview: two forming fixture groups');
select is((select (b.j#>>'{today,total}')::int-(a.j#>>'{today,total}')::int from b8_ov0 a,b8_ov1 b),30,'overview: today counts the 30 fixture portions');
select is((select (b.j#>>'{today,done}')::int-(a.j#>>'{today,done}')::int from b8_ov0 a,b8_ov1 b),1,'overview: today counts one done portion');
select is((select (b.j#>>'{khatmas,last_7d}')::int-(a.j#>>'{khatmas,last_7d}')::int from b8_ov0 a,b8_ov1 b),1,'overview: khatmas (7 days)');
select is((select (b.j#>>'{khatmas,last_30d}')::int-(a.j#>>'{khatmas,last_30d}')::int from b8_ov0 a,b8_ov1 b),1,'overview: khatmas (30 days)');
select is((select jsonb_array_length(j->'series') from b8_ov1),30,'overview: 30-day series');
select is((select j->'series'->29->>'date' from b8_ov1),(now() at time zone 'utc')::date::text,'overview: series ends today (UTC)');
select is((select (b.j->'series'->29->>'completed')::int-(a.j->'series'->29->>'completed')::int from b8_ov0 a,b8_ov1 b),1,'overview: series counts today''s completion');

-- ------------------------------------------------------------ list/search
select is((public.admin_list_groups('b8fix',null,50,0)->>'total')::int,3,'groups: search by name is case-insensitive');
select is((public.admin_list_groups('b8fix','forming',50,0)->>'total')::int,2,'groups: status filter');
select is((public.admin_list_groups('Q8AB2345',null,50,0)->'items'->0->>'id'),'b8000000-0000-0000-0000-000000000010','groups: search by invite code');
select is((public.admin_list_groups('B8FIX Fajr',null,50,0)->'items'->0->>'member_count')::int,4,'groups: member count');
select is((public.admin_list_groups('B8FIX Fajr',null,50,0)->'items'->0->>'owner_name'),'B8FIX Owner','groups: owner name');
select is(jsonb_array_length(public.admin_list_groups('b8fix',null,2,0)->'items'),2,'groups: limit pages results');
select throws_ok($$select public.admin_list_groups(null,'bogus',10,0)$$,'P0001','validation_failed','groups: unknown status refused');
select is(jsonb_array_length(public.admin_group_detail('b8000000-0000-0000-0000-000000000010')->'members'),4,'group detail: active members');
select is((public.admin_group_detail('b8000000-0000-0000-0000-000000000010')#>>'{today,done}')::int,1,'group detail: today progress');
select throws_ok($$select public.admin_group_detail('b8000000-0000-0000-0000-0000000000ff')$$,'P0001','group_not_found','group detail: unknown group');
select is((public.admin_list_users('b8fix',null,50,0)->>'total')::int,7,'users: search by name/email');
select is((public.admin_list_users('b8fix-member@',null,50,0)->'items'->0->>'email'),'b8fix-member@example.test','users: email visible to admins');
select is((public.admin_list_users('b8fix','admin',50,0)->>'total')::int,1,'users: admin filter');
select is((public.admin_list_users('B8FIX Owner',null,50,0)->'items'->0->>'groups_count')::int,2,'users: groups count');
select is(jsonb_array_length(public.admin_user_detail('b8000000-0000-0000-0000-000000000005')->'groups'),2,'user detail: groups');
select throws_ok($$select public.admin_user_detail('b8000000-0000-0000-0000-0000000000ff')$$,'P0001','user_not_found','user detail: unknown user');

-- ---------------------------------------------------------- group actions
select ok((public.admin_regenerate_invite('b8000000-0000-0000-0000-000000000010')->>'invite_code') ~ '^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{8}$','regenerate invite returns a valid new code');
select ok((select invite_code from public.groups where id='b8000000-0000-0000-0000-000000000010') <> 'Q8AB2345','regenerate invite replaces the code');
select throws_ok($$select public.admin_remove_member('b8000000-0000-0000-0000-000000000010',(select id from public.group_memberships where user_id='b8000000-0000-0000-0000-000000000002' and group_id='b8000000-0000-0000-0000-000000000010' and status='active'))$$,'P0001','owner_must_transfer','remove member: the owner cannot be removed');
select is((public.admin_remove_member('b8000000-0000-0000-0000-000000000010',(select id from public.group_memberships where user_id='b8000000-0000-0000-0000-000000000004' and status='active'))->>'removed'),'true','remove member: admin removes the supervisor');
select is((select status::text||':'||(seat_number is null)::text from public.group_memberships where user_id='b8000000-0000-0000-0000-000000000004'),'removed:true','remove member: seat freed');
select is((select a.status::text||':'||a.kind::text from public.assignments a join public.group_days d on d.id=a.group_day_id where d.group_id='b8000000-0000-0000-0000-000000000010' and a.seat_number=2),'available:unassigned','remove member: today''s portion released (spec 001 rules)');
select is((public.admin_transfer_ownership('b8000000-0000-0000-0000-000000000010',(select id from public.group_memberships where user_id='b8000000-0000-0000-0000-000000000003' and status='active'))->>'owner_user_id'),'b8000000-0000-0000-0000-000000000003','transfer ownership: new owner returned');
select is((select owner_id::text||':'||(select role::text from public.group_memberships where user_id='b8000000-0000-0000-0000-000000000002' and group_id=g.id and status='active') from public.groups g where id='b8000000-0000-0000-0000-000000000010'),'b8000000-0000-0000-0000-000000000003:member','transfer ownership: owner moved, old owner demoted');
select is((public.admin_archive_group('b8000000-0000-0000-0000-000000000010')->>'status'),'archived','archive group');
select is((select status::text from public.join_requests where user_id='b8000000-0000-0000-0000-000000000007'),'rejected','archive rejects pending join requests');
select throws_ok($$select public.admin_archive_group('b8000000-0000-0000-0000-000000000010')$$,'P0001','invalid_state','archive twice is refused');
select is((public.admin_restore_group('b8000000-0000-0000-0000-000000000010')->>'status'),'active','restore a started group to active');
select throws_ok($$select public.admin_delete_group('b8000000-0000-0000-0000-000000000020','wrong name')$$,'P0001','confirmation_mismatch','delete group needs the exact name');
select is((public.admin_delete_group('b8000000-0000-0000-0000-000000000020',' B8FIX Delete Me ')->>'deleted'),'true','delete group');
select is((select count(*)::int from public.groups g where g.id='b8000000-0000-0000-0000-000000000020')
  +(select count(*)::int from public.group_memberships where group_id='b8000000-0000-0000-0000-000000000020'),0,'delete group removes the group and memberships');

-- ------------------------------------------------- suspension cleanup flow
select throws_ok($$select public.admin_suspend_cleanup('b8000000-0000-0000-0000-000000000001')$$,'P0001','cannot_target_self','an admin cannot suspend themselves');
insert into private.app_admins (user_id) values ('b8000000-0000-0000-0000-000000000006');
select throws_ok($$select public.admin_suspend_cleanup('b8000000-0000-0000-0000-000000000006')$$,'P0001','target_is_admin','an admin account must lose admin before suspension');
select is((public.admin_suspend_cleanup('b8000000-0000-0000-0000-000000000005')->>'memberships_ended')::int,1,'suspend cleanup ends active memberships');
select ok((select suspended_at is not null from public.profiles where id='b8000000-0000-0000-0000-000000000005'),'suspend cleanup marks the profile suspended');
select is((select count(*)::int from public.group_memberships where user_id='b8000000-0000-0000-0000-000000000005' and group_id='b8000000-0000-0000-0000-000000000010' and status='active'),0,'suspended user left the active group');
select is((select status::text from public.groups where id='b8000000-0000-0000-0000-000000000030'),'archived','suspended owner''s empty group is archived');
select is((public.admin_list_users('b8fix-target',null,50,0)->'items'->0->>'status'),'suspended','users: status shows suspended');
select is((public.admin_clear_suspension('b8000000-0000-0000-0000-000000000005')->>'suspended'),'false','clear suspension');

-- ----------------------------------------------- account delete preparation
select throws_ok($$select public.admin_prepare_user_delete('b8000000-0000-0000-0000-000000000001')$$,'P0001','cannot_target_self','an admin cannot delete themselves');
select is((public.admin_prepare_user_delete('b8000000-0000-0000-0000-000000000003')->>'groups_transferred')::int,1,'delete prep transfers owned groups to the most senior member');
select is((select owner_id::text from public.groups where id='b8000000-0000-0000-0000-000000000010'),'b8000000-0000-0000-0000-000000000002','most senior remaining member became owner');
select lives_ok($$delete from auth.users where id='b8000000-0000-0000-0000-000000000003'$$,'prepared account can be deleted');
select is((select a.status::text||':'||(a.reader_membership_id is null)::text from public.assignments a join public.group_days d on d.id=a.group_day_id where d.group_id='b8000000-0000-0000-0000-000000000010' and a.seat_number=3),'completed:true','history keeps the completion but loses the name');
select is((select completed_count::int from public.group_days where group_id='b8000000-0000-0000-0000-000000000010'),0,'day counters are untouched by deletion');

-- ------------------------------------------------------------- admin role
select is((public.admin_set_admin('b8000000-0000-0000-0000-000000000005',true)->>'is_admin'),'true','grant admin');
select is((public.admin_set_admin('b8000000-0000-0000-0000-000000000005',false)->>'is_admin'),'false','revoke admin');
delete from private.app_admins where user_id <> 'b8000000-0000-0000-0000-000000000001';
select throws_ok($$select public.admin_set_admin('b8000000-0000-0000-0000-000000000001',false)$$,'P0001','last_admin','the last admin cannot revoke themselves');

-- ------------------------------------------------------------------ audit
select is((select count(*)::int from private.admin_audit where actor_user_id='b8000000-0000-0000-0000-000000000001'
  and action in ('regenerate_invite','remove_member','transfer_ownership','archive_group','restore_group',
  'delete_group','suspend_cleanup','clear_suspension','prepare_user_delete','grant_admin','revoke_admin')),11,
  'one audit row per successful admin action');
select is((public.admin_list_audit('delete_group',50,0)->'items'->0->>'target_label'),'B8FIX Delete Me','audit keeps the deleted group''s name');
select is((public.admin_list_audit('remove_member',50,0)->'items'->0->>'actor_name'),'B8FIX Admin A','audit list shows who acted');

select * from finish();
rollback;
