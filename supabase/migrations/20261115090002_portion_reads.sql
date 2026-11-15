-- Portion lifecycle settings and additive JSON read fields. Existing RPC arities
-- remain callable by clients already shipped against the juz contract.

create or replace function public.update_group_settings(
  p_group_id uuid, p_name text default null, p_short_description text default null,
  p_timezone text default null, p_day_start_time time default null,
  p_visibility public.group_visibility default null,
  p_join_mode public.join_mode default null,
  p_portion_unit public.portion_unit default null)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid; v_group public.groups; v_result jsonb;
begin
  v_uid:=public.require_auth_uid();
  if p_portion_unit is not null then
    select * into v_group from public.groups where id=p_group_id for update;
    if not found then raise exception 'group_not_found' using errcode='P0001'; end if;
    if v_group.owner_id<>v_uid then raise exception 'forbidden' using errcode='P0001'; end if;
  end if;
  v_result:=public.update_group_settings(p_group_id,p_name,p_short_description,p_timezone,
    p_day_start_time,p_visibility,p_join_mode);
  if p_portion_unit is not null then
    if v_group.status='forming' then
      update public.groups set portion_unit=p_portion_unit,pending_portion_unit=null,
        unit_era_start_portion=1 where id=p_group_id;
    else
      update public.groups set pending_portion_unit=p_portion_unit where id=p_group_id;
    end if;
  end if;
  select v_result || jsonb_build_object('portion_unit',g.portion_unit,
    'pending_portion_unit',g.pending_portion_unit) into v_result
  from public.groups g where g.id=p_group_id;
  return v_result;
end $$;
revoke all on function public.update_group_settings(uuid,text,text,text,time,public.group_visibility,public.join_mode,public.portion_unit) from public,anon;
grant execute on function public.update_group_settings(uuid,text,text,text,time,public.group_visibility,public.join_mode,public.portion_unit) to authenticated;

