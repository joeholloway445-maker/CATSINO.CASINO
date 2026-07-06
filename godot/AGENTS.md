# AI context for Periliminal.Space (the Godot project in CATSINO.CASINO)

This file is the FIRST thing any AI working on this project must read —
Claude Code in a terminal, an in-editor MCP plugin, anything. It says what
the game is, what already exists, what order to build/fix things in, and
the conventions that keep 100+ GDScript files consistent.

## How to get an AI working on this project (in-engine options)

Godot has no first-party AI panel. Real options, best first:

1. **Claude Code pointed at this folder** (`cd godot && claude`, or the
   desktop app / claude.ai/code with this repo). It reads this file
   automatically, can edit every `.gd`, and can run
   `godot --headless --check-only --script <file>` or open the project with
   `godot --headless --editor --quit` to harvest the full error list.
   This is the recommended workflow: **copy the editor's error output and
   paste it to Claude Code** — that beats any in-engine plugin today.
2. **Godot MCP plugin for in-editor chat** — install a community
   Godot-MCP bridge (e.g. `godot-mcp` on GitHub, or "AI Assistant Hub"
   from the AssetLib) into `addons/`, connect it to Claude via MCP. This
   gives a dock panel inside the editor that can inspect the scene tree
   live. Community-maintained; verify it targets Godot **4.3** before
   installing.
3. **External editor mode** — set VS Code/Cursor as Godot's external
   script editor (Editor Settings → Text Editor → External) and run an AI
   there; Godot hot-reloads scripts on save.

## Fixing a large error count (READ THIS BEFORE FIXING ANYTHING)

Godot error counts CASCADE. One file that fails to parse takes down every
script that references its `class_name` or autoload, so "800 errors" is
usually 5–15 root-cause files. Procedure:

1. Sort the errors by file, and fix files in DEPENDENCY ORDER (see the
   layer list below): data → core → world → layers → UI. Never start with
   a UI file's error — it's almost always a downstream symptom.
2. After each batch of fixes: Project → Reload Current Project. The count
   should drop by dozens per real fix.
3. The most likely root-cause classes in this codebase, in order:
   - **API drift vs Godot 4.3** — this code was written without a compiler
     available; property/method names were pattern-matched. Typical fixes
     are one-line renames.
   - **Typed-dictionary/array inference** — `:=` with a `.get(...)`
     result; fix by adding an explicit type or `str()/int()/float()` cast.
   - **Autoload order** — autoloads must not touch OTHER autoloads in
     `_init`/field initializers; do it in `_ready` or at call time.
   - **`await` on non-coroutines** and signal signature mismatches.
4. Do NOT rewrite systems to silence errors. Smallest possible fix, keep
   the design; the architecture below is intentional.

## Project identity

- **Game**: Periliminal.Space — a six-reality-layer psychology XRMMORPG.
  The casino ("Catsino") is ONE feature inside it (the Hyperliminal),
  not the game. Cat-themed skins are presentation only.
- **Engine**: Godot **4.3**, renderer **gl_compatibility** (mobile + web
  friendly). Forward+-only features (SSAO/SSIL/SSR/volumetric fog) must be
  gated behind `RenderCaps.is_compatibility()` — never used bare.
- **Companion site**: Next.js app in `apps/catsino-casino` (deployed on
  Vercel). It is the website, NOT the game. The game ships as a Godot Web
  export (preset target `builds/html5` — the one-time export preset must
  be created in the editor; CI/nginx infra already expects it).
- **Backend**: Supabase (shared Postgres, telemetry, currencies) +
  Nakama realtime client in `addons/nakama-godot-4/` (original in-house
  implementation — per-endpoint confidence notes in its README).
- **Ownership/UGC**: player blueprints stay the creator's; canon-accepted
  UGC becomes property of Holloway's Own Providential Enterprise Apex
  Holdings Inc. (10% cut). Forking is opt-in only. See `docs/UGC_POLICY.md`.

## The six reality layers (and how they connect — this is the game)

| layer | what it is | in | out |
|---|---|---|---|
| **Subliminal** | private apartment start; every boot begins here | invite/own | obvious door → Liminal |
| **Liminal** | never-static between-space; chunks dissolve behind you | doors from everywhere | LiminalDoor (prestige-gated) + LayerExitDoor archways (Hyperliminal weighted most common) |
| **Superliminal/Supraliminal** | persistent DFW Metroplex open world | obvious exits | venue doors + 1–3 seeded **HiddenDoor**s per city → Liminal (ZERO visual tells, by design) |
| **Hyperliminal** | the Catsino (casino, games) | easiest find from Liminal | UI navigation |
| **Extraliminal** | Pokémon-GO-style landmark overlay; guild wars | Liminal archway | obvious door back |
| **Periliminal** | the psychology gauntlet | ONLY the 7–15 min randomized Liminal pull (`LayerManager._pull_threshold`, re-rolled per entry, NO warnings ever) | ONLY the blessing door (`LayerExitDoor.blessing`), which appears after `PeriliminalRuns.blessing_ready()` |

NEVER add: a Periliminal entrance door, a pull countdown/warning, or a
visual tell on HiddenDoor. These are core design invariants.

Cities (ids unchanged): New Dallas (`dallas`), Hell's Half Acre
(`fort_worth`), Sky Fjord (`denton`), Soulless Sanctuary (`arlington` —
the ONLY city with Arena, College, Space Station). Every city gets the
civic set: market, bank, armorer, blacksmith, stockyards, wager hall.

## Currencies (six, fixed — do not invent more)

