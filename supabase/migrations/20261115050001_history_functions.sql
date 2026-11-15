-- 20261115050001_history_functions.sql (US7)
-- Functions: get_history, get_history_day
-- SECURITY DEFINER, SET search_path = '', role checks inside.

-- ---------------------------------------------------------------------------
-- get_history: list past days summaries (members)
-- ---------------------------------------------------------------------------
create or replace function public.get_history(
  p_group_id uuid,
  p_before_date date default null,
  p_limit int default 30
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_limit int;
  v_days jsonb;
begin
  v_uid := public.require_auth_uid();

  -- Group must exist
  if not exists (select 1 from public.groups where id = p_group_id) then
    raise exception 'group_not_found' using errcode = 'P0001';
  end if;

  -- Caller must be an active member
  if not exists (
    select 1 from public.group_memberships
    where group_id = p_group_id and user_id = v_uid and status = 'active'
  ) then
    raise exception 'not_member' using errcode = 'P0001';
  end if;

  v_limit := least(greatest(coalesce(p_limit, 30), 1), 60);

  select coalesce(jsonb_agg(d_json), '[]'::jsonb)
  into v_days
  from (
    select jsonb_build_object(
      'group_date', d.group_date::text,
      'completed_count', d.completed_count,
      'late_count', d.late_count,
      'missed_count', d.missed_count,
      'unread_count', d.unread_count,
      'full_khatma', d.full_khatma,
      'my_result', (
        select jsonb_build_object(
          'assignment_id', a.id,
          'juz', a.juz,
          'seat_number', a.seat_number,
          'kind', a.kind,
          'status', a.status,
          'reader_display_name', p.display_name,
          'is_me', true,
          'completed_at', a.completed_at
        )
        from public.assignments a
        join public.group_memberships m on m.id = a.reader_membership_id
        join public.profiles p on p.id = m.user_id
        where a.group_day_id = d.id and m.user_id = v_uid
        order by (case when a.kind = 'seat' then 0 else 1 end)
        limit 1
      )
    ) as d_json
    from public.group_days d
    where d.group_id = p_group_id
      and (p_before_date is null or d.group_date < p_before_date)
    order by d.group_date desc
    limit v_limit
  ) s;

  return v_days;
end;
$$;

revoke execute on function public.get_history(uuid, date, int) from public;
grant execute on function public.get_history(uuid, date, int) to authenticated;

-- ---------------------------------------------------------------------------
-- get_history_day: day detail (per-member rows for owner/supervisor, own row for member)
-- ---------------------------------------------------------------------------
create or replace function public.get_history_day(
  p_group_id uuid,
  p_group_date date
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_role public.group_role;
  v_day public.group_days%rowtype;
  v_my_result jsonb := null;
  v_per_juz jsonb := null;
begin
  v_uid := public.require_auth_uid();

  -- Group must exist
  if not exists (select 1 from public.groups where id = p_group_id) then
    raise exception 'group_not_found' using errcode = 'P0001';
  end if;

  -- Caller must be an active member; get their role
  select role into v_role
  from public.group_memberships
  where group_id = p_group_id and user_id = v_uid and status = 'active';

  if v_role is null then
    raise exception 'not_member' using errcode = 'P0001';
  end if;

  -- Day must exist
  select * into v_day
  from public.group_days
  where group_id = p_group_id and group_date = p_group_date;

  if not found then
    raise exception 'day_not_found' using errcode = 'P0001';
  end if;

  -- Caller's own assignment for this day
  select jsonb_build_object(
    'assignment_id', a.id,
    'juz', a.juz,
    'seat_number', a.seat_number,
    'kind', a.kind,
    'status', a.status,
    'reader_display_name', p.display_name,
    'is_me', true,
    'completed_at', a.completed_at
  )
  into v_my_result
  from public.assignments a
  join public.group_memberships m on m.id = a.reader_membership_id
  join public.profiles p on p.id = m.user_id
  where a.group_day_id = v_day.id and m.user_id = v_uid
  order by (case when a.kind = 'seat' then 0 else 1 end)
  limit 1;

  -- If owner or supervisor, populate per_juz
  if v_role in ('owner', 'supervisor') then
    select coalesce(jsonb_agg(
      jsonb_build_object(
        'assignment_id', a.id,
        'juz', a.juz,
        'seat_number', a.seat_number,
        'kind', a.kind,
        'status', a.status,
        'reader_display_name', p.display_name,
        'is_me', (m.user_id = v_uid),
        'completed_at', a.completed_at
      ) order by a.juz asc
    ), '[]'::jsonb)
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
    'per_juz', v_per_juz
  );
end;
$$;

revoke execute on function public.get_history_day(uuid, date) from public;
grant execute on function public.get_history_day(uuid, date) to authenticated;
