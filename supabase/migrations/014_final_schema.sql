-- Final schema cleanup and missing columns

-- Add title column to profiles
alter table public.profiles
  add column if not exists title text not null default 'Newcomer',
  add column if not exists frame text not null default 'basic',
  add column if not exists total_wins int not null default 0,
  add column if not exists total_wagered int not null default 0,
  add column if not exists companions_count int not null default 0;

-- Wallets: add gems currency
alter table public.wallets
  add column if not exists gems int not null default 0;

-- Record a game result (called server-side after each game)
create or replace function public.record_game_result_v2(
  p_game text,
  p_bet int,
  p_win int,
  p_multiplier numeric default 1.0
) returns json language plpgsql security definer as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then raise exception 'Not authenticated'; end if;

  -- Update wallet
  update public.wallets
  set coins = coins + p_win - p_bet
  where user_id = v_user_id;

  -- Update profile stats
  update public.profiles
  set
    total_wagered = total_wagered + p_bet,
    total_wins = total_wins + (case when p_win > 0 then 1 else 0 end)
  where id = v_user_id;

  -- Insert into game_stats if table exists
  insert into public.game_stats (user_id, game, bet, win, multiplier)
  values (v_user_id, p_game, p_bet, p_win, p_multiplier)
  on conflict do nothing;

  return json_build_object('success', true, 'net', p_win - p_bet);
end;
$$;

-- Update total_winnings trigger to also count game_stats wins
create or replace function public.sync_total_winnings()
returns trigger language plpgsql security definer as $$
begin
  update public.profiles
  set total_wins = (
    select count(*) from public.game_stats
    where user_id = new.user_id and win > 0
  )
  where id = new.user_id;
  return new;
end;
$$;

create or replace trigger sync_wins_on_game_result
  after insert on public.game_stats
  for each row execute procedure public.sync_total_winnings();

-- Set player title
create or replace function public.set_player_title(p_title text)
returns json language plpgsql security definer as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then raise exception 'Not authenticated'; end if;
  update public.profiles set title = p_title where id = v_user_id;
  return json_build_object('success', true, 'title', p_title);
end;
$$;

-- Set player frame
create or replace function public.set_player_frame(p_frame text)
returns json language plpgsql security definer as $$
declare
  v_user_id uuid := auth.uid();
  v_valid_frames text[] := array['basic','bolt','titan','ghost','royal','storm','iron','void',
    'ember','atlas','silk','nova','frost','blaze','rock','prism','wind','colossus','mirage','sovereign'];
begin
  if v_user_id is null then raise exception 'Not authenticated'; end if;
  if not (p_frame = any(v_valid_frames)) then raise exception 'Invalid frame'; end if;
  update public.profiles set frame = p_frame where id = v_user_id;
  return json_build_object('success', true, 'frame', p_frame);
end;
$$;
