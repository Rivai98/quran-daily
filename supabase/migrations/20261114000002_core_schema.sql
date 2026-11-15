-- 002_core_schema (spec 001): enums, tables, constraints, rotation helper,
-- group-local date helper, member-select RLS + deny-all writes.
-- Direct client writes are forbidden; all writes go through SECURITY
-- DEFINER functions (supabase-rpc contract).

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
create type public.group_status as enum ('forming', 'active', 'archived');
create type public.group_visibility as enum ('public', 'private');
create type public.join_mode as enum ('auto_accept', 'approval');
create type public.group_role as enum ('owner', 'supervisor', 'member');
create type public.membership_status as enum ('active', 'left', 'removed');
create type public.join_request_status
  as enum ('pending', 'approved', 'rejected', 'cancelled');
create type public.join_source as enum ('discovery', 'invite', 'match');
create type public.day_state as enum ('open', 'grace', 'closed');
create type public.assignment_kind
  as enum ('seat', 'override', 'volunteer', 'unassigned');
create type public.assignment_status
  as enum ('pending', 'completed', 'missed', 'late', 'available', 'unread');
create type public.completion_action as enum ('completed', 'late', 'undone');
create type public.completion_source as enum ('online', 'offline_sync');

-- ---------------------------------------------------------------------------
-- groups
-- ---------------------------------------------------------------------------
create table public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(btrim(name)) between 3 and 60),
  short_description text
    check (char_length(btrim(coalesce(short_description, ''))) <= 200),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  timezone text not null,
  day_start_time time not null default '00:00',
  visibility public.group_visibility not null default 'private',
  join_mode public.join_mode not null default 'approval',
  status public.group_status not null default 'forming',
  start_juz smallint check (start_juz between 1 and 30),
  start_date date,
  invite_code text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- start fields exist exactly when the group was started
  constraint groups_start_pair
    check ((start_juz is null) = (start_date is null)),
  constraint groups_invite_shape
    check (invite_code ~ '^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{8}$')
);

create unique index groups_invite_active
  on public.groups (invite_code)
  where status <> 'archived';

create table public.group_memberships (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role public.group_role not null default 'member',
  status public.membership_status not null default 'active',
  seat_number smallint check (seat_number between 1 and 30),
  joined_at timestamptz not null default now(),
  ended_at timestamptz,

  constraint memberships_seat_iff_active
    check ((status = 'active') = (seat_number is not null))
);

-- one active membership per (group, user)
create unique index memberships_unique_active_user
  on public.group_memberships (group_id, user_id)
  where status = 'active';
-- one active member per seat
create unique index memberships_unique_active_seat
  on public.group_memberships (group_id, seat_number)
  where status = 'active';
-- <= 30 active members: exclusivity over the 30 seats
create unique index memberships_active_seat_range
  on public.group_memberships (group_id, seat_number)
  where status = 'active' and seat_number between 1 and 30;
-- exactly one owner
create unique index memberships_one_owner
  on public.group_memberships (group_id)
  where role = 'owner' and status = 'active';

create index memberships_user_idx on public.group_memberships (user_id);

-- ---------------------------------------------------------------------------
-- join_requests
-- ---------------------------------------------------------------------------
create table public.join_requests (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  status public.join_request_status not null default 'pending',
  source public.join_source not null default 'discovery',
  requested_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references public.profiles (id) on delete set null
);

create unique index join_requests_one_pending
  on public.join_requests (group_id, user_id)
  where status = 'pending';
create index join_requests_group_pending_idx
  on public.join_requests (group_id)
  where status = 'pending';

-- ---------------------------------------------------------------------------
-- group_days
-- ---------------------------------------------------------------------------
create table public.group_days (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  group_date date not null,
  day_index int not null check (day_index >= 0),
  opens_at timestamptz not null,
  ends_at timestamptz not null,
  closes_at timestamptz not null,
  state public.day_state not null default 'open',
  completed_count smallint not null default 0,
  late_count smallint not null default 0,
  missed_count smallint not null default 0,
  unread_count smallint not null default 0,
  pending_count smallint not null default 0,
  available_count smallint not null default 0,
  full_khatma boolean not null default false,

  constraint group_days_times_ordered
    check (opens_at < ends_at and ends_at < closes_at)
);

create unique index group_days_unique_date
  on public.group_days (group_id, group_date);
create index group_days_open_idx
  on public.group_days (group_id, state)
  where state in ('open', 'grace');

