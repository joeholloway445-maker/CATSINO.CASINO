# Periliminal — single monorepo

This used to be split across two GitHub repos (`THE-HDV-CORE` and
`CATSINO.CASINO`), which made it impossible to tell where any given piece of
work actually lived. Everything now lives here, in one place.

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
- `godot_hdv_core/` — what's left of the other Godot client, not yet
  merged in: world generation/chunk streaming, the creator-mode sandbox
  (timeline replay/forge + Discord-mod-ticket UGC review pipeline), and
  ambient-NPC awareness reactions. These are large, genuinely separate
  systems (not just cosmetic differences), so they're being merged
  deliberately rather than by blind file overwrite. Treat this as a
  reference project, not dead code, until that happens.
- `scripts/` — shared tooling (e.g. `repo_factory.sh` for pulling in
  open-source Godot addons).

## Running an app

Each app under `apps/` is a self-contained Next.js project with its own
`package.json`. `cd` into the one you want and run it like any other
Next app (`npm install && npm run dev`).

## Running the Godot client

Open `godot/project.godot` (or `godot_hdv_core/project.godot`) directly in
Godot 4.x.
