-- black-cat-21, nine-lives-holdem, and feline-fortune all have live frontends
-- but call play_blackjack / play_holdem / draw_fortune, which never existed
-- in any prior migration -- those endpoints have been dead since launch.
-- This adds working, server-authoritative implementations. Card outcomes
-- (deck order, dealer hole card, future draws) are kept server-side in a
-- session table keyed by user_id rather than trusted from the client, so a
-- user cannot replay/forge game_state to control results.

create table if not exists public.blackjack_sessions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  deck integer[] not null,
  pos integer not null,
  player_hand integer[] not null,
  dealer_hand integer[] not null,
  bet bigint not null,
  doubled boolean not null default false,
  created_at timestamptz not null default now()
);
alter table public.blackjack_sessions enable row level security;
create policy "Users manage own blackjack session" on public.blackjack_sessions
  for select using (auth.uid() = user_id);

create table if not exists public.holdem_sessions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  deck integer[] not null,
  pos integer not null,
  player_hand integer[] not null,
  dealer_hand integer[] not null,
  community integer[] not null default '{}',
  ante bigint not null,
  player_paid bigint not null,
  phase text not null,
  created_at timestamptz not null default now()
);
alter table public.holdem_sessions enable row level security;
create policy "Users manage own holdem session" on public.holdem_sessions
  for select using (auth.uid() = user_id);

-- ── shared card-value helpers ──────────────────────────────────────────
create or replace function public.bj_card_score(p_hand integer[])
returns integer language plpgsql immutable as $$
declare
  v_sum integer := 0;
  v_aces integer := 0;
  v_rank integer;
  v_card integer;
begin
  foreach v_card in array p_hand loop
    v_rank := v_card % 13;
    if v_rank = 0 then
      v_sum := v_sum + 11;
      v_aces := v_aces + 1;
    elsif v_rank >= 9 then
      v_sum := v_sum + 10;
    else
      v_sum := v_sum + v_rank + 1;
    end if;
  end loop;
  while v_sum > 21 and v_aces > 0 loop
    v_sum := v_sum - 10;
    v_aces := v_aces - 1;
  end loop;
  return v_sum;
end;
$$;

-- ranks a 5-card poker hand: class*1000 + sum of card values as a tiebreak
create or replace function public.poker_hand_score(p_hand integer[])
returns integer language plpgsql immutable as $$
declare
  v_vals integer[];
  v_suits integer[];
  v_is_flush boolean;
  v_is_straight boolean;
  v_min_val integer;
  v_max_val integer;
  v_max_count integer := 0;
  v_pair_count integer := 0;
  v_cnt integer;
  v_i integer;
  v_class integer := 0;
  v_kicker integer := 0;
begin
  v_vals := array(select (p_hand[g] % 13) from generate_series(1,5) as g);
  v_suits := array(select floor(p_hand[g]::numeric / 13)::integer from generate_series(1,5) as g);
  v_is_flush := (select count(distinct x) from unnest(v_suits) x) = 1;
  v_min_val := (select min(x) from unnest(v_vals) x);
  v_max_val := (select max(x) from unnest(v_vals) x);
  v_is_straight := (select count(distinct x) from unnest(v_vals) x) = 5
    and (v_max_val - v_min_val = 4
      or (v_max_val = 12 and (select count(*) from unnest(v_vals) x where x in (0,1,2,3,12)) = 5));

  for v_i in 0..12 loop
    v_cnt := (select count(*) from unnest(v_vals) x where x = v_i);
    if v_cnt > v_max_count then v_max_count := v_cnt; end if;
    if v_cnt = 2 then v_pair_count := v_pair_count + 1; end if;
  end loop;

  if v_is_flush and v_is_straight and v_min_val = 0 and v_max_val = 12
    and (select count(*) from unnest(v_vals) x where x in (0,9,10,11,12)) = 5 then
    v_class := 9;
  elsif v_is_flush and v_is_straight then v_class := 8;
  elsif v_max_count = 4 then v_class := 7;
  elsif v_max_count = 3 and v_pair_count = 1 then v_class := 6;
  elsif v_is_flush then v_class := 5;
  elsif v_is_straight then v_class := 4;
  elsif v_max_count = 3 then v_class := 3;
  elsif v_pair_count = 2 then v_class := 2;
  elsif v_pair_count = 1 then v_class := 1;
  else v_class := 0;
  end if;

  v_kicker := (select sum(case when x = 0 then 14 else x + 1 end) from unnest(v_vals) x);
  return v_class * 1000 + v_kicker;
end;
$$;

-- best 5-of-7 score
create or replace function public.best_seven_score(p_cards integer[])
returns integer language plpgsql immutable as $$
declare
  v_best integer := -1;
  v_score integer;
  a integer; b integer; c integer; d integer; e integer;
  v_combo integer[];