alter function public.get_dashboard(uuid) rename to get_dashboard_portion_base;
create function public.get_dashboard(p_group_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_data jsonb; v_rows jsonb; v_my_rows jsonb; v_group public.groups; v_day public.group_days; v_done int; v_n int;
begin
  v_data:=public.get_dashboard_portion_base(p_group_id);
  select * into v_group from public.groups where id=p_group_id;
  v_data:=v_data || jsonb_build_object('portion_unit',v_group.portion_unit,
    'pending_portion_unit',v_group.pending_portion_unit);
  if v_group.status='active' then
    select * into v_day from public.group_days where group_id=p_group_id and group_date=public.group_local_date(p_group_id,now());
    v_n:=public.portion_count(v_day.portion_unit);
    select count(distinct a.portion_index)::int into v_done
    from public.group_days d join public.assignments a on a.group_day_id=d.id
    where d.group_id=p_group_id and d.cycle_number=v_day.cycle_number
      and d.portion_unit=v_day.portion_unit and a.status in ('completed','late');
    v_data:=jsonb_set(v_data,'{today}',coalesce(v_data->'today','{}'::jsonb) || jsonb_build_object(
      'portion_unit',v_day.portion_unit,'cycle_number',v_day.cycle_number,
      'cycle_day',v_day.cycle_day,'cycle_length',v_day.cycle_length,
      'cycle_completed_count',v_done,'cycle_portion_count',v_n),true);
    select coalesce(jsonb_agg(e.value || jsonb_build_object('portion_index',a.portion_index)
      order by a.seat_number),'[]'::jsonb) into v_rows
    from jsonb_array_elements(coalesce(v_data->'assignments','[]'::jsonb)) as e(value)
    join public.assignments a on a.id=(e.value->>'assignment_id')::uuid;
    v_data:=jsonb_set(v_data,'{assignments}',coalesce(v_rows,'[]'::jsonb),true);
    -- Build own assignment rows from the same canonical stored indexes.
    select coalesce(jsonb_agg(e.value || jsonb_build_object('portion_index',a.portion_index)
      order by a.seat_number),'[]'::jsonb) into v_my_rows
    from jsonb_array_elements(coalesce(public.get_dashboard_portion_base(p_group_id)->'my_assignments','[]'::jsonb)) as e(value)
    join public.assignments a on a.id=(e.value->>'assignment_id')::uuid;
    v_data:=jsonb_set(v_data,'{my_assignments}',coalesce(v_my_rows,'[]'::jsonb),true);
  end if;
  return v_data;
end $$;
revoke all on function public.get_dashboard_portion_base(uuid),public.get_dashboard(uuid) from public,anon;
grant execute on function public.get_dashboard(uuid) to authenticated;

alter function public.get_history(uuid,date,int) rename to get_history_portion_base;
create function public.get_history(p_group_id uuid,p_before_date date default null,p_limit int default 30)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_days jsonb; v_uid uuid;
begin
  v_uid:=public.require_auth_uid();
  if not exists(select 1 from public.groups where id=p_group_id) then
    raise exception 'group_not_found' using errcode='P0001';
  end if;
  if not exists(select 1 from public.group_memberships where group_id=p_group_id and user_id=v_uid and status='active') then
    raise exception 'not_member' using errcode='P0001';
  end if;
  select coalesce(jsonb_agg(e.value || jsonb_build_object('portion_unit',d.portion_unit,
    'cycle_number',d.cycle_number,'cycle_day',d.cycle_day,'cycle_length',d.cycle_length)
    order by d.group_date desc),'[]'::jsonb) into v_days
  from jsonb_array_elements(public.get_history_portion_base(p_group_id,p_before_date,p_limit)) e(value)
  join public.group_days d on d.group_id=p_group_id and d.group_date=(e.value->>'group_date')::date;
  return coalesce(v_days,'[]'::jsonb);
end $$;
revoke all on function public.get_history_portion_base(uuid,date,int),public.get_history(uuid,date,int) from public,anon;
grant execute on function public.get_history(uuid,date,int) to authenticated;

alter function public.get_history_day(uuid,date) rename to get_history_day_portion_base;
create function public.get_history_day(p_group_id uuid,p_group_date date)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_data jsonb; v_day public.group_days; v_uid uuid;
begin
  v_uid:=public.require_auth_uid();
  if not exists(select 1 from public.group_memberships where group_id=p_group_id and user_id=v_uid and status='active') then
    raise exception 'not_member' using errcode='P0001';
  end if;
  v_data:=public.get_history_day_portion_base(p_group_id,p_group_date);
  select * into v_day from public.group_days where group_id=p_group_id and group_date=p_group_date;
  v_data:=v_data || jsonb_build_object('portion_unit',v_day.portion_unit,'cycle_number',v_day.cycle_number,
    'cycle_day',v_day.cycle_day,'cycle_length',v_day.cycle_length);
  if jsonb_typeof(v_data->'per_juz')='array' then
    select v_data || jsonb_build_object('per_juz',coalesce(jsonb_agg(e.value || jsonb_build_object('portion_index',a.portion_index)
      order by a.seat_number),'[]'::jsonb)) into v_data
    from jsonb_array_elements(v_data->'per_juz') e(value)
    join public.assignments a on a.id=(e.value->>'assignment_id')::uuid;
  end if;
  return v_data;
end $$;
revoke all on function public.get_history_day_portion_base(uuid,date),public.get_history_day(uuid,date) from public,anon;
grant execute on function public.get_history_day(uuid,date) to authenticated;

alter function public.get_invite_preview(text) rename to get_invite_preview_portion_base;
create function public.get_invite_preview(p_invite_code text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_data jsonb; v_uid uuid;
begin
  v_uid:=public.require_auth_uid();
  v_data:=public.get_invite_preview_portion_base(p_invite_code);
  select v_data || jsonb_build_object('portion_unit',g.portion_unit) into v_data
  from public.groups g where g.id=(v_data->>'group_id')::uuid;
  return v_data;
end $$;
revoke all on function public.get_invite_preview_portion_base(text),public.get_invite_preview(text) from public,anon;
grant execute on function public.get_invite_preview(text) to authenticated;

alter function public.search_public_groups(text,boolean,integer,integer) rename to search_public_groups_portion_base;
create function public.search_public_groups(p_query text default null,p_needs_members_only boolean default true,p_limit integer default 20,p_offset integer default 0)
returns setof jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid;
begin
  v_uid:=public.require_auth_uid();
  return query select b.value || jsonb_build_object('portion_unit',g.portion_unit)
  from public.search_public_groups_portion_base(p_query,p_needs_members_only,p_limit,p_offset) b(value)
  join public.groups g on g.id=(b.value->>'group_id')::uuid;
end $$;
revoke all on function public.search_public_groups_portion_base(text,boolean,integer,integer),public.search_public_groups(text,boolean,integer,integer) from public,anon;
grant execute on function public.search_public_groups(text,boolean,integer,integer) to authenticated;

alter function public.get_my_groups() rename to get_my_groups_portion_base;
create function public.get_my_groups()
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid; v_data jsonb;
begin
  v_uid:=public.require_auth_uid();
  v_data:=public.get_my_groups_portion_base();
  select v_data || jsonb_build_object('groups',coalesce(jsonb_agg(e.value || jsonb_build_object('portion_unit',g.portion_unit)
    order by g.created_at),'[]'::jsonb)) into v_data
  from jsonb_array_elements(coalesce(v_data->'groups','[]'::jsonb)) e(value)
  join public.groups g on g.id=(e.value->>'group_id')::uuid;
  return v_data;
end $$;
revoke all on function public.get_my_groups_portion_base(),public.get_my_groups() from public,anon;
grant execute on function public.get_my_groups() to authenticated;
