-- These mutating helpers are reached through SECURITY DEFINER RPCs and are
-- not client RPCs themselves. Prevent direct PostgREST execution.
revoke all on function public.ensure_current_group_day(uuid) from public,anon,authenticated;
revoke all on function public.create_day_assignments(uuid,uuid,int) from public,anon,authenticated;
revoke all on function public.recompute_day_counts(uuid) from public,anon,authenticated;
revoke all on function public.generate_due_group_days() from public,anon,authenticated;
