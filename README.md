# Periliminal — single monorepo

This used to be split across two GitHub repos (`THE-HDV-CORE` and
`CATSINO.CASINO`), which made it impossible to tell where any given piece of
work actually lived. Everything now lives here, in one place.

This account also has several other repos that touch the same universe
(a Godot combat-AI reference, an AI world-model fork, an LLM inference
fork, and sister web apps). See [`docs/ECOSYSTEM.md`](docs/ECOSYSTEM.md)
for how they all relate to this monorepo.

## Layout

- `apps/catsino-casino/` — the cat-themed casino web skin (Next.js).
- `apps/hdv-core/` — the sci-fi web skin (Next.js).
- `supabase/` — the single shared Postgres schema/migrations both apps and
  the Godot client read from. There is one canonical database
  (`lamdemoaszkilguvkvcd`, "Periliminal.Space") behind everything --
  currencies, characters, inventory, etc. are never duplicated between
  skins. Migrations from the old THE-HDV-CORE repo were appended
  (`027`-`030`) rather than merged number-by-number, since both histories
  were already applied to the same live database independently.
- `godot/` — the canonical Godot client (combat, companions, economy,
  social, liveops, minigames). Two systems from `godot_hdv_core/` have been
  merged in so far:
  - **Character rig/preview** (`src/character/character_rig.gd`,
    `texture_materials.gd`, `character_preview.gd`) — the procedural 3D PBR
    rig is now wired to catsino's actual race/frame data (`RaceDataCharacter`,
    `FrameModData`) instead of hdv-core's `GameData`. Every cat breed got a
    `texture_type`/`primary_color` so the rig renders for all 20 races.
    `character_creator.gd` now uses real race/frame/stat data (it previously
    used a disconnected placeholder race list) and shows a live 3D preview.
  - **Game-mode layer** (`src/core/game_mode_manager.gd`,
    `game_mode_store.gd`, `src/data/game_mode_data.gd`,
    `src/ui/game_mode_store_ui.gd`) — this is a world-*state* toggle
    (persistent-aware / persistent-incognito / sandboxed creator modes), not
    a minigame system, so it doesn't compete with the slots/poker/blackjack
    in `src/games/` — both coexist untouched. Re-priced from hdv-core's real
    USD ($9.99/$14.99 IAP) to gems (catsino's existing premium currency),
    since this casino has no real-money trading. Reachable from the main
    menu's new "🌐 Game Modes" button.
  - **Ambient NPC awareness** (`src/world/ambient_npc.gd`) — mob NPCs that
    react differently depending on persistent-aware vs incognito mode.
    Rewired off hdv-core's `PersonaMatrixClient`/`GameData` onto catsino's
    `CasinoHTTPClient`; `recruit()` now just emits a signal since
    companion/mount/pet ids use different schemes here.
  - **Procedural world chunks + discovery** (`src/world/world_chunk.gd`,
    `hub_region_data.gd`, `procedural_region_generator.gd`,
    `player_influence_pack.gd`, `discovery_manager.gd`) — a chunk-based
    procedural overworld layered *alongside* catsino's hand-authored
    district system (`DistrictManager`), not replacing it. Driven by
    `cat_forest_scene.gd`'s `explore_chunk()`, wired into the existing
    "Ancient Ruins" discover-quest rather than a new entry point.
  - **Creator-mode UGC sandbox** (`src/data/timeline_data.gd`,
    `ugc_submission.gd`, `src/networking/discord_ticket_client.gd`,
    `src/ui/creator_mode_ui.gd`, `scenes/ui/creator_mode.tscn`) —
    timeline replay/forge submissions through the Discord-mod-ticket
    review pipeline. Reachable from the Game Modes store when a
    sandboxed mode is activated.

  Two pre-existing catsino bugs got fixed along the way (both were
  dormant/never actually called before this merge wired their callers
  up): `PlayerProfile` never persisted the player's chosen race at all
  (`selected_race_id` now exists, set via `set_race()`), and
  `CharacterCreatorLogic.apply_creation()` referenced fields/methods
  that don't exist on `PlayerProfile` (`companions`/`save()` instead of
  `active_companion_ids`/`_save()`).

  **Not wired into gameplay**: `world_select.gd`/`world_registry.gd`/
  `reality_layer_world.gd` are HDV-core's own multiverse-hub lore (the
  five reality layers, age-gated cross-repo world links — one entry
  literally treats Catsino as an external world to launch into).
  Catsino is its own world with its own rules, so none of this is
  reachable from catsino's UI flow. Rather than living in a second
  parallel Godot project, it's preserved inside the single project at
  `godot/hdv_lore/` (mirroring the original relative paths under its
  own `src/`/`scenes/`/`assets/` subtree), with its own
  `GameData`/`WorldRegistry`/`PersonaMatrixClient`/`ExternalGameLauncher`
  autoloads registered alongside catsino's — nothing in catsino's
  gameplay code references any of them. The only generic, data-driven
  pieces (`character_rig.gd`, `texture_materials.gd`) are shared rather
  than duplicated, since catsino's own rewired character preview uses
  them too.
  - **3D overworld** (`src/world/overworld/`) — a walkable third-person
    overworld: streamed procedural heightmap terrain (one mesh per
    DiscoveryManager chunk, biome-tinted, low-poly props from each chunk's
    deterministic prop seed), a procedural day/night sky, and a capsule-cat
    controller whose movement feel is adapted from the Godot TPS/platformer
    demos (fetched as reference — their binary assets can't be vendored, so
    everything here is procedural and asset-free). Walking into a
    never-generated chunk fires the discover mechanic and advances the
    "Cartographer's Call" quest; influence repaints show up as ground tint.
    Reachable from the main menu's "🗺️ Overworld" button.
- `scripts/` — shared tooling (e.g. `repo_factory.sh` for pulling in
  open-source Godot addons).

## Running an app

Each app under `apps/` is a self-contained Next.js project with its own
`package.json`. `cd` into the one you want and run it like any other
Next app (`npm install && npm run dev`).

## Running the Godot client

Open `godot/project.godot` directly in Godot 4.x. This is the single
canonical Godot project — there is no second project to open separately.
