-- Add faction to profiles
alter table public.profiles
  add column if not exists faction text not null default 'Factionless';

-- XP level recalculation view
create or replace view public.profiles_with_level as
select
  *,
  floor(sqrt(total_xp::float / 500))::integer as computed_level
from public.profiles;

-- RPC to add XP to profile
create or replace function public.add_profile_xp(p_amount integer)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_new_xp bigint;
  v_new_level integer;
begin
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

-- RPC to set faction
create or replace function public.set_player_faction(p_faction text)
returns void
language plpgsql
security definer
as $$
begin
  if p_faction not in ('SovereignCrown', 'WildlandsAscendant', 'VeiledCurrent', 'Factionless') then
    raise exception 'Invalid faction: %', p_faction;
  end if;
  update public.profiles
  set faction = p_faction
  where id = auth.uid();
end;
$$;

-- Faction leaderboard view
create or replace view public.faction_scores as
select
  faction,
  count(*) as member_count,
  sum(total_winnings) as total_winnings,
  avg(level) as avg_level
from public.profiles
group by faction
order by total_winnings desc;
