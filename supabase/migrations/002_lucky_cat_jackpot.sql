-- CATSINO.CASINO — Lucky Cat Jackpot wheel game
-- Adds an atomic, server-side RNG function for the wheel-spin game.
-- The wheel has 8 segments (indices 0-7); segment -> multiplier mapping
-- must match WHEEL_SEGMENTS in app/games/lucky-cat-jackpot/WheelGame.tsx.

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

  if v_roll < 0.45 then
    v_multiplier := 0;
    v_segment := v_zero_segments[1 + floor(random() * 3)::int];
  elsif v_roll < 0.65 then
    v_multiplier := 0.5;
    v_segment := 1;
  elsif v_roll < 0.80 then
    v_multiplier := 1;
    v_segment := 3;
  elsif v_roll < 0.92 then
    v_multiplier := 2;
    v_segment := 4;
  elsif v_roll < 0.98 then
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

grant execute on function public.spin_wheel(bigint) to authenticated;
