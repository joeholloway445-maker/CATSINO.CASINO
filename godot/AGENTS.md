# AI context for Periliminal.Space (the Godot project in CATSINO.CASINO)

This file is the FIRST thing any AI or agent working on this project must
read — Ziva, Claude Code, an in-editor MCP plugin, anything. It is written
to be tool-agnostic: no step below assumes a specific assistant, only that
you can read files, edit files, and see the Godot editor's error output.
It says what the game is, what already exists, what order to build/fix
things in, and the conventions that keep 100+ GDScript files consistent.

## EXACT operating procedure for any AI agent (follow verbatim)

1. Read this entire file before touching any code.
2. Open the project from `godot/project.godot` in the **newest stable
   Godot 4.x** available (4.3 or later — 4.7 recommended in mid-2026).
   If the version is older than 4.3, STOP and tell the user to upgrade:
   this code uses APIs (typed dictionaries, `class_name` statics,
   `ProceduralSkyMaterial` fields, `MultiMesh.transform_format`, etc.)
   that were not stable pre-4.3. Godot 3.x will NOT work at all — the
   language is different. Never downgrade the project to satisfy a
   version constraint; upgrade the editor instead.
3. Collect the CURRENT error list: Editor bottom panel → "Errors" tab
   (or run `godot --headless --editor --quit 2>errors.txt` from the
   `godot/` folder). Do not fix from memory of an old list.
4. Group the errors BY FILE, then order the files by layer:
   `src/data/` → `src/core/` → `src/identity|character|skills/` →
   `src/world/` → `src/layers/` → `src/companion|social|multiplayer/` →
   `src/ui/`. Fix in that order only — most UI errors are cascade
   symptoms of one broken upstream file (details in the next section).
5. Make the SMALLEST edit that fixes each error. Never rewrite a system,
   never rename public functions/signals other files call, never delete a
   feature to silence an error. The design invariants below are law.
6. After each file batch: Project → Reload Current Project, re-collect
   errors, confirm the count dropped. If a fix didn't drop the count,
   revert it and rediagnose.
7. When the project loads with ZERO script errors, proceed to the
   numbered **Build order** section — do its steps in order, one at a
   time, verifying each in the running game (F5) before the next.
8. Commit after every green step with a message naming the step.
   Never commit with the error count higher than you found it.

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
   - **API drift** — this code was written without a compiler available;
     property/method names were pattern-matched against Godot 4.3 docs
     and may need one-line renames on newer 4.x versions. Check the
     current API in the Godot docs before assuming an error is real.
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
- **Engine**: newest stable **Godot 4.x** (4.3 minimum; 4.7 recommended
  in mid-2026 — always use the newest stable that still parses this
  project). Renderer **gl_compatibility** (mobile + web friendly).
  Forward+-only features (SSAO/SSIL/SSR/volumetric fog) must be gated
  behind `RenderCaps.is_compatibility()` — never used bare.
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
- **City stack**: `src/world/city/` — `city_data.gd`, `osm_city_layout.gd`
  (OpenStreetMap downtown clones in `world_data/osm/`),
  `mega_city_builder.gd` (OSM streets/buildings when present; also seeds
  hideout sites + hidden doors), `building_builder.gd`,
  `landmark_builder.gd`, `city_venues.gd`, `city_lighting.gd`,
  `city_ambience.gd`, `traffic_ribbons.gd`, `city_door.gd`,
  `hidden_door.gd`, `breakable_prop.gd`, `guild_hideout.gd`.
  Refresh OSM data with `python3 scripts/fetch_osm_cities.py`
  (© OpenStreetMap contributors, ODbL).
- **Territory**: `src/social/hideout_registry.gd` (autoload) — multi-site
  hideouts in Supraliminal AND Extraliminal, 220m guild-exclusion radius,
  optional banners, PoGo-style entity defenders (a defending entity is
  REMOVED from the party until recalled — keep that invariant).
