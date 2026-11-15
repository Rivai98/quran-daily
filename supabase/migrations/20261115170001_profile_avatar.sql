-- Illustrated avatar selection for personal and group member profiles.
alter table public.profiles
  add column avatar_key text not null default 'ornament'
  check (avatar_key in ('ornament', 'man_kufi', 'woman_hijab'));

create or replace function public.get_my_profile()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_display_name text;
  v_avatar_key text;
  v_member_since date;
  v_streak int := 0;
  v_best int := 0;
  v_run int := 0;
  v_portions_read int := 0;
  v_portions_late int := 0;
  v_date date;
  v_complete boolean;
  v_earned_streak_7 date;
  v_earned_streak_30 date;
  v_earned_streak_100 date;
  v_earned_first_khatma date;
  v_earned_portions_100 date;
  v_khatmas jsonb;
  v_badges jsonb;
begin
  v_uid := public.require_auth_uid();

  -- Profile info
  select coalesce(p.display_name, ''), coalesce(p.avatar_key, 'ornament'), p.created_at::date
  into v_display_name, v_avatar_key, v_member_since
  from public.profiles p
  where p.id = v_uid;

  if not found then
    v_display_name := '';
    v_avatar_key := 'ornament';
    v_member_since := current_date;
  end if;

  -- Totals: portions_read (completed + late) and portions_late
  select
    coalesce(count(*) filter (where a.status in ('completed', 'late')), 0)::int,
    coalesce(count(*) filter (where a.status = 'late'), 0)::int
  into v_portions_read, v_portions_late
  from public.assignments a
  join public.group_memberships m on m.id = a.reader_membership_id
  where m.user_id = v_uid;

  -- 1. Current streak (counting backwards from today / latest day with items)
  -- FR-010: late keeps the streak, missed breaks it, days without assignments are skipped
  for v_date, v_complete in
    select d.group_date, bool_and(a.status in ('completed', 'late'))
    from public.assignments a
    join public.group_days d on d.id = a.group_day_id
    join public.group_memberships m on m.id = a.reader_membership_id
    where m.user_id = v_uid and d.group_date <= current_date
    group by d.group_date
    order by d.group_date desc
  loop
    if v_complete then
      v_streak := v_streak + 1;
    else
      exit;
    end if;
  end loop;

  -- 2. Best streak and streak badge dates (iterating forwards)
  for v_date, v_complete in
    select d.group_date, bool_and(a.status in ('completed', 'late'))
    from public.assignments a
    join public.group_days d on d.id = a.group_day_id
    join public.group_memberships m on m.id = a.reader_membership_id
    where m.user_id = v_uid and d.group_date <= current_date
    group by d.group_date
    order by d.group_date asc
  loop
    if v_complete then
      v_run := v_run + 1;
      if v_run = 7 and v_earned_streak_7 is null then
        v_earned_streak_7 := v_date;
      end if;
      if v_run = 30 and v_earned_streak_30 is null then
        v_earned_streak_30 := v_date;
      end if;
      if v_run = 100 and v_earned_streak_100 is null then
        v_earned_streak_100 := v_date;
      end if;
      v_best := greatest(v_best, v_run);
    else
      v_run := 0;
    end if;
  end loop;

  -- 3. Khatmas per group
  -- Groups where user has or had memberships, counting distinct completed cycles where full_khatma is true and user participated
  with khatma_counts as (
    select
      g.id as group_id,
      g.name as group_name,
      count(distinct d.cycle_number)::int as completed,
      min(d.group_date) as first_khatma_date
    from public.groups g
    join public.group_memberships m on m.group_id = g.id and m.user_id = v_uid
    join public.group_days d on d.group_id = g.id and d.full_khatma = true
    where exists (
      select 1 from public.assignments a
      join public.group_memberships am on am.id = a.reader_membership_id
      where a.group_day_id = d.id and am.user_id = v_uid and a.status in ('completed', 'late')
    )
    group by g.id, g.name
  )
  select
    coalesce(jsonb_agg(
      jsonb_build_object(
        'group_id', kc.group_id,
        'group_name', kc.group_name,
        'completed', kc.completed
      ) order by kc.completed desc, kc.group_name
    ), '[]'::jsonb),
    min(kc.first_khatma_date)
  into v_khatmas, v_earned_first_khatma
  from khatma_counts kc;

  -- 4. Portions 100 badge date
  if v_portions_read >= 100 then
    select d.group_date into v_earned_portions_100
    from public.assignments a
    join public.group_days d on d.id = a.group_day_id
    join public.group_memberships m on m.id = a.reader_membership_id
    where m.user_id = v_uid and a.status in ('completed', 'late')
    order by d.group_date asc, a.completed_at asc nulls last, a.id asc
    offset 99 limit 1;
    if v_earned_portions_100 is null then
      v_earned_portions_100 := current_date;
    end if;
  end if;

  -- 5. Construct badges array
  with raw_badges as (
    select 'first_khatma' as code, v_earned_first_khatma as earned_at
    where v_earned_first_khatma is not null
    union all
    select 'streak_7' as code, v_earned_streak_7 as earned_at
    where v_earned_streak_7 is not null
    union all
    select 'streak_30' as code, v_earned_streak_30 as earned_at
    where v_earned_streak_30 is not null
    union all
    select 'streak_100' as code, v_earned_streak_100 as earned_at
    where v_earned_streak_100 is not null
    union all
    select 'portions_100' as code, v_earned_portions_100 as earned_at
    where v_earned_portions_100 is not null
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object('code', rb.code, 'earned_at', rb.earned_at)
      order by rb.earned_at asc, rb.code asc
    ),
    '[]'::jsonb
  )
  into v_badges
  from raw_badges rb;

  return jsonb_build_object(
    'display_name', v_display_name,
    'avatar_key', v_avatar_key,
    'member_since', v_member_since,
    'streak', v_streak,
    'best_streak', v_best,
    'portions_read', v_portions_read,
    'portions_late', v_portions_late,
    'khatmas', coalesce(v_khatmas, '[]'::jsonb),
    'badges', coalesce(v_badges, '[]'::jsonb)
  );
