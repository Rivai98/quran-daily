create extension if not exists pgtap with schema extensions;
\i helpers/seed_members.sql
begin;
select plan(57);

select is(public.portion_count('juz'::public.portion_unit), 30, 'juz count');
select is(public.portion_count('half_juz'::public.portion_unit), 60, 'half juz count');
select is(public.portion_count('hizb'::public.portion_unit), 60, 'hizb count');
select is(public.portion_count('quarter'::public.portion_unit), 240, 'quarter count');
select is(public.portion_count('page'::public.portion_unit), 604, 'page count');
select is(public.portion_for_seat(1, 1, 0, 'juz'::public.portion_unit), 1, 'first juz');
select is(public.portion_for_seat(30, 1, 0, 'juz'::public.portion_unit), 30, 'last juz');
select is(public.portion_for_seat(1, 1, 1, 'hizb'::public.portion_unit), 31, 'second cycle day');
select is((select count(*)::int from generate_series(0,0) d cross join generate_series(1,30) s
  where public.portion_for_seat(s,1,d,'juz'::public.portion_unit) is not null),30,'juz cycle has 30 assignments');
select is((select count(distinct public.portion_for_seat(s,1,d,'juz'::public.portion_unit))::int
  from generate_series(0,0) d cross join generate_series(1,30) s),30,'juz cycle covers each portion once');
select is((select count(*)::int from generate_series(0,1) d cross join generate_series(1,30) s
  where public.portion_for_seat(s,1,d,'hizb'::public.portion_unit) is not null),60,'hizb cycle assigns 60 portions');
select is((select count(distinct public.portion_for_seat(s,1,d,'hizb'::public.portion_unit))::int
  from generate_series(0,1) d cross join generate_series(1,30) s),60,'hizb cycle covers each portion once');
select is((select count(*)::int from generate_series(0,1) d cross join generate_series(1,30) s
  where public.portion_for_seat(s,1,d,'half_juz'::public.portion_unit) is not null),60,'half juz cycle assigns 60 portions');
select is((select count(distinct public.portion_for_seat(s,1,d,'half_juz'::public.portion_unit))::int
  from generate_series(0,1) d cross join generate_series(1,30) s),60,'half juz cycle covers each portion once');
select is((select count(*)::int from generate_series(0,7) d cross join generate_series(1,30) s
  where public.portion_for_seat(s,1,d,'quarter'::public.portion_unit) is not null),240,'quarter cycle assigns 240 portions');
select is((select count(distinct public.portion_for_seat(s,1,d,'quarter'::public.portion_unit))::int
  from generate_series(0,7) d cross join generate_series(1,30) s),240,'quarter cycle covers each portion once');
select is((select count(*)::int from generate_series(0,20) d cross join generate_series(1,30) s
  where public.portion_for_seat(s,1,d,'page'::public.portion_unit) is not null),604,'page cycle assigns 604 portions');
select is((select count(distinct public.portion_for_seat(s,1,d,'page'::public.portion_unit))::int
  from generate_series(0,20) d cross join generate_series(1,30) s),604,'page cycle covers each portion once');
select is((select count(*)::int from generate_series(1,30) s
  where public.portion_for_seat(s,1,20,'page'::public.portion_unit) is null),26,'page cycle has 26 rest seats on final day');
select is(public.portion_for_seat(1,1,21,'page'::public.portion_unit),2,'next page cycle starts shifted by one');
select is((select count(*)::int from generate_series(1,30) s
  where public.portion_for_seat(s,1,7,'juz'::public.portion_unit)=public.juz_for_seat(s,1,7)),30,'juz rotation matches legacy helper');
