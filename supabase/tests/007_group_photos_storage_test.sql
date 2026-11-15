create extension if not exists pgtap with schema extensions;

\i helpers/seed_members.sql

begin;
select plan(16);

-- Spec 007 fixtures (b7 prefix, Q7 invite codes).
-- 21 owner of group 40, 22 member of 40, 23 former member of 40,
-- 24 outsider who owns group 41.
select tests_seed_user('b7000000-0000-0000-0000-000000000021', 's7p-owner@test.local', 'مالك صورة');
select tests_seed_user('b7000000-0000-0000-0000-000000000022', 's7p-mem@test.local', 'عضو صورة');
select tests_seed_user('b7000000-0000-0000-0000-000000000023', 's7p-old@test.local', 'سابق صورة');
select tests_seed_user('b7000000-0000-0000-0000-000000000024', 's7p-out@test.local', 'خارجي صورة');
select tests_seed_group('b7000000-0000-0000-0000-000000000040', 'حلقة الصورة',
  'b7000000-0000-0000-0000-000000000021', 'Africa/Cairo', 'Q7PHDDDD');
select tests_seed_group('b7000000-0000-0000-0000-000000000041', 'حلقة أخرى',
  'b7000000-0000-0000-0000-000000000024', 'Africa/Cairo', 'Q7PHEEEE');
select tests_seed_member('b7000000-0000-0000-0000-000000000040', 'b7000000-0000-0000-0000-000000000021', 1::smallint, 'owner'::public.group_role);
select tests_seed_member('b7000000-0000-0000-0000-000000000040', 'b7000000-0000-0000-0000-000000000022', 2::smallint);
select tests_seed_member('b7000000-0000-0000-0000-000000000041', 'b7000000-0000-0000-0000-000000000024', 1::smallint, 'owner'::public.group_role);
insert into public.group_memberships (group_id, user_id, role, status, seat_number, ended_at)
values ('b7000000-0000-0000-0000-000000000040', 'b7000000-0000-0000-0000-000000000023',
  'member', 'left', null, now());

-- Bucket configuration
select is(
  (select public::text || '|' || file_size_limit::text from storage.buckets where id = 'group-photos'),
  'false|1048576', 'group-photos bucket is private with a 1 MB limit');
select is(
  (select allowed_mime_types::text from storage.buckets where id = 'group-photos'),
  '{image/jpeg,image/png,image/webp}', 'group-photos accepts jpeg, png and webp only');

-- ---------------------------------------------------------------------------
-- Owner writes
-- ---------------------------------------------------------------------------
set role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', 'b7000000-0000-0000-0000-000000000021', 'role', 'authenticated')::text, true);
select lives_ok(
  'insert into storage.objects (bucket_id, name) values (''group-photos'', ''b7000000-0000-0000-0000-000000000040/a.jpg'')',
  'owner uploads a photo into the group folder');
select throws_ok(
  'insert into storage.objects (bucket_id, name) values (''group-photos'', ''b7000000-0000-0000-0000-000000000041/x.jpg'')',
  '42501', null, 'owner cannot upload into another group folder');
select throws_ok(
  'insert into storage.objects (bucket_id, name) values (''group-photos'', ''not-a-group/x.jpg'')',
  '42501', null, 'upload outside a group folder is refused');
reset role;

-- ---------------------------------------------------------------------------
-- Member reads, cannot write
-- ---------------------------------------------------------------------------
set role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', 'b7000000-0000-0000-0000-000000000022', 'role', 'authenticated')::text, true);
select is(count(*), 1::bigint, 'active member can read the group photo')
from storage.objects where bucket_id = 'group-photos' and name like 'b7000000-0000-0000-0000-000000000040/%';
select throws_ok(
  'insert into storage.objects (bucket_id, name) values (''group-photos'', ''b7000000-0000-0000-0000-000000000040/m.jpg'')',
  '42501', null, 'member cannot upload a group photo');
update storage.objects set metadata = '{"by":"member"}'
where bucket_id = 'group-photos' and name = 'b7000000-0000-0000-0000-000000000040/a.jpg';
select set_config('storage.allow_delete_query', 'true', true);
delete from storage.objects
where bucket_id = 'group-photos' and name = 'b7000000-0000-0000-0000-000000000040/a.jpg';
reset role;

select is(
  (select coalesce(metadata->>'by', 'none') from storage.objects
   where bucket_id = 'group-photos' and name = 'b7000000-0000-0000-0000-000000000040/a.jpg'),
  'none', 'member update does not touch the photo');
select is(
  (select count(*) from storage.objects
   where bucket_id = 'group-photos' and name = 'b7000000-0000-0000-0000-000000000040/a.jpg'),
  1::bigint, 'member delete does not remove the photo');

-- ---------------------------------------------------------------------------
-- Former member and outsider cannot read
-- ---------------------------------------------------------------------------
set role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', 'b7000000-0000-0000-0000-000000000023', 'role', 'authenticated')::text, true);
select is(count(*), 0::bigint, 'former member cannot read the group photo')
from storage.objects where bucket_id = 'group-photos' and name like 'b7000000-0000-0000-0000-000000000040/%';
select set_config('request.jwt.claims',
  json_build_object('sub', 'b7000000-0000-0000-0000-000000000024', 'role', 'authenticated')::text, true);
select is(count(*), 0::bigint, 'outsider cannot read the group photo')
from storage.objects where bucket_id = 'group-photos' and name like 'b7000000-0000-0000-0000-000000000040/%';
select set_config('request.jwt.claims', '', true);
select is(count(*), 0::bigint, 'unauthenticated caller cannot read the group photo')
from storage.objects where bucket_id = 'group-photos' and name like 'b7000000-0000-0000-0000-000000000040/%';
reset role;

-- ---------------------------------------------------------------------------
-- Owner updates and deletes
-- ---------------------------------------------------------------------------
set role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', 'b7000000-0000-0000-0000-000000000021', 'role', 'authenticated')::text, true);
select lives_ok(
  'update storage.objects set metadata = ''{"by":"owner"}'' where bucket_id = ''group-photos'' and name = ''b7000000-0000-0000-0000-000000000040/a.jpg''',
  'owner can update the photo');
select throws_ok(
  'update storage.objects set name = ''b7000000-0000-0000-0000-000000000041/a.jpg'' where bucket_id = ''group-photos'' and name = ''b7000000-0000-0000-0000-000000000040/a.jpg''',
  '42501', null, 'owner cannot move the photo into another group folder');
select set_config('storage.allow_delete_query', 'true', true);
delete from storage.objects
where bucket_id = 'group-photos' and name = 'b7000000-0000-0000-0000-000000000040/a.jpg';
reset role;

select is(
  (select count(*) from storage.objects where bucket_id = 'group-photos'
     and name = 'b7000000-0000-0000-0000-000000000040/a.jpg'),
  0::bigint, 'owner deletes the photo');

-- Policy helpers are not exposed to anon.
select is(has_function_privilege('anon', 'public.can_read_group_photo(text)', 'execute'),
  false, 'anon cannot call the photo read helper');

select * from finish();
rollback;