end;
$$;

revoke all on function public.get_my_profile() from public, anon;
grant execute on function public.get_my_profile() to authenticated;

create or replace function public.get_group_info(p_group_id uuid)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare v_uid uuid; v_group public.groups; v_role public.group_role; v_members jsonb;
begin
  v_uid := public.require_auth_uid();
  select * into v_group from public.groups where id = p_group_id;
  if not found then raise exception 'group_not_found' using errcode = 'P0001'; end if;
  select role into v_role from public.group_memberships
  where group_id = p_group_id and user_id = v_uid and status = 'active';
  if v_role is null then raise exception 'not_member' using errcode = 'P0001'; end if;

  select coalesce(jsonb_agg(jsonb_build_object(
      'user_id', p.id, 'membership_id', m.id, 'display_name', p.display_name,
      'initials', public.display_initials(p.display_name), 'avatar_key', p.avatar_key, 'role', m.role,
      'seat_number', m.seat_number, 'joined_at', m.joined_at, 'is_me', p.id = v_uid)
    order by case m.role when 'owner' then 0 when 'supervisor' then 1 else 2 end, m.seat_number),
    '[]'::jsonb)
  into v_members
  from public.group_memberships m join public.profiles p on p.id = m.user_id
  where m.group_id = p_group_id and m.status = 'active';

  return jsonb_build_object(
    'group_id', v_group.id, 'name', v_group.name, 'description', v_group.short_description,
    'photo_path', v_group.photo_path, 'status', v_group.status, 'visibility', v_group.visibility,
    'join_mode', v_group.join_mode, 'portion_unit', v_group.portion_unit,
    'timezone', v_group.timezone, 'day_start_time', v_group.day_start_time,
    'created_at', v_group.created_at, 'start_date', v_group.start_date,
    'my_role', v_role,
    'member_count', jsonb_array_length(v_members), 'seat_capacity', 30,
    'khatma_count', (select count(*)::int from public.group_days d
                     where d.group_id = p_group_id and d.full_khatma),
    'invite_code', case when v_role in ('owner', 'supervisor') then v_group.invite_code end,
    'members', v_members);
end $$;
revoke all on function public.get_group_info(uuid) from public, anon;
grant execute on function public.get_group_info(uuid) to authenticated;

create or replace function public.get_member_profile(p_user_id uuid, p_group_id uuid)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  v_uid uuid; v_caller_role public.group_role; v_target public.group_memberships;
  v_profile public.profiles; v_privileged boolean; v_streak int := 0; v_day record;
  v_done int; v_total int; v_read int; v_rows jsonb; v_recent jsonb; v_today date;
