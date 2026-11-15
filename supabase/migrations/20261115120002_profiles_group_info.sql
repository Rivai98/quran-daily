-- Spec 007: member bio, group photo path, group info and member profile RPCs.
-- Emails stay in auth.users and are never read by these functions.

alter table public.profiles
  add column bio text check (bio is null or char_length(bio) <= 120);

alter table public.groups
  add column photo_path text
    constraint groups_photo_path_in_group_folder
    check (photo_path is null or photo_path like id::text || '/%');

-- Group info screen: details, stats and the active member list.
-- invite_code only for owner/supervisor.
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
      'initials', public.display_initials(p.display_name), 'role', m.role,
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

-- Member profile in one group's context. The caller must be an active member
-- of the group and the target must have (or have had) a membership there.
-- Missed days are listed only to owner/supervisor and to the member themself.
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

-- Edit "ملفي الشخصي": display name 2-50 chars, bio up to 120 (blank clears).
create or replace function public.update_my_profile(p_display_name text, p_bio text default null)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid; v_name text; v_bio text; v_profile public.profiles;
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
  update public.profiles set display_name = v_name, bio = v_bio
  where id = v_uid returning * into v_profile;
  if not found then raise exception 'profile_not_found' using errcode = 'P0001'; end if;
  return jsonb_build_object('user_id', v_profile.id, 'display_name', v_profile.display_name,
    'initials', public.display_initials(v_profile.display_name), 'bio', v_profile.bio,
    'updated_at', v_profile.updated_at);
end $$;
revoke all on function public.update_my_profile(text, text) from public, anon;
grant execute on function public.update_my_profile(text, text) to authenticated;

-- Owner edits the group's name (3-60) and description (<= 200, blank clears).
create or replace function public.update_group_details(
  p_group_id uuid, p_name text, p_description text default null)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid; v_group public.groups; v_name text; v_description text;
begin
  v_uid := public.require_auth_uid();
  select * into v_group from public.groups where id = p_group_id for update;
  if not found then raise exception 'group_not_found' using errcode = 'P0001'; end if;
  if v_group.owner_id <> v_uid then raise exception 'forbidden' using errcode = 'P0001'; end if;
  v_name := btrim(coalesce(p_name, ''));
  v_description := nullif(btrim(coalesce(p_description, '')), '');
  if char_length(v_name) not between 3 and 60 or char_length(v_description) > 200 then
    raise exception 'validation_failed' using errcode = 'P0001';
  end if;
  update public.groups set name = v_name, short_description = v_description
  where id = p_group_id returning * into v_group;
  return jsonb_build_object('group_id', v_group.id, 'name', v_group.name,
    'description', v_group.short_description, 'photo_path', v_group.photo_path);
end $$;
revoke all on function public.update_group_details(uuid, text, text) from public, anon;
grant execute on function public.update_group_details(uuid, text, text) to authenticated;

-- Owner sets (after uploading to the group-photos bucket) or clears (null)
-- the group photo. The object must exist under "<group_id>/".
create or replace function public.set_group_photo(p_group_id uuid, p_path text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid; v_group public.groups;
begin
  v_uid := public.require_auth_uid();
  select * into v_group from public.groups where id = p_group_id for update;
  if not found then raise exception 'group_not_found' using errcode = 'P0001'; end if;
  if v_group.owner_id <> v_uid then raise exception 'forbidden' using errcode = 'P0001'; end if;
  if p_path is not null then
    if p_path !~ ('^' || p_group_id::text || '/[A-Za-z0-9._-]+$') or p_path like '%..%' then
      raise exception 'invalid_photo_path' using errcode = 'P0001';
    end if;
    if not exists (select 1 from storage.objects o
                   where o.bucket_id = 'group-photos' and o.name = p_path) then
      raise exception 'photo_not_found' using errcode = 'P0001';
    end if;
  end if;
  update public.groups set photo_path = p_path where id = p_group_id returning * into v_group;
  return jsonb_build_object('group_id', v_group.id, 'photo_path', v_group.photo_path);
end $$;
revoke all on function public.set_group_photo(uuid, text) from public, anon;
grant execute on function public.set_group_photo(uuid, text) to authenticated;
