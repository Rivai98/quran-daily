-- 008 admin console (T005): group actions, suspension cleanup, account-delete
-- preparation and admin role management. Every admin_* function calls
-- public.require_app_admin() FIRST ('not_admin' for anyone else) and writes
-- exactly one private.admin_audit row when it succeeds. Auth-level steps
-- (ban/unban, deleting the auth user) run in the admin-user-action Edge
-- Function, which calls these RPCs with the admin's own token.

-- ---------------------------------------------------------------------------
-- Internal helpers (private schema: unreachable through the API)
-- ---------------------------------------------------------------------------
create or replace function private.admin_archive_group_rows(p_group_id uuid, p_actor uuid)
returns void
language plpgsql
set search_path = ''
as $$
begin
  update public.groups set status = 'archived' where id = p_group_id;
  update public.join_requests
     set status = 'rejected', reviewed_at = now(), reviewed_by = p_actor
   where group_id = p_group_id and status = 'pending';
end;
$$;

-- Same rule as public.transfer_ownership (spec 001), without the caller check.
create or replace function private.admin_transfer_owner(p_group_id uuid, p_membership_id uuid)
returns uuid
language plpgsql
set search_path = ''
as $$
declare
  v_target public.group_memberships;
begin
  select * into v_target from public.group_memberships
   where id = p_membership_id and group_id = p_group_id
     and status = 'active' and role <> 'owner'
   for update;
  if not found then
    raise exception 'validation_failed' using errcode = 'P0001';
  end if;
  update public.group_memberships set role = 'member'
   where group_id = p_group_id and role = 'owner' and status = 'active';
  update public.group_memberships set role = 'owner' where id = p_membership_id;
  update public.groups set owner_id = v_target.user_id where id = p_group_id;
  return v_target.user_id;
end;
$$;

-- Ends an active membership with spec 001 rules: today's unfinished portions
-- are released, completed rows stay.
create or replace function private.admin_end_membership(p_group_id uuid, p_membership_id uuid)
returns void
language plpgsql
set search_path = ''
as $$
begin
  perform public.us6_release_member_today(p_group_id, p_membership_id);
  update public.group_memberships
     set status = 'removed', seat_number = null, ended_at = now()
   where id = p_membership_id and status = 'active';
end;
$$;

-- Most senior remaining member: supervisors first, then earliest joined.
create or replace function private.admin_successor(p_group_id uuid, p_leaving_user uuid)
returns uuid
language sql
stable
set search_path = ''
as $$
  select m.id from public.group_memberships m
   where m.group_id = p_group_id and m.status = 'active'
     and m.user_id <> p_leaving_user and m.role <> 'owner'
   order by (m.role = 'supervisor') desc, m.joined_at, m.id
   limit 1;
$$;

-- Removes a user from their groups (suspension or account deletion).
-- Owned groups pass to the most senior member; an owned group with no other
-- member is archived (suspend) or deleted (account delete: the FK
-- groups.owner_id -> profiles cascades, so it cannot outlive the account).
create or replace function private.admin_vacate_user(
  p_user_id uuid, p_actor uuid, p_for_delete boolean)
returns jsonb
language plpgsql
set search_path = ''
as $$
declare
  r record;
  v_successor uuid;
  v_ended int := 0;
  v_transferred int := 0;
  v_archived int := 0;
  v_deleted int := 0;
begin
  for r in
    select m.id, m.group_id, m.role, g.status as group_status
      from public.group_memberships m
      join public.groups g on g.id = m.group_id
     where m.user_id = p_user_id and m.status = 'active'
     order by m.joined_at
     for update of m
  loop
    if r.role = 'owner' then
      v_successor := private.admin_successor(r.group_id, p_user_id);
      if v_successor is not null then
        perform private.admin_transfer_owner(r.group_id, v_successor);
        v_transferred := v_transferred + 1;
      elsif p_for_delete then
        delete from public.groups where id = r.group_id;
        v_deleted := v_deleted + 1;
        continue;
      else
        if r.group_status <> 'archived' then
          perform private.admin_archive_group_rows(r.group_id, p_actor);
          v_archived := v_archived + 1;
        end if;
        continue; -- the archived group keeps its (suspended) owner
      end if;
    end if;
    perform private.admin_end_membership(r.group_id, r.id);
    v_ended := v_ended + 1;
  end loop;

  if p_for_delete then
    -- Owned groups without an active owner membership (legacy rows).
    for r in select g.id from public.groups g where g.owner_id = p_user_id loop
      v_successor := private.admin_successor(r.id, p_user_id);
      if v_successor is not null then
        perform private.admin_transfer_owner(r.id, v_successor);
        v_transferred := v_transferred + 1;
      else
        delete from public.groups where id = r.id;
        v_deleted := v_deleted + 1;
      end if;
    end loop;
    -- History keeps the day's statuses and counts but loses the name.
    update public.assignments a
       set kind = 'unassigned', reader_membership_id = null, updated_at = now()
     where a.reader_membership_id in (
       select m.id from public.group_memberships m where m.user_id = p_user_id);
    delete from public.completion_records where actor_user_id = p_user_id;
  end if;

  update public.join_requests set status = 'cancelled'
   where user_id = p_user_id and status = 'pending';

  return jsonb_build_object(
    'memberships_ended', v_ended,
    'groups_transferred', v_transferred,
    'groups_archived', v_archived,
    'groups_deleted', v_deleted);
