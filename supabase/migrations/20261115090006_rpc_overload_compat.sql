-- Keep the original arities exact; the new overloads require explicit unit
-- parameters so calls that omit them are unambiguous on SQL and PostgREST.
drop function public.create_group(text,text,text,time,public.group_visibility,public.join_mode,public.portion_unit);
create function public.create_group(
  p_name text,p_short_description text,p_timezone text,p_day_start_time time,
  p_visibility public.group_visibility,p_join_mode public.join_mode,
  p_portion_unit public.portion_unit)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid; v_name text; v_desc text; v_group uuid; v_code text;
begin
  v_uid:=public.require_auth_uid();
  v_name:=btrim(coalesce(p_name,'')); v_desc:=btrim(coalesce(p_short_description,''));
  if length(v_name) not between 3 and 60 or length(v_desc)>200 or p_timezone is null
     or p_portion_unit is null or not exists(select 1 from pg_catalog.pg_timezone_names where name=p_timezone) then
    raise exception 'validation_failed' using errcode='P0001';
  end if;
  if (select count(*) from public.groups where owner_id=v_uid and status<>'archived')>=3 then
    raise exception 'owner_group_limit' using errcode='P0001';
  end if;
  v_group:=gen_random_uuid();
  loop
    v_code:=public.new_invite_code();
    exit when not exists(select 1 from public.groups where invite_code=v_code and status<>'archived');
  end loop;
  insert into public.groups(id,name,short_description,owner_id,timezone,day_start_time,visibility,join_mode,status,invite_code,portion_unit)
  values(v_group,v_name,v_desc,v_uid,p_timezone,coalesce(p_day_start_time,'00:00'),p_visibility,p_join_mode,'forming',v_code,p_portion_unit);
  insert into public.group_memberships(group_id,user_id,role,status,seat_number) values(v_group,v_uid,'owner','active',1);
  return jsonb_build_object('group_id',v_group,'invite_code',v_code,'portion_unit',p_portion_unit);
end $$;
revoke all on function public.create_group(text,text,text,time,public.group_visibility,public.join_mode,public.portion_unit) from public,anon;
grant execute on function public.create_group(text,text,text,time,public.group_visibility,public.join_mode,public.portion_unit) to authenticated;

drop function public.update_group_settings(uuid,text,text,text,time,public.group_visibility,public.join_mode,public.portion_unit);
create function public.update_group_settings(
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
  v_result:=public.update_group_settings(p_group_id,p_name,p_short_description,p_timezone,p_day_start_time,p_visibility,p_join_mode);
  if p_portion_unit is not null then
    if v_group.status='forming' then
      update public.groups set portion_unit=p_portion_unit,pending_portion_unit=null,unit_era_start_portion=1 where id=p_group_id;
    else
      update public.groups set pending_portion_unit=p_portion_unit where id=p_group_id;
    end if;
  end if;
  select v_result || jsonb_build_object('portion_unit',g.portion_unit,'pending_portion_unit',g.pending_portion_unit)
    into v_result from public.groups g where g.id=p_group_id;
  return v_result;
end $$;
revoke all on function public.update_group_settings(uuid,text,text,text,time,public.group_visibility,public.join_mode,public.portion_unit) from public,anon;
grant execute on function public.update_group_settings(uuid,text,text,text,time,public.group_visibility,public.join_mode,public.portion_unit) to authenticated;
