-- Preserve the legacy RPC signature while returning a JSON object correctly.
create or replace function public.update_group_settings(
  p_group_id uuid,p_name text default null,p_short_description text default null,
  p_timezone text default null,p_day_start_time time default null,
  p_visibility public.group_visibility default null,p_join_mode public.join_mode default null)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid; v_group public.groups; v_result jsonb;
begin
  v_uid:=public.require_auth_uid();
  select * into v_group from public.groups where id=p_group_id for update;
  if not found then raise exception 'group_not_found' using errcode='P0001'; end if;
  if v_group.owner_id<>v_uid then raise exception 'forbidden' using errcode='P0001'; end if;
  if p_name is not null then
    if length(btrim(p_name)) not between 3 and 60 then raise exception 'validation_failed' using errcode='P0001'; end if;
    update public.groups set name=btrim(p_name) where id=p_group_id;
  end if;
  if p_short_description is not null then
    if length(btrim(p_short_description))>200 then raise exception 'validation_failed' using errcode='P0001'; end if;
    update public.groups set short_description=btrim(p_short_description) where id=p_group_id;
  end if;
  if p_timezone is not null then
    if not exists(select 1 from pg_timezone_names where name=p_timezone) then raise exception 'validation_failed' using errcode='P0001'; end if;
    update public.groups set timezone=p_timezone where id=p_group_id;
  end if;
  if p_day_start_time is not null then update public.groups set day_start_time=p_day_start_time where id=p_group_id; end if;
  if p_visibility is not null then update public.groups set visibility=p_visibility where id=p_group_id; end if;
  if p_join_mode is not null then update public.groups set join_mode=p_join_mode where id=p_group_id; end if;
  select jsonb_build_object('group_id',g.id,'name',g.name,'status',g.status,'my_role','owner',
    'active_member_count',(select count(*) from public.group_memberships m where m.group_id=g.id and m.status='active'))
    into v_result from public.groups g where g.id=p_group_id;
  return v_result;
end $$;
revoke all on function public.update_group_settings(uuid,text,text,text,time,public.group_visibility,public.join_mode) from public,anon;
grant execute on function public.update_group_settings(uuid,text,text,text,time,public.group_visibility,public.join_mode) to authenticated;

-- The latest pending choice wins; choosing the current unit clears a pending change.
create or replace function public.update_group_settings(
  p_group_id uuid,p_name text,p_short_description text,p_timezone text,
  p_day_start_time time,p_visibility public.group_visibility,p_join_mode public.join_mode,
  p_portion_unit public.portion_unit)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid; v_group public.groups; v_result jsonb;
begin
  v_uid:=public.require_auth_uid();
  select * into v_group from public.groups where id=p_group_id for update;
  if not found then raise exception 'group_not_found' using errcode='P0001'; end if;
  if v_group.owner_id<>v_uid then raise exception 'forbidden' using errcode='P0001'; end if;
  v_result:=public.update_group_settings(p_group_id,p_name,p_short_description,p_timezone,
    p_day_start_time,p_visibility,p_join_mode);
  if p_portion_unit is not null then
    if v_group.status='forming' then
      update public.groups set portion_unit=p_portion_unit,pending_portion_unit=null,
        unit_era_start_portion=1 where id=p_group_id;
    else
      update public.groups set pending_portion_unit=case when portion_unit=p_portion_unit then null else p_portion_unit end
        where id=p_group_id;
    end if;
  end if;
  select v_result || jsonb_build_object('portion_unit',g.portion_unit,'pending_portion_unit',g.pending_portion_unit)
    into v_result from public.groups g where g.id=p_group_id;
  return v_result;
end $$;
revoke all on function public.update_group_settings(uuid,text,text,text,time,public.group_visibility,public.join_mode,public.portion_unit) from public,anon;
grant execute on function public.update_group_settings(uuid,text,text,text,time,public.group_visibility,public.join_mode,public.portion_unit) to authenticated;