end;
$$;

revoke all on function private.admin_archive_group_rows(uuid, uuid) from public, anon, authenticated;
revoke all on function private.admin_transfer_owner(uuid, uuid) from public, anon, authenticated;
revoke all on function private.admin_end_membership(uuid, uuid) from public, anon, authenticated;
revoke all on function private.admin_successor(uuid, uuid) from public, anon, authenticated;
revoke all on function private.admin_vacate_user(uuid, uuid, boolean) from public, anon, authenticated;

-- Locks and returns a group or raises group_not_found.
create or replace function private.admin_lock_group(p_group_id uuid)
returns public.groups
language plpgsql
set search_path = ''
as $$
declare
  v_group public.groups;
begin
  select * into v_group from public.groups where id = p_group_id for update;
  if not found then
    raise exception 'group_not_found' using errcode = 'P0001';
  end if;
  return v_group;
end;
$$;

-- Validates a user target for suspend/delete style actions.
create or replace function private.admin_user_target(
  p_actor uuid, p_user_id uuid, p_forbid_self boolean, p_forbid_admin boolean)
returns public.profiles
language plpgsql
set search_path = ''
as $$
declare
  v_profile public.profiles;
begin
  if p_forbid_self and p_user_id = p_actor then
    raise exception 'cannot_target_self' using errcode = 'P0001';
  end if;
  select * into v_profile from public.profiles where id = p_user_id for update;
  if not found then
    raise exception 'user_not_found' using errcode = 'P0001';
  end if;
  if p_forbid_admin and exists (
      select 1 from private.app_admins a where a.user_id = p_user_id) then
    raise exception 'target_is_admin' using errcode = 'P0001';
  end if;
  return v_profile;
end;
$$;

