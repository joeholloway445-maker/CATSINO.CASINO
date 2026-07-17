# v0.1 Goal: AAA Game of the Year

**Decision (locked):** Periliminal.Space **v0.1 ships as an AAA GOTY contender** — not a thin vertical slice, not a “honest demo.” Every build order step, PR, and content pass is judged against that bar.

Canonical execution order remains `godot/AGENTS.md` **Build order**. This doc is the goal contract and critical path; older checklists (`AAA_GAME_BLUEPRINT.md`, `LAUNCH_CHECKLIST_AND_ROADMAP.md`) are reference inventories — they do **not** redefine v0.1 down to MVP.

## What “AAA GOTY v0.1” means here

A player can:

1. Boot to a branded title without script errors.
2. Create an identity (race / frame / mod) and enter the **Liminal**.
3. Complete the **layer spine**: Liminal → Supraliminal city → HiddenDoor → Periliminal pull → blessing exit.
4. Feel combat, economy, Hope, and identity as one game — not disconnected prototypes.
5. Play the **hero modes** end-to-end (PVXC, arena lobby modes, hideout contest) with juice, audio, and readable UI.
6. Export Web (`builds/html5`) and run the same spine in browser.
7. Meet performance/feel targets in `docs/AAA_GAME_BLUEPRINT.md` § Performance where they apply to Godot Web + desktop.

Deferred only when they conflict with the spine: real Nakama scale, voice acting, 50+ raids, 1000+ cosmetics. Those are **post-v0.1 seasons**, not excuses to ship a hollow v0.1.

## Critical path (gates)

| # | Gate | Status |
|---|---|---|
| 1 | Zero SCRIPT ERROR / failed autoload | Done (PR #22) |
| 2 | Boot path: splash → login/guest → title → New Venture → Liminal; Continue → Subliminal | Done (Play Offline + boot_smoke PASS) |
| 3 | Layer round-trip (spine) | Prototype path + `layer_spine_smoke` PASS (Play Prototype Spine) |
| 3b | **ESO visual bar** — PeriHumans + Terrain3D desktop + Forward+ + HDRI | MPFB2 PeriHumans + hero heightfields; cinema CC4/MetaHuman/DAZ = owner drop (`OWNER_TRIALS.md`) |
| 4 | Web export preset + CI green | Preset + `scripts/export_web.sh` verified locally; CI artifact on PR |
| 5 | Combat/economy/hideout/casino/StoryVote in-engine pass | **Done** — chips floor, juice, quest HUD, hideout VFX, combat SFX, boss phase telegraphs |
| 6 | Game modes: 2v2 → zone bosses → world bosses → dungeons → PvP campaigns | **Done** — arena HotbarUI + skill casts; thicken online with Gate 8 |
| 7 | Content + art/audio packs via AssetLibrary | **Done** — OSM shells (no Draco), ambience, dialogue, music beds, combat/boss SFX slots |
| 8 | Real multiplayer beyond presence bots | Client + docker-compose + layer presence + hideout online + world-boss cadence + live CI `gate8_smoke`; **prod host/secrets owner-only** |

## Doc map

| Doc | Role under GOTY v0.1 |
|---|---|
| `godot/AGENTS.md` | Operating procedure + build order (law) |
| `docs/SHIPPING.md` | Plug/play checklist; asset drop |
| `docs/AAA_GAME_BLUEPRINT.md` | Feature inventory & competitive targets |
| `docs/LAUNCH_CHECKLIST_AND_ROADMAP.md` | Expansion roadmap (do not shrink v0.1 to MVP) |
| `docs/IMPLEMENTATION_STATUS.md` | System wiring status |
| **This file** | Goal lock + gate table |

## Agent rule

When choosing work: prefer the **lowest unfinished gate** above. Do not start cosmetics, new parallel systems, or roadmap fluff while a lower gate is red.
