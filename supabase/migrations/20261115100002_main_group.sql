alter table public.profiles add column main_group_id uuid references public.groups(id) on delete set null;
alter table public.group_memberships add column last_opened_at timestamptz;

create function public.set_main_group(p_group_id uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare v_uid uuid;
begin
  v_uid:=public.require_auth_uid();
  if p_group_id is not null and not exists(select 1 from public.group_memberships where user_id=v_uid and group_id=p_group_id and status='active') then
    raise exception 'not_member' using errcode='P0001';
  end if;
  update public.profiles set main_group_id=p_group_id where id=v_uid;
end $$;

create function public.mark_group_opened(p_group_id uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare v_uid uuid;
begin
  v_uid:=public.require_auth_uid();
  update public.group_memberships set last_opened_at=now()
  where user_id=v_uid and group_id=p_group_id and status='active';
end $$;
revoke all on function public.set_main_group(uuid),public.mark_group_opened(uuid) from public,anon;
grant execute on function public.set_main_group(uuid),public.mark_group_opened(uuid) to authenticated;