begin
  v_uid := public.require_auth_uid();
  select role into v_caller_role from public.group_memberships
  where group_id = p_group_id and user_id = v_uid and status = 'active';
  select * into v_target from public.group_memberships
  where group_id = p_group_id and user_id = p_user_id
  order by (status = 'active') desc, joined_at desc limit 1;
  if v_caller_role is null or v_target.id is null then
    raise exception 'profile_not_accessible' using errcode = 'P0001';
  end if;
  select * into v_profile from public.profiles where id = p_user_id;
  v_privileged := v_caller_role in ('owner', 'supervisor') or p_user_id = v_uid;
  v_today := public.group_local_date(p_group_id, now());

  -- All of the target's portions in this group (any of their memberships).
  select coalesce(jsonb_agg(jsonb_build_object(
      'group_date', d.group_date, 'portion_index', a.portion_index, 'juz', a.juz,
      'kind', a.kind, 'status', a.status, 'completed_at', a.completed_at)), '[]'::jsonb)
  into v_rows
  from public.assignments a
  join public.group_days d on d.id = a.group_day_id and d.group_id = p_group_id
  join public.group_memberships m on m.id = a.reader_membership_id
  where m.group_id = p_group_id and m.user_id = p_user_id;

  select count(*) filter (where r.status in ('completed', 'late'))::int,
         count(*) filter (where r.kind in ('seat', 'override') and r.status in ('completed', 'late'))::int,
         count(*) filter (where r.kind in ('seat', 'override') and r.status in ('completed', 'late', 'missed'))::int
  into v_read, v_done, v_total
  from jsonb_to_recordset(v_rows) as r(group_date date, kind text, status text);

  -- Streak: consecutive seat days read (late counts), newest first; a day
  -- still pending does not break it, a missed day does.
  for v_day in
    select r.group_date, bool_or(r.status in ('completed', 'late')) as read,
           bool_or(r.status = 'missed') as missed
    from jsonb_to_recordset(v_rows) as r(group_date date, kind text, status text)
    where r.kind in ('seat', 'override')
    group by r.group_date order by r.group_date desc
  loop
    if v_day.read then v_streak := v_streak + 1;
    elsif v_day.missed then exit;
    end if;
  end loop;

  select coalesce(jsonb_agg(e.value
    order by (e.value->>'group_date')::date desc, (e.value->>'portion_index')::int), '[]'::jsonb)
  into v_recent
  from jsonb_array_elements(v_rows) e(value)
  where (e.value->>'group_date')::date between v_today - 13 and v_today
    and (v_privileged or e.value->>'status' <> 'missed');

  return jsonb_build_object(
    'user_id', p_user_id, 'group_id', p_group_id,
    'display_name', v_profile.display_name,
    'initials', public.display_initials(v_profile.display_name),
    'avatar_key', v_profile.avatar_key,
    'bio', v_profile.bio,
    'role', case when v_target.status = 'active' then v_target.role::text else 'former_member' end,
    'seat_number', v_target.seat_number,
    'member_since', v_target.joined_at,
    'is_me', p_user_id = v_uid,
    'current_streak', v_streak,
    'completion_rate', case when v_total > 0 then round(100.0 * v_done / v_total)::int end,
    'portions_read', v_read,
    'recent_days', v_recent);
end $$;
revoke all on function public.get_member_profile(uuid, uuid) from public, anon;
grant execute on function public.get_member_profile(uuid, uuid) to authenticated;

create or replace function public.update_my_profile(
  p_display_name text,
  p_bio text default null,
  p_avatar_key text default 'ornament'
)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid; v_name text; v_bio text; v_key text; v_profile public.profiles;
begin
  v_uid := public.require_auth_uid();
  v_name := btrim(coalesce(p_display_name, ''));
  if char_length(v_name) not between 2 and 50 then
    raise exception 'invalid_display_name' using errcode = 'P0001';
  end if;
  v_bio := nullif(btrim(coalesce(p_bio, '')), '');
  if char_length(v_bio) > 120 then
    raise exception 'invalid_bio' using errcode = 'P0001';
  end if;
  v_key := coalesce(nullif(btrim(p_avatar_key), ''), 'ornament');
  if v_key not in ('ornament', 'man_kufi', 'woman_hijab') then
    raise exception 'invalid_avatar_key' using errcode = 'P0001';
  end if;
  update public.profiles set display_name = v_name, bio = v_bio, avatar_key = v_key
  where id = v_uid returning * into v_profile;
  if not found then raise exception 'profile_not_found' using errcode = 'P0001'; end if;
  return jsonb_build_object('user_id', v_profile.id, 'display_name', v_profile.display_name,
    'initials', public.display_initials(v_profile.display_name), 'bio', v_profile.bio,
    'avatar_key', v_profile.avatar_key, 'updated_at', v_profile.updated_at);
end $$;
revoke all on function public.update_my_profile(text, text) from public, anon;
drop function public.update_my_profile(text, text);
revoke all on function public.update_my_profile(text, text, text) from public, anon;
grant execute on function public.update_my_profile(text, text, text) to authenticated;


