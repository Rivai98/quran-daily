create table public.reading_positions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  last_page integer not null check (last_page between 1 and 604),
  updated_at timestamptz not null default now()
);

create table public.bookmarks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  surah integer not null check (surah between 1 and 114),
  ayah integer check (ayah is null or ayah > 0),
  page integer not null check (page between 1 and 604),
  note text check (note is null or char_length(note) <= 200),
  created_at timestamptz not null default now()
);

create index bookmarks_user_created_at_idx
  on public.bookmarks (user_id, created_at desc);

alter table public.reading_positions enable row level security;
alter table public.bookmarks enable row level security;

create policy reading_positions_owner_all
  on public.reading_positions
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy bookmarks_owner_all
  on public.bookmarks
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

revoke all on public.reading_positions from anon, authenticated;
revoke all on public.bookmarks from anon, authenticated;
grant select, insert, update, delete on public.reading_positions to authenticated;
grant select, insert, update, delete on public.bookmarks to authenticated;
