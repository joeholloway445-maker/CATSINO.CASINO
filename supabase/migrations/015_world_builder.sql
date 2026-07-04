-- World Builder tables — stores world data edited via the web dashboard

create table if not exists world_districts (
  id text primary key,
  display_name text not null,
  description text not null default '',
  scene_path text not null default '',
  music_track text not null default '',
  entry_fee integer not null default 0,
  color_hex text not null default '#9B59B6',
  max_players integer not null default 100,
  ambient_npc_count integer not null default 10,
  weather text not null default 'clear',
  time_of_day text not null default 'day',
  enabled boolean not null default true,
  updated_at timestamptz not null default now()
);

create table if not exists world_npcs (
  id text primary key,
  name text not null,
  district text not null references world_districts(id) on delete cascade,
  role text not null default 'ambient',
  faction text not null default 'Factionless',
  emoji text not null default '🐱',
  greeting text not null default 'Hello!',
  pos_x float not null default 0,
  pos_y float not null default 0,
  pos_z float not null default 0,
  shop_id text not null default '',
  quest_ids text[] not null default '{}',
  dialogue_id text not null default '',
  enabled boolean not null default true,
  updated_at timestamptz not null default now()
);

create table if not exists world_dialogues (
  dialogue_id text primary key,
  npc_id text references world_npcs(id) on delete cascade,
  start_node text not null default 'greeting',
  nodes jsonb not null default '[]',
  updated_at timestamptz not null default now()
);

create table if not exists world_shops (
  shop_id text primary key,
  shop_name text not null,
  district text not null references world_districts(id) on delete cascade,
  items jsonb not null default '[]',
  enabled boolean not null default true,
  updated_at timestamptz not null default now()
);

create table if not exists world_quests (
  id text primary key,
  title text not null,
  type text not null default 'side',
  description text not null default '',
  giver_npc text not null default '',
  district text not null default 'paw_vegas',
  prerequisites text[] not null default '{}',
  objectives jsonb not null default '[]',
  reward_coins integer not null default 0,
  reward_xp integer not null default 0,
  unlock_companion text not null default '',
  next_quest text not null default '',
  enabled boolean not null default true,
  updated_at timestamptz not null default now()
);

-- RLS: only authenticated users can read; only service role can write
alter table world_districts enable row level security;
alter table world_npcs enable row level security;
alter table world_dialogues enable row level security;
alter table world_shops enable row level security;
alter table world_quests enable row level security;

create policy "world_read_all" on world_districts for select using (true);
create policy "world_read_all" on world_npcs for select using (true);
create policy "world_read_all" on world_dialogues for select using (true);
create policy "world_read_all" on world_shops for select using (true);
create policy "world_read_all" on world_quests for select using (true);

-- Admin-only write via service role (bypasses RLS)

-- Helper: get all NPCs in a district
create or replace function get_world_npcs(p_district text)
returns setof world_npcs
language sql stable security definer as $$
  select * from world_npcs where district = p_district and enabled = true;
$$;

-- Helper: get full district data
create or replace function get_world_district(p_id text)
returns world_districts
language sql stable security definer as $$
  select * from world_districts where id = p_id;
$$;