-- Carry selected avatars through the forming-group member list.
create or replace function public.get_dashboard_portion_base(p_group_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid; v_group public.groups; v_membership_id uuid; v_role public.group_role;
  v_member_count int; v_day public.group_days; v_assignments jsonb; v_my_assignments jsonb; v_seats jsonb;
begin
  v_uid:=public.require_auth_uid();
  select * into v_group from public.groups where id=p_group_id;
  if not found then raise exception 'group_not_found' using errcode='P0001'; end if;
  select id,role into v_membership_id,v_role from public.group_memberships
    where group_id=p_group_id and user_id=v_uid and status='active';
  if not found then raise exception 'not_member' using errcode='P0001'; end if;
  select count(*)::int into v_member_count from public.group_memberships where group_id=p_group_id and status='active';
  if v_group.status='forming' then
    select jsonb_build_object('group_id',p_group_id,'active_member_count',v_member_count,
      'invite_code',v_group.invite_code,'members',coalesce((select jsonb_agg(jsonb_build_object(
        'membership_id',m.id,'user_id',p.id,'display_name',p.display_name,'avatar_key',p.avatar_key,'role',m.role,'seat_number',m.seat_number) order by m.seat_number)
        from public.group_memberships m join public.profiles p on p.id=m.user_id
        where m.group_id=p_group_id and m.status='active'),'[]'::jsonb)) into v_seats;
    return jsonb_build_object('group_id',v_group.id,'group_name',v_group.name,'my_role',v_role,
      'status',v_group.status,'server_generated_at',now(),'active_member_count',v_member_count,
      'invite_code',v_group.invite_code,'seats',v_seats);
  end if;
  if v_group.status='archived' then raise exception 'group_archived' using errcode='P0001'; end if;
  perform public.ensure_current_group_day(p_group_id);
  select * into v_day from public.group_days where group_id=p_group_id
    and group_date=public.group_local_date(p_group_id,now());
  if not found then raise exception 'group_day_unavailable' using errcode='P0001'; end if;
  perform public.recompute_day_counts(v_day.id);
  select * into v_day from public.group_days where id=v_day.id;
  select coalesce(jsonb_agg(jsonb_build_object('assignment_id',a.id,'juz',a.juz,
    'seat_number',a.seat_number,'kind',a.kind,
    'status',case when h.hidden then 'unread'::public.assignment_status else a.status end,
    'reader_display_name',case when h.hidden then null else p.display_name end,
    'reader',case when h.hidden then null else public.reader_json(p.id,p.display_name) end,
    'is_me',coalesce(a.reader_membership_id=v_membership_id,false),'is_khatm_juz',a.juz=30,
    'completed_at',a.completed_at) order by a.juz),'[]'::jsonb) into v_assignments
  from public.assignments a left join public.group_memberships m on m.id=a.reader_membership_id
    left join public.profiles p on p.id=m.user_id
    cross join lateral (select public.reader_hidden(v_role,a.status,m.user_id,v_uid) as hidden) h
  where a.group_day_id=v_day.id;
  select coalesce(jsonb_agg(jsonb_build_object('assignment_id',a.id,'juz',a.juz,
    'seat_number',a.seat_number,'kind',a.kind,'status',a.status,'reader_display_name',p.display_name,
    'reader',public.reader_json(p.id,p.display_name),
    'is_me',true,'is_khatm_juz',a.juz=30,'completed_at',a.completed_at) order by a.juz),'[]'::jsonb)
    into v_my_assignments from public.assignments a join public.group_memberships m on m.id=a.reader_membership_id
      join public.profiles p on p.id=m.user_id where a.group_day_id=v_day.id and a.reader_membership_id=v_membership_id;
  return jsonb_build_object('group_id',v_group.id,'group_name',v_group.name,'my_role',v_role,
    'status',v_group.status,'server_generated_at',now(),'active_member_count',v_member_count,
    'invite_code',v_group.invite_code,'today',jsonb_build_object('group_date',v_day.group_date,
      'state',v_day.state,'completed_count',v_day.completed_count,'late_count',v_day.late_count,
      'missed_count',v_day.missed_count,'unread_count',v_day.unread_count,'pending_count',v_day.pending_count,
      'available_count',v_day.available_count,'full_khatma',v_day.full_khatma,'ends_at',v_day.ends_at),
    'my_assignments',v_my_assignments,'assignments',v_assignments);
end $$;
revoke all on function public.get_dashboard_portion_base(uuid) from public,anon,authenticated;
