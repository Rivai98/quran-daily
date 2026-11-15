-- US4 fix-forward: approval groups with no free seat cannot accept join requests.

create or replace function public.join_group(
  p_group_id uuid default null,
  p_invite_code text default null,
  p_source public.join_source default 'discovery'
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_group public.groups;
  v_membership_id uuid;
  v_request_id uuid;
  v_seat smallint;
  v_removed boolean;
  v_day_id uuid;
begin
  v_uid := public.require_auth_uid();
  if (p_group_id is null) = (p_invite_code is null)
      or p_source is null or p_source not in ('discovery', 'invite', 'match') then
    raise exception 'validation_failed' using errcode = 'P0001';
  end if;

  if p_invite_code is not null then
    select * into v_group from public.groups
    where invite_code = upper(btrim(p_invite_code));
  else
    select * into v_group from public.groups where id = p_group_id;
  end if;
  if not found then
    if p_group_id is not null then
      raise exception 'group_not_found' using errcode = 'P0001';
    end if;
    raise exception 'invite_invalid' using errcode = 'P0001';
  end if;
  if v_group.status = 'archived' then
    raise exception 'group_archived' using errcode = 'P0001';
  end if;
  if p_group_id is not null and v_group.visibility <> 'public' then
    raise exception 'group_not_public' using errcode = 'P0001';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(v_group.id::text, 0));
  select * into v_group from public.groups where id = v_group.id;
  if v_group.status = 'archived' then
    raise exception 'group_archived' using errcode = 'P0001';
  end if;
  if exists (
    select 1 from public.group_memberships m
    where m.group_id = v_group.id and m.user_id = v_uid and m.status = 'active'
  ) then
    raise exception 'already_member' using errcode = 'P0001';
  end if;
  if exists (
    select 1 from public.join_requests j
    where j.group_id = v_group.id and j.user_id = v_uid and j.status = 'pending'
  ) then
    raise exception 'request_already_pending' using errcode = 'P0001';
  end if;

  select exists (
    select 1 from public.group_memberships m
    where m.group_id = v_group.id and m.user_id = v_uid and m.status = 'removed'
  ) into v_removed;

  if not exists (
    select 1 from generate_series(1, 30) s
    where not exists (
      select 1 from public.group_memberships m
      where m.group_id = v_group.id and m.status = 'active' and m.seat_number = s
    )
  ) then
    raise exception 'group_full' using errcode = 'P0001';
  end if;
  if v_group.join_mode = 'approval' or v_removed then
    insert into public.join_requests (group_id, user_id, status, source)
    values (v_group.id, v_uid, 'pending', p_source)
    returning id into v_request_id;
    return jsonb_build_object(
      'result', 'pending', 'join_request_id', v_request_id
    );
  end if;

  select s::smallint into v_seat
  from generate_series(1, 30) s
  where not exists (
    select 1 from public.group_memberships m
    where m.group_id = v_group.id and m.status = 'active' and m.seat_number = s
  )
  order by s
  limit 1;
  if v_seat is null then
    raise exception 'group_full' using errcode = 'P0001';
  end if;

  insert into public.group_memberships (group_id, user_id, role, status, seat_number)
  values (v_group.id, v_uid, 'member', 'active', v_seat)
  returning id into v_membership_id;

  -- A newly occupied seat takes today's available row, but never steals a
  -- volunteer or owner override already attached to that juz.
  if v_group.status = 'active' then
    v_day_id := public.ensure_current_group_day(v_group.id);
    if v_day_id is not null then
      update public.assignments
      set kind = 'seat', reader_membership_id = v_membership_id,
          status = 'pending', updated_at = now()
      where group_day_id = v_day_id and seat_number = v_seat
        and kind = 'unassigned' and status = 'available';
      perform public.recompute_day_counts(v_day_id);
    end if;
  end if;

  return jsonb_build_object(
    'result', 'joined', 'membership_id', v_membership_id, 'seat_number', v_seat
  );
end;
$$;

revoke all on function public.join_group(uuid, text, public.join_source) from public;
grant execute on function public.join_group(uuid, text, public.join_source) to authenticated;
