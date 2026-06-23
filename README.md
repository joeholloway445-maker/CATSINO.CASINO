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
- `godot/` — the more actively developed of the two Godot clients (combat,
  companions, economy, social, liveops systems).
- `godot_hdv_core/` — the other Godot client (world generation,
  game-mode store, character creator/rig, discovery systems). **Not yet
  merged into `godot/`** -- the two diverged into genuinely different,
  non-overlapping systems rather than just cosmetic differences, so a
  real merge (deciding which systems to keep, port, or combine) needs to
  happen deliberately rather than by blind file overwrite. Until that
  happens, treat this as a second reference project, not dead code.
- `scripts/` — shared tooling (e.g. `repo_factory.sh` for pulling in
  open-source Godot addons).

## Running an app

Each app under `apps/` is a self-contained Next.js project with its own
`package.json`. `cd` into the one you want and run it like any other
Next app (`npm install && npm run dev`).

## Running the Godot client

Open `godot/project.godot` (or `godot_hdv_core/project.godot`) directly in
Godot 4.x.
