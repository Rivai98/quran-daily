create extension if not exists pgtap with schema extensions;
\i helpers/seed_members.sql
begin;
select plan(3);
select tests_seed_user('a5000000-0000-0000-0000-000000000041','p5-today@test.local','P5 today');
select tests_seed_group('a5000000-0000-0000-0000-000000000042','P5 today group','a5000000-0000-0000-0000-000000000041','Africa/Cairo','P5ABCDEL');
select tests_seed_member('a5000000-0000-0000-0000-000000000042'::uuid,'a5000000-0000-0000-0000-000000000041'::uuid,1::smallint,'owner'::public.group_role);
select set_config('request.jwt.claims',json_build_object('sub','a5000000-0000-0000-0000-000000000041','role','authenticated')::text,true);
select is(jsonb_array_length(public.get_my_today()->'groups'),1,'forming membership appears in today feed');
select is(public.get_my_today()->'groups'->0->>'status','forming','group status is included');
select ok(public.get_my_today()->>'main_group_id'='a5000000-0000-0000-0000-000000000042','fallback picks an active group as main');
select * from finish();
rollback;
