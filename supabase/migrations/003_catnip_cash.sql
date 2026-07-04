create or replace function public.scratch_card(p_bet bigint)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_balance bigint;
  v_symbols text[] := array['🌿','🐱','🪙','⭐','💎','👑'];
  v_grid text[] := array[]::text[];
  v_i int;
  v_matches int := 0;
  v_win bigint := 0;
  v_multiplier numeric := 0;
begin
  -- auth + balance check
  if v_user is null then raise exception 'Not authenticated'; end if;
  if p_bet <= 0 or p_bet > 100000 then raise exception 'Invalid bet'; end if;
  select coins into v_balance from public.wallets where user_id = v_user for update;
  if v_balance is null then raise exception 'Wallet not found'; end if;
  if v_balance < p_bet then raise exception 'Insufficient balance'; end if;

  -- generate 3x3 grid (9 symbols)
  for v_i in 1..9 loop
    -- weighted: 🌿 35%, 🐱 25%, 🪙 20%, ⭐ 12%, 💎 6%, 👑 2%
    declare v_roll double precision := random();
    begin
      if v_roll < 0.35 then v_grid := v_grid || '🌿';
      elsif v_roll < 0.60 then v_grid := v_grid || '🐱';
      elsif v_roll < 0.80 then v_grid := v_grid || '🪙';
      elsif v_roll < 0.92 then v_grid := v_grid || '⭐';
      elsif v_roll < 0.98 then v_grid := v_grid || '💎';
      else v_grid := v_grid || '👑';
      end if;
    end;
  end loop;

  -- count matches of most frequent symbol
  declare
    v_sym text;
    v_count int;
    v_best_sym text := '';
    v_best_count int := 0;
  begin
    foreach v_sym in array v_symbols loop
      select count(*) into v_count from unnest(v_grid) s where s = v_sym;
      if v_count > v_best_count then v_best_count := v_count; v_best_sym := v_sym; end if;
    end loop;
    v_matches := v_best_count;
  end;

  -- payout table: 3 matches=1x, 4=2x, 5=5x, 6=10x, 7=20x, 8=50x, 9=100x
  case v_matches
    when 3 then v_multiplier := 1;
    when 4 then v_multiplier := 2;
    when 5 then v_multiplier := 5;
    when 6 then v_multiplier := 10;
    when 7 then v_multiplier := 20;
    when 8 then v_multiplier := 50;
    when 9 then v_multiplier := 100;
    else v_multiplier := 0;
  end case;

  v_win := floor(p_bet * v_multiplier);

  update public.wallets
  set coins = coins - p_bet + v_win,
      xp = xp + floor(v_win / 10),
      updated_at = now()
  where user_id = v_user;

  insert into public.spins (user_id, game, bet, win, multiplier, reels)
  values (v_user, 'catnip_cash', p_bet, v_win, v_multiplier, to_jsonb(v_grid));

  return jsonb_build_object(
    'grid', to_jsonb(v_grid),
    'matches', v_matches,
    'multiplier', v_multiplier,
    'win', v_win,
    'balance', (select coins from public.wallets where user_id = v_user)
  );
end;
$$;
grant execute on function public.scratch_card(bigint) to authenticated;
