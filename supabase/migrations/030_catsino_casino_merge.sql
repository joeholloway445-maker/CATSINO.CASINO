-- Merge CATSINO.CASINO's Cat Coins economy into the shared Periliminal.Space
-- project so Supraliminal-layer casino play and the simulation share one
-- database/auth pool. Adds wallets/spins onto the existing public.profiles
-- (does not recreate it — CATSINO.CASINO's own 001_initial_schema.sql created
-- a duplicate profiles/trigger that is superseded by this project's).

alter table public.profiles add column if not exists is_admin boolean not null default false;

-- ── WALLETS (Cat Coins) ────────────────────────────────────────────────────
create table if not exists public.wallets (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  coins bigint not null default 10000,
  xp bigint not null default 0,
  daily_streak int not null default 0,
  last_daily_claim timestamptz,
  updated_at timestamptz default now()
);

-- ── SPIN / GAME HISTORY ──────────────────────────────────────────────────────
create table if not exists public.spins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  game text not null,
  bet bigint not null,
  win bigint not null,
  multiplier numeric not null,
  reels jsonb not null,
  created_at timestamptz default now()
);

create index if not exists spins_user_id_created_at_idx on public.spins (user_id, created_at desc);

-- ── ROW LEVEL SECURITY ───────────────────────────────────────────────────────
alter table public.wallets enable row level security;
alter table public.spins enable row level security;

create policy "own wallet" on public.wallets
  for select using (auth.uid() = user_id);

create policy "own spins" on public.spins
  for select using (auth.uid() = user_id);

-- Helper to check admin status without recursive RLS on profiles
create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select coalesce((select is_admin from public.profiles where id = auth.uid()), false);
$$;

create policy "admin read profiles" on public.profiles
  for select using (public.is_admin());

create policy "admin read wallets" on public.wallets
  for select using (public.is_admin());

create policy "admin update wallets" on public.wallets
  for update using (public.is_admin());

-- ── BOOTSTRAP A WALLET ALONGSIDE THE EXISTING PROFILE/CURRENCY BOOTSTRAP ────
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, username)
  values (new.id, split_part(new.email, '@', 1))
  on conflict (id) do nothing;

  insert into public.player_currencies (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  insert into public.wallets (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

-- ── SLOT SPIN (server-side RNG, atomic balance update) ───────────────────────
-- Symbols: CAT, FISH, COIN, YARN, BOWL, CROWN (jackpot)
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

  if v_roll < 0.50 then
    v_multiplier := 0;
  elsif v_roll < 0.80 then
    v_multiplier := 1.5;
  elsif v_roll < 0.95 then
    v_multiplier := 3;
  elsif v_roll < 0.99 then
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

grant execute on function public.spin_slot(text, bigint) to authenticated;

-- ── DAILY BONUS ──────────────────────────────────────────────────────────────
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

  update public.wallets
  set coins = coins + v_reward,
      daily_streak = v_streak,
      last_daily_claim = now(),
      updated_at = now()
  where user_id = v_user;

  return jsonb_build_object(
    'reward', v_reward,
    'streak', v_streak,
    'balance', (select coins from public.wallets where user_id = v_user)
  );
end;
$$;

grant execute on function public.claim_daily_bonus() to authenticated;

-- ── ADMIN: ADJUST COINS ──────────────────────────────────────────────────────
create or replace function public.admin_adjust_coins(p_user_id uuid, p_amount bigint)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_is_admin boolean;
begin
  select is_admin into v_is_admin from public.profiles where id = auth.uid();

  if not coalesce(v_is_admin, false) then
    raise exception 'Not authorized';
  end if;

  update public.wallets
  set coins = greatest(0, coins + p_amount), updated_at = now()
  where user_id = p_user_id;

  return jsonb_build_object('balance', (select coins from public.wallets where user_id = p_user_id));
end;
$$;

grant execute on function public.admin_adjust_coins(uuid, bigint) to authenticated;
