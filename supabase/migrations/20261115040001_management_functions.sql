-- US6 group membership and assignment management RPCs.
-- All mutations are authenticated SECURITY DEFINER entry points.

create or replace function public.list_join_requests(p_group_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid; v_rows jsonb;
begin
  v_uid := public.require_auth_uid();
  if not exists (select 1 from public.group_memberships m where m.group_id=p_group_id
    and m.user_id=v_uid and m.status='active' and m.role in ('owner','supervisor')) then
    raise exception 'forbidden' using errcode='P0001';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object('join_request_id',j.id,
    'user_display_name',coalesce(p.display_name,''),'requested_at',j.requested_at,'source',j.source)
    order by j.requested_at), '[]'::jsonb) into v_rows
  from public.join_requests j join public.profiles p on p.id=j.user_id
  where j.group_id=p_group_id and j.status='pending';
  return v_rows;
end $$;

create or replace function public.review_join_request(p_join_request_id uuid,p_decision text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid; v_req public.join_requests; v_group public.groups; v_seat int;
begin
  v_uid:=public.require_auth_uid();
  if p_decision not in ('approve','reject') then raise exception 'validation_failed' using errcode='P0001'; end if;
  select * into v_req from public.join_requests where id=p_join_request_id for update;
  if not found or v_req.status <> 'pending' then raise exception 'request_not_pending' using errcode='P0001'; end if;
  select * into v_group from public.groups where id=v_req.group_id for update;
  if not exists(select 1 from public.group_memberships where group_id=v_req.group_id and user_id=v_uid
    and status='active' and role in ('owner','supervisor')) then raise exception 'forbidden' using errcode='P0001'; end if;
  if p_decision='reject' then
    update public.join_requests set status='rejected', reviewed_at=now(), reviewed_by=v_uid where id=p_join_request_id;
    return jsonb_build_object('result','rejected');
  end if;
  if v_group.status='archived' or exists(select 1 from public.group_memberships where group_id=v_req.group_id and user_id=v_req.user_id and status='active') then
    raise exception 'request_not_pending' using errcode='P0001';
  end if;
  select s into v_seat from generate_series(1,30) s where not exists
    (select 1 from public.group_memberships m where m.group_id=v_req.group_id and m.seat_number=s and m.status='active') order by s limit 1;
  if v_seat is null then raise exception 'group_full' using errcode='P0001'; end if;
  insert into public.group_memberships(group_id,user_id,role,status,seat_number)
    values(v_req.group_id,v_req.user_id,'member','active',v_seat);
  update public.join_requests set status='approved', reviewed_at=now(), reviewed_by=v_uid where id=p_join_request_id;
  return jsonb_build_object('result','approved','seat_number',v_seat);
end $$;

create or replace function public.get_group_members(p_group_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid; v_members jsonb; v_count int; v_code text;
begin
  v_uid:=public.require_auth_uid();
  if not exists(select 1 from public.group_memberships where group_id=p_group_id and user_id=v_uid and status='active') then raise exception 'forbidden' using errcode='P0001'; end if;
  select count(*) into v_count from public.group_memberships where group_id=p_group_id and status='active';
  select invite_code into v_code from public.groups where id=p_group_id;
  select coalesce(jsonb_agg(jsonb_build_object('membership_id',m.id,'display_name',coalesce(p.display_name,''),'role',m.role,'seat_number',m.seat_number) order by m.seat_number),'[]'::jsonb)
    into v_members from public.group_memberships m join public.profiles p on p.id=m.user_id where m.group_id=p_group_id and m.status='active';
  return jsonb_build_object('group_id',p_group_id,'members',v_members,'active_member_count',v_count,'invite_code',v_code);
end $$;

create or replace function public.move_member_seat(p_group_id uuid,p_membership_id uuid,p_target_seat smallint)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid; v_group public.groups; v_source smallint; v_other uuid;
begin
  v_uid:=public.require_auth_uid();
  select * into v_group from public.groups where id=p_group_id for update;
  if not found then raise exception 'group_not_found' using errcode='P0001'; end if;
  if not exists(select 1 from public.group_memberships where group_id=p_group_id and user_id=v_uid and status='active' and (role='owner' or (role='supervisor' and v_group.status='forming'))) then raise exception 'forbidden' using errcode='P0001'; end if;
  if p_target_seat not between 1 and 30 then raise exception 'validation_failed' using errcode='P0001'; end if;
  select seat_number into v_source from public.group_memberships where id=p_membership_id and group_id=p_group_id and status='active';
  if not found then raise exception 'validation_failed' using errcode='P0001'; end if;
  select id into v_other from public.group_memberships where group_id=p_group_id and seat_number=p_target_seat and status='active' and id<>p_membership_id;
  if v_other is not null then
    update public.group_memberships set seat_number=case when id=p_membership_id then p_target_seat else v_source end
      where id in (p_membership_id,v_other);
  else update public.group_memberships set seat_number=p_target_seat where id=p_membership_id; end if;
  return jsonb_build_object('membership_id',p_membership_id,'seat_number',p_target_seat,'effective_next_day',v_group.status='active');
end $$;

create or replace function public.set_member_role(p_group_id uuid,p_membership_id uuid,p_role public.group_role)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid;
begin
  v_uid:=public.require_auth_uid();
  if not exists(select 1 from public.groups where id=p_group_id and owner_id=v_uid) then raise exception 'forbidden' using errcode='P0001'; end if;
  if p_role not in ('member','supervisor') or not exists(select 1 from public.group_memberships where id=p_membership_id and group_id=p_group_id and status='active' and role<>'owner') then raise exception 'validation_failed' using errcode='P0001'; end if;
  update public.group_memberships set role=p_role where id=p_membership_id;
  return jsonb_build_object('membership_id',p_membership_id,'role',p_role);
end $$;

create or replace function public.us6_release_member_today(p_group_id uuid,p_membership_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  update public.assignments a set kind='unassigned',reader_membership_id=null,status='available',completed_at=null
  from public.group_days d where a.group_day_id=d.id and d.group_id=p_group_id and d.group_date=public.group_local_date(p_group_id,now())
    and d.state='open' and a.reader_membership_id=p_membership_id and a.status<>'completed';
  update public.group_days d set available_count=(select count(*) from public.assignments a where a.group_day_id=d.id and a.status='available'),
    pending_count=(select count(*) from public.assignments a where a.group_day_id=d.id and a.status='pending')
  where d.group_id=p_group_id and d.group_date=public.group_local_date(p_group_id,now()) and d.state='open';
end $$;

create or replace function public.remove_member(p_group_id uuid,p_membership_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid; v_member public.group_memberships;
begin
  v_uid:=public.require_auth_uid();
  if not exists(select 1 from public.groups where id=p_group_id and owner_id=v_uid) then raise exception 'forbidden' using errcode='P0001'; end if;
  select * into v_member from public.group_memberships where id=p_membership_id and group_id=p_group_id and status='active' for update;
  if not found or v_member.user_id=v_uid or v_member.role='owner' then raise exception 'validation_failed' using errcode='P0001'; end if;
  perform public.us6_release_member_today(p_group_id,p_membership_id);
  update public.group_memberships set status='removed',seat_number=null,ended_at=now() where id=p_membership_id;
  return jsonb_build_object('removed',true);
end $$;

create or replace function public.leave_group(p_group_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid; v_member public.group_memberships;
begin
  v_uid:=public.require_auth_uid();
  select * into v_member from public.group_memberships where group_id=p_group_id and user_id=v_uid and status='active' for update;
  if not found then raise exception 'not_member' using errcode='P0001'; end if;
  if v_member.role='owner' then raise exception 'owner_must_transfer' using errcode='P0001'; end if;
  perform public.us6_release_member_today(p_group_id,v_member.id);
  update public.group_memberships set status='left',seat_number=null,ended_at=now() where id=v_member.id;
  return jsonb_build_object('left',true);
end $$;

create or replace function public.transfer_ownership(p_group_id uuid,p_new_owner_membership_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid; v_target public.group_memberships; v_old uuid;
begin
  v_uid:=public.require_auth_uid();
  if not exists(select 1 from public.groups where id=p_group_id and owner_id=v_uid for update) then raise exception 'forbidden' using errcode='P0001'; end if;
  select * into v_target from public.group_memberships where id=p_new_owner_membership_id and group_id=p_group_id and status='active' and role<>'owner' for update;
  if not found then raise exception 'validation_failed' using errcode='P0001'; end if;
  update public.group_memberships set role='member' where group_id=p_group_id and role='owner' and status='active' returning id into v_old;
  update public.group_memberships set role='owner' where id=p_new_owner_membership_id;
  update public.groups set owner_id=v_target.user_id where id=p_group_id;
  return jsonb_build_object('owner_membership_id',p_new_owner_membership_id);
end $$;

create or replace function public.archive_group(p_group_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid;
begin
  v_uid:=public.require_auth_uid();
  if not exists(select 1 from public.groups where id=p_group_id and owner_id=v_uid) then raise exception 'forbidden' using errcode='P0001'; end if;
  update public.groups set status='archived' where id=p_group_id;
  update public.join_requests set status='rejected',reviewed_at=now(),reviewed_by=v_uid where group_id=p_group_id and status='pending';
  return jsonb_build_object('archived',true);
end $$;

create or replace function public.override_assignment(p_assignment_id uuid,p_membership_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid; v_group uuid; v_reader uuid; v_day uuid; v_juz smallint;
begin
  v_uid:=public.require_auth_uid();
  select d.group_id,a.reader_membership_id,a.group_day_id,a.juz into v_group,v_reader,v_day,v_juz from public.assignments a join public.group_days d on d.id=a.group_day_id where a.id=p_assignment_id for update of a;
  if not found then raise exception 'assignment_not_found' using errcode='P0001'; end if;
  if not exists(select 1 from public.groups where id=v_group and owner_id=v_uid) then raise exception 'forbidden' using errcode='P0001'; end if;
  if not exists(select 1 from public.group_days where id=v_day and state='open') then raise exception 'day_closed' using errcode='P0001'; end if;
  if not exists(select 1 from public.group_memberships where id=p_membership_id and group_id=v_group and status='active') then raise exception 'validation_failed' using errcode='P0001'; end if;
  if exists(select 1 from public.assignments where group_day_id=v_day and reader_membership_id=p_membership_id and id<>p_assignment_id and status<>'completed') then raise exception 'already_assigned' using errcode='P0001'; end if;
  if exists(select 1 from public.assignments where id=p_assignment_id and status='completed') then raise exception 'already_completed' using errcode='P0001'; end if;
  update public.assignments set reader_membership_id=p_membership_id,kind='override',status='pending' where id=p_assignment_id;
  if v_reader is not null and v_reader<>p_membership_id then perform public.us6_release_member_today(v_group,v_reader); end if;
  return jsonb_build_object('assignment_id',p_assignment_id,'membership_id',p_membership_id,'juz',v_juz);
end $$;

create or replace function public.us6_grants()
returns void language plpgsql security definer set search_path = '' as $$ begin null; end $$;

revoke all on function public.list_join_requests(uuid), public.review_join_request(uuid,text), public.get_group_members(uuid), public.move_member_seat(uuid,uuid,smallint), public.set_member_role(uuid,uuid,public.group_role), public.remove_member(uuid,uuid), public.leave_group(uuid), public.transfer_ownership(uuid,uuid), public.archive_group(uuid), public.override_assignment(uuid,uuid), public.us6_release_member_today(uuid,uuid), public.us6_grants() from public, anon;
grant execute on function public.list_join_requests(uuid), public.review_join_request(uuid,text), public.get_group_members(uuid), public.move_member_seat(uuid,uuid,smallint), public.set_member_role(uuid,uuid,public.group_role), public.remove_member(uuid,uuid), public.leave_group(uuid), public.transfer_ownership(uuid,uuid), public.archive_group(uuid), public.override_assignment(uuid,uuid) to authenticated;
revoke all on function public.us6_release_member_today(uuid,uuid), public.us6_grants() from authenticated;
drop function public.us6_grants();
