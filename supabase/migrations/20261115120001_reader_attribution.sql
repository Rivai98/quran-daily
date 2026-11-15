-- Spec 007: reader attribution on the dashboard and history (additive JSON).
-- Every assignment row gains `reader` {user_id, display_name, initials} next
-- to the existing kind/status/completed_at fields; history days gain a
-- `portions` array visible to every member.
-- Visibility: owner/supervisor see everything. A regular member sees readers
-- of completed/late/volunteer/pending portions and always their own rows, but
-- another member's missed/unread portion comes back with reader = null,
-- reader_display_name = null and the neutral status 'unread'.
-- Emails are never read here (profiles only).

-- Avatar initials: first letter of the first word and of the last significant
-- word ("محمد عبد الله" -> "م ع"; compound prefixes such as عبد/أبو keep the
-- compound together); a single word gives one letter.
create or replace function public.display_initials(p_name text)
returns text language plpgsql immutable set search_path = '' as $$
declare v_words text[]; v_n int; v_last text;
begin
  v_words := array_remove(regexp_split_to_array(btrim(coalesce(p_name, '')), '\s+'), '');
  v_n := coalesce(array_length(v_words, 1), 0);
  if v_n = 0 then return null; end if;
  if v_n = 1 then return upper(left(v_words[1], 1)); end if;
  v_last := v_words[v_n];
  if v_words[v_n - 1] in ('عبد', 'أبو', 'ابو', 'أبي', 'ابي') then
    if v_n = 2 then return upper(left(v_words[1], 1)); end if;
    v_last := v_words[v_n - 1];
  end if;
  return upper(left(v_words[1], 1)) || ' ' || upper(left(v_last, 1));
end $$;
revoke all on function public.display_initials(text) from public, anon, authenticated;

create or replace function public.reader_json(p_user_id uuid, p_display_name text)
returns jsonb language sql immutable set search_path = '' as $$
  select case when p_user_id is null then null else jsonb_build_object(
    'user_id', p_user_id, 'display_name', p_display_name,
    'initials', public.display_initials(p_display_name)) end;
$$;
revoke all on function public.reader_json(uuid, text) from public, anon, authenticated;

-- True when the viewer must not learn who left this portion unread.
create or replace function public.reader_hidden(
  p_viewer_role public.group_role, p_status public.assignment_status,
  p_reader_user uuid, p_viewer uuid)
returns boolean language sql immutable set search_path = '' as $$
  select p_viewer_role not in ('owner', 'supervisor')
    and p_status in ('missed', 'unread')
    and p_reader_user is distinct from p_viewer;
$$;
revoke all on function public.reader_hidden(public.group_role, public.assignment_status, uuid, uuid)
  from public, anon, authenticated;

-- Dashboard base (latest: 20261115090005) + reader fields and visibility.
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
        'membership_id',m.id,'display_name',p.display_name,'role',m.role,'seat_number',m.seat_number) order by m.seat_number)
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

-- History day base (latest body: 20261115050001) + reader fields, portion_index
-- and a `portions` array for every member (per_juz stays manager-only).
create or replace function public.get_history_day_portion_base(p_group_id uuid, p_group_date date)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid;
  v_role public.group_role;
  v_day public.group_days%rowtype;
  v_my_result jsonb := null;
  v_per_juz jsonb := null;
  v_portions jsonb;
