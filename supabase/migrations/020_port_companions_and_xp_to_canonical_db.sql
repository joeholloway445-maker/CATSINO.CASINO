-- Port companion_inventory + XP/faction support to whatever database this
-- runs against. Written defensively (IF NOT EXISTS / OR REPLACE everywhere)
-- so it's safe to apply both to CATSINO.CASINO's own database (where most
-- of this already exists from 007_xp_and_faction.sql / 008_companions_inventory.sql)
-- and to Periliminal.Space (the now-canonical database), which is missing
-- companion_inventory entirely and never had total_xp/level/faction columns
-- on profiles -- companions/summon and battlepass/xp have been silently
-- broken there.

alter table public.profiles
  add column if not exists faction text not null default 'Factionless',
  add column if not exists total_xp bigint not null default 0,
  add column if not exists level integer not null default 1,
  add column if not exists total_winnings bigint not null default 0;

create or replace function public.add_profile_xp(p_amount integer)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_new_xp bigint;
  v_new_level integer;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  if p_amount <= 0 then raise exception 'Invalid amount'; end if;

  update public.profiles
  set total_xp = total_xp + p_amount
  where id = auth.uid()
  returning total_xp into v_new_xp;

  v_new_level := floor(sqrt(v_new_xp::float / 500))::integer;

  update public.profiles
  set level = greatest(1, v_new_level)
  where id = auth.uid();

  return jsonb_build_object('total_xp', v_new_xp, 'level', greatest(1, v_new_level));
end;
$$;

create or replace function public.set_player_faction(p_faction text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  if p_faction not in ('SovereignCrown', 'WildlandsAscendant', 'VeiledCurrent', 'Factionless') then
    raise exception 'Invalid faction: %', p_faction;
  end if;
  update public.profiles
  set faction = p_faction
  where id = auth.uid();
end;
$$;

create table if not exists public.companion_inventory (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  companion_id text not null,
  faction text not null default 'FL',
  rarity text not null default 'common',
  level int not null default 1,
  xp int not null default 0,
  equipped boolean not null default false,
  slot int,
  acquired_at timestamptz default now(),
  unique(user_id, companion_id)
);

alter table public.companion_inventory enable row level security;

drop policy if exists "Users own companions" on public.companion_inventory;
create policy "Users own companions" on public.companion_inventory
  for all using (auth.uid() = user_id);

create or replace function public.grant_starter_companion()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.companion_inventory (user_id, companion_id, faction, rarity, equipped, slot)
  values (new.id, 'FL001', 'FL', 'common', true, 1)
  on conflict do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_starter_companion on auth.users;
create trigger on_auth_user_starter_companion
  after insert on auth.users
  for each row execute procedure public.grant_starter_companion();

create or replace function public.unlock_companion(p_companion_id text, p_faction text default 'FL', p_rarity text default 'common')
returns json language plpgsql security definer set search_path = public as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  insert into public.companion_inventory (user_id, companion_id, faction, rarity)
  values (v_user_id, p_companion_id, p_faction, p_rarity)
  on conflict (user_id, companion_id) do nothing;

  return json_build_object('success', true, 'companion_id', p_companion_id);
end;
$$;
