-- 005_dashboard_functions (US1): authenticated members' dashboard read model.
-- All reads use one JSON shape consumed by the repository mappers.

create or replace function public.get_dashboard(p_group_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_group public.groups;
  v_membership_id uuid;
  v_role public.group_role;
  v_member_count int;
  v_day public.group_days;
  v_assignments jsonb;
  v_my_assignments jsonb;
  v_seats jsonb;
begin
  v_uid := public.require_auth_uid();

  select * into v_group
  from public.groups
  where id = p_group_id;
  if not found then
    raise exception 'group_not_found' using errcode = 'P0001';
  end if;

  select id, role into v_membership_id, v_role
  from public.group_memberships
  where group_id = p_group_id
    and user_id = v_uid
    and status = 'active';
  if not found then
    raise exception 'not_member' using errcode = 'P0001';
  end if;

  select count(*)::int into v_member_count
  from public.group_memberships
  where group_id = p_group_id and status = 'active';

  if v_group.status = 'forming' then
    select jsonb_build_object(
      'group_id', p_group_id,
      'active_member_count', v_member_count,
      'invite_code', v_group.invite_code,
      'members', coalesce((
        select jsonb_agg(jsonb_build_object(
          'membership_id', m.id,
          'display_name', p.display_name,
          'role', m.role,
          'seat_number', m.seat_number
        ) order by m.seat_number)
        from public.group_memberships m
        join public.profiles p on p.id = m.user_id
        where m.group_id = p_group_id and m.status = 'active'
      ), '[]'::jsonb)
    ) into v_seats;

    return jsonb_build_object(
      'group_id', v_group.id,
      'group_name', v_group.name,
      'my_role', v_role,
      'status', v_group.status,
      'server_generated_at', now(),
      'active_member_count', v_member_count,
      'invite_code', v_group.invite_code,
      'seats', v_seats
    );
  end if;

  if v_group.status = 'archived' then
    raise exception 'group_archived' using errcode = 'P0001';
  end if;

  perform public.ensure_current_group_day(p_group_id);
  select id into v_day.id
  from public.group_days
  where group_id = p_group_id
    and group_date = public.group_local_date(p_group_id, now());
  if not found then
    raise exception 'group_day_unavailable' using errcode = 'P0001';
  end if;
  perform public.recompute_day_counts(v_day.id);
  select * into v_day
  from public.group_days
  where group_id = p_group_id
    and group_date = public.group_local_date(p_group_id, now());
  if not found then
    raise exception 'group_day_unavailable' using errcode = 'P0001';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'assignment_id', a.id,
    'juz', a.juz,
    'seat_number', a.seat_number,
    'kind', a.kind,
    'status', a.status,
    'reader_display_name', p.display_name,
    'is_me', coalesce(a.reader_membership_id = v_membership_id, false),
    'is_khatm_juz', a.juz = 30,
    'completed_at', a.completed_at
  ) order by a.juz), '[]'::jsonb)
  into v_assignments
  from public.assignments a
  left join public.group_memberships m on m.id = a.reader_membership_id
  left join public.profiles p on p.id = m.user_id
  where a.group_day_id = v_day.id;

  select coalesce(jsonb_agg(jsonb_build_object(
    'assignment_id', a.id,
    'juz', a.juz,
    'seat_number', a.seat_number,
    'kind', a.kind,
    'status', a.status,
    'reader_display_name', p.display_name,
    'is_me', true,
    'is_khatm_juz', a.juz = 30,
    'completed_at', a.completed_at
  ) order by a.juz), '[]'::jsonb)
  into v_my_assignments
  from public.assignments a
  join public.group_memberships m on m.id = a.reader_membership_id
  join public.profiles p on p.id = m.user_id
  where a.group_day_id = v_day.id
    and a.reader_membership_id = v_membership_id;

  return jsonb_build_object(
    'group_id', v_group.id,
    'group_name', v_group.name,
    'my_role', v_role,
    'status', v_group.status,
    'server_generated_at', now(),
    'active_member_count', v_member_count,
    'invite_code', v_group.invite_code,
    'today', jsonb_build_object(
      'group_date', v_day.group_date,
      'state', v_day.state,
      'completed_count', v_day.completed_count,
      'late_count', v_day.late_count,
      'missed_count', v_day.missed_count,
      'unread_count', v_day.unread_count,
      'pending_count', v_day.pending_count,
      'available_count', v_day.available_count,
      'full_khatma', v_day.full_khatma,
      'ends_at', v_day.ends_at
    ),
    'my_assignments', v_my_assignments,
    'assignments', v_assignments
  );
end;
$$;

revoke all on function public.get_dashboard(uuid) from public, anon;
grant execute on function public.get_dashboard(uuid) to authenticated;
