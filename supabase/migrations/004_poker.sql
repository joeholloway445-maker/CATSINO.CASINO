create or replace function play_poker(
  p_bet bigint,
  p_held_indices integer[],
  p_phase text
) returns jsonb
language plpgsql security definer
as $$
declare
  v_user_id uuid := auth.uid();
  v_coins bigint;
  v_deck integer[];
  v_hand integer[];
  v_i integer;
  v_j integer;
  v_temp integer;
  v_rank text := '';
  v_multiplier numeric := 0;
  v_win bigint := 0;
  v_vals integer[];
  v_suits integer[];
  v_max_count integer := 0;
  v_pair_count integer := 0;
  v_is_flush boolean;
  v_is_straight boolean;
  v_min_val integer;
  v_max_val integer;
  v_cnt integer;
begin
  select coins into v_coins from wallets where user_id = v_user_id for update;
  if v_coins is null then raise exception 'wallet not found'; end if;
  if p_bet > v_coins then raise exception 'insufficient coins'; end if;

  -- build deck 0-51 and fisher-yates shuffle
  v_deck := array(select generate_series(0, 51));
  for v_i in reverse 51..1 loop
    v_j := floor(random() * (v_i + 1))::integer;
    v_temp := v_deck[v_i + 1];
    v_deck[v_i + 1] := v_deck[v_j + 1];
    v_deck[v_j + 1] := v_temp;
  end loop;

  if p_phase = 'deal' then
    update wallets set coins = coins - p_bet where user_id = v_user_id;
    v_hand := v_deck[1:5];
    return jsonb_build_object(
      'cards', to_jsonb(v_hand),
      'held_indices', '[]'::jsonb,
      'win', 0,
      'new_balance', v_coins - p_bet,
      'hand_rank', ''
    );
  end if;

  -- draw phase: deal 5 fresh cards (client already has held ones)
  v_hand := v_deck[1:5];

  -- extract values (0-12) and suits (0-3)
  v_vals := array(select (v_hand[g] % 13) from generate_series(1,5) as g);
  v_suits := array(select floor(v_hand[g]::numeric / 13)::integer from generate_series(1,5) as g);

  v_is_flush := (select count(distinct x) from unnest(v_suits) x) = 1;
  v_min_val := (select min(x) from unnest(v_vals) x);
  v_max_val := (select max(x) from unnest(v_vals) x);
  -- straight: 5 distinct values spanning 4, or A-2-3-4-5 (ace=0, 2=1..5=4)
  v_is_straight := (select count(distinct x) from unnest(v_vals) x) = 5
    and (v_max_val - v_min_val = 4
      or (v_max_val = 12 and (select count(*) from unnest(v_vals) x where x in (0,1,2,3,12)) = 5));

  -- count value frequencies
  for v_i in 0..12 loop
    v_cnt := (select count(*) from unnest(v_vals) x where x = v_i);
    if v_cnt > v_max_count then v_max_count := v_cnt; end if;
    if v_cnt = 2 then v_pair_count := v_pair_count + 1; end if;
  end loop;

  -- Royal Flush: A-K-Q-J-10 same suit (values 0,9,10,11,12)
  if v_is_flush and v_is_straight and v_min_val = 0 and v_max_val = 12
    and (select count(*) from unnest(v_vals) x where x in (0,9,10,11,12)) = 5 then
    v_rank := 'Royal Flush'; v_multiplier := 250;
  elsif v_is_flush and v_is_straight then
    v_rank := 'Straight Flush'; v_multiplier := 50;
  elsif v_max_count = 4 then
    v_rank := 'Four of a Kind'; v_multiplier := 25;
  elsif v_max_count = 3 and v_pair_count = 1 then
    v_rank := 'Full House'; v_multiplier := 9;
  elsif v_is_flush then
    v_rank := 'Flush'; v_multiplier := 6;
  elsif v_is_straight then
    v_rank := 'Straight'; v_multiplier := 4;
  elsif v_max_count = 3 then
    v_rank := 'Three of a Kind'; v_multiplier := 3;
  elsif v_pair_count = 2 then
    v_rank := 'Two Pair'; v_multiplier := 2;
  elsif v_pair_count = 1 then
    -- Jacks or better: pair must be J(10), Q(11), K(12), or A(0)
    if (select count(*) from (
      select x from unnest(v_vals) x where x in (0,10,11,12)
      having count(*) >= 2
    ) sub) > 0 then
      v_rank := 'Jacks or Better'; v_multiplier := 1;
    end if;
  end if;

  v_win := (p_bet * v_multiplier)::bigint;
  if v_win > 0 then
    update wallets set coins = coins + v_win, xp = xp + (p_bet / 10)
    where user_id = v_user_id;
  end if;

  insert into spins(user_id, game, bet, win, multiplier, reels)
  values(v_user_id, 'whisker-wins', p_bet, v_win, v_multiplier,
    array(select v_hand[g]::text from generate_series(1,5) as g));

  return jsonb_build_object(
    'cards', to_jsonb(v_hand),
    'held_indices', to_jsonb(p_held_indices),
    'win', v_win,
    'new_balance', v_coins - p_bet + v_win,
    'hand_rank', v_rank
  );
end;
$$;
