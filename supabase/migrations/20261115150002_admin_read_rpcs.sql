-- 008 admin console (T004): read RPCs for the overview, groups, users and
-- the audit log. Every function calls public.require_app_admin() FIRST and
-- raises 'not_admin' (P0001) for anyone outside private.app_admins.
-- Emails (auth.users) are returned only here, i.e. only to admins (FR-007).

-- Escapes LIKE wildcards in a free-text search term (internal helper).
create or replace function public.like_search_pattern(p_query text)
returns text
language sql
immutable
set search_path = ''
as $$
  select '%' || replace(replace(replace(btrim(p_query), '\', '\\'), '%', '\%'), '_', '\_') || '%';
$$;
revoke all on function public.like_search_pattern(text) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- admin_overview(): US1 metrics, computed server-side
-- ---------------------------------------------------------------------------
create or replace function public.admin_overview()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_today date;
  v_today_start timestamptz;
  v_users jsonb;
  v_groups jsonb;
  v_progress jsonb;
  v_khatmas jsonb;
  v_series jsonb;
begin
  perform public.require_app_admin();
  v_today := (now() at time zone 'utc')::date;
  v_today_start := v_today::timestamp at time zone 'utc';

  select jsonb_build_object(
    'total', count(*),
    'new_7d', count(*) filter (where p.created_at >= now() - interval '7 days'),
    'new_30d', count(*) filter (where p.created_at >= now() - interval '30 days'),
    'suspended', count(*) filter (where p.suspended_at is not null),
    'admins', (select count(*) from private.app_admins),
    'active_today', (select count(distinct x.uid) from (
        select cr.actor_user_id as uid from public.completion_records cr
        where cr.recorded_at >= v_today_start
        union
        select m.user_id from public.group_memberships m
        where m.last_opened_at >= v_today_start) x))
  into v_users
  from public.profiles p;

  select jsonb_build_object(
    'total', count(*),
    'forming', count(*) filter (where g.status = 'forming'),
    'active', count(*) filter (where g.status = 'active'),
    'archived', count(*) filter (where g.status = 'archived'))
  into v_groups
  from public.groups g;

  -- Today's progress across active groups, each on its own local day.
  select jsonb_build_object(
    'groups', count(distinct d.id),
    'total', count(a.id),
    'done', count(a.id) filter (where a.status in ('completed', 'late')),
    'rate_percent', case when count(a.id) = 0 then null
      else round(100.0 * count(a.id) filter (where a.status in ('completed', 'late'))
                 / count(a.id))::int end)
  into v_progress
  from public.groups g
  join public.group_days d
    on d.group_id = g.id
   and d.group_date = date((now() at time zone g.timezone) - g.day_start_time)
  left join public.assignments a on a.group_day_id = d.id
  where g.status = 'active';

  select jsonb_build_object(
    'total', count(*),
    'last_7d', count(*) filter (where d.group_date > v_today - 7),
    'last_30d', count(*) filter (where d.group_date > v_today - 30))
  into v_khatmas
  from public.group_days d
  where d.full_khatma;

  select coalesce(jsonb_agg(jsonb_build_object(
      'date', s.day::date, 'completed', coalesce(c.n, 0)) order by s.day), '[]'::jsonb)
  into v_series
  from generate_series(v_today - 29, v_today, interval '1 day') as s(day)
  left join (
    select (a.completed_at at time zone 'utc')::date as day, count(*) as n
    from public.assignments a
    where a.status in ('completed', 'late')
      and a.completed_at >= (v_today - 29)::timestamp at time zone 'utc'
    group by 1) c on c.day = s.day::date;

  return jsonb_build_object(
    'generated_at', now(),
    'users', v_users,
    'groups', v_groups,
    'today', v_progress,
    'khatmas', v_khatmas,
    'series', v_series);
end;
$$;

-- ---------------------------------------------------------------------------
-- Groups
-- ---------------------------------------------------------------------------
create or replace function public.admin_list_groups(
  p_query text default null,
  p_status text default null,
  p_limit int default 50,
  p_offset int default 0)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_q text := nullif(btrim(coalesce(p_query, '')), '');
  v_limit int := least(greatest(coalesce(p_limit, 50), 1), 200);
  v_offset int := greatest(coalesce(p_offset, 0), 0);
  v_total int;
  v_items jsonb;
begin
  perform public.require_app_admin();
  if p_status is not null and p_status not in ('forming', 'active', 'archived') then
    raise exception 'validation_failed' using errcode = 'P0001';
  end if;

  select count(*) into v_total
  from public.groups g
  where (p_status is null or g.status::text = p_status)
    and (v_q is null or g.name ilike public.like_search_pattern(v_q)
         or g.invite_code = upper(v_q));

  select coalesce(jsonb_agg(x.item order by x.created_at desc, x.id), '[]'::jsonb)
  into v_items
  from (
    select g.id, g.created_at, jsonb_build_object(
      'id', g.id,
      'name', g.name,
      'status', g.status,
      'visibility', g.visibility,
      'join_mode', g.join_mode,
      'portion_unit', g.portion_unit,
      'invite_code', g.invite_code,
      'owner_id', g.owner_id,
      'owner_name', p.display_name,
      'member_count', (select count(*) from public.group_memberships m
                       where m.group_id = g.id and m.status = 'active'),
      'created_at', g.created_at) as item
    from public.groups g
    join public.profiles p on p.id = g.owner_id
    where (p_status is null or g.status::text = p_status)
      and (v_q is null or g.name ilike public.like_search_pattern(v_q)
           or g.invite_code = upper(v_q))
    order by g.created_at desc, g.id
    limit v_limit offset v_offset) x;

  return jsonb_build_object('total', v_total, 'items', v_items);
end;
$$;

create or replace function public.admin_group_detail(p_group_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_group public.groups;
  v_local date;
  v_today jsonb;
begin
  perform public.require_app_admin();
  select * into v_group from public.groups where id = p_group_id;
  if not found then
    raise exception 'group_not_found' using errcode = 'P0001';
  end if;
  v_local := date((now() at time zone v_group.timezone) - v_group.day_start_time);

  select jsonb_build_object(
    'day_id', d.id,
    'group_date', d.group_date,
    'state', d.state,
    'total', count(a.id),
    'done', count(a.id) filter (where a.status in ('completed', 'late')),
    'completed', count(a.id) filter (where a.status = 'completed'),
    'late', count(a.id) filter (where a.status = 'late'),
    'pending', count(a.id) filter (where a.status = 'pending'),
    'available', count(a.id) filter (where a.status = 'available'),
    'missed', count(a.id) filter (where a.status = 'missed'),
    'unread', count(a.id) filter (where a.status = 'unread'),
    'rate_percent', case when count(a.id) = 0 then null
      else round(100.0 * count(a.id) filter (where a.status in ('completed', 'late'))
                 / count(a.id))::int end)
  into v_today
  from public.group_days d
  left join public.assignments a on a.group_day_id = d.id
  where d.group_id = p_group_id and d.group_date = v_local
  group by d.id, d.group_date, d.state;

  return jsonb_build_object(
    'group', jsonb_build_object(
      'id', v_group.id,
      'name', v_group.name,
      'short_description', v_group.short_description,
      'status', v_group.status,
      'visibility', v_group.visibility,
      'join_mode', v_group.join_mode,
      'portion_unit', v_group.portion_unit,
      'timezone', v_group.timezone,
      'day_start_time', v_group.day_start_time,
      'start_date', v_group.start_date,
      'invite_code', v_group.invite_code,
      'owner_id', v_group.owner_id,
      'owner_name', (select display_name from public.profiles where id = v_group.owner_id),
      'created_at', v_group.created_at,
      'pending_requests', (select count(*) from public.join_requests r
                           where r.group_id = p_group_id and r.status = 'pending')),
    'members', coalesce((
      select jsonb_agg(jsonb_build_object(
        'membership_id', m.id,
        'user_id', m.user_id,
        'display_name', p.display_name,
        'role', m.role,
        'seat_number', m.seat_number,
        'joined_at', m.joined_at,
        'last_opened_at', m.last_opened_at,
        'suspended', p.suspended_at is not null) order by m.seat_number)
      from public.group_memberships m
      join public.profiles p on p.id = m.user_id
      where m.group_id = p_group_id and m.status = 'active'), '[]'::jsonb),
    'today', v_today);
end;
$$;

-- ---------------------------------------------------------------------------
-- Users
-- ---------------------------------------------------------------------------
-- One user row as the console sees it (internal; called by admin RPCs only).
create or replace function public.user_admin_json(p_user_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'id', p.id,
    'display_name', p.display_name,
    'email', u.email,
    'created_at', p.created_at,
    'last_sign_in_at', u.last_sign_in_at,
    'last_activity_at', greatest(u.last_sign_in_at,
      (select max(cr.recorded_at) from public.completion_records cr where cr.actor_user_id = p.id),
      (select max(m.last_opened_at) from public.group_memberships m where m.user_id = p.id)),
    'groups_count', (select count(*) from public.group_memberships m
                     where m.user_id = p.id and m.status = 'active'),
    'is_admin', exists (select 1 from private.app_admins a where a.user_id = p.id),
    'suspended_at', p.suspended_at,
    'status', case when p.suspended_at is null then 'active' else 'suspended' end)
  from public.profiles p
  left join auth.users u on u.id = p.id
  where p.id = p_user_id;
$$;
revoke all on function public.user_admin_json(uuid) from public, anon, authenticated;

create or replace function public.admin_list_users(
  p_query text default null,
  p_status text default null,
  p_limit int default 50,
  p_offset int default 0)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_q text := nullif(btrim(coalesce(p_query, '')), '');
  v_limit int := least(greatest(coalesce(p_limit, 50), 1), 200);
  v_offset int := greatest(coalesce(p_offset, 0), 0);
  v_total int;
  v_items jsonb;
begin
  perform public.require_app_admin();
  if p_status is not null and p_status not in ('active', 'suspended', 'admin') then
    raise exception 'validation_failed' using errcode = 'P0001';
  end if;

  with hits as (
    select p.id, p.created_at
    from public.profiles p
    left join auth.users u on u.id = p.id
    where (v_q is null or p.display_name ilike public.like_search_pattern(v_q)
           or u.email ilike public.like_search_pattern(v_q))
      and (p_status is null
           or (p_status = 'active' and p.suspended_at is null)
           or (p_status = 'suspended' and p.suspended_at is not null)
           or (p_status = 'admin' and exists (
                 select 1 from private.app_admins a where a.user_id = p.id)))),
  page as (
    select h.id, h.created_at from hits h
    order by h.created_at desc, h.id limit v_limit offset v_offset)
  select (select count(*) from hits),
         coalesce((select jsonb_agg(public.user_admin_json(pg.id) order by pg.created_at desc, pg.id)
                   from page pg), '[]'::jsonb)
  into v_total, v_items;

  return jsonb_build_object('total', v_total, 'items', v_items);
end;
$$;

create or replace function public.admin_user_detail(p_user_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user jsonb;
begin
  perform public.require_app_admin();
  v_user := public.user_admin_json(p_user_id);
  if v_user is null then
    raise exception 'user_not_found' using errcode = 'P0001';
  end if;

  return jsonb_build_object(
    'user', v_user || jsonb_build_object(
      'owned_groups_count', (select count(*) from public.groups g where g.owner_id = p_user_id)),
    'groups', coalesce((
      select jsonb_agg(jsonb_build_object(
        'membership_id', m.id,
        'group_id', g.id,
        'group_name', g.name,
        'group_status', g.status,
        'role', m.role,
        'membership_status', m.status,
        'seat_number', m.seat_number,
        'joined_at', m.joined_at,
        'ended_at', m.ended_at) order by (m.status = 'active') desc, m.joined_at desc)
      from public.group_memberships m
      join public.groups g on g.id = m.group_id
      where m.user_id = p_user_id), '[]'::jsonb));
end;
$$;

-- ---------------------------------------------------------------------------
-- Audit log (the ONLY read path to private.admin_audit)
-- ---------------------------------------------------------------------------
create or replace function public.admin_list_audit(
  p_action text default null,
  p_limit int default 50,
  p_offset int default 0)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_action text := nullif(btrim(coalesce(p_action, '')), '');
  v_limit int := least(greatest(coalesce(p_limit, 50), 1), 200);
  v_offset int := greatest(coalesce(p_offset, 0), 0);
begin
  perform public.require_app_admin();

  return jsonb_build_object(
    'total', (select count(*) from private.admin_audit l
              where v_action is null or l.action = v_action),
    'items', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', x.id,
        'action', x.action,
        'actor_user_id', x.actor_user_id,
        'actor_name', x.actor_name,
        'target_user_id', x.target_user_id,
        'target_name', x.target_name,
        'target_group_id', x.target_group_id,
        'target_label', x.target_label,
        'result', x.result,
        'details', x.details,
        'created_at', x.created_at) order by x.created_at desc, x.id)
      from (
        select l.*, pa.display_name as actor_name, pt.display_name as target_name
        from private.admin_audit l
        left join public.profiles pa on pa.id = l.actor_user_id
        left join public.profiles pt on pt.id = l.target_user_id
        where v_action is null or l.action = v_action
        order by l.created_at desc, l.id
        limit v_limit offset v_offset) x), '[]'::jsonb));
end;
$$;

-- ---------------------------------------------------------------------------
-- Grants: authenticated may call; the in-function guard decides.
-- ---------------------------------------------------------------------------
revoke all on function public.admin_overview() from public, anon;
revoke all on function public.admin_list_groups(text, text, int, int) from public, anon;
revoke all on function public.admin_group_detail(uuid) from public, anon;
revoke all on function public.admin_list_users(text, text, int, int) from public, anon;
revoke all on function public.admin_user_detail(uuid) from public, anon;
revoke all on function public.admin_list_audit(text, int, int) from public, anon;
grant execute on function public.admin_overview() to authenticated;
grant execute on function public.admin_list_groups(text, text, int, int) to authenticated;
grant execute on function public.admin_group_detail(uuid) to authenticated;
grant execute on function public.admin_list_users(text, text, int, int) to authenticated;
grant execute on function public.admin_user_detail(uuid) to authenticated;
grant execute on function public.admin_list_audit(text, int, int) to authenticated;
