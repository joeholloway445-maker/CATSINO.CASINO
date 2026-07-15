-- Player psychology anomalies (distinct from world entity registry `anomalies`).
-- Written by services/psychology when Hope axes trip apex_aggressor /
-- lost_wanderer / spiraling rules.

create table if not exists player_anomalies (
  id bigint generated always as identity primary key,
  player_id text not null,
  anomaly_type text not null,          -- apex_aggressor | lost_wanderer | spiraling
  courage numeric not null default 0.5,
  curiosity numeric not null default 0.5,
  composure numeric not null default 0.5,
  created_at timestamptz not null default now()
);
create index if not exists player_anomalies_player_idx
  on player_anomalies (player_id, created_at desc);

alter table player_anomalies enable row level security;
create policy "own anomalies r" on player_anomalies for select
  using (auth.uid()::text = player_id);
-- Service role writes bypass RLS; no public insert policy.
