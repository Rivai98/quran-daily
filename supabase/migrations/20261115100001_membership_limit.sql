create or replace function public.active_membership_count(p_user_id uuid)
returns integer language sql stable security definer set search_path = '' as $$
  select count(*)::integer from public.group_memberships m
  join public.groups g on g.id=m.group_id
  where m.user_id=p_user_id and m.status='active' and g.status<>'archived'
$$;
revoke all on function public.active_membership_count(uuid) from public,anon,authenticated;

alter function public.create_group(text,text,text,time,public.group_visibility,public.join_mode) rename to create_group_limit_base;
alter function public.create_group(text,text,text,time,public.group_visibility,public.join_mode,public.portion_unit) rename to create_group_unit_limit_base;
create function public.create_group(p_name text,p_short_description text,p_timezone text,p_day_start_time time,p_visibility public.group_visibility,p_join_mode public.join_mode)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid; v_result jsonb;
begin
  v_uid:=public.require_auth_uid(); perform pg_advisory_xact_lock(hashtextextended(v_uid::text,505));
  if public.active_membership_count(v_uid)>=2 then raise exception 'membership_limit' using errcode='P0001'; end if;
  return public.create_group_limit_base(p_name,p_short_description,p_timezone,p_day_start_time,p_visibility,p_join_mode);
end $$;
create function public.create_group(p_name text,p_short_description text,p_timezone text,p_day_start_time time,p_visibility public.group_visibility,p_join_mode public.join_mode,p_portion_unit public.portion_unit)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid;
begin
  v_uid:=public.require_auth_uid(); perform pg_advisory_xact_lock(hashtextextended(v_uid::text,505));
  if public.active_membership_count(v_uid)>=2 then raise exception 'membership_limit' using errcode='P0001'; end if;
  return public.create_group_unit_limit_base(p_name,p_short_description,p_timezone,p_day_start_time,p_visibility,p_join_mode,p_portion_unit);
end $$;
revoke all on function public.create_group_limit_base(text,text,text,time,public.group_visibility,public.join_mode),public.create_group_unit_limit_base(text,text,text,time,public.group_visibility,public.join_mode,public.portion_unit),public.create_group(text,text,text,time,public.group_visibility,public.join_mode),public.create_group(text,text,text,time,public.group_visibility,public.join_mode,public.portion_unit) from public,anon;
grant execute on function public.create_group(text,text,text,time,public.group_visibility,public.join_mode),public.create_group(text,text,text,time,public.group_visibility,public.join_mode,public.portion_unit) to authenticated;

alter function public.join_group(uuid,text,public.join_source) rename to join_group_limit_base;
create function public.join_group(p_group_id uuid default null,p_invite_code text default null,p_source public.join_source default 'discovery')
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid;
begin
  v_uid:=public.require_auth_uid(); perform pg_advisory_xact_lock(hashtextextended(v_uid::text,505));
  if public.active_membership_count(v_uid)>=2 and not exists(select 1 from public.group_memberships m join public.groups g on g.id=m.group_id where m.user_id=v_uid and m.status='active' and g.status<>'archived' and ((p_group_id is not null and m.group_id=p_group_id) or (p_invite_code is not null and g.invite_code=upper(btrim(p_invite_code))))) then raise exception 'membership_limit' using errcode='P0001'; end if;
  return public.join_group_limit_base(p_group_id,p_invite_code,p_source);
end $$;
revoke all on function public.join_group_limit_base(uuid,text,public.join_source),public.join_group(uuid,text,public.join_source) from public,anon;
grant execute on function public.join_group(uuid,text,public.join_source) to authenticated;

alter function public.join_any_group(text) rename to join_any_group_limit_base;
create function public.join_any_group(p_device_timezone text) returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid;
begin
  v_uid:=public.require_auth_uid(); perform pg_advisory_xact_lock(hashtextextended(v_uid::text,505));
  if public.active_membership_count(v_uid)>=2 then raise exception 'membership_limit' using errcode='P0001'; end if;
  return public.join_any_group_limit_base(p_device_timezone);
end $$;
revoke all on function public.join_any_group_limit_base(text),public.join_any_group(text) from public,anon;
grant execute on function public.join_any_group(text) to authenticated;

alter function public.review_join_request(uuid,text) rename to review_join_request_limit_base;
create function public.review_join_request(p_join_request_id uuid,p_decision text) returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid; v_target uuid;
begin
  v_uid:=public.require_auth_uid();
  select user_id into v_target from public.join_requests where id=p_join_request_id;
  if p_decision='approve' and v_target is not null then
    perform pg_advisory_xact_lock(hashtextextended(v_target::text,505));
    if public.active_membership_count(v_target)>=2 then raise exception 'membership_limit' using errcode='P0001'; end if;
  end if;
  return public.review_join_request_limit_base(p_join_request_id,p_decision);
end $$;
revoke all on function public.review_join_request_limit_base(uuid,text),public.review_join_request(uuid,text) from public,anon;
grant execute on function public.review_join_request(uuid,text) to authenticated;

alter function public.get_invite_preview(text) rename to get_invite_preview_limit_base;
create function public.get_invite_preview(p_invite_code text) returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid; v_data jsonb;
begin
  v_uid:=public.require_auth_uid(); v_data:=public.get_invite_preview_limit_base(p_invite_code);
  return v_data || jsonb_build_object('can_join_limit',public.active_membership_count(v_uid)<2);
end $$;
revoke all on function public.get_invite_preview_limit_base(text),public.get_invite_preview(text) from public,anon;
grant execute on function public.get_invite_preview(text) to authenticated;

alter function public.search_public_groups(text,boolean,integer,integer) rename to search_public_groups_limit_base;
create function public.search_public_groups(p_query text default null,p_needs_members_only boolean default true,p_limit integer default 20,p_offset integer default 0) returns setof jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid; v_can_join boolean;
begin
  v_uid:=public.require_auth_uid(); v_can_join:=public.active_membership_count(v_uid)<2;
  return query select b.value || jsonb_build_object('can_join_limit',v_can_join) from public.search_public_groups_limit_base(p_query,p_needs_members_only,p_limit,p_offset) b(value);
end $$;
revoke all on function public.search_public_groups_limit_base(text,boolean,integer,integer),public.search_public_groups(text,boolean,integer,integer) from public,anon;
grant execute on function public.search_public_groups(text,boolean,integer,integer) to authenticated;