revoke all on function private.admin_lock_group(uuid) from public, anon, authenticated;
revoke all on function private.admin_user_target(uuid, uuid, boolean, boolean) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Group actions
-- ---------------------------------------------------------------------------
create or replace function public.admin_archive_group(p_group_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_group public.groups;
begin
  v_uid := public.require_app_admin();
  v_group := private.admin_lock_group(p_group_id);
  if v_group.status = 'archived' then
    raise exception 'invalid_state' using errcode = 'P0001';
  end if;
  perform private.admin_archive_group_rows(p_group_id, v_uid);
  perform public.write_admin_audit('archive_group', v_uid, null, p_group_id, v_group.name,
    'succeeded', jsonb_build_object('previous_status', v_group.status), null);
  return jsonb_build_object('group_id', p_group_id, 'status', 'archived');
end;
$$;

create or replace function public.admin_restore_group(p_group_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_group public.groups;
  v_status public.group_status;
  v_code text;
begin
  v_uid := public.require_app_admin();
  v_group := private.admin_lock_group(p_group_id);
  if v_group.status <> 'archived' then
    raise exception 'invalid_state' using errcode = 'P0001';
  end if;
  v_status := case when v_group.start_date is null then 'forming' else 'active' end;
  v_code := v_group.invite_code;
  -- Invite codes are unique among non-archived groups only.
  while exists (select 1 from public.groups
                where invite_code = v_code and status <> 'archived' and id <> p_group_id) loop
    v_code := public.new_invite_code();
  end loop;
  update public.groups set status = v_status, invite_code = v_code where id = p_group_id;
  perform public.write_admin_audit('restore_group', v_uid, null, p_group_id, v_group.name,
    'succeeded', jsonb_build_object('status', v_status,
      'invite_regenerated', v_code <> v_group.invite_code), null);
  return jsonb_build_object('group_id', p_group_id, 'status', v_status, 'invite_code', v_code);
end;
$$;

-- p_confirm_name must equal the group's name (second confirmation, server-side).
create or replace function public.admin_delete_group(p_group_id uuid, p_confirm_name text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_group public.groups;
  v_members int;
begin
  v_uid := public.require_app_admin();
  v_group := private.admin_lock_group(p_group_id);
  if btrim(coalesce(p_confirm_name, '')) <> btrim(v_group.name) then
    raise exception 'confirmation_mismatch' using errcode = 'P0001';
  end if;
  select count(*) into v_members from public.group_memberships
   where group_id = p_group_id and status = 'active';
  -- Cascades to memberships, join requests, days, assignments, completions.
  delete from public.groups where id = p_group_id;
  perform public.write_admin_audit('delete_group', v_uid, v_group.owner_id, p_group_id,
    v_group.name, 'succeeded',
    jsonb_build_object('status', v_group.status, 'active_members', v_members), null);
  return jsonb_build_object('group_id', p_group_id, 'deleted', true);
end;
$$;

create or replace function public.admin_remove_member(p_group_id uuid, p_membership_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_group public.groups;
  v_member public.group_memberships;
begin
  v_uid := public.require_app_admin();
  v_group := private.admin_lock_group(p_group_id);
  select * into v_member from public.group_memberships
   where id = p_membership_id and group_id = p_group_id and status = 'active'
   for update;
  if not found then
    raise exception 'validation_failed' using errcode = 'P0001';
  end if;
  if v_member.role = 'owner' then
    raise exception 'owner_must_transfer' using errcode = 'P0001';
  end if;
  perform private.admin_end_membership(p_group_id, p_membership_id);
  perform public.write_admin_audit('remove_member', v_uid, v_member.user_id, p_group_id,
    v_group.name, 'succeeded',
    jsonb_build_object('membership_id', p_membership_id, 'role', v_member.role,
      'seat_number', v_member.seat_number), null);
  return jsonb_build_object('membership_id', p_membership_id, 'removed', true);
end;
$$;

create or replace function public.admin_transfer_ownership(
  p_group_id uuid, p_new_owner_membership_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_group public.groups;
  v_new_owner uuid;
begin
  v_uid := public.require_app_admin();
  v_group := private.admin_lock_group(p_group_id);
  v_new_owner := private.admin_transfer_owner(p_group_id, p_new_owner_membership_id);
  perform public.write_admin_audit('transfer_ownership', v_uid, v_new_owner, p_group_id,
    v_group.name, 'succeeded',
    jsonb_build_object('previous_owner_id', v_group.owner_id), null);
  return jsonb_build_object('group_id', p_group_id,
    'owner_membership_id', p_new_owner_membership_id, 'owner_user_id', v_new_owner);
end;
$$;

create or replace function public.admin_regenerate_invite(p_group_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_group public.groups;
  v_code text;
begin
  v_uid := public.require_app_admin();
  v_group := private.admin_lock_group(p_group_id);
  loop
    v_code := public.new_invite_code();
    exit when v_code <> v_group.invite_code and not exists (
      select 1 from public.groups where invite_code = v_code and status <> 'archived');
  end loop;
  update public.groups set invite_code = v_code where id = p_group_id;
  perform public.write_admin_audit('regenerate_invite', v_uid, null, p_group_id,
    v_group.name, 'succeeded', '{}'::jsonb, null);
  return jsonb_build_object('group_id', p_group_id, 'invite_code', v_code);
end;
$$;

-- ---------------------------------------------------------------------------
-- User actions (data side; the Edge Function applies the auth side)
-- ---------------------------------------------------------------------------
-- Called after/with the auth ban: marks the profile suspended and removes the
-- user from active groups. Idempotent.
create or replace function public.admin_suspend_cleanup(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_profile public.profiles;
  v_result jsonb;
begin
  v_uid := public.require_app_admin();
  v_profile := private.admin_user_target(v_uid, p_user_id, true, true);
  update public.profiles set suspended_at = coalesce(suspended_at, now()) where id = p_user_id;
  v_result := private.admin_vacate_user(p_user_id, v_uid, false);
  perform public.write_admin_audit('suspend_cleanup', v_uid, p_user_id, null,
    v_profile.display_name, 'succeeded', v_result, null);
  return v_result || jsonb_build_object('user_id', p_user_id, 'suspended', true);
end;
$$;

-- Unsuspend restores sign-in only (FR-005): memberships are not restored.
create or replace function public.admin_clear_suspension(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_profile public.profiles;
begin
  v_uid := public.require_app_admin();
  v_profile := private.admin_user_target(v_uid, p_user_id, false, false);
  update public.profiles set suspended_at = null where id = p_user_id;
  perform public.write_admin_audit('clear_suspension', v_uid, p_user_id, null,
    v_profile.display_name, 'succeeded',
    jsonb_build_object('was_suspended', v_profile.suspended_at is not null), null);
  return jsonb_build_object('user_id', p_user_id, 'suspended', false);
end;
$$;

-- Runs right before the Edge Function deletes the auth user: hands owned
-- groups over, ends memberships and anonymizes history so the cascade from
-- auth.users succeeds. Leaves the profile suspended in case deletion fails.
create or replace function public.admin_prepare_user_delete(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_profile public.profiles;
  v_result jsonb;
begin
  v_uid := public.require_app_admin();
  v_profile := private.admin_user_target(v_uid, p_user_id, true, true);
  update public.profiles set suspended_at = coalesce(suspended_at, now()) where id = p_user_id;
  v_result := private.admin_vacate_user(p_user_id, v_uid, true);
  perform public.write_admin_audit('prepare_user_delete', v_uid, p_user_id, null,
    v_profile.display_name, 'succeeded', v_result, null);
  return v_result || jsonb_build_object('user_id', p_user_id, 'prepared', true);
end;
$$;

-- Grant (p_grant = true) or revoke app-admin. The last admin cannot be removed.
create or replace function public.admin_set_admin(p_user_id uuid, p_grant boolean)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_profile public.profiles;
  v_was boolean;
begin
  v_uid := public.require_app_admin();
  if p_grant is null then
    raise exception 'validation_failed' using errcode = 'P0001';
  end if;
  v_profile := private.admin_user_target(v_uid, p_user_id, false, false);
  -- Serialize admin-set changes so two revokes cannot both pass the check.
  lock table private.app_admins in share row exclusive mode;
  v_was := exists (select 1 from private.app_admins where user_id = p_user_id);

  if p_grant then
    if v_profile.suspended_at is not null then
      raise exception 'target_suspended' using errcode = 'P0001';
    end if;
    insert into private.app_admins (user_id, granted_by)
    values (p_user_id, v_uid) on conflict (user_id) do nothing;
  else
    if v_was and (select count(*) from private.app_admins) <= 1 then
      raise exception 'last_admin' using errcode = 'P0001';
    end if;
    delete from private.app_admins where user_id = p_user_id;
  end if;

  perform public.write_admin_audit(
    case when p_grant then 'grant_admin' else 'revoke_admin' end,
    v_uid, p_user_id, null, v_profile.display_name, 'succeeded',
    jsonb_build_object('changed', v_was <> p_grant), null);
  return jsonb_build_object('user_id', p_user_id, 'is_admin', p_grant);
end;
$$;

-- ---------------------------------------------------------------------------
-- Grants: authenticated may call; the in-function guard decides.
-- ---------------------------------------------------------------------------
revoke all on function public.admin_archive_group(uuid) from public, anon;
revoke all on function public.admin_restore_group(uuid) from public, anon;
revoke all on function public.admin_delete_group(uuid, text) from public, anon;
revoke all on function public.admin_remove_member(uuid, uuid) from public, anon;
revoke all on function public.admin_transfer_ownership(uuid, uuid) from public, anon;
revoke all on function public.admin_regenerate_invite(uuid) from public, anon;
revoke all on function public.admin_suspend_cleanup(uuid) from public, anon;
revoke all on function public.admin_clear_suspension(uuid) from public, anon;
revoke all on function public.admin_prepare_user_delete(uuid) from public, anon;
revoke all on function public.admin_set_admin(uuid, boolean) from public, anon;
grant execute on function public.admin_archive_group(uuid) to authenticated;
grant execute on function public.admin_restore_group(uuid) to authenticated;
grant execute on function public.admin_delete_group(uuid, text) to authenticated;
grant execute on function public.admin_remove_member(uuid, uuid) to authenticated;
grant execute on function public.admin_transfer_ownership(uuid, uuid) to authenticated;
grant execute on function public.admin_regenerate_invite(uuid) to authenticated;
grant execute on function public.admin_suspend_cleanup(uuid) to authenticated;
grant execute on function public.admin_clear_suspension(uuid) to authenticated;
grant execute on function public.admin_prepare_user_delete(uuid) to authenticated;
grant execute on function public.admin_set_admin(uuid, boolean) to authenticated;
