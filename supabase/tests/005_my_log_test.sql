create extension if not exists pgtap with schema extensions;
\i helpers/seed_members.sql
begin;
select plan(11);
select tests_seed_user('a5000000-0000-0000-0000-000000000051','p5-log@test.local','P5 log');
select tests_seed_user('a5000000-0000-0000-0000-000000000054','p5-log-other@test.local','P5 other');
select tests_seed_group('a5000000-0000-0000-0000-000000000052','P5 log group','a5000000-0000-0000-0000-000000000051','Africa/Cairo','P5ABCDF3');
select tests_seed_group('a5000000-0000-0000-0000-000000000053','P5 other group','a5000000-0000-0000-0000-000000000054','Africa/Cairo','P5ABCDF4');
select tests_seed_member('a5000000-0000-0000-0000-000000000052'::uuid,'a5000000-0000-0000-0000-000000000051'::uuid,1::smallint,'owner'::public.group_role);
select tests_seed_member('a5000000-0000-0000-0000-000000000053'::uuid,'a5000000-0000-0000-0000-000000000051'::uuid,1::smallint);
select tests_seed_member('a5000000-0000-0000-0000-000000000052'::uuid,'a5000000-0000-0000-0000-000000000054'::uuid,2::smallint);
insert into public.group_days(id,group_id,group_date,day_index,opens_at,ends_at,closes_at,state)
values ('a5000000-0000-0000-0000-000000000061','a5000000-0000-0000-0000-000000000052',current_date-3,0,now()-interval '5 days',now()-interval '4 days',now()-interval '3 days','closed'),
       ('a5000000-0000-0000-0000-000000000062','a5000000-0000-0000-0000-000000000052',current_date-2,1,now()-interval '4 days',now()-interval '3 days',now()-interval '2 days','closed'),
       ('a5000000-0000-0000-0000-000000000063','a5000000-0000-0000-0000-000000000052',current_date-1,2,now()-interval '3 days',now()-interval '2 days',now()-interval '1 day','closed');
insert into public.group_days(id,group_id,group_date,day_index,opens_at,ends_at,closes_at,state)
values ('a5000000-0000-0000-0000-000000000064','a5000000-0000-0000-0000-000000000052',current_date-4,3,now()-interval '6 days',now()-interval '5 days',now()-interval '4 days','closed');
insert into public.assignments(group_day_id,juz,seat_number,kind,reader_membership_id,status,completed_at)
select d.id, 1, 1, 'seat', m.id, case when d.group_date=current_date-2 then 'missed'::public.assignment_status else 'late'::public.assignment_status end, now()
from public.group_days d join public.group_memberships m on m.group_id=d.group_id and m.user_id='a5000000-0000-0000-0000-000000000051'
where d.id in ('a5000000-0000-0000-0000-000000000061','a5000000-0000-0000-0000-000000000062','a5000000-0000-0000-0000-000000000063');
insert into public.assignments(group_day_id,juz,seat_number,kind,reader_membership_id,status,completed_at)
select 'a5000000-0000-0000-0000-000000000063',2,2,'seat',id,'completed',now()
from public.group_memberships where group_id='a5000000-0000-0000-0000-000000000052' and user_id='a5000000-0000-0000-0000-000000000054';
select set_config('request.jwt.claims',json_build_object('sub','a5000000-0000-0000-0000-000000000051','role','authenticated')::text,true);
select is(public.get_my_log()->>'streak','1','late completed day preserves current streak');
select is(public.get_my_log()->>'best_streak','1','missed day breaks streak');
select is(jsonb_array_length(public.get_my_log()->'days'),3,'days with items are returned');
select is((public.get_my_log()->'days'->0->>'date')::date,current_date-1,'days are newest first');
select is(public.get_my_log()->'days'->0->>'complete','true','late item counts as complete');
select is(public.get_my_log()->'days'->1->>'complete','false','missed item breaks completion');
select is(jsonb_array_length(public.get_my_log()->'days'->0->'items'),1,'log excludes assignments read by another user');
select is((public.get_my_log()->'month'->>'full_days')::int,2,'month counts fully completed days');
select is((public.get_my_log()->'month'->>'days_with_items')::int,3,'month counts days containing items');
select is(jsonb_array_length(public.get_my_log(current_date-1,1)->'days'),1,'pagination limits returned days');
select is(public.get_my_log(current_date-1,1)->>'next_before',(current_date-2)::text,'pagination returns next cursor');
update public.group_memberships set status='left',seat_number=null,ended_at=now() where group_id='a5000000-0000-0000-0000-000000000052' and user_id='a5000000-0000-0000-0000-000000000051';
select is(jsonb_array_length(public.get_my_log()->'days'),3,'history remains after leaving a group');
select * from finish();
rollback;
