-- Daily reward tracking columns on profiles
alter table public.profiles
  add column if not exists daily_streak int not null default 0,
  add column if not exists last_daily_claim timestamptz;

-- Claim daily reward (idempotent within the same day)
create or replace function public.claim_daily_reward()
returns json language plpgsql security definer as $$
declare
  v_user_id uuid := auth.uid();
  v_streak int;
  v_last_claim timestamptz;
  v_day int;
  v_reward int;
  v_rewards int[] := array[100, 150, 200, 300, 400, 500, 1000, 200, 250, 350, 500, 600, 750, 2000];
begin
  if v_user_id is null then raise exception 'Not authenticated'; end if;

  select daily_streak, last_daily_claim
  into v_streak, v_last_claim
  from public.profiles where id = v_user_id;

  -- Check cooldown
  if v_last_claim is not null and (now() - v_last_claim) < interval '24 hours' then
    raise exception 'Already claimed today';
  end if;

  -- Reset streak if missed a day
  if v_last_claim is not null and (now() - v_last_claim) > interval '48 hours' then
    v_streak := 0;
  end if;

  v_streak := v_streak + 1;
  v_day := ((v_streak - 1) % 14) + 1;
  v_reward := v_rewards[v_day];

  update public.profiles
  set daily_streak = v_streak, last_daily_claim = now()
  where id = v_user_id;

  update public.wallets set coins = coins + v_reward where user_id = v_user_id;

  return json_build_object('success', true, 'day', v_day, 'streak', v_streak, 'reward', v_reward);
end;
$$;