begin
  v_uid := public.require_auth_uid();
  if not exists (select 1 from public.groups where id = p_group_id) then
    raise exception 'group_not_found' using errcode = 'P0001';
  end if;
  select role into v_role from public.group_memberships
  where group_id = p_group_id and user_id = v_uid and status = 'active';
  if v_role is null then
    raise exception 'not_member' using errcode = 'P0001';
  end if;
  select * into v_day from public.group_days
  where group_id = p_group_id and group_date = p_group_date;
  if not found then
    raise exception 'day_not_found' using errcode = 'P0001';
  end if;

  select jsonb_build_object(
    'assignment_id', a.id, 'juz', a.juz, 'portion_index', a.portion_index,
    'seat_number', a.seat_number, 'kind', a.kind, 'status', a.status,
    'reader_display_name', p.display_name,
    'reader', public.reader_json(p.id, p.display_name),
    'is_me', true, 'completed_at', a.completed_at)
  into v_my_result
  from public.assignments a
  join public.group_memberships m on m.id = a.reader_membership_id
  join public.profiles p on p.id = m.user_id
  where a.group_day_id = v_day.id and m.user_id = v_uid
  order by (case when a.kind = 'seat' then 0 else 1 end)
  limit 1;

  select coalesce(jsonb_agg(jsonb_build_object(
    'assignment_id', a.id, 'juz', a.juz, 'portion_index', a.portion_index,
    'seat_number', a.seat_number, 'kind', a.kind,
    'status', case when h.hidden then 'unread'::public.assignment_status else a.status end,
    'reader_display_name', case when h.hidden then null else p.display_name end,
    'reader', case when h.hidden then null else public.reader_json(p.id, p.display_name) end,
    'is_me', coalesce(m.user_id = v_uid, false),
    'completed_at', a.completed_at) order by a.seat_number), '[]'::jsonb)
  into v_portions
  from public.assignments a
  left join public.group_memberships m on m.id = a.reader_membership_id
  left join public.profiles p on p.id = m.user_id
  cross join lateral (select public.reader_hidden(v_role, a.status, m.user_id, v_uid) as hidden) h
  where a.group_day_id = v_day.id;

  if v_role in ('owner', 'supervisor') then
    select coalesce(jsonb_agg(jsonb_build_object(
      'assignment_id', a.id, 'juz', a.juz, 'portion_index', a.portion_index,
      'seat_number', a.seat_number, 'kind', a.kind, 'status', a.status,
      'reader_display_name', p.display_name,
      'reader', public.reader_json(p.id, p.display_name),
      'is_me', (m.user_id = v_uid), 'completed_at', a.completed_at
    ) order by a.juz asc), '[]'::jsonb)
    into v_per_juz
    from public.assignments a
    left join public.group_memberships m on m.id = a.reader_membership_id
    left join public.profiles p on p.id = m.user_id
    where a.group_day_id = v_day.id;
  end if;

  return jsonb_build_object(
    'group_date', v_day.group_date::text,
    'completed_count', v_day.completed_count,
    'late_count', v_day.late_count,
    'missed_count', v_day.missed_count,
    'unread_count', v_day.unread_count,
    'full_khatma', v_day.full_khatma,
    'my_result', v_my_result,
    'per_juz', v_per_juz,
    'portions', v_portions);
end $$;
revoke all on function public.get_history_day_portion_base(uuid, date) from public, anon, authenticated;

-- History day wrapper (latest: 20261115090002); portion_index now comes from
-- the base rows, so the wrapper only adds the day's cycle fields.
create or replace function public.get_history_day(p_group_id uuid, p_group_date date)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_data jsonb; v_day public.group_days; v_uid uuid;
begin
  v_uid:=public.require_auth_uid();
  if not exists(select 1 from public.groups where id=p_group_id) then
    raise exception 'group_not_found' using errcode='P0001';
  end if;
  if not exists(select 1 from public.group_memberships where group_id=p_group_id and user_id=v_uid and status='active') then
    raise exception 'not_member' using errcode='P0001';
  end if;
  v_data:=public.get_history_day_portion_base(p_group_id,p_group_date);
  select * into v_day from public.group_days where group_id=p_group_id and group_date=p_group_date;
  return v_data || jsonb_build_object('portion_unit',v_day.portion_unit,'cycle_number',v_day.cycle_number,
    'cycle_day',v_day.cycle_day,'cycle_length',v_day.cycle_length);
end $$;
revoke all on function public.get_history_day(uuid,date) from public,anon;
grant execute on function public.get_history_day(uuid,date) to authenticated;
