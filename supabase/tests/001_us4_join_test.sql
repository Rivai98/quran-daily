create extension if not exists pgtap with schema extensions;
\i helpers/seed_members.sql
begin;
select plan(29);

select tests_seed_user('d4000000-0000-0000-0000-000000000001', 'us4-a@test.local', 'عضو ألف');
select tests_seed_user('d4000000-0000-0000-0000-000000000002', 'us4-b@test.local', 'عضو باء');
select tests_seed_user('d4000000-0000-0000-0000-000000000003', 'us4-c@test.local', 'عضو جيم');
select tests_seed_user('d4000000-0000-0000-0000-000000000004', 'us4-d@test.local', 'عضو دال');

insert into public.groups (id,name,owner_id,timezone,visibility,join_mode,status,start_juz,start_date,invite_code)
values
 ('d4000000-0000-0000-0000-000000000101','عام آلي','d4000000-0000-0000-0000-000000000001','Africa/Cairo','public','auto_accept','forming',null,null,'US4A2345'),
 ('d4000000-0000-0000-0000-000000000102','عام بطلب','d4000000-0000-0000-0000-000000000001','Asia/Riyadh','public','approval','forming',null,null,'US4B2345'),
 ('d4000000-0000-0000-0000-000000000103','خاص','d4000000-0000-0000-0000-000000000001','Africa/Cairo','private','auto_accept','forming',null,null,'US4C2345'),
 ('d4000000-0000-0000-0000-000000000104','مكتملة','d4000000-0000-0000-0000-000000000001','Africa/Cairo','public','auto_accept','forming',null,null,'US4D2345'),
 ('d4000000-0000-0000-0000-000000000105','نشطة','d4000000-0000-0000-0000-000000000001','Asia/Riyadh','public','auto_accept','active',1,current_date,'US4E2345'),
 ('d4000000-0000-0000-0000-000000000106','مؤرشفة','d4000000-0000-0000-0000-000000000001','Africa/Cairo','private','auto_accept','archived',null,null,'US4F2345');

-- Isolate join-any from pre-existing hosted DEV groups. The test transaction
-- rolls this temporary visibility change back after assertions finish.
update public.groups set visibility='private'
where visibility='public' and id not in (
  'd4000000-0000-0000-0000-000000000101',
  'd4000000-0000-0000-0000-000000000102',
  'd4000000-0000-0000-0000-000000000104',
  'd4000000-0000-0000-0000-000000000105'
);

insert into public.group_memberships (group_id,user_id,role,status,seat_number)
select g.id, 'd4000000-0000-0000-0000-000000000001', 'owner','active',1
from public.groups g where g.id in (
  'd4000000-0000-0000-0000-000000000101',
  'd4000000-0000-0000-0000-000000000102',
  'd4000000-0000-0000-0000-000000000103',
  'd4000000-0000-0000-0000-000000000105',
  'd4000000-0000-0000-0000-000000000106'
);
do $$
declare n integer;
begin
  for n in 1..30 loop
    perform tests_seed_user(('d4000000-0000-0000-0000-' || lpad((200+n)::text,12,'0'))::uuid, 'us4-full-' || n || '@test.local', 'عضو ممتلئ');
  end loop;
end
$$;
insert into public.group_memberships (group_id,user_id,role,status,seat_number)
select 'd4000000-0000-0000-0000-000000000104',
       ('d4000000-0000-0000-0000-' || lpad((200+n)::text,12,'0'))::uuid, 'member','active',n
from generate_series(1,30) n;
insert into public.group_days (id,group_id,group_date,day_index,opens_at,ends_at,closes_at,state)
values ('d4000000-0000-0000-0000-000000000201','d4000000-0000-0000-0000-000000000105',current_date,0,now()-interval '1 hour',now()+interval '1 day',now()+interval '2 days','open');
insert into public.assignments (group_day_id,juz,seat_number,kind,reader_membership_id,status)
select 'd4000000-0000-0000-0000-000000000201',s,s,
       case when s=1 then 'seat'::public.assignment_kind when s=3 then 'volunteer'::public.assignment_kind else 'unassigned'::public.assignment_kind end,
       case when s in (1,3) then (select id from public.group_memberships where group_id='d4000000-0000-0000-0000-000000000105' and seat_number=1 and status='active') else null end,
       case when s=1 then 'pending'::public.assignment_status when s=3 then 'pending'::public.assignment_status else 'available'::public.assignment_status end
from generate_series(1,30) s;

select set_config('request.jwt.claims',json_build_object('sub','d4000000-0000-0000-0000-000000000002','role','authenticated')::text,true);

