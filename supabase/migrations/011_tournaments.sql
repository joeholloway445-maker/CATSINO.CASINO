-- Tournaments system
create table if not exists public.tournaments (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  game_type text,
  prize_pool int not null default 10000,
  entry_fee int not null default 100,
  entry_count int not null default 0,
  starts_at timestamptz not null default now(),
  ends_at timestamptz not null default (now() + interval '7 days'),
  created_at timestamptz default now()
);

create table if not exists public.tournament_entries (
  id uuid default gen_random_uuid() primary key,
  tournament_id uuid references public.tournaments(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  score int not null default 0,
  rank int,
  entered_at timestamptz default now(),
  unique(tournament_id, user_id)
);

alter table public.tournaments enable row level security;
alter table public.tournament_entries enable row level security;

create policy "Anyone reads tournaments" on public.tournaments for select using (true);
create policy "Users see own entries" on public.tournament_entries for select using (auth.uid() = user_id);
create policy "Users insert own entries" on public.tournament_entries for insert with check (auth.uid() = user_id);

-- Enter a tournament (deducts fee, inserts entry)
create or replace function public.enter_tournament(p_tournament_id uuid)
returns json language plpgsql security definer as $$
declare
  v_user_id uuid := auth.uid();
  v_tournament public.tournaments;
  v_coins int;
begin
  if v_user_id is null then raise exception 'Not authenticated'; end if;

  select * into v_tournament from public.tournaments where id = p_tournament_id;
  if not found then raise exception 'Tournament not found'; end if;
  if v_tournament.ends_at < now() then raise exception 'Tournament has ended'; end if;

  select coins into v_coins from public.wallets where user_id = v_user_id;
  if v_coins < v_tournament.entry_fee then raise exception 'Insufficient coins'; end if;

  update public.wallets set coins = coins - v_tournament.entry_fee where user_id = v_user_id;

  insert into public.tournament_entries (tournament_id, user_id)
  values (p_tournament_id, v_user_id)
  on conflict do nothing;

  update public.tournaments set entry_count = entry_count + 1,
    prize_pool = prize_pool + (v_tournament.entry_fee * 9 / 10)  -- 90% of fees go to pool
  where id = p_tournament_id;

  return json_build_object('success', true, 'tournament_id', p_tournament_id);
end;
$$;

-- Seed a weekly tournament
insert into public.tournaments (name, game_type, prize_pool, entry_fee, starts_at, ends_at)
values ('Weekly Jackpot Championship', 'slots', 50000, 500,
  date_trunc('week', now()), date_trunc('week', now()) + interval '7 days')
on conflict do nothing;
