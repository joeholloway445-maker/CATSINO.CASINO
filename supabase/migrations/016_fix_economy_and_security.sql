-- Fix two critical issues found in audit:
--
-- 1. record_game_result_v2 (014_final_schema.sql) is a security definer function,
--    callable by any authenticated user via the public Supabase RPC endpoint
--    (Postgres grants EXECUTE to PUBLIC by default unless revoked). It applies
--    `coins = coins + p_win - p_bet` with no balance check, no row lock, and
--    fully client-controlled p_bet/p_win — anyone can call it directly to mint
--    unlimited coins. Nothing in the app currently calls it, so revoke public
--    execute access and harden the body in case it's wired up later.
--
-- 2. spin_slot (001_initial_schema.sql) and spin_wheel (002_lucky_cat_jackpot.sql)
--    both have positive expected value for the player (~1.80x and ~1.29x bet
--    respectively) — the house loses coins on every play on average, which
--    hyperinflates the Cat Coins economy. Rebalance both to ~0.90x EV (90% RTP),
--    a standard generous-but-sustainable rate for a free social casino. Win
--    tiers/multipliers are unchanged (the wheel's segment indices must keep
--    matching WHEEL_SEGMENTS in app/games/lucky-cat-jackpot/WheelGame.tsx) —
--    only the probability of landing each tier changes.

-- ── Lock down record_game_result_v2 ───────────────────────────────────────
revoke execute on function public.record_game_result_v2(text, int, int, numeric) from public;
revoke execute on function public.record_game_result_v2(text, int, int, numeric) from anon;
revoke execute on function public.record_game_result_v2(text, int, int, numeric) from authenticated;

create or replace function public.record_game_result_v2(
  p_game text,
  p_bet int,
  p_win int,
  p_multiplier numeric default 1.0
) returns json language plpgsql security definer as $$
declare
  v_user_id uuid := auth.uid();
  v_balance int;
begin
  if v_user_id is null then raise exception 'Not authenticated'; end if;
  if p_bet < 0 or p_win < 0 then raise exception 'Invalid amount'; end if;

  select coins into v_balance from public.wallets where user_id = v_user_id for update;
  if v_balance is null then raise exception 'Wallet not found'; end if;
  if v_balance < p_bet then raise exception 'Insufficient balance'; end if;

  update public.wallets
  set coins = coins + p_win - p_bet
  where user_id = v_user_id;

  update public.profiles
  set
    total_wagered = total_wagered + p_bet,
    total_wins = total_wins + (case when p_win > 0 then 1 else 0 end)
  where id = v_user_id;

  insert into public.game_stats (user_id, game, bet, win, multiplier)
  values (v_user_id, p_game, p_bet, p_win, p_multiplier)
  on conflict do nothing;

  return json_build_object('success', true, 'net', p_win - p_bet);
end;
$$;

-- ── Rebalance spin_slot to ~90% RTP (was ~180%) ───────────────────────────
create or replace function public.spin_slot(p_game text, p_bet bigint)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_balance bigint;
  v_roll double precision;
  v_multiplier numeric;
  v_win bigint;
  v_reels jsonb;
  v_symbol text;
  v_other text[] := array['CAT','FISH','COIN','YARN'];
begin
  if v_user is null then
    raise exception 'Not authenticated';
  end if;

  if p_bet <= 0 or p_bet > 100000 then
    raise exception 'Invalid bet';
  end if;

  select coins into v_balance from public.wallets where user_id = v_user for update;

  if v_balance is null then
    raise exception 'Wallet not found';
  end if;

  if v_balance < p_bet then
    raise exception 'Insufficient balance';
  end if;

  v_roll := random();

  if v_roll < 0.75 then
    v_multiplier := 0;
  elsif v_roll < 0.90 then
    v_multiplier := 1.5;
  elsif v_roll < 0.975 then
    v_multiplier := 3;
  elsif v_roll < 0.995 then
    v_multiplier := 10;
  else
    v_multiplier := 50;
  end if;

  v_win := floor(p_bet * v_multiplier);

  if v_multiplier = 0 then
    -- guaranteed non-matching reels for a clear loss
    v_reels := jsonb_build_array(
      v_other[1 + floor(random() * 4)::int],
      v_other[1 + floor(random() * 4)::int],
      v_other[1 + floor(random() * 4)::int]
    );
    if v_reels->>0 = v_reels->>1 and v_reels->>1 = v_reels->>2 then
      v_reels := jsonb_set(v_reels, '{2}', to_jsonb(v_other[1 + (floor(random()*3)::int + 2) % 4]));
    end if;
  else
    v_symbol := case
      when v_multiplier = 1.5 then 'CAT'
      when v_multiplier = 3 then 'FISH'
      when v_multiplier = 10 then 'BOWL'
      else 'CROWN'
    end;
    v_reels := jsonb_build_array(v_symbol, v_symbol, v_symbol);
  end if;

  update public.wallets
  set coins = coins - p_bet + v_win,
      xp = xp + floor(v_win / 10),
      updated_at = now()
  where user_id = v_user;

  insert into public.spins (user_id, game, bet, win, multiplier, reels)
  values (v_user, p_game, p_bet, v_win, v_multiplier, v_reels);

  return jsonb_build_object(
    'reels', v_reels,
    'win', v_win,
    'multiplier', v_multiplier,
    'balance', (select coins from public.wallets where user_id = v_user),
    'xp', (select xp from public.wallets where user_id = v_user)
  );
end;
$$;

-- ── Rebalance spin_wheel to ~89% RTP (was ~129%) ──────────────────────────
create or replace function public.spin_wheel(p_bet bigint)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_balance bigint;
  v_roll double precision;
  v_multiplier numeric;
  v_win bigint;
  v_segment int;
  v_zero_segments int[] := array[0, 2, 5];
begin
  if v_user is null then
    raise exception 'Not authenticated';
  end if;

  if p_bet <= 0 or p_bet > 100000 then
    raise exception 'Invalid bet';
  end if;

  select coins into v_balance from public.wallets where user_id = v_user for update;

  if v_balance is null then
    raise exception 'Wallet not found';
  end if;

  if v_balance < p_bet then
    raise exception 'Insufficient balance';
  end if;

  v_roll := random();

  if v_roll < 0.62 then
    v_multiplier := 0;
    v_segment := v_zero_segments[1 + floor(random() * 3)::int];
  elsif v_roll < 0.7582 then
    v_multiplier := 0.5;
    v_segment := 1;
  elsif v_roll < 0.8618 then
    v_multiplier := 1;
    v_segment := 3;
  elsif v_roll < 0.9447 then
    v_multiplier := 2;
    v_segment := 4;
  elsif v_roll < 0.9862 then
    v_multiplier := 5;
    v_segment := 6;
  else
    v_multiplier := 25;
    v_segment := 7;
  end if;

  v_win := floor(p_bet * v_multiplier);

  update public.wallets
  set coins = coins - p_bet + v_win,
      xp = xp + floor(v_win / 10),
      updated_at = now()
  where user_id = v_user;

  insert into public.spins (user_id, game, bet, win, multiplier, reels)
  values (v_user, 'lucky_cat_jackpot', p_bet, v_win, v_multiplier, jsonb_build_array(v_segment));

  return jsonb_build_object(
    'segment', v_segment,
    'multiplier', v_multiplier,
    'win', v_win,
    'balance', (select coins from public.wallets where user_id = v_user),
    'xp', (select xp from public.wallets where user_id = v_user)
  );
end;
$$;
