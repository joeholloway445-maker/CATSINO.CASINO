-- Multi-character slots + OmniDex discovery tracking

-- ── CHARACTER SLOTS ──────────────────────────────────────────────────────────
alter table public.profiles
  add column if not exists character_slots int not null default 3;

alter table public.characters
  add column if not exists slot_number int not null default 1;

alter table public.characters
  drop constraint if exists characters_user_id_key;

alter table public.characters
  add constraint characters_user_slot_key unique (user_id, slot_number);

-- ── ENTITY DISCOVERY (OmniDex) ───────────────────────────────────────────────
-- first_encountered_at already marks "discovered" (full picture unlocked).
-- caught_at marks "caught" (lore/description unlocked).
alter table public.player_entities
  add column if not exists caught_at timestamptz;
