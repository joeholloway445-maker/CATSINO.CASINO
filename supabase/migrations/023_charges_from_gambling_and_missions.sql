-- Wire "charges" (spec: "earned through mission rewards or gambling/wagers")
-- into the gambling RPCs and daily bonus that already exist, on top of the
-- player_currencies foundation from 021/022. Each function keeps its
-- existing wallets.coins logic untouched -- this only adds an atomic
-- charges grant alongside it, in the same transaction.

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
  v_charges bigint;
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

  v_charges := floor(v_win / 50);
  if v_charges > 0 then
    insert into public.player_currencies (user_id) values (v_user) on conflict (user_id) do nothing;
    update public.player_currencies set charges = charges + v_charges, updated_at = now() where user_id = v_user;
  end if;

  insert into public.spins (user_id, game, bet, win, multiplier, reels)
  values (v_user, p_game, p_bet, v_win, v_multiplier, v_reels);

  return jsonb_build_object(
    'reels', v_reels,
    'win', v_win,
    'multiplier', v_multiplier,
    'balance', (select coins from public.wallets where user_id = v_user),
    'xp', (select xp from public.wallets where user_id = v_user),
    'charges_earned', v_charges
  );
end;
$$;

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
  v_charges bigint;
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

  v_charges := floor(v_win / 50);
  if v_charges > 0 then
    insert into public.player_currencies (user_id) values (v_user) on conflict (user_id) do nothing;
    update public.player_currencies set charges = charges + v_charges, updated_at = now() where user_id = v_user;
  end if;

  insert into public.spins (user_id, game, bet, win, multiplier, reels)
  values (v_user, 'lucky_cat_jackpot', p_bet, v_win, v_multiplier, jsonb_build_array(v_segment));

  return jsonb_build_object(
    'segment', v_segment,
    'multiplier', v_multiplier,
    'win', v_win,
    'balance', (select coins from public.wallets where user_id = v_user),
    'xp', (select xp from public.wallets where user_id = v_user),
    'charges_earned', v_charges
  );
end;
$$;

-- Daily bonus is a mission reward, so it grants a small flat amount of
-- charges scaled by streak, alongside the existing coin reward.
create or replace function public.claim_daily_bonus()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_last timestamptz;
  v_streak int;
  v_reward bigint;
  v_charges bigint;
begin
  if v_user is null then
    raise exception 'Not authenticated';
  end if;

  select last_daily_claim, daily_streak into v_last, v_streak
  from public.wallets where user_id = v_user for update;

  if v_last is not null and v_last > now() - interval '20 hours' then
    raise exception 'Daily bonus already claimed';
  end if;

  if v_last is not null and v_last < now() - interval '48 hours' then
    v_streak := 0;
  end if;

  v_streak := v_streak + 1;
  v_reward := 200 + (v_streak * 50);
  v_charges := least(v_streak, 10);

  update public.wallets
  set coins = coins + v_reward,
      daily_streak = v_streak,
      last_daily_claim = now(),
      updated_at = now()
  where user_id = v_user;

  insert into public.player_currencies (user_id) values (v_user) on conflict (user_id) do nothing;
  update public.player_currencies set charges = charges + v_charges, updated_at = now() where user_id = v_user;

  return jsonb_build_object(
    'reward', v_reward,
    'streak', v_streak,
    'balance', (select coins from public.wallets where user_id = v_user),
    'charges_earned', v_charges
  );
end;
$$;
