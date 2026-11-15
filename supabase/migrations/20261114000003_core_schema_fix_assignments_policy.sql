-- 002a fix-forward: assignments RLS policy used group_day_id where the
-- group id is required (members saw 0 assignment rows). Also drop default
-- write privileges so direct client writes fail closed (they previously
-- silently no-oped under RLS because Supabase grants ALL to API roles).

drop policy if exists assignments_select_member on public.assignments;

create policy assignments_select_member
  on public.assignments for select to authenticated
  using (
    exists (
      select 1
      from public.group_days d
      where d.id = assignments.group_day_id
        and public.is_active_member(d.group_id)
    )
  );

-- Deny-all writes, hard: no write policies exist, and now no write grants.
revoke all on public.groups from anon, authenticated;
revoke all on public.group_memberships from anon, authenticated;
revoke all on public.join_requests from anon, authenticated;
revoke all on public.group_days from anon, authenticated;
revoke all on public.assignments from anon, authenticated;
revoke all on public.completion_records from anon, authenticated;

grant select on public.groups, public.group_memberships,
  public.join_requests, public.group_days, public.assignments,
  public.completion_records to authenticated;
