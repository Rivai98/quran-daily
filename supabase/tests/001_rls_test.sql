create extension if not exists pgtap with schema extensions;

\i helpers/seed_members.sql

begin;
select plan(12);

-- Seed: one group, two members (owner + member), and an outsider.
select tests_seed_user('d0000000-0000-0000-0000-000000000001', 'rls-owner@test.local', 'مالك رلس');
select tests_seed_user('d0000000-0000-0000-0000-000000000002', 'rls-member@test.local', 'عضو رلس');
select tests_seed_user('d0000000-0000-0000-0000-000000000003', 'rls-outsider@test.local', 'غريب');
select tests_seed_group('e0000000-0000-0000-0000-000000000001', 'حلقة رلس',
                        'd0000000-0000-0000-0000-000000000001', 'Africa/Cairo', 'R5TEST23');
select tests_seed_member('e0000000-0000-0000-0000-000000000001',
                         'd0000000-0000-0000-0000-000000000001', 1::smallint, 'owner'::public.group_role);
select tests_seed_member('e0000000-0000-0000-0000-000000000001',
                         'd0000000-0000-0000-0000-000000000002', 2::smallint);

-- Start the group so a day + 30 assignments exist (direct, superuser).
update public.groups
set status = 'active', start_juz = 1, start_date = current_date
where id = 'e0000000-0000-0000-0000-000000000001';

insert into public.group_days (id, group_id, group_date, day_index, opens_at, ends_at, closes_at)
values ('f0000000-0000-0000-0000-000000000001',
        'e0000000-0000-0000-0000-000000000001', current_date, 0,
        now(), now() + interval '24 hours', now() + interval '48 hours');

insert into public.assignments (group_day_id, juz, seat_number, kind, reader_membership_id, status)
select 'f0000000-0000-0000-0000-000000000001',
       s::smallint,
       s::smallint,
       case when s <= 2 then 'seat'::public.assignment_kind
            else 'unassigned'::public.assignment_kind end,
       case when s = 1
            then (select id from public.group_memberships
                  where group_id = 'e0000000-0000-0000-0000-000000000001'
                    and user_id = 'd0000000-0000-0000-0000-000000000001')
            when s = 2
            then (select id from public.group_memberships
                  where group_id = 'e0000000-0000-0000-0000-000000000001'
                    and user_id = 'd0000000-0000-0000-0000-000000000002')
            else null end,
       case when s <= 2 then 'pending'::public.assignment_status
            else 'available'::public.assignment_status end
from generate_series(1, 30) s;

-- ---------------------------------------------------------------------------
-- As MEMBER: can read own group rows; cannot write anything.
-- ---------------------------------------------------------------------------
set role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', 'd0000000-0000-0000-0000-000000000002', 'role', 'authenticated')::text, true);

select is(count(*), 1::bigint, 'member reads own group row')
from public.groups;
select is(count(*), 30::bigint, 'member reads the 30 assignments')
from public.assignments
where group_day_id = 'f0000000-0000-0000-0000-000000000001';

-- All client writes fail closed: write privileges are revoked and RLS has
-- no write policies, so every direct write raises 42501.
select throws_ok(
  'update public.groups set name = ''اختراق'' where id = ''e0000000-0000-0000-0000-000000000001''',
  42501);
-- desc: member cannot update groups directly
select throws_ok(
  'insert into public.group_memberships (id, group_id, user_id, role, status, seat_number) values (gen_random_uuid(), ''e0000000-0000-0000-0000-000000000001'', ''d0000000-0000-0000-0000-000000000003'', ''member'', ''active'', 5)',
  42501);
-- desc: member cannot insert memberships directly
select throws_ok(
  'update public.assignments set status = ''completed'' where group_day_id = ''f0000000-0000-0000-0000-000000000001'' and juz = 1',
  42501);
-- desc: member cannot write assignments directly (must use RPC)
select throws_ok(
  'insert into public.completion_records (assignment_id, actor_user_id, action, client_recorded_at) values (''f0000000-0000-0000-0000-000000000001'', ''d0000000-0000-0000-0000-000000000002'', ''completed'', now())',
  42501);
-- desc: member cannot insert completion records directly
select throws_ok(
  'delete from public.group_days where group_id = ''e0000000-0000-0000-0000-000000000001''',
  42501);
-- desc: member cannot delete group days
reset role;

-- ---------------------------------------------------------------------------
-- As OUTSIDER: sees none of the group's rows.
-- ---------------------------------------------------------------------------
set role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', 'd0000000-0000-0000-0000-000000000003', 'role', 'authenticated')::text, true);

select is(count(*), 0::bigint, 'outsider sees no groups')
from public.groups;
select is(count(*), 0::bigint, 'outsider sees no memberships')
from public.group_memberships;
select is(count(*), 0::bigint, 'outsider sees no assignments')
from public.assignments;
select is(count(*), 0::bigint, 'outsider sees no group days')
from public.group_days;
select is(count(*), 0::bigint, 'outsider sees no completion records')
from public.completion_records;
reset role;

select * from finish();
rollback;
