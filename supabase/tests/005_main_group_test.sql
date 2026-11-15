create extension if not exists pgtap with schema extensions;
\i helpers/seed_members.sql
begin;
select plan(4);
select tests_seed_user('a5000000-0000-0000-0000-000000000021','p5-main@test.local','P5 main');
select tests_seed_user('a5000000-0000-0000-0000-000000000022','p5-other@test.local','P5 other');
select tests_seed_group('a5000000-0000-0000-0000-000000000031','P5 main group','a5000000-0000-0000-0000-000000000021','Africa/Cairo','P5ABCDEJ');
select tests_seed_group('a5000000-0000-0000-0000-000000000032','P5 other group','a5000000-0000-0000-0000-000000000021','Africa/Cairo','P5ABCDEK');
select tests_seed_member('a5000000-0000-0000-0000-000000000031'::uuid,'a5000000-0000-0000-0000-000000000021'::uuid,1::smallint,'owner'::public.group_role);
select tests_seed_member('a5000000-0000-0000-0000-000000000032'::uuid,'a5000000-0000-0000-0000-000000000021'::uuid,1::smallint,'owner'::public.group_role);
select set_config('request.jwt.claims',json_build_object('sub','a5000000-0000-0000-0000-000000000021','role','authenticated')::text,true);
select lives_ok('select public.set_main_group(''a5000000-0000-0000-0000-000000000032''::uuid)','member can pin a group');
select is((select main_group_id::text from public.profiles where id='a5000000-0000-0000-0000-000000000021'),'a5000000-0000-0000-0000-000000000032','pin is stored on profile');
select lives_ok('select public.mark_group_opened(''a5000000-0000-0000-0000-000000000031''::uuid)','member can mark group opened');
select lives_ok('select public.set_main_group(null)','null clears the pin');
select * from finish();
rollback;
