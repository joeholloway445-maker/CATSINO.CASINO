-- Friends table
create table if not exists public.friends (
  user_id  uuid not null references auth.users(id) on delete cascade,
  friend_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, friend_id)
);

alter table public.friends enable row level security;

create policy "Users can manage own friends"
  on public.friends for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can see who added them"
  on public.friends for select
  using (auth.uid() = friend_id);

-- Guilds table
create table if not exists public.guilds (
  id          uuid primary key default gen_random_uuid(),
  name        text not null unique,
  faction     text not null default 'Factionless',
  created_by  uuid not null references auth.users(id) on delete cascade,
  created_at  timestamptz not null default now(),
  member_count integer not null default 1,
  description text not null default ''
);

alter table public.guilds enable row level security;

create policy "Anyone can read guilds"
  on public.guilds for select using (true);

create policy "Owner can update guild"
  on public.guilds for update
  using (auth.uid() = created_by);

-- Guild memberships
create table if not exists public.guild_members (
  guild_id   uuid not null references public.guilds(id) on delete cascade,
  user_id    uuid not null references auth.users(id) on delete cascade,
  role       text not null default 'member',
  joined_at  timestamptz not null default now(),
  primary key (guild_id, user_id)
);

alter table public.guild_members enable row level security;

create policy "Anyone can read guild members"
  on public.guild_members for select using (true);

create policy "Users can leave guilds"
  on public.guild_members for delete
  using (auth.uid() = user_id);

-- Add total_winnings to profiles if not present
alter table public.profiles
  add column if not exists total_winnings bigint not null default 0;

-- Update total_winnings from spin history
create or replace function public.update_total_winnings()
returns trigger
language plpgsql
security definer
as $$
begin
  if new.payout > 0 then
    update public.profiles
    set total_winnings = total_winnings + new.payout
    where id = new.user_id;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_update_winnings on public.spin_results;
create trigger trg_update_winnings
  after insert on public.spin_results
  for each row execute function public.update_total_winnings();
