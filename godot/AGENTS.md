# AI context for Periliminal.Space (the Godot project in CATSINO.CASINO)

This file is the FIRST thing any AI or agent working on this project must
read — Ziva, Claude Code, an in-editor MCP plugin, anything. It is written
to be tool-agnostic: no step below assumes a specific assistant, only that
you can read files, edit files, and see the Godot editor's error output.
It says what the game is, what already exists, what order to build/fix
things in, and the conventions that keep 100+ GDScript files consistent.

## EXACT operating procedure for any AI agent (follow verbatim)

0. Install the addon stack ONCE per fresh clone:
   `bash scripts/install_addons.sh` from the repo root (see
   `docs/ADDONS.md`). Pure-GDScript addons only, so the Web export
   target keeps working — never add a GDExtension addon without
   confirming a web binary ships. If the script fails on a specific
   addon, install the others and note the failure; do not skip this
   step entirely.
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
9. **Asset drops** (models / textures / sounds / logo): follow the
   section **How to drop assets into slots** below — rename files to
   exact slot names under `godot/assets/`; do not invent registration
   code. Owner may hand you a PNG/GLB and say "put this in as logo /
   metahuman_player / …" — that section is the whole job.
10. **PeriHumans:** characters/NPCs must ship in the build. Players never
    install Unreal/MakeHuman/DAZ. Prefer updating
    `peri_human_player.glb` / `peri_human_npc.glb` (and variant pools).
    Do not ask the owner to run third-party character tools to play.

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

NEVER add: a Periliminal entrance door, a pull countdown/warning, a
visual tell on HiddenDoor, or ANY label/hint/tutorial/achievement text
that reveals the Recall Walk (see Body memory below). These are core
design invariants.

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
- **Body memory**: `src/core/proprioception.gd` (autoload) — tracks gait/
  turns/posture from `ThirdPersonController` and holds the game's one
  fully unlabeled secret, the **Recall Walk**: 7 paces backward → 180°
  left → 3 paces backward → 180° right → crouch (holdable indefinitely;
  every other stage times out) → rise ⇒ instant return to the player's
  own Subliminal from ANY layer, Periliminal included
  (`PeriliminalRuns.recall_escape()` — run ends unbanked AND unwiped).
  First-ever performance queues a durable report to
  `/api/secret/discovery` (Supabase `secret_discoveries` + optional
  `DISCORD_SECRET_WEBHOOK_URL` owner ping, server-side env only) and
  registers + auto-accepts the discoverer-only `recall_*` quest chain.
  Crouch is a real movement feature (Ctrl/C, or the touch posture
  button) so the final ingredient looks unremarkable.
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
  ships as MPFB2 PeriHuman / humanoid GLBs** (see `assets/models/ATTRIBUTION.md`)
  — `NpcBody` tints whatever surfaces the ACTUAL installed mesh exposes
  (skin/hair on PeriHuman / MetaHuman-slot exports)
  and hides non-humanoid appendages for every archetype but
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
| 5v5 MOBA ("Paws of the Ancients") | built (offline + online) | Offline: `src/world/moba/*`. Online: Nakama `moba_match` + `MobaOnlineClient` via Arena hub queue |
| Team deathmatch / large team battle | defined, lobby-level | `arena_modes.gd` (`conflict`, team_size=12) |
| Survival (shrinking zone) | defined, lobby-level | `arena_modes.gd` (`survival`) |
| Zombies / horde co-op | defined, lobby-level | `arena_modes.gd` (`zombies` — waves of feral entities) |
| CTF + arena racing | defined, lobby-level | `arena_modes.gd` (`ctf`, `race_arena`) |
| PvXC open pit (Ark-style) | built | `src/pvxc/pvxc_manager.gd`, `pvxc_zone.gd`, `pvxc_gate_ui.gd` |
| Open-world PvP + bots | built | `src/layers/layer_world.gd` + `src/multiplayer/presence_manager.gd` |
| Guild wars | built | `ExtraliminalManager.open_liminal_door` + `HideoutRegistry.contest` |

Built (Gates 5–7 thickened — Gate 8 local docker path; prod secrets pinned):

