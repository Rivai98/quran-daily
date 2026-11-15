-- Fix forward: the active-seat unique index is checked during row updates,
-- so a two-row CASE update can still collide before the other tuple changes.
create or replace function public.move_member_seat(
  p_group_id uuid, p_membership_id uuid, p_target_seat smallint)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid;
  v_group public.groups;
  v_source smallint;
  v_other uuid;
begin
  v_uid := public.require_auth_uid();
  select * into v_group from public.groups where id=p_group_id for update;
  if not found then raise exception 'group_not_found' using errcode='P0001'; end if;
  if not exists (select 1 from public.group_memberships where group_id=p_group_id
      and user_id=v_uid and status='active' and role in ('owner','supervisor')) then
    raise exception 'forbidden' using errcode='P0001';
  end if;
  if p_target_seat not between 1 and 30 then raise exception 'validation_failed' using errcode='P0001'; end if;
  select seat_number into v_source from public.group_memberships
    where id=p_membership_id and group_id=p_group_id and status='active';
  if not found then raise exception 'validation_failed' using errcode='P0001'; end if;
  select id into v_other from public.group_memberships where group_id=p_group_id
    and seat_number=p_target_seat and status='active' and id<>p_membership_id;
  if v_other is not null then
    -- Vacate both unique keys within this transaction, then assign the swap.
    update public.group_memberships set status='left',seat_number=null
      where id in (p_membership_id,v_other);
    update public.group_memberships set status='active',seat_number=case
      when id=p_membership_id then p_target_seat else v_source end
      where id in (p_membership_id,v_other);
  else
    update public.group_memberships set seat_number=p_target_seat where id=p_membership_id;
  end if;
  return jsonb_build_object('membership_id',p_membership_id,'seat_number',p_target_seat,
    'effective_next_day',v_group.status='active');
end $$;

revoke all on function public.move_member_seat(uuid,uuid,smallint) from public, anon;
grant execute on function public.move_member_seat(uuid,uuid,smallint) to authenticated;
