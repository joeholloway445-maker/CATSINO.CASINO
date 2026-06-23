# AI context for the CATSINO.CASINO Godot project

This file travels with the Godot project on purpose: whenever this project is
opened (imported into a fresh Godot install, cloned to a new machine, or
pointed at by an AI coding tool — including Claude Code itself, or any
MCP-based Godot plugin), this file is the first thing to read. It exists so
"the AI" has the game plan and current state without anyone re-explaining it.

## How to actually get an AI working *inside* the Godot editor

Godot has no official first-party AI chat panel. The two real options, in
order of how little setup they need:

1. **Run Claude Code against this folder directly** (`cd godot && claude`).
   No Godot plugin required — this already works today, and is what's
   producing this file. Claude Code can read/edit any `.gd`/`.tscn`/`.tres`
   file here, run `godot --headless --script ...` for batch operations, and
   it picks up this file automatically because it behaves like an
   AGENTS.md/CLAUDE.md.
2. **Install an open-source Godot-MCP plugin** (e.g. `godot-mcp` on GitHub)
   if in-editor chat (a dock panel you talk to while the editor is open) is
   wanted instead of a terminal. This is a community plugin, not something
   we control from this repo — installing it is a one-time step the person
   running the Godot editor does locally (Godot AssetLib or manual addon
   drop into `addons/`), and once installed it can read this same file for
   context. Not yet installed in this project; nothing here depends on it.

There is no way to make an AI "automatically" attach itself the moment
someone opens the project in Godot — Godot doesn't expose a hook for that.
What *can* travel automatically is this file's content, so option 1 always
has full context with zero setup.

## Project identity

- **Game**: CATSINO.CASINO — cat-themed cosmetic skin over the same database
  as THE-HDV-CORE ("Periliminal.Space"). Same player accounts, same wallet,
  same everything; only presentation differs (e.g. "coin" displays as
  "Cat Coin", "chip" as "Cat Chip").
- **Database**: Supabase/Postgres project `lamdemoaszkilguvkvcd`
  ("Periliminal.Space"), shared with THE-HDV-CORE. Never assume this Godot
  client owns its own database — schema changes must stay compatible with
  the Next.js side (`/home/user/THE-HDV-CORE` and `/home/user/CATSINO.CASINO`
  repos, `supabase/migrations/`).
- **Engine**: Godot 4.3, Forward+ renderer (`project.godot`).
- **Networking**: `src/networking/http_client.gd` talks to Supabase REST/RPC;
  `src/networking/nakama_modules/` holds a Nakama-based realtime layer for
  anything that needs live multiplayer state.

## Currency model (do not invent new currencies — six exist, by design)

| name | shown as (Cat skin) | earned via | spent on |
|---|---|---|---|
| coin | Cat Coin | real money | anything |
| chip | Cat Chip | exchanged from coin (10:1) | gambling/wagers |
| tokens | Tokens | PvP kills/quests, first 3 coin purchases, random events | PvP items; droppable on death, lootable |
| fragments | Shard Fragments | PvE kills/quests, first 3 coin purchases, random events | PvE items; partially droppable, not regainable |
| charges | Charge Nodes | mission rewards, gambling wins | companions, mounts |
| renown | Perception | passive XP from all play | leveling perception; gating race/faction/morality content; **fallback wager currency when out of chips** |

RPCs live in `supabase/migrations/005_currency_foundation.sql` (and CATSINO's
mirrors) — `grant_currency`, `spend_currency`, `exchange_coin_for_chip`. The
Godot client should call these via RPC, never write `player_currencies`
columns directly client-side.

## Player-driven storyline / wagering system (new, foundation only)

`story_arcs` / `story_choices` / `story_wagers` tables + `place_story_wager`
/ `resolve_story_arc` RPCs (`supabase/migrations/007_story_arcs_and_wagering.sql`
in THE-HDV-CORE, mirrored as `025_...` here) let players invest chips (or
renown, automatically, when out of chips) into competing outcomes on shared
plot arcs. Resolution pays out the winning side pari-mutuel from the pool,
tallied per faction. **Nothing in this Godot client consumes arc outcomes
yet** — wiring a resolved arc to an actual in-world effect (open a district,
shift entity spawn tiers, unlock a questline) is unbuilt. This is the next
piece of narrative work, not graphics work.

## Endgame roadmap (planned, not yet built — see web app's `/endgame` hub)

Long-term direction, roughly in build-order of what's most tractable with
existing open-source building blocks vs. needing bespoke work from scratch:

1. **Seasonal ever-expanding storyline** — one new story arc/season,
   wired to real consequences (district unlocks, faction power shifts).
2. **1v1 / 2v2 PvP** — smallest-scope competitive mode, reuses
   `src/combat/combat_system.gd` already in this project.
3. **MOBA mode** (Mobile-Legends-style: multiple game modes — classic,
   brawl, ranked) — biggest net-new system; look at open-source Godot MOBA
   starter kits before building combat/lane/jungle logic from scratch.
4. **"Conflict" mode** (CoD-style classic modes — team deathmatch, domination,
   search & destroy equivalents) — reuses combat_system + needs a map/loadout
   layer.
5. **Zombies mode** (in-house spin, not a CoD clone) — wave-survival loop,
   reuses combat_system + entity spawner from `lib/game` on the Next.js side
   as a design reference (tiered entities already exist there).
6. **PvP campaigns / dungeons / boss fights** (ESO/WoW-style) — needs
   instance/party tooling that doesn't exist yet anywhere in either repo.
7. **UGC** — there is already a *separate*, unrelated UGC system in
   THE-HDV-CORE (`types/ugc.ts`, blueprint/charge mechanic for companion
   creation) — extend that rather than building a second UGC pipeline.

None of these are implemented in this Godot project yet beyond the systems
already listed in `project.godot`'s `[autoload]` section (combat, companion,
economy, social, liveops, tournaments). Treat the numbered order above as
the working priority, not a promise of what exists today.
