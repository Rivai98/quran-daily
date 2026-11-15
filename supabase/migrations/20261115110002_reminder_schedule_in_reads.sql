-- Spec 006: expose the group's reminder schedule in get_dashboard (additive).
-- Body copied from the latest definition (20261115090004_portion_read_compat_fix.sql);
-- the only change is the reminder_schedule key (JSON null when none is set).
-- get_my_today does not exist on this branch, so only get_dashboard changes.
create or replace function public.get_dashboard(p_group_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_data jsonb; v_rows jsonb; v_my_rows jsonb; v_group public.groups;
  v_day public.group_days; v_done int; v_n int;
begin
  v_data:=public.get_dashboard_portion_base(p_group_id);
  select * into v_group from public.groups where id=p_group_id;
  v_data:=v_data || jsonb_build_object('portion_unit',v_group.portion_unit,
    'pending_portion_unit',v_group.pending_portion_unit,
    'reminder_schedule',public.group_reminder_schedule_json(p_group_id));
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
