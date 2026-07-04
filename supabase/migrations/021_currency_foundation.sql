-- Mirrors THE-HDV-CORE's supabase/migrations/005_currency_foundation.sql.
-- Both repos share the canonical Periliminal.Space database (already applied
-- there), so this file exists for parity/history in this repo rather than to
-- be reapplied. Foundation for the 6-currency economy (coin, chip, fragments,
-- tokens, charges, renown) on top of the existing public.player_currencies
-- table (020_port_companions_and_xp_to_canonical_db.sql / THE-HDV-CORE's
-- 004_catsino_casino_merge.sql): row-locked, allow-listed grant_currency/
-- spend_currency RPCs, plus exchange_coin_for_chip at the documented 10:1
-- rate, all security-definer so the table itself never needs public write
-- access (same pattern as spend_coins/add_profile_xp).

create or replace function public.grant_currency(p_currency text, p_amount bigint)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_new_balance bigint;
begin
  if v_user is null then raise exception 'Not authenticated'; end if;
  if p_amount <= 0 then raise exception 'Invalid amount'; end if;
  if p_currency not in ('coin', 'chip', 'fragments', 'tokens', 'charges', 'renown') then
    raise exception 'Invalid currency: %', p_currency;
  end if;

  insert into public.player_currencies (user_id) values (v_user)
  on conflict (user_id) do nothing;

  execute format(
    'update public.player_currencies set %I = %I + $1, updated_at = now() where user_id = $2 returning %I',
    p_currency, p_currency, p_currency
  ) into v_new_balance using p_amount, v_user;

  return jsonb_build_object('currency', p_currency, 'balance', v_new_balance);
end;
$$;

revoke all on function public.grant_currency(text, bigint) from public;
grant execute on function public.grant_currency(text, bigint) to authenticated;

create or replace function public.spend_currency(p_currency text, p_amount bigint)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_balance bigint;
  v_new_balance bigint;
begin
  if v_user is null then raise exception 'Not authenticated'; end if;
  if p_amount <= 0 then raise exception 'Invalid amount'; end if;
  if p_currency not in ('coin', 'chip', 'fragments', 'tokens', 'charges', 'renown') then
    raise exception 'Invalid currency: %', p_currency;
  end if;

  execute format('select %I from public.player_currencies where user_id = $1 for update', p_currency)
    into v_balance using v_user;

  if v_balance is null then raise exception 'Currency ledger not found'; end if;
  if v_balance < p_amount then raise exception 'Insufficient %', p_currency; end if;

  execute format(
    'update public.player_currencies set %I = %I - $1, updated_at = now() where user_id = $2 returning %I',
    p_currency, p_currency, p_currency
  ) into v_new_balance using p_amount, v_user;

  return jsonb_build_object('currency', p_currency, 'balance', v_new_balance);
end;
$$;

revoke all on function public.spend_currency(text, bigint) from public;
grant execute on function public.spend_currency(text, bigint) to authenticated;

-- Coin -> Chip exchange at the 10:1 rate already documented in
-- lib/game/data/currencies.ts ("Exchanged from Coin at 10:1 rate").
create or replace function public.exchange_coin_for_chip(p_coin_amount bigint)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_coin bigint;
  v_chip_gain bigint;
  v_new_coin bigint;
  v_new_chip bigint;
begin
  if v_user is null then raise exception 'Not authenticated'; end if;
  if p_coin_amount <= 0 or p_coin_amount % 10 <> 0 then
    raise exception 'Coin amount must be a positive multiple of 10';
  end if;

  select coin into v_coin from public.player_currencies where user_id = v_user for update;
  if v_coin is null then raise exception 'Currency ledger not found'; end if;
  if v_coin < p_coin_amount then raise exception 'Insufficient coin'; end if;

  v_chip_gain := p_coin_amount / 10;

  update public.player_currencies
  set coin = coin - p_coin_amount,
      chip = chip + v_chip_gain,
      updated_at = now()
  where user_id = v_user
  returning coin, chip into v_new_coin, v_new_chip;

  return jsonb_build_object('coin', v_new_coin, 'chip', v_new_chip);
end;
$$;

revoke all on function public.exchange_coin_for_chip(bigint) from public;
grant execute on function public.exchange_coin_for_chip(bigint) to authenticated;
