-- Hope's observation stream: one row per behavioral event per player.
-- Hope (the companion) classifies WHY a choice was made (drive) and
-- snapshots the evolving playstyle profile; Knoll reads the same table
-- to build the shadow encounters. RLS: players only see their own Hope.
create table if not exists hope_telemetry (
  id bigint generated always as identity primary key,
  player_id text not null,
  event text not null,                -- e.g. 'liminal_door', 'loot_vs_exit'
  context jsonb not null default '{}'::jsonb, -- approach, hesitation, door id...
  drive text,                          -- fear | lust | boredom | anxiety | curiosity
  profile_snapshot jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists hope_telemetry_player_idx on hope_telemetry (player_id, created_at desc);

alter table hope_telemetry enable row level security;

create policy "players read own hope" on hope_telemetry
  for select using (auth.uid()::text = player_id);
create policy "players write own hope" on hope_telemetry
  for insert with check (auth.uid()::text = player_id);
