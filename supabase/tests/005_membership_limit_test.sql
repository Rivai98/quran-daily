create extension if not exists pgtap with schema extensions;
\i helpers/seed_members.sql
begin;
select plan(3);
select tests_seed_user('a5000000-0000-0000-0000-000000000001','p5-owner@test.local','P5 owner');
select tests_seed_user('a5000000-0000-0000-0000-000000000002','p5-member@test.local','P5 member');
select tests_seed_group('a5000000-0000-0000-0000-000000000011','P5 group one','a5000000-0000-0000-0000-000000000001','Africa/Cairo','P5ABCDEF');
select tests_seed_group('a5000000-0000-0000-0000-000000000012','P5 group two','a5000000-0000-0000-0000-000000000002','Africa/Cairo','P5ABCDEG');
select tests_seed_group('a5000000-0000-0000-0000-000000000013','P5 group three','a5000000-0000-0000-0000-000000000002','Africa/Cairo','P5ABCDEH');
select tests_seed_member('a5000000-0000-0000-0000-000000000011'::uuid,'a5000000-0000-0000-0000-000000000001'::uuid,1::smallint,'owner'::public.group_role);
select tests_seed_member('a5000000-0000-0000-0000-000000000012'::uuid,'a5000000-0000-0000-0000-000000000001'::uuid,1::smallint);
select set_config('request.jwt.claims',json_build_object('sub','a5000000-0000-0000-0000-000000000001','role','authenticated')::text,true);
select throws_ok('select public.create_group(''P5 third group'','''',''Africa/Cairo'',''00:00'',''private'',''approval'')','P0001',null,'third active membership is refused');
select is((select count(*)::int from public.group_memberships where user_id='a5000000-0000-0000-0000-000000000001' and status='active'),2,'fixture has two active memberships');
update public.groups set status='archived' where id='a5000000-0000-0000-0000-000000000012';
select lives_ok('select public.create_group(''P5 after archive'','''',''Africa/Cairo'',''00:00'',''private'',''approval'')','archived membership does not count');
select * from finish();
rollback;

