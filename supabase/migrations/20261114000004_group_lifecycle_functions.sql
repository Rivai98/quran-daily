-- 003_group_lifecycle_functions (spec 001 US2)
create extension if not exists pgcrypto with schema extensions;
-- create_group, update_group_settings, start_khatma, ensure_current_group_day,
-- generate_due_group_days, get_my_groups, regenerate_invite, move_member_seat
-- (forming groups; US6 extends it to active groups).
-- SECURITY DEFINER, SET search_path = '', role checks inside.

-- ---------------------------------------------------------------------------
-- Shared helpers
-- ---------------------------------------------------------------------------
create or replace function public.require_auth_uid()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare v_uid uuid;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'unauthenticated' using errcode = 'P0001';
  end if;
  return v_uid;
end;
$$;

-- Deterministic 8-char code from the unambiguous alphabet (R9).
create or replace function public.new_invite_code()
returns text
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_alphabet text := '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  v_code text := '';
  i int;
  v_bytes bytea;
begin
  v_bytes := extensions.gen_random_bytes(8);
  for i in 1..8 loop
    v_code := v_code || substr(v_alphabet,
      ((get_byte(v_bytes, i - 1) % 32) + 1), 1);
  end loop;
  return v_code;
end;
$$;

-- ---------------------------------------------------------------------------
-- create_group (supabase-rpc contract)
-- ---------------------------------------------------------------------------
create or replace function public.create_group(
  p_name text,
  p_short_description text,
  p_timezone text,
  p_day_start_time time,
  p_visibility public.group_visibility,
  p_join_mode public.join_mode
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_name text;
  v_desc text;
  v_group_id uuid;
  v_code text;
begin
  v_uid := public.require_auth_uid();

  v_name := btrim(coalesce(p_name, ''));
  v_desc := btrim(coalesce(p_short_description, ''));

  if length(v_name) < 3 or length(v_name) > 60 then
    raise exception 'validation_failed' using errcode = 'P0001';
  end if;
  if length(v_desc) > 200 then
    raise exception 'validation_failed' using errcode = 'P0001';
  end if;
  if p_timezone is null
     or not exists (select 1 from pg_timezone_names where name = p_timezone) then
    raise exception 'validation_failed' using errcode = 'P0001';
  end if;

  -- FR-002: at most 3 non-archived owned groups
  if (select count(*) from public.groups
      where owner_id = v_uid and status <> 'archived') >= 3 then
    raise exception 'owner_group_limit' using errcode = 'P0001';
  end if;

  v_group_id := gen_random_uuid();
  loop
    v_code := public.new_invite_code();
    exit when not exists (
      select 1 from public.groups
      where invite_code = v_code and status <> 'archived');
  end loop;

  insert into public.groups (id, name, short_description, owner_id, timezone,
                             day_start_time, visibility, join_mode,
                             status, invite_code)
  values (v_group_id, v_name, v_desc, v_uid, p_timezone,
          coalesce(p_day_start_time, '00:00'), p_visibility, p_join_mode,
          'forming', v_code);

  insert into public.group_memberships (group_id, user_id, role, status, seat_number)
  values (v_group_id, v_uid, 'owner', 'active', 1);

  return jsonb_build_object('group_id', v_group_id, 'invite_code', v_code);
end;
$$;

grant execute on function public.create_group(text, text, text, time,
  public.group_visibility, public.join_mode) to authenticated;

-- ---------------------------------------------------------------------------
-- update_group_settings (owner only; tz/start-time changes apply next day)
-- ---------------------------------------------------------------------------
create or replace function public.update_group_settings(
  p_group_id uuid,
  p_name text default null,
  p_short_description text default null,
  p_timezone text default null,
  p_day_start_time time default null,
  p_visibility public.group_visibility default null,
  p_join_mode public.join_mode default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_group public.groups;
begin
  v_uid := public.require_auth_uid();

  select * into v_group from public.groups where id = p_group_id;
  if not found then
    raise exception 'group_not_found' using errcode = 'P0001';
  end if;
  if v_group.owner_id <> v_uid then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;

  if p_name is not null then
    if length(btrim(p_name)) < 3 or length(btrim(p_name)) > 60 then
      raise exception 'validation_failed' using errcode = 'P0001';
    end if;
    update public.groups set name = btrim(p_name) where id = p_group_id;
  end if;

  if p_short_description is not null then
    if length(btrim(p_short_description)) > 200 then
      raise exception 'validation_failed' using errcode = 'P0001';
    end if;
    update public.groups set short_description = btrim(p_short_description)
    where id = p_group_id;
  end if;

  if p_timezone is not null then
    if not exists (select 1 from pg_timezone_names where name = p_timezone) then
      raise exception 'validation_failed' using errcode = 'P0001';
    end if;
    update public.groups set timezone = p_timezone where id = p_group_id;
  end if;

  if p_day_start_time is not null then
    update public.groups set day_start_time = p_day_start_time
    where id = p_group_id;
  end if;

  if p_visibility is not null then
    update public.groups set visibility = p_visibility where id = p_group_id;
  end if;

  if p_join_mode is not null then
    update public.groups set join_mode = p_join_mode where id = p_group_id;
  end if;

  select jsonb_build_object(
    'group_id', g.id, 'name', g.name, 'status', g.status,
    'my_role', 'owner', 'active_member_count',
      (select count(*) from public.group_memberships m
       where m.group_id = g.id and m.status = 'active')
  )
  into v_group
  from public.groups g where g.id = p_group_id;

  return to_jsonb(v_group);
end;
$$;

grant execute on function public.update_group_settings(uuid, text, text,
  text, time, public.group_visibility, public.join_mode) to authenticated;

-- ---------------------------------------------------------------------------
-- start_khatma (owner only; forming only; >= 1 active member)
-- ---------------------------------------------------------------------------
create or replace function public.start_khatma(
  p_group_id uuid, p_start_juz int default 1)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_group public.groups;
  v_member_count int;
  v_day_id uuid;
begin
  v_uid := public.require_auth_uid();

  select * into v_group from public.groups where id = p_group_id;
  if not found then
    raise exception 'group_not_found' using errcode = 'P0001';
  end if;
  if v_group.owner_id <> v_uid then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;
  if v_group.status <> 'forming' then
    raise exception 'group_not_forming' using errcode = 'P0001';
  end if;
  if p_start_juz is null or p_start_juz < 1 or p_start_juz > 30 then
    raise exception 'validation_failed' using errcode = 'P0001';
  end if;

  select count(*) into v_member_count
  from public.group_memberships
  where group_id = p_group_id and status = 'active';
  if v_member_count < 1 then
    raise exception 'validation_failed' using errcode = 'P0001';
  end if;

  update public.groups
  set status = 'active',
      start_juz = p_start_juz,
      start_date = public.group_local_date(p_group_id, now())
  where id = p_group_id;

  v_day_id := public.ensure_current_group_day(p_group_id);

  return jsonb_build_object(
    'group_id', v_group.id,
    'group_name', v_group.name,
    'my_role', 'owner',
    'status', 'active',
    'server_generated_at', now(),
    'active_member_count', v_member_count,
    'invite_code', v_group.invite_code,
    'today', true
  );
end;
$$;

grant execute on function public.start_khatma(uuid, int) to authenticated;

-- ---------------------------------------------------------------------------
-- ensure_current_group_day: idempotent day creation with full backfill
-- (research R7/U2: rotation computed from the DATE INDEX so history has
-- no gaps; past days get grace/closed states applied immediately)
-- ---------------------------------------------------------------------------
create or replace function public.ensure_current_group_day(
  p_group_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_group public.groups;
  v_today date;
  v_last date;
  v_day_id uuid;
  v_idx int;
  v_missing date;
begin
  select * into v_group from public.groups where id = p_group_id;
  if not found or v_group.status <> 'active' then
    return null;
  end if;

  v_today := public.group_local_date(p_group_id, now());
  select max(group_date) into v_last
  from public.group_days where group_id = p_group_id;

  if v_last is not null and v_last >= v_today then
    -- current day already exists (or we are somehow behind); return it
    select id into v_day_id from public.group_days
    where group_id = p_group_id and group_date = v_today;
    if v_day_id is not null then
      return v_day_id;
    end if;
  end if;

  -- backfill every missing date since the last existing day (or today)
  v_missing := coalesce(v_last, v_today - 1);
  while v_missing < v_today loop
    v_missing := v_missing + 1;
    v_idx := (v_missing - v_group.start_date);

    insert into public.group_days (
      group_id, group_date, day_index, opens_at, ends_at, closes_at, state)
    values (
      p_group_id, v_missing, v_idx,
      v_missing::timestamptz + v_group.day_start_time,
      (v_missing + 1)::timestamptz + v_group.day_start_time,
      (v_missing + 2)::timestamptz + v_group.day_start_time,
      case
        when v_missing < v_today then 'closed'::public.day_state
        else 'open'::public.day_state
      end
    )
    on conflict (group_id, group_date) do nothing
    returning id into v_day_id;

    if v_day_id is not null then
      perform public.create_day_assignments(v_day_id, p_group_id, v_idx);
      if v_missing < v_today then
        -- past day: missed/unread states applied immediately (R6)
        perform public.freeze_day_states(v_day_id, 'closed');
      end if;
    end if;
  end loop;

  select id into v_day_id from public.group_days
  where group_id = p_group_id and group_date = v_today;
  return v_day_id;
end;
$$;

grant execute on function public.ensure_current_group_day(uuid) to authenticated;

-- 30 assignment rows for one day from the seats (R4): occupied seat ->
-- seat/pending; empty seat -> unassigned/available; juz = juz_for_seat.
create or replace function public.create_day_assignments(
  p_day_id uuid, p_group_id uuid, p_day_index int)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_start_juz smallint;
begin
  select start_juz into v_start_juz from public.groups where id = p_group_id;
  if v_start_juz is null then
    raise exception 'validation_failed' using errcode = 'P0001';
  end if;

  insert into public.assignments (
    group_day_id, juz, seat_number, kind, reader_membership_id, status)
  select
    p_day_id,
    public.juz_for_seat(s, v_start_juz, p_day_index)::smallint,
    s::smallint,
    (case when m.id is null then 'unassigned' else 'seat' end)::public.assignment_kind,
    m.id,
    (case when m.id is null then 'available' else 'pending' end)::public.assignment_status
  from generate_series(1, 30) s
  left join public.group_memberships m
    on m.group_id = p_group_id and m.seat_number = s and m.status = 'active'
  on conflict (group_day_id, seat_number) do nothing;
end;
$$;

-- apply non-open states + recompute counts/full_khatma (R6)
create or replace function public.freeze_day_states(
  p_day_id uuid, p_target public.day_state)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_target = 'closed' then
    update public.assignments
    set status = case when status = 'pending' then 'missed'
                      when status = 'available' then 'unread'
                      else status end
    where group_day_id = p_day_id and status in ('pending', 'available');
    update public.group_days set state = 'closed' where id = p_day_id;
  elsif p_target = 'grace' then
    update public.assignments
    set status = case when status = 'pending' then 'missed'
                      when status = 'available' then 'unread'
                      else status end
    where group_day_id = p_day_id and status in ('pending', 'available');
    update public.group_days set state = 'grace' where id = p_day_id;
  end if;

  perform public.recompute_day_counts(p_day_id);
end;
$$;

create or replace function public.recompute_day_counts(p_day_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.group_days d
  set completed_count = c.completed,
      late_count = c.late,
      missed_count = c.missed,
      unread_count = c.unread,
      pending_count = c.pending,
      available_count = c.available,
      full_khatma = (c.completed + c.late) = 30
  from (
    select
      count(*) filter (where status = 'completed') as completed,
      count(*) filter (where status = 'late') as late,
      count(*) filter (where status = 'missed') as missed,
      count(*) filter (where status = 'unread') as unread,
      count(*) filter (where status = 'pending') as pending,
      count(*) filter (where status = 'available') as available
    from public.assignments
    where group_day_id = p_day_id
  ) c
  where d.id = p_day_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- generate_due_group_days: pg_cron target over all active groups (R3)
-- ---------------------------------------------------------------------------
create or replace function public.generate_due_group_days()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  g record;
begin
  for g in
    select id from public.groups where status = 'active'
  loop
    perform public.ensure_current_group_day(g.id);
  end loop;
  -- advance_day_states() is scheduled separately (migration 006).
end;
$$;

-- ---------------------------------------------------------------------------
-- get_my_groups: active memberships + own pending requests (S1 feed)
-- ---------------------------------------------------------------------------
create or replace function public.get_my_groups()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_groups jsonb;
  v_pending jsonb;
begin
  v_uid := public.require_auth_uid();

  select coalesce(jsonb_agg(x), '[]'::jsonb) into v_groups
  from (
    select jsonb_build_object(
      'group_id', g.id,
      'name', g.name,
      'status', g.status,
      'my_role', m.role,
      'active_member_count',
        (select count(*) from public.group_memberships mm
         where mm.group_id = g.id and mm.status = 'active'),
      'today_my_assignment', (
        select jsonb_build_object(
          'assignment_id', a.id, 'juz', a.juz, 'status', a.status)
        from public.assignments a
        join public.group_days d on d.id = a.group_day_id
        join public.group_memberships me
          on me.id = a.reader_membership_id
        where d.group_id = g.id and d.state = 'open'
          and me.user_id = v_uid
        order by d.group_date desc limit 1
      )
    ) x
    from public.group_memberships m
    join public.groups g on g.id = m.group_id
    where m.user_id = v_uid and m.status = 'active'
    order by g.created_at
  ) rows;

  select coalesce(jsonb_agg(x), '[]'::jsonb) into v_pending
  from (
    select jsonb_build_object(
      'join_request_id', j.id,
      'group_id', j.group_id,
      'group_name', g.name,
      'requested_at', j.requested_at,
      'source', j.source
    ) x
    from public.join_requests j
    join public.groups g on g.id = j.group_id
    where j.user_id = v_uid and j.status = 'pending'
    order by j.requested_at
  ) rows;

  return jsonb_build_object('groups', v_groups, 'pending_requests', v_pending);
end;
$$;

grant execute on function public.get_my_groups() to authenticated;

-- ---------------------------------------------------------------------------
-- regenerate_invite (owner only; old code stops working)
-- ---------------------------------------------------------------------------
create or replace function public.regenerate_invite(p_group_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_owner uuid;
  v_code text;
begin
  v_uid := public.require_auth_uid();
  select owner_id into v_owner from public.groups where id = p_group_id;
  if not found then
    raise exception 'group_not_found' using errcode = 'P0001';
  end if;
  if v_owner <> v_uid then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;

  loop
    v_code := public.new_invite_code();
    exit when not exists (
      select 1 from public.groups
      where invite_code = v_code and status <> 'archived');
  end loop;

  update public.groups set invite_code = v_code where id = p_group_id;
  return jsonb_build_object('invite_code', v_code);
end;
$$;

grant execute on function public.regenerate_invite(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- move_member_seat: forming groups now (US2 acceptance 5); US6 extends to
-- active groups (swap when target occupied).
-- ---------------------------------------------------------------------------
create or replace function public.move_member_seat(
  p_group_id uuid, p_membership_id uuid, p_target_seat smallint)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_group public.groups;
  v_mover uuid;
  v_source smallint;
begin
  v_uid := public.require_auth_uid();

  select * into v_group from public.groups where id = p_group_id;
  if not found then
    raise exception 'group_not_found' using errcode = 'P0001';
  end if;
  if v_group.owner_id <> v_uid then
    if not exists (
      select 1 from public.group_memberships
      where group_id = p_group_id and user_id = v_uid
        and role = 'supervisor' and status = 'active'
    ) then
      raise exception 'forbidden' using errcode = 'P0001';
    end if;
  end if;

  if p_target_seat < 1 or p_target_seat > 30 then
    raise exception 'validation_failed' using errcode = 'P0001';
  end if;

  -- in forming groups moves are immediate; active groups apply next day
  -- (already-materialized rows keep today; FR-007) — US6 overrides rows.
  select user_id, seat_number into v_mover, v_source
  from public.group_memberships
  where id = p_membership_id and group_id = p_group_id
    and status = 'active';
  if not found then
    raise exception 'validation_failed' using errcode = 'P0001';
  end if;

  if exists (
    select 1 from public.group_memberships
    where group_id = p_group_id and seat_number = p_target_seat
      and status = 'active' and id <> p_membership_id
  ) then
    -- swap the two members
    update public.group_memberships
    set seat_number = v_source
    where group_id = p_group_id and seat_number = p_target_seat
      and status = 'active' and id <> p_membership_id;
  end if;

  update public.group_memberships
  set seat_number = p_target_seat
  where id = p_membership_id;

  return jsonb_build_object('membership_id', p_membership_id,
                            'seat_number', p_target_seat);
end;
$$;

grant execute on function public.move_member_seat(uuid, uuid, smallint)
  to authenticated;
