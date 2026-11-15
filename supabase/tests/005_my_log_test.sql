create extension if not exists pgtap with schema extensions;
\i helpers/seed_members.sql
begin;
select plan(3);
select tests_seed_user('a5000000-0000-0000-0000-000000000051','p5-log@test.local','P5 log');
select set_config('request.jwt.claims',json_build_object('sub','a5000000-0000-0000-0000-000000000051','role','authenticated')::text,true);
select is(public.get_my_log()->>'streak','0','empty log has zero streak');
select is(jsonb_array_length(public.get_my_log()->'days'),0,'empty log has no days');
select ok(public.get_my_log()->'month' ? 'full_days','month summary is present');
select * from finish();
rollback;
