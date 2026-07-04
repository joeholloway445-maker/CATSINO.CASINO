-- companions/summon/route.ts read the wallet balance, then wrote a new
-- balance back in a separate request — two concurrent summons can both
-- read the same starting balance and both succeed, spending the cost twice
-- for the price of once. Add an atomic, row-locked spend RPC and use it
-- instead of the read-then-write pattern.

create or replace function public.spend_coins(p_amount bigint)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_balance bigint;
begin
  if v_user_id is null then raise exception 'Not authenticated'; end if;
  if p_amount <= 0 then raise exception 'Invalid amount'; end if;

  select coins into v_balance from public.wallets where user_id = v_user_id for update;
  if v_balance is null then raise exception 'Wallet not found'; end if;
  if v_balance < p_amount then raise exception 'Insufficient coins'; end if;

  update public.wallets set coins = coins - p_amount, updated_at = now()
  where user_id = v_user_id;

  return jsonb_build_object('balance', v_balance - p_amount);
end;
$$;
