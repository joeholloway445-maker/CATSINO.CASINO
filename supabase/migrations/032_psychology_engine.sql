-- Periliminal.Space psychology engine schema.
-- Novel, in-house, legally-collected psychology data: every table is
-- per-player RLS-isolated; door_exploration and gambling_sessions are the
-- raw streams, psychology_profiles the compiled score the Perception
-- Engine reads, perceptions the per-player rendering cache, anomalies the
-- shared entity registry (read-only to players).

create table if not exists psychology_profiles (
  player_id text primary key,
  psychology_score numeric not null default 50,  -- 0..100
  courage numeric not null default 0.5,
  curiosity numeric not null default 0.5,
  composure numeric not null default 0.5,
  dominant_drive text,                            -- fear|lust|boredom|anxiety|curiosity
  profile jsonb not null default '{}'::jsonb,     -- full Hope axes
  updated_at timestamptz not null default now()
);

create table if not exists door_exploration (
  id bigint generated always as identity primary key,
  player_id text not null,
  door_id text not null,
  layer text not null,
  approach text not null,          -- rushed|circled|peeked|opened_closed|avoided|lingered
  hesitation_s numeric not null default 0,
  behind jsonb not null default '{}'::jsonb, -- what was actually behind it
  inferred_drive text,
  created_at timestamptz not null default now()
);
create index if not exists door_exploration_player_idx on door_exploration (player_id, created_at desc);

create table if not exists anomalies (
  id text primary key,
  name text not null,
  layer text not null,
  base_confidence numeric not null default 30, -- 0..100, how "real" it is
  behavior_tree text,                           -- LimboAI BT resource path
  definition jsonb not null default '{}'::jsonb
);

create table if not exists perceptions (
  player_id text not null,
  entity_id text not null,
  confidence numeric not null,     -- 0..100 as computed by PerceptionEngine
  mode text not null,              -- solid|holographic|flickering|distorted
  computed_at timestamptz not null default now(),
  primary key (player_id, entity_id)
);

create table if not exists gambling_sessions (
  id bigint generated always as identity primary key,
  player_id text not null,
  game text not null,
  bet integer not null,
  payout integer not null,
  balance_before integer not null,
  balance_after integer not null,
  streak integer not null default 0,       -- consecutive losses (pressure)
  pressure numeric not null default 0,     -- bet / balance_before
  decision_ms integer,                     -- time to place the bet
  created_at timestamptz not null default now()
);
create index if not exists gambling_sessions_player_idx on gambling_sessions (player_id, created_at desc);

-- RLS: players only touch their own psychology; anomalies are world-public.
alter table psychology_profiles enable row level security;
alter table door_exploration enable row level security;
alter table perceptions enable row level security;
alter table gambling_sessions enable row level security;
alter table anomalies enable row level security;

create policy "own profile"  on psychology_profiles for all    using (auth.uid()::text = player_id) with check (auth.uid()::text = player_id);
create policy "own doors r"  on door_exploration  for select  using (auth.uid()::text = player_id);
create policy "own doors w"  on door_exploration  for insert  with check (auth.uid()::text = player_id);
create policy "own percept"  on perceptions       for all     using (auth.uid()::text = player_id) with check (auth.uid()::text = player_id);
create policy "own gamble r" on gambling_sessions for select  using (auth.uid()::text = player_id);
create policy "own gamble w" on gambling_sessions for insert  with check (auth.uid()::text = player_id);
create policy "anomalies public read" on anomalies for select using (true);
