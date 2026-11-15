-- US5: claim an available juz for the current group day.
create or replace function public.volunteer_for_juz(p_assignment_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_group_day_id uuid;
  v_group_id uuid;
  v_assignment public.assignments;
  v_day public.group_days;
begin
  v_uid := public.require_auth_uid();

  select d.id, d.group_id into v_group_day_id, v_group_id
  from public.assignments a
  join public.group_days d on d.id = a.group_day_id
  where a.id = p_assignment_id;
  if not found then
    raise exception 'assignment_not_found' using errcode = 'P0001';
  end if;

  if not exists (
    select 1 from public.group_memberships m
    where m.group_id = v_group_id and m.user_id = v_uid
      and m.status = 'active'
  ) then
    raise exception 'not_member' using errcode = 'P0001';
  end if;

  select * into v_day from public.group_days where id = v_group_day_id;
  if v_day.state <> 'open' or v_day.ends_at <= now() then
    raise exception 'day_not_open' using errcode = 'P0001';
  end if;

  -- The conditional update is the concurrency boundary: only one transaction
  -- can claim a row while it is still unassigned and available.
  update public.assignments a
  set kind = 'volunteer',
      reader_membership_id = m.id,
      status = 'pending',
      updated_at = now()
  from public.group_memberships m
  where a.id = p_assignment_id
    and a.group_day_id = v_group_day_id
    and a.kind = 'unassigned'
    and a.status = 'available'
    and m.group_id = v_group_id
    and m.user_id = v_uid
    and m.status = 'active'
  returning a.* into v_assignment;

  if not found then
    raise exception 'juz_already_taken' using errcode = 'P0001';
  end if;

  perform public.recompute_day_counts(v_group_day_id);
  return to_jsonb(v_assignment);
end;
$$;

revoke all on function public.volunteer_for_juz(uuid) from public, anon;
grant execute on function public.volunteer_for_juz(uuid) to authenticated;
