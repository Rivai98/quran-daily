-- US4 public discovery, invite previews, and joining flows.

create or replace function public.search_public_groups(
  p_query text default null,
  p_needs_members_only boolean default true,
  p_limit integer default 20,
  p_offset integer default 0
)
returns setof jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_query text;
begin
  v_uid := public.require_auth_uid();
  if p_limit < 1 or p_limit > 100 or p_offset < 0 then
    raise exception 'validation_failed' using errcode = 'P0001';
  end if;
  v_query := nullif(btrim(coalesce(p_query, '')), '');

  return query
  select jsonb_build_object(
    'group_id', g.id,
    'name', g.name,
    'short_description', g.short_description,
    'status', g.status,
    'active_member_count', counts.member_count,
    'timezone', g.timezone,
    'join_mode', g.join_mode,
    'my_request_status', requests.request_status,
    'my_join_request_id', requests.request_id
  )
  from public.groups g
  cross join lateral (
    select count(*)::integer as member_count
    from public.group_memberships m
    where m.group_id = g.id and m.status = 'active'
  ) counts
  left join lateral (
    select j.status::text as request_status, j.id as request_id
    from public.join_requests j
    where j.group_id = g.id and j.user_id = v_uid
      and j.status in ('pending', 'rejected')
    order by (j.status = 'pending') desc, j.requested_at desc
    limit 1
  ) requests on true
  where g.visibility = 'public'
    and g.status <> 'archived'
    and (not p_needs_members_only or counts.member_count < 30)
    and (v_query is null or g.name ilike '%' || v_query || '%'
      or coalesce(g.short_description, '') ilike '%' || v_query || '%')
  order by counts.member_count desc, g.created_at, g.id
  limit p_limit offset p_offset;
end;
$$;

revoke all on function public.search_public_groups(text, boolean, integer, integer) from public;
grant execute on function public.search_public_groups(text, boolean, integer, integer) to authenticated;

create or replace function public.get_invite_preview(p_invite_code text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_profile jsonb;
begin
  v_uid := public.require_auth_uid();
  select jsonb_build_object(
    'group_id', g.id,
    'name', g.name,
    'short_description', g.short_description,
    'status', g.status,
    'active_member_count', counts.member_count,
    'timezone', g.timezone,
    'join_mode', g.join_mode,
    'my_request_status', requests.request_status,
    'my_join_request_id', requests.request_id
  ) into v_profile
  from public.groups g
  cross join lateral (
    select count(*)::integer as member_count
    from public.group_memberships m
    where m.group_id = g.id and m.status = 'active'
  ) counts
  left join lateral (
    select j.status::text as request_status, j.id as request_id
    from public.join_requests j
    where j.group_id = g.id and j.user_id = v_uid
      and j.status in ('pending', 'rejected')
    order by (j.status = 'pending') desc, j.requested_at desc
    limit 1
  ) requests on true
  where g.invite_code = upper(btrim(coalesce(p_invite_code, '')));

  if v_profile is null then
    raise exception 'invite_invalid' using errcode = 'P0001';
  end if;
  return v_profile;
end;
$$;

revoke all on function public.get_invite_preview(text) from public;
grant execute on function public.get_invite_preview(text) to authenticated;

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
      or p_source not in ('discovery', 'invite', 'match') then
    raise exception 'validation_failed' using errcode = 'P0001';
  end if;

  if p_invite_code is not null then
    select * into v_group from public.groups
    where invite_code = upper(btrim(p_invite_code));
  else
    select * into v_group from public.groups where id = p_group_id;
  end if;
  if not found then
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

create or replace function public.join_any_group(p_device_timezone text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_candidate record;
  v_result jsonb;
begin
  v_uid := public.require_auth_uid();
  if nullif(btrim(coalesce(p_device_timezone, '')), '') is null then
    raise exception 'validation_failed' using errcode = 'P0001';
  end if;

  for v_candidate in
    select g.id
    from public.groups g
    where g.visibility = 'public' and g.join_mode = 'auto_accept'
      and g.status <> 'archived'
      and exists (
        select 1 from generate_series(1, 30) s
        where not exists (
          select 1 from public.group_memberships m
          where m.group_id = g.id and m.status = 'active' and m.seat_number = s
        )
      )
      and not exists (
        select 1 from public.group_memberships mine
        where mine.group_id = g.id and mine.user_id = v_uid and mine.status = 'active'
      )
      and not exists (
        select 1 from public.join_requests j
        where j.group_id = g.id and j.user_id = v_uid and j.status = 'pending'
      )
    order by (g.timezone = p_device_timezone) desc,
      (select count(*) from public.group_memberships m
       where m.group_id = g.id and m.status = 'active') desc,
      g.created_at, g.id
  loop
    begin
      v_result := public.join_group(v_candidate.id, null, 'match');
      return v_result || jsonb_build_object('group_id', v_candidate.id);
    exception when sqlstate 'P0001' then
      if sqlerrm <> 'group_full' then
        raise;
      end if;
    end;
  end loop;

  raise exception 'no_group_available' using errcode = 'P0001';
end;
$$;

revoke all on function public.join_any_group(text) from public;
grant execute on function public.join_any_group(text) to authenticated;

create or replace function public.cancel_join_request(p_join_request_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
begin
  v_uid := public.require_auth_uid();
  update public.join_requests
  set status = 'cancelled', reviewed_at = now(), reviewed_by = v_uid
  where id = p_join_request_id and user_id = v_uid and status = 'pending';
  if not found then
    if exists (select 1 from public.join_requests where id = p_join_request_id) then
      raise exception 'forbidden' using errcode = 'P0001';
    end if;
    raise exception 'request_not_pending' using errcode = 'P0001';
  end if;
end;
$$;

revoke all on function public.cancel_join_request(uuid) from public;
grant execute on function public.cancel_join_request(uuid) to authenticated;

-- Preserve every existing get_my_groups field and add nothing unless the
-- returning user has pending requests; this replacement is required so the
-- US4 request list remains part of the cached S1 overview contract.
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
        join public.group_memberships me on me.id = a.reader_membership_id
        where d.group_id = g.id and d.state = 'open' and me.user_id = v_uid
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

revoke all on function public.get_my_groups() from public;
grant execute on function public.get_my_groups() to authenticated;
