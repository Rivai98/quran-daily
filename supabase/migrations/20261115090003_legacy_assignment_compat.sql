-- Old test fixtures and integrations insert only `juz`; keep them valid while
-- storing the equivalent portion index for legacy juz days.
create or replace function public.assignments_fill_portion_index()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.portion_index is null then new.portion_index := new.juz; end if;
  return new;
end;
$$;
create trigger assignments_fill_portion_index
before insert on public.assignments
for each row execute function public.assignments_fill_portion_index();
revoke all on function public.assignments_fill_portion_index() from public, anon, authenticated;