select is((select count(*) from public.search_public_groups(null,true,20,0)),3::bigint,'discovery lists public groups needing seats');
select is((select count(*) from public.search_public_groups(null,false,20,0)),4::bigint,'discovery may include full public groups');
select is((select r.value->>'group_id' from public.search_public_groups(null,false,20,0) with ordinality as r(value,ord) where r.ord=1),'d4000000-0000-0000-0000-000000000104','discovery sorts groups closest to full first');
select is((select public.get_invite_preview('US4C2345')->>'group_id'),'d4000000-0000-0000-0000-000000000103','invite preview supports private groups');
select is((select count(*) from jsonb_object_keys(public.get_invite_preview('US4A2345'))),10::bigint,'invite preview adds portion unit to profile and own request fields');
select ok((select not (r.value ? 'members') and not (r.value ? 'progress') from public.search_public_groups(null,true,20,0) with ordinality as r(value,ord) where r.ord=1),'public discovery exposes no member list or progress');
select is(public.get_invite_preview('US4F2345')->>'status','archived','archived invite preview explains the unavailable group');
select throws_ok('select public.get_invite_preview(''BADCODE1'')','P0001','invite_invalid','invalid invite code rejected');
select throws_ok('select public.join_group(''d4000000-0000-0000-0000-000000000103'',null,''discovery'')','P0001','group_not_public','private group cannot be joined through discovery');
select throws_ok('select public.join_group(null,''US4F2345'',''invite'')','P0001','group_archived','archived invite cannot be joined');
select throws_ok('select public.join_group(gen_random_uuid(),null,''discovery'')','P0001','group_not_found','unknown group identifier reports not found');

select is((public.join_group('d4000000-0000-0000-0000-000000000101',null,'discovery')->>'seat_number')::smallint,2::smallint,'auto-accept assigns the lowest empty seat');
select is(public.join_group(null,'US4C2345','invite')->>'result','joined','private group can be joined using its invite code');
select is(public.join_group(null,'US4B2345','invite')->>'result','pending','approval group invite creates pending request');
select ok((public.get_my_groups()->'pending_requests') @> jsonb_build_array(jsonb_build_object('group_id','d4000000-0000-0000-0000-000000000102')),'my groups lists pending join request');
select ok(public.get_invite_preview('US4B2345')->>'my_join_request_id' is not null,'invite preview identifies the caller pending request');
select throws_ok('select public.join_group(''d4000000-0000-0000-0000-000000000101'',null,''discovery'')','P0001','already_member','active member cannot join same group twice');
select lives_ok('select public.cancel_join_request((select id from public.join_requests where group_id=''d4000000-0000-0000-0000-000000000102'' and user_id=auth.uid() and status=''pending''))','requester may cancel own request');
select is((select count(*) from public.join_requests where group_id='d4000000-0000-0000-0000-000000000102' and user_id=auth.uid() and status='pending'),0::bigint,'cancelled request is no longer pending');
select throws_ok('select public.cancel_join_request(gen_random_uuid())','P0001','request_not_pending','unknown request cannot be cancelled');
update public.groups set join_mode='approval' where id='d4000000-0000-0000-0000-000000000104';
select throws_ok('select public.join_group(''d4000000-0000-0000-0000-000000000104'',null,''discovery'')','P0001','group_full','full approval group rejects a pending join request');

select is((public.join_group(null,'US4E2345','invite')->>'seat_number')::smallint,2::smallint,'mid-day join receives today''s lowest vacant seat');
select is((select kind::text || ':' || status::text from public.assignments where group_day_id='d4000000-0000-0000-0000-000000000201' and seat_number=2),'seat:pending','mid-day join takes over the available seat assignment');

select set_config('request.jwt.claims',json_build_object('sub','d4000000-0000-0000-0000-000000000003','role','authenticated')::text,true);
insert into public.group_memberships (group_id,user_id,role,status,seat_number,ended_at)
values ('d4000000-0000-0000-0000-000000000101',auth.uid(),'member','removed',null,now());
select is(public.join_group('d4000000-0000-0000-0000-000000000101',null,'discovery')->>'result','pending','removed user must request approval even for auto-accept group');
select is((public.join_group(null,'US4E2345','invite')->>'seat_number')::smallint,3::smallint,'joining active group allocates next seat');
select is((select reader_membership_id from public.assignments where group_day_id='d4000000-0000-0000-0000-000000000201' and seat_number=3),(select id from public.group_memberships where group_id='d4000000-0000-0000-0000-000000000105' and user_id='d4000000-0000-0000-0000-000000000001' and status='active'),'mid-day join does not take over a volunteered juz');

select set_config('request.jwt.claims',json_build_object('sub','d4000000-0000-0000-0000-000000000004','role','authenticated')::text,true);
select is((public.join_any_group('Asia/Riyadh')->>'group_id')::uuid,'d4000000-0000-0000-0000-000000000105'::uuid,'join-any prefers a timezone match');
select is((public.join_any_group('Africa/Cairo')->>'group_id')::uuid,'d4000000-0000-0000-0000-000000000101'::uuid,'join-any next chooses fewest empty seats then creation order');
select throws_ok('select public.join_any_group(''UTC'')','P0001','no_group_available','join-any reports no group after membership');

select * from finish();
rollback;