-- ---------------------------------------------------------------------------
-- assignments (exactly 30 per day: one per juz, one per seat)
-- ---------------------------------------------------------------------------
create table public.assignments (
  id uuid primary key default gen_random_uuid(),
  group_day_id uuid not null references public.group_days (id) on delete cascade,
  juz smallint not null check (juz between 1 and 30),
  seat_number smallint not null check (seat_number between 1 and 30),
  kind public.assignment_kind not null default 'seat',
  reader_membership_id uuid references public.group_memberships (id)
    on delete set null,
  status public.assignment_status not null default 'pending',
  completed_at timestamptz,
  updated_at timestamptz not null default now(),

  -- unassigned rows have no reader and vice versa
  constraint assignments_reader_iff_assigned
    check ((kind = 'unassigned') = (reader_membership_id is null))
);

create unique index assignments_unique_juz_per_day
  on public.assignments (group_day_id, juz);
create unique index assignments_unique_seat_per_day
  on public.assignments (group_day_id, seat_number);
create index assignments_day_status_idx
  on public.assignments (group_day_id, status);

-- ---------------------------------------------------------------------------
-- completion_records (append-only history of completion actions)
-- ---------------------------------------------------------------------------
create table public.completion_records (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid not null references public.assignments (id)
    on delete cascade,
  actor_user_id uuid not null references public.profiles (id),
  action public.completion_action not null,
  client_recorded_at timestamptz not null,
  recorded_at timestamptz not null default now(),
  source public.completion_source not null default 'online'
);

create index completion_records_assignment_idx
  on public.completion_records (assignment_id);

-- ---------------------------------------------------------------------------
-- Rotation helper (immutable, pure; research R1 / supabase-rpc contract)
-- ---------------------------------------------------------------------------
create or replace function public.juz_for_seat(
  seat int, start_juz int, day_index int)
returns int
language sql
immutable
as $$
  select (((start_juz - 1) + (seat - 1) + day_index) % 30) + 1;
$$;

-- ---------------------------------------------------------------------------
-- Group-local date: date((t AT TIME ZONE tz) - day_start_time) (research R2)
-- ---------------------------------------------------------------------------
create or replace function public.group_local_date(
  p_group uuid, p_ts timestamptz)
returns date
language plpgsql
stable
as $$
declare
  v_tz text;
  v_start time;
begin
  select timezone, day_start_time into v_tz, v_start
  from public.groups where id = p_group;
  if not found then
    raise exception 'group_not_found' using errcode = 'P0001';
  end if;
  return date((p_ts at time zone v_tz) - v_start);
end;
$$;

-- updated_at touch for groups
create or replace function public.groups_touch_updated_at()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger groups_touch_updated_at
  before update on public.groups
  for each row
  execute function public.groups_touch_updated_at();

-- ---------------------------------------------------------------------------
-- RLS: members read their group's rows; ALL direct writes denied.
-- (Member-select policies per supabase-rpc contract "Privacy guarantees".)
-- ---------------------------------------------------------------------------
alter table public.groups enable row level security;
alter table public.group_memberships enable row level security;
alter table public.join_requests enable row level security;
alter table public.group_days enable row level security;
alter table public.assignments enable row level security;
alter table public.completion_records enable row level security;

-- helper: active membership check for the caller (used by policies)
create or replace function public.is_active_member(p_group uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.group_memberships m
    where m.group_id = p_group
      and m.user_id = auth.uid()
      and m.status = 'active'
  );
$$;

create policy groups_select_member
  on public.groups for select to authenticated
  using (public.is_active_member(id));

create policy memberships_select_member
  on public.group_memberships for select to authenticated
  using (public.is_active_member(group_id));

create policy join_requests_select_member_or_own
  on public.join_requests for select to authenticated
  using (
    public.is_active_member(group_id)
    or user_id = auth.uid()
  );

create policy group_days_select_member
  on public.group_days for select to authenticated
  using (public.is_active_member(group_id));

create policy assignments_select_member
  on public.assignments for select to authenticated
  using (public.is_active_member(group_day_id));

create policy completion_records_select_member
  on public.completion_records for select to authenticated
  using (
    exists (
      select 1
      from public.assignments a
      join public.group_days d on d.id = a.group_day_id
      where a.id = completion_records.assignment_id
        and public.is_active_member(d.group_id)
    )
  );

-- Deny-all writes: no INSERT/UPDATE/DELETE policies exist, so RLS blocks
-- client writes; grant only select through the API.
grant select on public.groups, public.group_memberships,
  public.join_requests, public.group_days, public.assignments,
  public.completion_records to authenticated;