- **Capture-by-defeat**: `src/companion/capture_system.gd` (autoload
  `CaptureSystem`) — wild entities can ONLY be bonded by defeating them.
  Called from `layer_world._on_entity_died` with the player's remaining
  HP ratio. Base chance by category, minus a stage penalty, plus health
  and Hope-bond bonuses, minus a Periliminal-difficulty penalty. Never
  auto-unlock an entity anywhere else; if legacy UI wants to, route it
  through this system. Never add a "catch a wild entity without fighting"
  path — the whole design invariant is that captures stay rare.
- **Breeding**: `src/companion/companion_breeding.gd` (autoload
  `CompanionBreeding`) — pair two UNLOCKED entities, 6h gestation,
  parents locked out of other pairings while gestating. Offspring
  always Stage 1, same-category pairs bias to that category,
  cross-faction pairs sometimes yield Factionless "orphan" lines.
  Charges pay both the initial cost and hurry-through.
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
- **NPC population**: `data/npc_templates.json` (5 lore archetypes —
  Barista/Archivist/Authority/Lover/Reflection — × 6 layer variants,
  natural-human trait ranges) → `src/world/npc_generator.gd` (1,000+
  deterministic NPCs; realistic heights/skin/hair hexes + archetype
  `chassis_hex`) → `NPCManager` autoload (per-layer rosters, live-position
  LOD: full <30m / no-shadow <100m / silhouette impostor beyond, ≤50
  full-detail per district) → `src/world/npc_spawner.gd` (AmbientNpc
  root wearing `src/world/npc_body.gd`, which resolves visuals through
  `MetahumanCharacter` — never label-only NPCs). Dialogue: shared lore
  blocks per archetype × layer in `src/world/npc_dialogue_library.gd`,
  registered into `WorldLoader.dialogues`. Crowd density is layer
  psychology (Subliminal 12, Liminal 8, Periliminal 6, cities 50) —
  keep it sparse where the lore says lonely. **The installed body mesh
  is currently a robot, not a human** (see `assets/models/ATTRIBUTION.md`)
  — `NpcBody` tints whatever surfaces the ACTUAL installed mesh exposes
  (skin/hair on a MetaHuman export, chassis/glow on the current robot)
  and hides the robot's cannon appendage for every archetype but
  Authority. Never assume the mesh is human without checking its glTF
  material names first.