1. **2v2** — `duel_2v2` + ally bots that follow, focus weakest, show HP.
2. **Zone bosses** — `ZoneBossSpawner` → `setup_boss(..., "ZONE WARDEN")`.
3. **World bosses** — `WorldBossScheduler` + multiphase `setup_boss`.
4. **Dungeons** — seeded dens via `DungeonRuns.run_seed()`, no wipe, no blessing exit.
5. **PvP campaigns** — `pvp_campaign_01..03` + warden-scout dialogue hooks.
6. **Casino** — OfflineCasino spends/pays **chips**; `get_leaderboard` soft-path.
7. **Gate 8** — `scripts/build_nakama_modules.sh` + `gate8_smoke` (SKIP if down).

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
4. **Web export preset.** Preset exists (`export_presets.cfg` →
   `../builds/html5/index.html`). Export with `bash scripts/export_web.sh`,
   serve with `bash scripts/serve_web.sh`. CI uploads the html5 artifact
   on PRs. Verified headless export OK on 2026-07-15 (~95MB: index.pck +
   index.wasm).
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

## Current status snapshot (last checked 2026-07-16, post CI-green)

This section exists because two "status" docs in `docs/` (`IMPLEMENTATION_STATUS.md`,
`LAUNCH_CHECKLIST_AND_ROADMAP.md`) are point-in-time snapshots that predate
the world-building/visual work below and read as more pessimistic than
current reality. **`docs/V01_GOTY.md`'s gate table is the one to trust**;
this section is the most recent concrete read against it. Update this
section (with today's date) whenever you re-verify a gate — don't let it
go stale the way the other two did.

- **CI GREEN (2026-07-16, run 29468572375 at b8fcbba).** First successful
  CI validation since 2026-07-10: headless import + Web export completed
  in ~12.5 min and uploaded a real `builds/html5` artifact. Getting here
  required fixing hang cause #2 (after terrain_3d below): the fight-loop
  pass added `offline_casino.gd` with two `:=` type-inference parse
  errors, which cascade-broke NetworkManager → EconomyManager →
  AccountManager → GameManager (5 autoloads from 2 lines), and the
  headless editor parked on a modal again. Fixed with explicit `: bool`
  annotations, plus process-level `timeout` wrappers on both godot
  invocations in godot-ci.yml so any future modal hang fails the STEP in
  minutes with the SCRIPT ERROR lines visible in the log. TWO operational
  rules from this saga: (1) pushes from Claude/agent sessions do NOT
  trigger the pull_request workflow — validate via manual dispatch
  (`gh workflow run godot-ci.yml --ref <branch>` or the Actions API);
  (2) a hung in_progress job's logs 404 — only completed jobs' logs
  download, which is why fast timeouts are what make failures
  diagnosable.
- **Initial prototype spine (2026-07-15).** Gate 1 re-verified clean (0
  SCRIPT ERROR / failed autoload on Godot 4.3 headless editor open). Gate 2
  `boot_smoke` PASS. Gate 3 walkable via title **Play Prototype Spine**
  (`LayerManager.enable_prototype_mode`: 8s Liminal pull, guaranteed
  Metroplex/Catsino exits near spawn, blessing depth 1) and verified by
  `godot --headless --path godot -s res://src/dev/layer_spine_smoke.gd`
  (RESULT=PASS). Production pull remains 7–15 min with no warnings.
- **Web export verified (2026-07-15).** `bash scripts/export_web.sh` produces
  `builds/html5/` (~59MB pck + ~34MB wasm). Serve with
  `bash scripts/serve_web.sh` (COOP/COEP). Artifact is gitignored; CI uploads
  `periliminal-space-html5` on PRs.
- **Branch history reconciled with main (2026-07-15).** This branch had
  been merged into main 9+ times and reused each time without syncing
  back; PR #28 initially showed a 927K-line "dirty" diff of two-sided
  divergence. Resolved via a single merge commit (10 conflicts resolved
  by hand — see commit 2022e74's message for the per-file reasoning).
  Two findings from that merge worth remembering: (a) the crouch
  mechanic + `Proprioception.feed()` call had been silently LOST from
  `third_person_controller.gd` on one side of the divergence — the
  Recall Walk was dead code until re-integrated; (b) several docs
  (`ADDONS.md`, `ASSET_SHOPPING_LIST.md`, `install_addons.sh`) existed
  in two contradictory versions — the versions matching actual disk
  state won.
- **Boot-order audit (2026-07-15) found and fixed three real bugs** that
  no amount of per-file review would catch — check for these PATTERNS in
  new code:
  1. Duplicate `class_name AmbientNpc` in both `src/world/ambient_npc.gd`
     and `hdv_lore/src/world/ambient_npc.gd` — two global declarations of
     the same name break the whole project's parse. The hdv_lore original
     now has no class_name (loaded by path via its own .tscn). Rule: NEVER
     add a class_name that already exists anywhere under res://, including
     hdv_lore/.
  2. `WorldQuestBridge`/`FactionQuestBridge` were listed BEFORE
     `QuestManager` in [autoload] while calling `QuestManager.register_quest()`
     from `_ready()` — a later autoload is null at that moment. Fixed by
     reordering them after QuestManager. Rule: an autoload's _ready() may
     only touch autoloads listed ABOVE it; for anything else use
     `call_deferred` (runs after all autoloads are up).
  3. `GameManager._ready()` connected to `AccountManager`/`DistrictManager`
     signals through `if AccountManager:` guards — both are later
     autoloads, so the guards evaluated null→false and the connections
     silently never happened (auth/district events went unheard). Fixed
     with `_connect_manager_signals.call_deferred()`.
- **CI (`godot-ci.yml`) only triggers on push to `main` or an open PR** —
  it does NOT run on every push to a feature branch. PR #28 is the open
  PR keeping CI live for this branch. Check `Actions → godot-ci` and
  match run SHAs against `git log` before assuming a branch's current
  head has been validated. `godot-ci` runs a real headless Web export
  (`godot --headless --export-release Web`) — a failure there is a real
  parse/import failure. It also runs gdUnit4 tests IF `godot/test/*.gd`
  files exist; as of this snapshot that directory is empty, so that step
  just no-ops green. `boot_smoke.gd` (`src/dev/boot_smoke.gd`) is NOT
  wired into CI at all — manual/local only (`godot --headless --path
  godot -s res://src/dev/boot_smoke.gd`).
- **CI hang root-caused and fixed (2026-07-15).** Every CI run since
  Terrain3D landed (2026-07-12) hung on the "Web export" step for
  exactly 6 hours until GitHub's default timeout killed it — zero
  successful validations of anything in that window. Cause (from run
  29177454189's logs): `[editor_plugins]` had `terrain_3d` enabled; its
  GDExtension fails to load inside the godot-ci container, the enabled
  editor plugin then hits parse errors, and the editor pops MODAL error
  dialogs — in headless mode nothing can dismiss them, so `--import`
  waits forever. Fixes: terrain_3d plugin disabled in project.godot
  (runtime is unaffected — TerrainBridge probes for the classes and
  falls back to ProceduralTerrain; the plugin is editor-UI only, enable
  it locally for sculpting sessions and never commit it enabled), and
  `timeout-minutes` caps on both CI jobs so any future hang fails in 30
  minutes with fetchable logs instead of silently eating 6 hours. RULE:
  never commit an enabled editor plugin whose load can fail headless —
  a failing plugin doesn't error out in CI, it hangs it.
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
- **Audio:** Kenney Casino / Interface / UI SFX are in `assets/audio/`
  (see `assets/audio/ATTRIBUTION.md`). City ambience WAVs ship for
  `city_traffic`, `city_crowd`, `neon_hum`,
  `machine_hum`. Combat one-shots ship for `skill_*` + `boss_*`
  (SkillVFX / WorldEntity → `CombatSfx`; synth fallback if a slot is
  empty). Music lives under `assets/music/`.
- **Model slots:** core shopping-list slots are filled (cats, creatures,
  crystals, aircraft, ruins, furniture, city/vehicles, trees/rocks).
  See `assets/models/ATTRIBUTION.md`. Rebake humans/cats/crystals with
  `scripts/bake_visual_gaps.py`.
- **Human / PeriHuman mesh:** hair + fitted clothes + shoes on shipped
  PeriHuman slots; cat skins for Catsino mode; Quaternius creature pool.
  Players never need Unreal/MakeHuman.
- **Lighting / terrain realism:** HDRI IBL; PBR ground; multi-layer
  ridged heightfields with spawn-plaza flatten (Terrain3D + procedural).

## How to drop assets into slots (Ziva / any agent — follow verbatim)

**There is no special importer UI.** A “slot” is just an **exact filename**
in a known folder. `AssetLibrary` looks for that name; if the file exists,
the whole game upgrades with **zero code changes**. If it doesn’t, the
procedural fallback stays.

Full tables also live in `docs/SHIPPING.md` §3 and `docs/ASSET_PIPELINE.md`.
License rules (what is safe to commit): `docs/ASSET_SHOPPING_LIST.md`.

### Procedure (do this for every drop)

1. Work in the real project: open `godot/project.godot` from this repo
   (never the TPS demo).
2. Obtain a model as **`.glb`** (preferred) or `.gltf`. If the source is
   `.blend` / DAZ / MetaHuman / FBX, convert in **Blender → Export GLB**
   (embedded textures, apply transforms, ~real-world scale).
3. **Rename** the file to the exact slot name below (case-sensitive).
4. **Copy** it into the matching folder under `godot/assets/` (paths
   relative to the `godot/` project root = `res://assets/...`).
5. In Godot: **Project → Reload Current Project** (or re-open) so it
   reimports. Wait until the FileSystem dock shows the new file with no
   red errors.
6. Press **F5** and check the place that uses that slot (city for
   `city_tower`, casino for `card_shuffle`, player for `peri_human_player / metahuman_player`).
7. If the license allows public redistribution, commit the file + its
   `.import` sidecar and add one row to the folder’s `ATTRIBUTION.md`.
   If the license forbids redistributing source (RenderPeople, most
   TurboSquid/CGTrader free RF): put the download in
   `godot/assets/private/` (gitignored) and only commit a cleaned GLB
   when the license clearly allows it.

**Do NOT:** edit `AssetLibrary` to “register” the file; invent new slot
names without wiring callers; overwrite a filled slot without backing it
up; commit non-redistributable marketplace ZIPs.

### Model slots → `godot/assets/models/<slot>.glb`

| Slot filename | What it upgrades |
|---|---|
| `peri_human_player / metahuman_player.glb` | Local player (preferred photoreal) |
| `metahuman_npc.glb` | NPCs / peers |
| `metahuman_<race_id>.glb` | Optional per-race body |
| `player_human.glb` / `npc_human.glb` | Interim humanoid (robot stand-in today) |
| `player_cat.glb` / `npc_cat.glb` | Catsino animal skins |
| `creature.glb` | Wild / PVXC creatures |
| `tree.glb` / `rock.glb` / `crystal.glb` | Nature / liminal props |
| `ruin_pillar.glb` / `extraction_gate.glb` / `harvest_node.glb` | Layer props |
| `apartment_prop.glb` | Hideout furniture |
| `city_tower.glb` / `city_lowrise.glb` / `city_house.glb` / `city_industrial.glb` | City buildings |
| `road_segment.glb` / `sidewalk.glb` / `streetlight.glb` / `city_prop.glb` / `neon_sign.glb` | City kit |
| `vehicle_car_body.glb` / `vehicle_boat_body.glb` / `vehicle_aircraft_body.glb` / `vehicle_spacecraft_body.glb` | Vehicles |

**Variants (optional):** put extra GLBs in
`godot/assets/models/variants/<slot>/` and list filenames in
`godot/data/asset_variants.json`. Same slot name, multiple looks.

### Texture slots → `godot/assets/textures/`

Name maps: `<slot>_albedo.png` (or `.jpg`) plus optional `_normal`,
`_rough`, `_metallic`, `_emissive`. City slots: `facade_brick`,
`facade_concrete`, `facade_metal`, `facade_glass`, `asphalt`, `sidewalk`,
`neon`.

### Sound slots → `godot/assets/audio/<slot>.ogg` (`.wav` / `.mp3` also OK)

| Slot | Use |
|---|---|
| `ui_click` / `ui_confirm` / `ui_back` / `ui_error` / `ui_hover` / `ui_switch` | UI |
| `card_shuffle` / `card_place` / `chip_place` / `chips_collide` / `dice_throw` | Casino |
| `door_slide` | City doors |
| `city_traffic` / `city_crowd` / `neon_hum` / `machine_hum` | City ambience loops |
| `skill_cast` / `skill_hit` / `skill_ult` / `skill_shield` | Combat cast / impact / ult / shield (SkillVFX → CombatSfx) |
| `boss_spawn` / `boss_phase` / `boss_death` | World/zone boss phase juice (WorldEntity) |

### Brand / splash → `godot/assets/ui/`

| File | Effect |
|---|---|
| `logo.png` | Title emblem + splash art |
| `boot_splash.png` | Godot boot splash (also set in `project.godot`) |
| `icon.png` | App / window icon |

### Sky HDRI → `godot/assets/environments/`

e.g. `kloppenheim_06_1k.hdr` (Poly Haven CC0). Procedural `DayNightSky`
remains the default mood; HDRI is available for look-dev upgrades.

### Quick verify (agent checklist)

```text
[ ] File path is exactly res://assets/.../<slot>.<ext>
[ ] Godot imported it (sidecar .import exists, no import error)
[ ] F5: the feature that uses the slot shows the new art/sound
[ ] ATTRIBUTION.md updated if committing
[ ] Nothing from assets/private/ was committed
```

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
