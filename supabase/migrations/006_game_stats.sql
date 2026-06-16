-- Per-game statistics table
create table if not exists public.game_stats (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  game       text not null,
  action     text not null default 'play',
  bet        integer not null default 0,
  payout     integer not null default 0,
  result     text not null default '',
  metadata   jsonb not null default '{}',
  created_at timestamptz not null default now()
);

alter table public.game_stats enable row level security;

create policy "Users can read own game stats"
  on public.game_stats for select
  using (auth.uid() = user_id);

create policy "Users can insert own game stats"
  on public.game_stats for insert
  with check (auth.uid() = user_id);

-- Aggregate view for leaderboard
create or replace view public.player_leaderboard as
select
  p.id,
  p.username,
  p.level,
  p.total_winnings,
  p.total_xp,
  count(gs.id) as total_games_played,
  coalesce(sum(case when gs.payout > gs.bet then 1 else 0 end), 0) as total_wins,
  coalesce(sum(gs.bet), 0) as total_wagered,
  coalesce(sum(gs.payout), 0) as total_paid_out
from public.profiles p
left join public.game_stats gs on gs.user_id = p.id
group by p.id, p.username, p.level, p.total_winnings, p.total_xp;

-- Function to record a game result
create or replace function public.record_game_result(
  p_game text,
  p_action text,
  p_bet integer,
  p_payout integer,
  p_result text,
  p_metadata jsonb default '{}'
)
returns void
language plpgsql
security definer
as $$
begin
  insert into public.game_stats (user_id, game, action, bet, payout, result, metadata)
  values (auth.uid(), p_game, p_action, p_bet, p_payout, p_result, p_metadata);

  -- Update total_winnings if net positive
  if p_payout > 0 then
    update public.profiles
    set total_winnings = total_winnings + p_payout
    where id = auth.uid();
  end if;
end;
$$;

-- Indexes
create index if not exists idx_game_stats_user on public.game_stats(user_id);
create index if not exists idx_game_stats_game on public.game_stats(game);
create index if not exists idx_game_stats_created on public.game_stats(created_at desc);