- **Asset variety**: `src/core/asset_library.gd`'s `instance_variant(slot,
  rng)` picks deterministically from `data/asset_variants.json` →
  `assets/models/variants/<slot>/*.glb` pools (falls back to the single-
  file `instance(slot)` when no pool exists). Wired into
  `BuildingBuilder.build()/build_osm()` (via the caller's existing
  per-city `rng`, so cities stay deterministic) and `BreakableProp`
  (`variant_seed` set by its placer). Land/space vehicle bodies vary by
  spawn-position hash. Road/sidewalk tiles are deliberately NOT
  variant-pooled — they interlock at fixed pivots and a random swap would
  break the street grid, not just look different.
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

## Game modes (NOT lost — here is where each one lives or goes)

Existing code — extend these, never create parallel systems:

| mode | status | code |
|---|---|---|
| 1v1 duels | built (trial context) | `src/ascension/ascension_trial.gd` + `trial_arena.gd` — Round II/III duels vs Knoll built from Hope's profile; generalize this into open 1v1 |
| 5v5 MOBA ("Paws of the Ancients") | defined, lobby-level | `src/data/arena_modes.gd` (`moba`) via Arena hub (`src/ui/arena_hub_ui.gd`) |
| Team deathmatch / large team battle | defined, lobby-level | `arena_modes.gd` (`conflict`, team_size=12) |
| Survival (shrinking zone) | defined, lobby-level | `arena_modes.gd` (`survival`) |
| Zombies / horde co-op | defined, lobby-level | `arena_modes.gd` (`zombies` — waves of feral entities) |
| CTF + arena racing | defined, lobby-level | `arena_modes.gd` (`ctf`, `race_arena`) |
| PvXC open pit (Ark-style) | built | `src/pvxc/pvxc_manager.gd`, `pvxc_zone.gd`, `pvxc_gate_ui.gd` |
| Open-world PvP + bots | built | `src/layers/layer_world.gd` + `src/multiplayer/presence_manager.gd` |
| Guild wars | built | `ExtraliminalManager.open_liminal_door` + `HideoutRegistry.contest` |

Planned — NOT yet in code (build in this order, inside the systems named):

1. **2v2** — add `{id="duel_2v2", team_size=2}` to `ArenaModes.MODES`;
   matchmaking rides the same Arena lobby as 1v1.
2. **Zone bosses** — Stage-3 `WorldEntity` elites at seeded landmarks per
   city; spawn from `LandmarkBuilder`/`layer_world`, announce via
   NotificationUI, pay fragments + charges.
3. **World bosses** — one server-wide Stage-3+ entity on a StoryVote-able
   schedule; extend `WorldEntity` with a boss health pool and phase
   triggers; rewards through `EconomyManager` + `CrownManager`.
4. **Dungeons** — instanced party runs: reuse the Periliminal's
   generated-then-static seed pattern (`PeriliminalRuns._seed_ledger`)
   but WITHOUT the wipe rule; entry doors as `LiminalDoor` variants.
5. **PvP campaigns** (ESO/WoW-style) — chained `QuestManager` arcs whose
   stages are contested `TerritoryControl` chunks; faction score through
   `CrownManager`.

Rule: arena-hosted things are MODES of Soulless Sanctuary's Arena (lobby
hop), not new reality layers. Promote a mode to a layer only if it gains a
persistent world/economy of its own (`arena_modes.gd` header explains).

## Build order (do these IN ORDER — each gates the next)

**v0.1 goal = AAA GOTY.** See `docs/V01_GOTY.md`. Visual bar =
realistic ESO (`docs/VISUAL_DIRECTION_ESO.md`) — MetaHumans for characters,
Terrain3D for desktop terrain. Do not redefine ship as a thin MVP while
this goal is locked.

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
6. **Game modes** (in the order listed in the Game modes section:
   2v2 → zone bosses → world bosses → dungeons → PvP campaigns), each
   playable end-to-end before starting the next.
7. **Content**: dialogue JSON, dex descriptions, blueprint presets,
   audio packs (Suno-generated songs slot in via AssetLibrary sound
   slots), city texture/light/sound packs per race. External
   writer-friendly dialogue (Dialogue Manager) and other community
   addons: see `docs/ADDONS.md` / `docs/ASSET_SHOPPING_LIST.md` —
   install with `bash scripts/install_addons.sh`; enable plugins only
   after a zero-error smoke open. Prefer pure-GDScript (web export).
8. **Real multiplayer**: wire NetworkManager/Nakama beyond presence bots.

## Current status snapshot (last checked 2026-07-15 — re-verify, don't trust)

This section exists because two "status" docs in `docs/` (`IMPLEMENTATION_STATUS.md`,
`LAUNCH_CHECKLIST_AND_ROADMAP.md`) are point-in-time snapshots that predate
the world-building/visual work below and read as more pessimistic than
current reality. **`docs/V01_GOTY.md`'s gate table is the one to trust**;
this section is the most recent concrete read against it. Update this
section (with today's date) whenever you re-verify a gate — don't let it
go stale the way the other two did.

- **Gate 1 (zero script errors) / Gate 2 (boot path): STATUS UNKNOWN, NOT
  STALE-PASS.** `V01_GOTY.md` marks both "Done (PR #22)" / "Done (boot_smoke
  PASS)", but that was recorded before at least 5 subsequent commits
  (vehicle/spawn-point pass, NPC population system, two GLB asset passes,
  a PBR texture pass) — none of which have been opened in an actual Godot
  editor or exercised by CI. **Do not assume they still hold.** First
  action on this project, every session: re-run the error-collection
  procedure at the top of this file before trusting anything past it.
- **CI (`godot-ci.yml`) only triggers on push to `main` or an open PR** —
  it does NOT run on every push to a feature branch. Check
  `Actions → godot-ci` and match run SHAs against `git log` before
  assuming a branch's current head has been validated. A green run on an
  old SHA tells you nothing about later commits on the same branch.
  `godot-ci` runs a real headless Web export (`godot --headless
  --export-release Web`) — a failure there is a real parse/import
  failure. It also runs gdUnit4 tests IF `godot/test/*.gd` files exist;
  as of this snapshot that directory is empty, so that step just skips.
  `boot_smoke.gd` (`src/dev/boot_smoke.gd`) is NOT wired into CI at all —
  it's a manual/local check only (`godot --headless --path godot -s
  res://src/dev/boot_smoke.gd`).
- **Web export preset EXISTS** (`godot/export_presets.cfg` has Windows/
  Linux/macOS/Web, Web pointed at `../builds/html5/index.html` matching
  what CI/nginx expect) — Build order step 4 is further along than
  "Next" in `V01_GOTY.md` suggests; it still needs a real green CI run
  to confirm it actually works end to end, not just that the file exists.
- **Addons: all 8 recommended in `docs/ADDONS.md` are already vendored**
  in `godot/addons/` (Dialogue Manager, Phantom Camera, Beehave, GLoot,
  Maaack's Menus Template, Panku Console, gdUnit4, Terrain3D). Only
  `Terrain3D` is enabled in `project.godot`'s `[editor_plugins]` — this
  is INTENTIONAL, not unfinished work (`docs/ADDONS.md`: "do not enable
  plugins until a smoke open confirms zero parse errors"). Do not
  re-fetch or re-install any of these; the only remaining step is
  enabling them one at a time, in the editor, after Gate 1 is
  re-confirmed clean.
- **Audio: `godot/assets/audio/` has nothing but `.gitkeep`.** Zero SFX,
  music, ambience, or UI sound has been sourced — this is a real, total
  gap, not started, distinct from the visual-asset work below which has
  had two full passes.
- **Model slots still empty** (per `docs/SHIPPING.md`'s own shopping
  table, never sourced despite being called out there): `player_cat`,
  `npc_cat`, `creature`, `tree`, `crystal`, `ruin_pillar`,
  `extraction_gate`, `harvest_node`, `apartment_prop`,
  `vehicle_aircraft_body` (no CC0 source found — see
  `assets/models/ATTRIBUTION.md`). Filled so far: vehicle car/boat/
  spacecraft bodies + variant pools, all four city building types +
  variant pools, road/sidewalk/streetlight/prop, five PBR facade/ground
  texture sets (see `assets/models/ATTRIBUTION.md` and
  `assets/textures/ATTRIBUTION.md` for exact sources/licenses).
- **Human mesh gap** (full detail in the NPC population bullet above and
  `assets/models/ATTRIBUTION.md`): the installed `player_human.glb` is a
  sci-fi robot (tps-demo), not a human, despite its name and older
  comments. No CC0/MIT photoreal human GLB was found that doesn't
  require a Blender/MakeHuman export step — that step hasn't been run by
  anyone yet. Don't re-litigate the search; `docs/ASSET_SHOPPING_LIST.md`
  has the full source-by-source verdict (including why RenderPeople/
  TurboSquid/CGTrader free tiers are NOT safe to commit — free-to-download
  ≠ safe-to-redistribute, and a git push IS redistribution).

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
  `TouchControls.move_vector` / `look_delta` (consume once/frame) /
  `sprint_held` / `consume_jump()` / `consume_interact()` statics, never
  require hover. Left thumb = joystick, right half of screen = camera
  drag, right column = JUMP / E / cast slot 1 / SPRINT (hold).
  MOBILE IS THE FIRST-CLASS TEST TARGET — verify any new HUD/UI element
  at phone aspect ratios (portrait 9:16 and landscape 16:9) and respect
  safe-area insets before shipping.