coins (money) · chips (casino, from coins) · fragments (PvE) ·
tokens (PvP) · charges (quests/leaderboards/achievements) ·
prestige (XP+currency; the ONLY thing a Periliminal wipe spares).
`EconomyManager` owns them; `equivalent_exchange` (prestige) is the
intended bypass for gated content.

## System inventory (what exists — extend, don't duplicate)

- **Layers**: `src/layers/layer_manager.gd` (autoload; wander timer),
  `layer_world.gd` (one scene script, all explorable layers),
  `periliminal_runs.gd` (runs, wipe, `difficulty()`, blessing),
  `layer_exit_door.gd`, `extraliminal_manager.gd`, `src/world/door.gd`
  (prestige LiminalDoor).
- **City stack**: `src/world/city/` — `city_data.gd`, `mega_city_builder.gd`
  (also seeds hideout sites + hidden doors), `building_builder.gd`,
  `landmark_builder.gd`, `city_venues.gd`, `city_lighting.gd`,
  `city_ambience.gd`, `traffic_ribbons.gd`, `city_door.gd`,
  `hidden_door.gd`, `breakable_prop.gd`, `guild_hideout.gd`.
- **Territory**: `src/social/hideout_registry.gd` (autoload) — multi-site
  hideouts in Supraliminal AND Extraliminal, 220m guild-exclusion radius,
  optional banners, PoGo-style entity defenders (a defending entity is
  REMOVED from the party until recalled — keep that invariant).
- **Psychology**: `src/companion/hope.gd` (autoload; observes everything,
  feeds Supabase `hope_telemetry`), `src/social/word_of_mouth.gd`
  (autoload; per-NPC firsthand memory + hash-seeded gossip spread — word
  of mouth, NOT a hive mind). Periliminal difficulty reads both.
- **Skills**: `src/skills/skill_data.gd` (all lines incl. Unarmed Way +
  Gunplay; six ELEMENTS on every line), `skill_manager.gd` (attunements;
  bars use `.actives`, NOT "slots"). Element combat riders live in
  `layer_world._on_cast`.
- **Blueprints/UGC**: `src/blueprints/` + `src/ui/blueprint_forge_ui.gd` —
  every weapon/armor/skill/entity is a visually+sonically editable
  blueprint; governance: private → mod_review → dev_review → canon.
- **Entities**: `src/data/entity_dex_data.gd` (144 faction lines + 48
  Factionless ancient-pantheon lines — many cultures, nothing copyrighted,
  never Yahweh), `src/data/companion_registry.gd`, `src/world/world_entity.gd`
  (RPS via PerceptionSystem).
- **Fake multiplayer**: `src/multiplayer/presence_manager.gd` — tiered
  KNOLL bots (STATIC 60% / REACTIVE 30% / ADAPTIVE 10%).
- **UI/UX**: `src/ui/title_screen.gd` (Start New Venture → Liminal;
  Continue Expedition → Subliminal), `venture_wizard.gd` (MK-style),
  `logo_emblem.gd` (procedural God-of-gods emblem; yields to
  `assets/ui/logo.png` if present), `omni_dex_ui.gd`, `touch_controls.gd`
  (mobile; static state consumed by the controller), `npc_dialogue_ui.gd`
  (JSON dialogue + WordOfMouth greetings/social moves), `aaa_theme.gd`,
  `src/rendering/reality_bend.gdshader` + overlay.
- **Community**: `src/community/story_vote.gd` — one vote per ballot per
  server day (4h), stacking, soft cap only. No hard caps.
- **Assets**: `src/core/asset_library.gd` — ALL hard meshes/materials/
  sounds route through `AssetLibrary.instance()/material()/sound()` so
  texture/light/sound packs and the race IdentityLens swap in without
  touching geometry code. Keep new world code on this path.

## Build order (do these IN ORDER — each gates the next)

1. **Make it parse.** Open the editor, fix errors per the cascade
   procedure above until the project loads with zero script errors.
2. **Boot path.** Confirm: title screen loads → New Venture → race/frame/
   mod wizard → Liminal; Continue → Subliminal. Fix scene wiring only
   after scripts parse.
3. **Layer round-trip.** Liminal exit archways work; Supraliminal city
   builds; a HiddenDoor drops into Liminal; the pull fires into
   Periliminal; blessing door exits. This is the spine of the game —
   verify before touching anything cosmetic.
4. **Web export preset.** Editor → Project → Export → add Web preset →
   output `builds/html5/index.html`. CI + nginx `game` service already
   expect this path. This is what finally puts the GAME (not just the
   site) on the internet.
5. **Combat/economy pass in-engine**: skills bars, element riders,
   hideout claim/defend flow, casino games, StoryVote.
6. **Content**: dialogue JSON, dex descriptions, blueprint presets,
   audio packs (Suno-generated songs slot in via AssetLibrary sound
   slots), city texture/light/sound packs per race.
7. **Real multiplayer**: wire NetworkManager/Nakama beyond presence bots.

## Conventions

- Tabs for indentation. `:=` where the type is inferable. `class_name`
  statics for stateless helpers; autoloads (registered in `project.godot`
  `[autoload]`) for stateful systems.
- New autoloads: add to `project.godot`, never assume load order — touch
  other autoloads only from `_ready()` or later.
- Every user-visible string goes through `NotificationUI.notify_info/
  notify_win/notify_error`. Keep the game's voice: second person,
  atmospheric, brief.
- Persistence is `user://*.json` via `FileAccess` + `JSON` (see
  `hideout_registry.gd` for the pattern).
- Determinism matters: anything world-placed is seeded
  (`rng.seed = hash("thing_" + id)`) so every visit rebuilds identically.
- Mobile: gate Forward+ features on `RenderCaps`, read
  `TouchControls.move_vector/consume_*` statics, never require hover.
