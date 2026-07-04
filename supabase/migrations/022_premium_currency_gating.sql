-- Mirrors THE-HDV-CORE's supabase/migrations/006_premium_currency_gating.sql
-- (already applied to the shared canonical database). Foundation for the
-- token/fragments purchase-gating rule from the currency spec: "only
-- purchasable on the first three coin purchases or via random events;
-- otherwise earned via PvP/PvE quests and kills." There is no real-money
-- purchase flow wired up yet (Stripe or similar), so this adds the tracking
-- column + RPCs now so that flow (and future random-event grants) has
-- something concrete to call into.

alter table public.player_currencies
  add column if not exists premium_purchases integer not null default 0;

-- Call this from the real-money purchase webhook once it exists, after the
-- coin grant itself (grant_currency('coin', ...)). Tracks how many times
-- the player has bought coin with real money, for the first-three-purchases
-- token/fragments eligibility window.
create or replace function public.record_premium_purchase()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_count integer;
begin
  if v_user is null then raise exception 'Not authenticated'; end if;

  insert into public.player_currencies (user_id) values (v_user)
  on conflict (user_id) do nothing;

  update public.player_currencies
  set premium_purchases = premium_purchases + 1
  where user_id = v_user
  returning premium_purchases into v_count;

  return v_count;
end;
$$;

revoke all on function public.record_premium_purchase() from public;
grant execute on function public.record_premium_purchase() to authenticated;

-- Coin -> tokens / fragments, gated to the first three premium purchases.
-- Random-event grants (the other stated eligibility path) aren't wired up
-- yet -- whatever system implements them should call grant_currency('tokens'
-- | 'fragments', ...) directly, bypassing this gate entirely, since this
-- function only covers the coin-purchase path.
create or replace function public.purchase_premium_currency(p_currency text, p_coin_amount bigint, p_rate integer default 10)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_coin bigint;
  v_purchases integer;
  v_gain bigint;
  v_new_coin bigint;
  v_new_balance bigint;
begin
  if v_user is null then raise exception 'Not authenticated'; end if;
  if p_currency not in ('tokens', 'fragments') then
    raise exception 'Invalid currency: %', p_currency;
  end if;
  if p_coin_amount <= 0 or p_coin_amount % p_rate <> 0 then
    raise exception 'Coin amount must be a positive multiple of %', p_rate;
  end if;

  select coin, premium_purchases into v_coin, v_purchases
  from public.player_currencies where user_id = v_user for update;

  if v_coin is null then raise exception 'Currency ledger not found'; end if;
  if v_purchases >= 3 then
    raise exception 'Premium-purchase window closed -- earn % through quests instead', p_currency;
  end if;
  if v_coin < p_coin_amount then raise exception 'Insufficient coin'; end if;

  v_gain := p_coin_amount / p_rate;

  execute format(
    'update public.player_currencies set coin = coin - $1, %I = %I + $2, premium_purchases = premium_purchases + 1, updated_at = now() where user_id = $3 returning coin, %I',
    p_currency, p_currency, p_currency
  ) into v_new_coin, v_new_balance using p_coin_amount, v_gain, v_user;

  return jsonb_build_object('coin', v_new_coin, p_currency, v_new_balance);
end;
$$;

revoke all on function public.purchase_premium_currency(text, bigint, integer) from public;
grant execute on function public.purchase_premium_currency(text, bigint, integer) to authenticated;
