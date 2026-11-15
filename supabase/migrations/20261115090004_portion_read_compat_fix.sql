-- Fix JSON element aliases in the portion wrappers (legacy JSON is preserved).
create or replace function public.get_dashboard(p_group_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_data jsonb; v_rows jsonb; v_my_rows jsonb; v_group public.groups;
  v_day public.group_days; v_done int; v_n int;
begin
  v_data:=public.get_dashboard_portion_base(p_group_id);
  select * into v_group from public.groups where id=p_group_id;
  v_data:=v_data || jsonb_build_object('portion_unit',v_group.portion_unit,
    'pending_portion_unit',v_group.pending_portion_unit);
  if v_group.status='active' then
    select * into v_day from public.group_days where group_id=p_group_id
      and group_date=public.group_local_date(p_group_id,now());
    v_n:=public.portion_count(v_day.portion_unit);
    select count(distinct a.portion_index)::int into v_done from public.group_days d
      join public.assignments a on a.group_day_id=d.id
      where d.group_id=p_group_id and d.cycle_number=v_day.cycle_number
        and d.portion_unit=v_day.portion_unit and a.status in('completed','late');
    v_data:=jsonb_set(v_data,'{today}',coalesce(v_data->'today','{}'::jsonb) || jsonb_build_object(
      'portion_unit',v_day.portion_unit,'cycle_number',v_day.cycle_number,
      'cycle_day',v_day.cycle_day,'cycle_length',v_day.cycle_length,
      'cycle_completed_count',v_done,'cycle_portion_count',v_n),true);
    select coalesce(jsonb_agg(e.value || jsonb_build_object('portion_index',a.portion_index)
      order by a.seat_number),'[]'::jsonb) into v_rows
      from jsonb_array_elements(coalesce(v_data->'assignments','[]'::jsonb)) e(value)
      join public.assignments a on a.id=(e.value->>'assignment_id')::uuid;
    v_data:=jsonb_set(v_data,'{assignments}',coalesce(v_rows,'[]'::jsonb),true);
    select coalesce(jsonb_agg(e.value || jsonb_build_object('portion_index',a.portion_index)
      order by a.seat_number),'[]'::jsonb) into v_my_rows
      from jsonb_array_elements(coalesce(v_data->'my_assignments','[]'::jsonb)) e(value)
      join public.assignments a on a.id=(e.value->>'assignment_id')::uuid;
    v_data:=jsonb_set(v_data,'{my_assignments}',coalesce(v_my_rows,'[]'::jsonb),true);
  end if;
  return v_data;
end $$;
revoke all on function public.get_dashboard(uuid) from public,anon;
grant execute on function public.get_dashboard(uuid) to authenticated;

create or replace function public.get_history(p_group_id uuid,p_before_date date default null,p_limit int default 30)
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
revoke all on function public.get_history(uuid,date,int) from public,anon;
grant execute on function public.get_history(uuid,date,int) to authenticated;