begin
  for a in 1..3 loop
    for b in a+1..4 loop
      for c in b+1..5 loop
        for d in c+1..6 loop
          for e in d+1..7 loop
            v_combo := array[p_cards[a], p_cards[b], p_cards[c], p_cards[d], p_cards[e]];
            v_score := public.poker_hand_score(v_combo);
            if v_score > v_best then v_best := v_score; end if;
          end loop;
        end loop;
      end loop;
    end loop;
  end loop;
  return v_best;
end;
$$;

create or replace function public.shuffled_deck()
returns integer[] language plpgsql as $$
declare
  v_deck integer[] := array(select generate_series(0, 51));
  v_i integer; v_j integer; v_temp integer;
begin
  for v_i in reverse 51..1 loop
    v_j := floor(random() * (v_i + 1))::integer;
    v_temp := v_deck[v_i + 1];
    v_deck[v_i + 1] := v_deck[v_j + 1];
    v_deck[v_j + 1] := v_temp;
  end loop;
  return v_deck;
end;
$$;

-- ── Black Cat 21 ───────────────────────────────────────────────────────
create or replace function public.play_blackjack(p_action text, p_bet bigint, p_game_state jsonb default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_balance bigint;
  v_deck integer[];
  v_pos integer;
  v_player integer[];
  v_dealer integer[];
  v_bet bigint;
  v_doubled boolean;
  v_player_score integer;
  v_dealer_score integer;
  v_win bigint;
  v_result text;
  v_done boolean := false;
begin
  if v_user is null then raise exception 'Not authenticated'; end if;

  if p_action = 'deal' then
    if p_bet <= 0 or p_bet > 100000 then raise exception 'Invalid bet'; end if;
    delete from public.blackjack_sessions where user_id = v_user;

    select coins into v_balance from public.wallets where user_id = v_user for update;
    if v_balance is null then raise exception 'Wallet not found'; end if;
    if v_balance < p_bet then raise exception 'Insufficient balance'; end if;

    update public.wallets set coins = coins - p_bet, updated_at = now() where user_id = v_user;

    v_deck := public.shuffled_deck();
    v_player := array[v_deck[1], v_deck[3]];
    v_dealer := array[v_deck[2], v_deck[4]];
    v_pos := 5;
    v_bet := p_bet;
    v_doubled := false;

    v_player_score := public.bj_card_score(v_player);
    v_dealer_score := public.bj_card_score(v_dealer);

    if v_player_score = 21 or v_dealer_score = 21 then
      v_done := true;
      if v_player_score = 21 and v_dealer_score = 21 then
        v_result := 'PUSH'; v_win := v_bet;
      elsif v_player_score = 21 then
        v_result := 'blackjack'; v_win := floor(v_bet * 2.5);
      else
        v_result := 'LOSE'; v_win := 0;
      end if;
      if v_win > 0 then
        update public.wallets set coins = coins + v_win, updated_at = now() where user_id = v_user;
      end if;
    else
      insert into public.blackjack_sessions (user_id, deck, pos, player_hand, dealer_hand, bet, doubled)
      values (v_user, v_deck, v_pos, v_player, v_dealer, v_bet, v_doubled);
      v_win := 0; v_result := null;
    end if;

  elsif p_action in ('hit', 'stand', 'double') then
    select deck, pos, player_hand, dealer_hand, bet, doubled
      into v_deck, v_pos, v_player, v_dealer, v_bet, v_doubled
      from public.blackjack_sessions where user_id = v_user for update;
    if v_deck is null then raise exception 'No active hand'; end if;

    if p_action = 'double' then
      if array_length(v_player, 1) <> 2 or v_doubled then raise exception 'Cannot double now'; end if;
      select coins into v_balance from public.wallets where user_id = v_user for update;
      if v_balance < v_bet then raise exception 'Insufficient balance to double'; end if;
      update public.wallets set coins = coins - v_bet, updated_at = now() where user_id = v_user;
      v_bet := v_bet * 2;
      v_doubled := true;
      v_player := v_player || v_deck[v_pos]; v_pos := v_pos + 1;
    elsif p_action = 'hit' then
      v_player := v_player || v_deck[v_pos]; v_pos := v_pos + 1;
    end if;

    v_player_score := public.bj_card_score(v_player);

    if p_action = 'hit' and v_player_score <= 21 then
      update public.blackjack_sessions set player_hand = v_player, pos = v_pos where user_id = v_user;
      v_done := false; v_win := 0; v_result := null;
    else
      v_done := true;
      if v_player_score > 21 then
        v_dealer_score := public.bj_card_score(v_dealer);
        v_result := 'bust'; v_win := 0;
      else
        v_dealer_score := public.bj_card_score(v_dealer);
        while v_dealer_score < 17 loop
          v_dealer := v_dealer || v_deck[v_pos]; v_pos := v_pos + 1;
          v_dealer_score := public.bj_card_score(v_dealer);
        end loop;
        if v_dealer_score > 21 or v_dealer_score < v_player_score then
          v_result := 'WIN'; v_win := v_bet * 2;
        elsif v_dealer_score > v_player_score then
          v_result := 'LOSE'; v_win := 0;
        else
          v_result := 'PUSH'; v_win := v_bet;
        end if;
      end if;
      if v_win > 0 then
        update public.wallets set coins = coins + v_win, updated_at = now() where user_id = v_user;
      end if;
      delete from public.blackjack_sessions where user_id = v_user;
    end if;
  else
    raise exception 'Invalid action';
  end if;

  if v_done then
    insert into public.spins (user_id, game, bet, win, multiplier, reels)
    values (v_user, 'black-cat-21', v_bet, v_win, case when v_bet > 0 then v_win::numeric / v_bet else 0 end,
      jsonb_build_object('player', v_player, 'dealer', v_dealer));
  end if;

  return jsonb_build_object(
    'done', v_done,
    'result', v_result,
    'win', v_win,
    'new_balance', (select coins from public.wallets where user_id = v_user),
    'game_state', jsonb_build_object(
      'player_hand', to_jsonb(v_player),
      'dealer_hand', to_jsonb(v_dealer),
      'player_score', v_player_score,
      'dealer_score', public.bj_card_score(v_dealer),
      'bet', v_bet,
      'doubled', v_doubled
    )
  );
end;
$$;

-- ── Nine Lives Hold'em ───────────────────────────────────────────────
create or replace function public.play_holdem(p_action text, p_bet bigint, p_game_state jsonb default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_balance bigint;
  v_deck integer[];
  v_pos integer;
  v_player integer[];
  v_dealer integer[];
  v_community integer[];
  v_ante bigint;
  v_paid bigint;
  v_phase text;
  v_win bigint := 0;
  v_result text;
  v_done boolean := false;
  v_dealer_action text;
  v_dealer_flavors text[] := array['checks', 'calls', 'matches your bet', 'considers folding', 'raises an eyebrow'];
  v_player_score integer;
  v_dealer_score integer;
begin
  if v_user is null then raise exception 'Not authenticated'; end if;
  v_dealer_action := v_dealer_flavors[1 + floor(random() * array_length(v_dealer_flavors, 1))::int];

  if p_action = 'deal' then
    if p_bet <= 0 or p_bet > 100000 then raise exception 'Invalid bet'; end if;
    delete from public.holdem_sessions where user_id = v_user;

    select coins into v_balance from public.wallets where user_id = v_user for update;
    if v_balance is null then raise exception 'Wallet not found'; end if;
    if v_balance < p_bet then raise exception 'Insufficient balance'; end if;

    update public.wallets set coins = coins - p_bet, updated_at = now() where user_id = v_user;

    v_deck := public.shuffled_deck();
    v_player := array[v_deck[1], v_deck[3]];
    v_dealer := array[v_deck[2], v_deck[4]];
    v_pos := 5;
    v_community := array[]::integer[];
    v_ante := p_bet;
    v_paid := p_bet;
    v_phase := 'preflop';

    insert into public.holdem_sessions (user_id, deck, pos, player_hand, dealer_hand, community, ante, player_paid, phase)
    values (v_user, v_deck, v_pos, v_player, v_dealer, v_community, v_ante, v_paid, v_phase);

  elsif p_action = 'fold' then
    delete from public.holdem_sessions where user_id = v_user returning deck, player_hand, dealer_hand, community, ante, player_paid, phase
      into v_deck, v_player, v_dealer, v_community, v_ante, v_paid, v_phase;
    if v_deck is null then raise exception 'No active hand'; end if;
    v_done := true; v_result := 'FOLD'; v_win := 0;

  elsif p_action in ('call', 'check', 'raise') then
    select deck, pos, player_hand, dealer_hand, community, ante, player_paid, phase
      into v_deck, v_pos, v_player, v_dealer, v_community, v_ante, v_paid, v_phase
      from public.holdem_sessions where user_id = v_user for update;
    if v_deck is null then raise exception 'No active hand'; end if;

    if p_action in ('call', 'raise') then
      if p_bet <= 0 then raise exception 'Invalid bet'; end if;
      select coins into v_balance from public.wallets where user_id = v_user for update;
      if v_balance < p_bet then raise exception 'Insufficient balance'; end if;
      update public.wallets set coins = coins - p_bet, updated_at = now() where user_id = v_user;
      v_paid := v_paid + p_bet;
    end if;

    if v_phase = 'preflop' then
      v_community := v_deck[v_pos:v_pos+2]; v_pos := v_pos + 3; v_phase := 'flop';
    elsif v_phase = 'flop' then
      v_community := v_community || v_deck[v_pos]; v_pos := v_pos + 1; v_phase := 'turn';
    elsif v_phase = 'turn' then
      v_community := v_community || v_deck[v_pos]; v_pos := v_pos + 1; v_phase := 'river';
    elsif v_phase = 'river' then
      v_phase := 'result';
    end if;

    if v_phase = 'result' then
      v_player_score := public.best_seven_score(v_player || v_community);
      v_dealer_score := public.best_seven_score(v_dealer || v_community);
      v_done := true;
      if v_player_score > v_dealer_score then
        v_result := 'WIN'; v_win := v_paid * 2;
      elsif v_dealer_score > v_player_score then
        v_result := 'LOSE'; v_win := 0;
      else
        v_result := 'PUSH'; v_win := v_paid;
      end if;
      delete from public.holdem_sessions where user_id = v_user;
    else
      update public.holdem_sessions
      set pos = v_pos, community = v_community, player_paid = v_paid, phase = v_phase
      where user_id = v_user;
    end if;
  else
    raise exception 'Invalid action';
  end if;

  if v_win > 0 then
    update public.wallets set coins = coins + v_win, updated_at = now() where user_id = v_user;
  end if;

  if v_done then
    insert into public.spins (user_id, game, bet, win, multiplier, reels)
    values (v_user, 'nine-lives-holdem', v_paid, v_win, case when v_paid > 0 then v_win::numeric / v_paid else 0 end,
      jsonb_build_object('player', v_player, 'dealer', v_dealer, 'community', v_community));
  end if;

  return jsonb_build_object(
    'done', v_done,
    'result', v_result,
    'win', v_win,
    'new_balance', (select coins from public.wallets where user_id = v_user),
    'game_state', jsonb_build_object(
      'player_hand', to_jsonb(v_player),
      'dealer_hand', to_jsonb(v_dealer),
      'community', to_jsonb(v_community),
      'pot', v_paid * 2,
      'ante', v_ante,
      'phase', v_phase,
      'dealer_action', v_dealer_action
    )
  );
end;
$$;

-- ── Feline Fortune ─────────────────────────────────────────────────────
-- card ids/multipliers must match FORTUNE_CARDS in FortuneGame.tsx.
-- Weighted so overall EV is ~92% of bet (generous-but-sustainable RTP).
create or replace function public.draw_fortune(p_bet bigint)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_balance bigint;
  v_roll double precision;
  v_card_index integer;
  v_multiplier numeric;
  v_win bigint;
begin
  if v_user is null then raise exception 'Not authenticated'; end if;
  if p_bet <= 0 or p_bet > 100000 then raise exception 'Invalid bet'; end if;

  select coins into v_balance from public.wallets where user_id = v_user for update;
  if v_balance is null then raise exception 'Wallet not found'; end if;
  if v_balance < p_bet then raise exception 'Insufficient balance'; end if;

  v_roll := random();

  if v_roll < 0.420 then v_card_index := 5; v_multiplier := 0;
  elsif v_roll < 0.600 then v_card_index := 4; v_multiplier := 1;
  elsif v_roll < 0.720 then v_card_index := 3; v_multiplier := 1.5;
  elsif v_roll < 0.840 then v_card_index := 7; v_multiplier := 1.5;
  elsif v_roll < 0.920 then v_card_index := 1; v_multiplier := 2;
  elsif v_roll < 0.970 then v_card_index := 2; v_multiplier := 2;
  elsif v_roll < 0.990 then v_card_index := 0; v_multiplier := 3;
  elsif v_roll < 0.998 then v_card_index := 6; v_multiplier := 5;
  else v_card_index := 8; v_multiplier := 10;
  end if;

  v_win := floor(p_bet * v_multiplier);

  update public.wallets
  set coins = coins - p_bet + v_win, xp = xp + floor(v_win / 10), updated_at = now()
  where user_id = v_user;

  insert into public.spins (user_id, game, bet, win, multiplier, reels)
  values (v_user, 'feline-fortune', p_bet, v_win, v_multiplier, jsonb_build_array(v_card_index));

  return jsonb_build_object(
    'card_index', v_card_index,
    'multiplier', v_multiplier,
    'win', v_win,
    'new_balance', (select coins from public.wallets where user_id = v_user)
  );
end;
$$;