select ok((select exists(select 1 from pg_attribute where attrelid='public.groups'::regclass and attname='portion_unit' and not attisdropped)),'groups have portion unit');
select ok((select exists(select 1 from pg_attribute where attrelid='public.group_days'::regclass and attname='cycle_day' and not attisdropped)),'days store cycle metadata');
select ok((select exists(select 1 from pg_attribute where attrelid='public.assignments'::regclass and attname='portion_index' and not attisdropped)),'assignments store portion index');
select is((select column_default::text from information_schema.columns where table_schema='public' and table_name='groups' and column_name='portion_unit'),'''juz''::portion_unit','legacy groups default to juz');
select has_function('public','portion_count',array['public.portion_unit'],'portion count helper is registered');
select has_function('public','portion_for_seat',array['integer','integer','integer','public.portion_unit'],'rotation helper is registered');
select is(public.portion_for_seat(1,30,0,'juz'::public.portion_unit),30,'start portion seeds first seat');
select is(public.portion_for_seat(1,30,1,'juz'::public.portion_unit),1,'next juz cycle advances by one');

select tests_seed_user('a4000000-0000-0000-0000-000000000001','portion-owner@test.local','مالك الوحدات');
select tests_seed_user('a4000000-0000-0000-0000-000000000002','portion-member@test.local','عضو الوحدات');
select tests_seed_user('a4000000-0000-0000-0000-000000000003','portion-reader@test.local','قارئ الوحدات');
select set_config('request.jwt.claims',json_build_object('sub','a4000000-0000-0000-0000-000000000001','role','authenticated')::text,true);
create temporary table portion_group as
select (public.create_group('مجموعة اختبار الحزب','', 'Africa/Cairo','00:00','private','approval','hizb')->>'group_id')::uuid as id;
select is((select portion_unit::text from public.groups where id=(select id from portion_group)),'hizb','new group stores selected unit');
insert into public.group_memberships(group_id,user_id,role,status,seat_number)
values((select id from portion_group),'a4000000-0000-0000-0000-000000000002','member','active',2),
      ((select id from portion_group),'a4000000-0000-0000-0000-000000000003','member','active',3);
select lives_ok(format('select public.start_khatma(%L::uuid,31)',(select id from portion_group)),'legacy start_juz parameter accepts start portion for hizb');
select is((select portion_index from public.assignments a join public.group_days d on d.id=a.group_day_id where d.group_id=(select id from portion_group) and d.day_index=0 and a.seat_number=1),31::smallint,'seat one starts on requested portion');
select is((select portion_index from public.assignments a join public.group_days d on d.id=a.group_day_id where d.group_id=(select id from portion_group) and d.day_index=0 and a.seat_number=30),60::smallint,'seat thirty ends first block');
select is((select cycle_length from public.group_days where group_id=(select id from portion_group) and day_index=0),2::smallint,'hizb group cycle length is two days');
select is((public.get_dashboard((select id from portion_group))->>'portion_unit'),'hizb','dashboard returns unit');
select is((public.get_dashboard((select id from portion_group))->'assignments'->0->>'portion_index') is not null,true,'dashboard assignments expose portion index');
select is((public.get_my_groups()->'groups'->0->>'portion_unit'),'hizb','my groups read model returns unit');
select is((public.get_invite_preview((select invite_code from public.groups where id=(select id from portion_group)))->>'portion_unit'),'hizb','invite preview returns unit');
update public.groups set visibility='public' where id=(select id from portion_group);
select ok(exists(select 1 from public.search_public_groups(null,false,100,0) as r(value)
  where r.value->>'group_id'=(select id::text from portion_group) and r.value->>'portion_unit'='hizb'),
  'public discovery read model returns unit');
select lives_ok(format('select public.update_group_settings(%L::uuid,null,null,null,null,null,null,''quarter''::public.portion_unit)',(select id from portion_group)),'owner can schedule a unit change');
select is((select pending_portion_unit::text from public.groups where id=(select id from portion_group)),'quarter','active group retains current unit until boundary');
update public.group_days set group_date=public.group_local_date((select id from portion_group),now())-2,
  opens_at=now()-interval '3 days',ends_at=now()-interval '2 days',closes_at=now()-interval '1 day'
where group_id=(select id from portion_group) and day_index=0;
update public.groups set start_date=public.group_local_date((select id from portion_group),now())-2 where id=(select id from portion_group);
select public.ensure_current_group_day((select id from portion_group));
select is((select portion_unit::text from public.groups where id=(select id from portion_group)),'quarter','pending unit applies at next cycle boundary');
select is((select pending_portion_unit is null from public.groups where id=(select id from portion_group)),true,'applied pending unit is cleared');
select is((select count(*)::int from public.assignments a join public.group_days d on d.id=a.group_day_id where d.group_id=(select id from portion_group) and d.group_date=public.group_local_date((select id from portion_group),now())),30,'new unit day materializes seat assignments');
update public.assignments a set status='completed' from public.group_days d where a.group_day_id=d.id and d.group_id=(select id from portion_group) and d.day_index in (0,1);
update public.assignments a set status='late' from public.group_days d where a.group_day_id=d.id and d.group_id=(select id from portion_group) and d.day_index=1 and a.seat_number=30;
select is((select count(distinct a.portion_index)::int from public.assignments a join public.group_days d on d.id=a.group_day_id where d.group_id=(select id from portion_group) and d.cycle_number=0 and d.portion_unit='hizb' and a.status in('completed','late')),60,'completed cycle has all 60 structural portions');
select is((select bool_and(cycle_day in(0,1)) from public.group_days where group_id=(select id from portion_group) and cycle_number=0 and portion_unit='hizb'),true,'hizb days store both cycle offsets');
select lives_ok(format('select public.recompute_day_counts((select id from public.group_days where group_id=%L::uuid and day_index=1))',(select id from portion_group)),'cycle completion recomputes full khatma with late portions');
select is((select full_khatma from public.group_days where group_id=(select id from portion_group) and day_index=1),true,'final cycle day records full khatma including late portions');
select is((select full_khatma from public.group_days where group_id=(select id from portion_group) and day_index=0),false,'full khatma is not attached to an earlier cycle day');
select is((public.get_history((select id from portion_group))->0->>'portion_unit'),'quarter','history summary returns day unit');
select is((public.get_history_day((select id from portion_group),public.group_local_date((select id from portion_group),now()))->>'portion_unit'),'quarter','history detail returns day unit');
select set_config('request.jwt.claims',json_build_object('sub','a4000000-0000-0000-0000-000000000002','role','authenticated')::text,true);
select lives_ok(format('select public.volunteer_for_juz((select a.id from public.assignments a join public.group_days d on d.id=a.group_day_id where d.group_id=%L::uuid and d.group_date=public.group_local_date(%L::uuid,now()) and a.seat_number=4))',(select id from portion_group),(select id from portion_group)),'member can volunteer on non-juz portion');
select is((select portion_index from public.assignments a join public.group_days d on d.id=a.group_day_id where d.group_id=(select id from portion_group) and d.group_date=public.group_local_date((select id from portion_group),now()) and a.seat_number=4),4::smallint,'volunteering preserves portion index');
select set_config('request.jwt.claims',json_build_object('sub','a4000000-0000-0000-0000-000000000001','role','authenticated')::text,true);
update public.assignments a set status='completed' from public.group_days d where a.group_day_id=d.id and d.group_id=(select id from portion_group) and d.group_date=public.group_local_date((select id from portion_group),now()) and a.seat_number=3;
select lives_ok(format('select public.override_assignment((select a.id from public.assignments a join public.group_days d on d.id=a.group_day_id where d.group_id=%L::uuid and d.group_date=public.group_local_date(%L::uuid,now()) and a.seat_number=5),(select id from public.group_memberships where group_id=%L::uuid and seat_number=3 and status=''active''))',(select id from portion_group),(select id from portion_group),(select id from portion_group)),'owner can override a non-juz portion');
select is((select portion_index from public.assignments a join public.group_days d on d.id=a.group_day_id where d.group_id=(select id from portion_group) and d.group_date=public.group_local_date((select id from portion_group),now()) and a.seat_number=5),5::smallint,'override preserves portion index');
select lives_ok(format('select public.remove_member(%L::uuid,(select id from public.group_memberships where group_id=%L::uuid and seat_number=3 and status=''active''))',(select id from portion_group),(select id from portion_group)),'owner can remove non-juz day member');
select is((select status::text from public.assignments a join public.group_days d on d.id=a.group_day_id where d.group_id=(select id from portion_group) and d.group_date=public.group_local_date((select id from portion_group),now()) and a.seat_number=5),'available','member removal releases the portion');

select * from finish();
rollback;
