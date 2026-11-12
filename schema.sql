-- PORTAL SEPAK TAKRAW MSSM: Supabase schema
-- Jalankan sekali di Supabase > SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  role text not null default 'viewer' check (role in ('viewer','admin')),
  created_at timestamptz not null default now()
);

create or replace function public.create_profile_for_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles(id, display_name, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email,'@',1)), 'viewer')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
after insert on auth.users
for each row execute procedure public.create_profile_for_new_user();

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

create table if not exists public.seasons (
  id uuid primary key default gen_random_uuid(),
  year integer not null unique,
  title text not null,
  is_active boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.teams (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  name text not null,
  state_code text,
  category text not null check (category in ('Bawah 12','Bawah 15','Bawah 18','Terbuka')),
  logo_url text,
  created_at timestamptz not null default now(),
  unique(season_id, name, category)
);

create table if not exists public.players (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  full_name text not null,
  jersey_number integer,
  position text,
  school text,
  created_at timestamptz not null default now()
);

create table if not exists public.matches (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  category text not null,
  round_name text,
  court text,
  match_date timestamptz,
  team_a_id uuid references public.teams(id) on delete set null,
  team_b_id uuid references public.teams(id) on delete set null,
  sets_a integer not null default 0,
  sets_b integer not null default 0,
  status text not null default 'Akan Datang' check (status in ('Akan Datang','Sedang Berlangsung','Tamat','Dibatalkan')),
  notes text,
  created_at timestamptz not null default now(),
  check (team_a_id is null or team_b_id is null or team_a_id <> team_b_id)
);

create table if not exists public.officials (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  full_name text not null,
  role_title text not null,
  organization text,
  created_at timestamptz not null default now()
);

create table if not exists public.galleries (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  title text not null,
  description text,
  image_url text not null,
  album_date date,
  created_at timestamptz not null default now()
);

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  season_id uuid references public.seasons(id) on delete cascade,
  title text not null,
  body text not null,
  is_published boolean not null default false,
  published_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.live_streams (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  title text not null,
  stream_url text not null,
  is_live boolean not null default false,
  created_at timestamptz not null default now()
);

-- Carta kedudukan asas: 2 mata menang, 0 mata kalah.
create or replace view public.standings as
with appearances as (
  select m.season_id, m.category, m.team_a_id as team_id,
         1 as played,
         case when m.sets_a > m.sets_b then 1 else 0 end as won,
         case when m.sets_a < m.sets_b then 1 else 0 end as lost,
         m.sets_a as sets_for, m.sets_b as sets_against,
         case when m.sets_a > m.sets_b then 2 else 0 end as points
  from public.matches m
  where m.status = 'Tamat' and m.team_a_id is not null and m.team_b_id is not null
  union all
  select m.season_id, m.category, m.team_b_id,
         1,
         case when m.sets_b > m.sets_a then 1 else 0 end,
         case when m.sets_b < m.sets_a then 1 else 0 end,
         m.sets_b, m.sets_a,
         case when m.sets_b > m.sets_a then 2 else 0 end
  from public.matches m
  where m.status = 'Tamat' and m.team_a_id is not null and m.team_b_id is not null
)
select t.season_id, t.category, t.id as team_id, t.name as team_name,
       coalesce(sum(a.played),0)::integer as played,
       coalesce(sum(a.won),0)::integer as won,
       coalesce(sum(a.lost),0)::integer as lost,
       coalesce(sum(a.sets_for),0)::integer as sets_for,
       coalesce(sum(a.sets_against),0)::integer as sets_against,
       coalesce(sum(a.points),0)::integer as points
from public.teams t
left join appearances a on a.team_id = t.id
group by t.season_id, t.category, t.id, t.name;

-- RLS: orang awam boleh baca data portal; hanya admin boleh menulis.
alter table public.profiles enable row level security;
alter table public.seasons enable row level security;
alter table public.teams enable row level security;
alter table public.players enable row level security;
alter table public.matches enable row level security;
alter table public.officials enable row level security;
alter table public.galleries enable row level security;
alter table public.announcements enable row level security;
alter table public.live_streams enable row level security;

drop policy if exists "profile read self or admin" on public.profiles;
create policy "profile read self or admin" on public.profiles for select
using (id = auth.uid() or public.is_admin());

drop policy if exists "admin update profile" on public.profiles;
create policy "admin update profile" on public.profiles for update
using (public.is_admin()) with check (public.is_admin());

do $$
declare t text;
begin
  foreach t in array array['seasons','teams','players','matches','officials','galleries','announcements','live_streams'] loop
    execute format('drop policy if exists "public read %1$s" on public.%1$I', t);
    execute format('create policy "public read %1$s" on public.%1$I for select using (true)', t);
    execute format('drop policy if exists "admin insert %1$s" on public.%1$I', t);
    execute format('create policy "admin insert %1$s" on public.%1$I for insert with check (public.is_admin())', t);
    execute format('drop policy if exists "admin update %1$s" on public.%1$I', t);
    execute format('create policy "admin update %1$s" on public.%1$I for update using (public.is_admin()) with check (public.is_admin())', t);
    execute format('drop policy if exists "admin delete %1$s" on public.%1$I', t);
    execute format('create policy "admin delete %1$s" on public.%1$I for delete using (public.is_admin())', t);
  end loop;
end $$;

grant usage on schema public to anon, authenticated;
grant select on public.seasons, public.teams, public.players, public.matches,
  public.officials, public.galleries, public.announcements, public.live_streams,
  public.standings to anon, authenticated;
grant insert, update, delete on public.seasons, public.teams, public.players,
  public.matches, public.officials, public.galleries, public.announcements,
  public.live_streams to authenticated;
grant select, update on public.profiles to authenticated;
