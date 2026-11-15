create extension if not exists pgtap with schema extensions;

begin;
select plan(27);
-- The remote TAP runner buffers assertion output in this temporary table.
grant select on tap_lines to authenticated;

select has_table('public', 'reading_positions', 'reading positions table exists');
select has_table('public', 'bookmarks', 'bookmarks table exists');

select has_column('public', 'reading_positions', 'user_id', 'position has user id');
select has_column('public', 'reading_positions', 'last_page', 'position has last page');
select has_column('public', 'reading_positions', 'updated_at', 'position has updated at');
select has_column('public', 'bookmarks', 'id', 'bookmark has id');
select has_column('public', 'bookmarks', 'user_id', 'bookmark has user id');
select has_column('public', 'bookmarks', 'surah', 'bookmark has surah');
select has_column('public', 'bookmarks', 'ayah', 'bookmark has ayah');
select has_column('public', 'bookmarks', 'page', 'bookmark has page');
select has_column('public', 'bookmarks', 'note', 'bookmark has note');
select has_column('public', 'bookmarks', 'created_at', 'bookmark has created at');

insert into auth.users (id, email, aud, role, encrypted_password, created_at, updated_at)
values
  ('a3000000-0000-0000-0000-000000000001', 'mushaf-owner@test.local', 'authenticated', 'authenticated', '', now(), now()),
  ('a3000000-0000-0000-0000-000000000002', 'mushaf-outsider@test.local', 'authenticated', 'authenticated', '', now(), now());

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"a3000000-0000-0000-0000-000000000001","role":"authenticated"}', true);

insert into public.reading_positions (user_id, last_page)
values ('a3000000-0000-0000-0000-000000000001', 250);
select is((select last_page from public.reading_positions where user_id = auth.uid()), 250, 'user inserts own position');
insert into public.reading_positions (user_id, last_page)
values ('a3000000-0000-0000-0000-000000000001', 251)
on conflict (user_id) do update set last_page = excluded.last_page, updated_at = now();
select is((select last_page from public.reading_positions where user_id = auth.uid()), 251, 'user upserts own last page');
select is((select count(*) from public.reading_positions), 1::bigint, 'position primary key keeps one row per user');
select throws_ok($$insert into public.reading_positions(user_id,last_page) values ('a3000000-0000-0000-0000-000000000002', 1)$$, 42501, null, 'user cannot insert another user position');
select lives_ok($$update public.reading_positions set last_page=1 where user_id='a3000000-0000-0000-0000-000000000002'$$, 'user cannot update another user position');

insert into public.bookmarks (id,user_id,surah,ayah,page,note)
values ('a3000000-0000-0000-0000-000000000011','a3000000-0000-0000-0000-000000000001',2,255,42,'note');
select is((select count(*) from public.bookmarks), 1::bigint, 'user inserts own bookmark');
update public.bookmarks set note='updated' where id='a3000000-0000-0000-0000-000000000011';
select is((select note from public.bookmarks where id='a3000000-0000-0000-0000-000000000011'), 'updated', 'user updates own bookmark');
delete from public.bookmarks where id='a3000000-0000-0000-0000-000000000011';
select is((select count(*) from public.bookmarks), 0::bigint, 'user deletes own bookmark');
select throws_ok($$insert into public.bookmarks(user_id,surah,ayah,page) values ('a3000000-0000-0000-0000-000000000002',2,1,1)$$, 42501, null, 'user cannot insert another user bookmark');
select throws_ok($$insert into public.bookmarks(user_id,surah,ayah,page,note) values (auth.uid(),2,1,1,repeat('x',201))$$, 23514, null, 'bookmark note limited to 200 characters');
select throws_ok($$insert into public.bookmarks(user_id,surah,ayah,page) values (auth.uid(),0,1,1)$$, 23514, null, 'surah range enforced');
select throws_ok($$insert into public.bookmarks(user_id,surah,ayah,page) values (auth.uid(),2,1,605)$$, 23514, null, 'page range enforced');
reset role;

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"a3000000-0000-0000-0000-000000000002","role":"authenticated"}', true);
select is((select count(*) from public.reading_positions), 0::bigint, 'outsider cannot read another user position');
select is((select count(*) from public.bookmarks), 0::bigint, 'outsider cannot read another user bookmarks');
select lives_ok($$delete from public.bookmarks where user_id='a3000000-0000-0000-0000-000000000001'$$, 'outsider cannot delete another user bookmark');

select * from finish();
rollback;
