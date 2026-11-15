-- US3 completion RPCs and scheduled day-state transitions.

create or replace function public.mark_assignment_complete(
  p_assignment_id uuid,
  p_client_recorded_at timestamptz,
  p_source public.completion_source default 'online'
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_assignment public.assignments;
  v_day public.group_days;
  v_effective_at timestamptz;
  v_status public.assignment_status;
begin
  v_uid := public.require_auth_uid();

  select a, d into v_assignment, v_day
  from public.assignments a
  join public.group_days d on d.id = a.group_day_id
  where a.id = p_assignment_id
  for update of a, d;
  if not found then
    raise exception 'assignment_not_found' using errcode = 'P0001';
  end if;

  if not exists (
    select 1 from public.group_memberships m
    where m.id = v_assignment.reader_membership_id
      and m.user_id = v_uid and m.group_id = v_day.group_id
      and m.status = 'active'
  ) then
    raise exception 'not_reader' using errcode = 'P0001';
  end if;

  if p_source is null or p_source not in ('online', 'offline_sync') then
    raise exception 'validation_failed' using errcode = 'P0001';
  end if;
  v_effective_at := case when p_source = 'online' then now()
    else greatest(v_day.opens_at, least(coalesce(p_client_recorded_at, now()), now()))
  end;

  if v_day.state = 'closed' or now() >= v_day.closes_at then
    raise exception 'day_closed' using errcode = 'P0001';
  end if;

  if v_assignment.status in ('completed', 'late') then
    perform public.recompute_day_counts(v_day.id);
    return jsonb_build_object(
      'assignment_id', v_assignment.id, 'status', v_assignment.status,
      'completed_at', v_assignment.completed_at,
      'day_counts', (select to_jsonb(d) from public.group_days d where d.id = v_day.id));
  end if;

  if v_effective_at >= v_day.ends_at then
    v_status := 'late';
  else
    v_status := 'completed';
  end if;

  if v_assignment.status not in ('pending', 'missed') then
    raise exception 'day_closed' using errcode = 'P0001';
  end if;

  update public.assignments
  set status = v_status, completed_at = v_effective_at, updated_at = now()
  where id = v_assignment.id;
  insert into public.completion_records (
    assignment_id, actor_user_id, action, client_recorded_at, source)
  values (v_assignment.id, v_uid, v_status::text::public.completion_action,
          v_effective_at, p_source);
  perform public.recompute_day_counts(v_day.id);

  return jsonb_build_object(
    'assignment_id', v_assignment.id, 'status', v_status,
    'completed_at', v_effective_at,
    'day_counts', (select to_jsonb(d) from public.group_days d where d.id = v_day.id));
end;
$$;

create or replace function public.undo_assignment_completion(p_assignment_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_assignment public.assignments;
  v_day public.group_days;
  v_next public.assignment_status;
begin
  v_uid := public.require_auth_uid();
  select a, d into v_assignment, v_day
  from public.assignments a
  join public.group_days d on d.id = a.group_day_id
  where a.id = p_assignment_id
  for update of a, d;
  if not found then
    raise exception 'assignment_not_found' using errcode = 'P0001';
  end if;
  if not exists (
    select 1 from public.group_memberships m
    where m.id = v_assignment.reader_membership_id
      and m.user_id = v_uid and m.group_id = v_day.group_id
      and m.status = 'active'
  ) then
    raise exception 'not_reader' using errcode = 'P0001';
  end if;
  if v_day.state = 'closed' or now() >= v_day.closes_at then
    raise exception 'day_closed' using errcode = 'P0001';
  end if;
  if v_day.state = 'grace' or now() >= v_day.ends_at then
    if v_assignment.status <> 'late' then
      raise exception 'day_closed' using errcode = 'P0001';
    end if;
    v_next := 'missed';
  else
    if v_assignment.status <> 'completed' then
      raise exception 'validation_failed' using errcode = 'P0001';
    end if;
    v_next := 'pending';
  end if;
  update public.assignments
  set status = v_next, completed_at = null, updated_at = now()
  where id = v_assignment.id;
  insert into public.completion_records (
    assignment_id, actor_user_id, action, client_recorded_at, source)
  values (v_assignment.id, v_uid, 'undone', now(), 'online');
  perform public.recompute_day_counts(v_day.id);
  return jsonb_build_object(
    'assignment_id', v_assignment.id, 'status', v_next,
    'completed_at', null,
    'day_counts', (select to_jsonb(d) from public.group_days d where d.id = v_day.id));
end;
$$;

create or replace function public.advance_day_states()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_day record;
begin
  -- The scheduled postgres connection has no end-user JWT; interactive calls
  -- require an authenticated session and can only apply time-due transitions.
  if auth.uid() is null and session_user <> 'postgres' then
    raise exception 'unauthenticated' using errcode = 'P0001';
  end if;
  for v_day in
    select id from public.group_days
    where (state = 'open' and ends_at <= now())
       or (state = 'grace' and closes_at <= now())
    for update
  loop
    update public.assignments
    set status = case when status = 'pending' then 'missed'::public.assignment_status
                      when status = 'available' then 'unread'::public.assignment_status
                      else status end,
        updated_at = now()
    where group_day_id = v_day.id and status in ('pending', 'available');
    update public.group_days
    set state = case when closes_at <= now() then 'closed'::public.day_state
                     else 'grace'::public.day_state end
    where id = v_day.id;
    perform public.recompute_day_counts(v_day.id);
  end loop;
end;
$$;

revoke all on function public.mark_assignment_complete(uuid, timestamptz, public.completion_source) from public, anon;
revoke all on function public.undo_assignment_completion(uuid) from public, anon;
revoke all on function public.advance_day_states() from public, anon;
grant execute on function public.mark_assignment_complete(uuid, timestamptz, public.completion_source) to authenticated;
grant execute on function public.undo_assignment_completion(uuid) to authenticated;
grant execute on function public.advance_day_states() to authenticated;

select cron.schedule(
  'quran-daily-advance-day-states', '* * * * *',
  $$select public.advance_day_states()$$
);
