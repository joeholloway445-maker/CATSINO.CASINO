# Asset & addon shopping list — Periliminal.Space

Curated for THIS project's constraints. `docs/SHIPPING.md` §3 already maps
the CC0 **3D model** packs (Kenney / Quaternius / KayKit) to every
`AssetLibrary` slot — start there for visuals. This doc covers everything
else: editor addons, audio, shaders, and tooling.

## The three rules before adding anything

1. **Web export is the target** (`builds/html5`). Godot 4.3 GDExtension
   support on Web is experimental and most GDExtension addons don't ship
   web binaries. **Prefer pure-GDScript addons**; anything GDExtension
   must prove a working web build before it's allowed in.
2. **License MIT / CC0 only** (or unambiguous royalty-free for audio).
   Canon UGC ownership (docs/UGC_POLICY.md) means no viral licenses.
3. **Extend, don't duplicate** (AGENTS.md law). We already have inventory,
   quests, dialogue-from-JSON, terrain, day/night sky, touch controls,
   economy. An addon that parallels an existing system is a reference to
   read, not a dependency to add.

## Editor addons — high value, GDScript-pure (web-safe)

| Addon | Where | Why for us |
|---|---|---|
| **Dialogue Manager** (Nathan Hoad) | Asset Library / github `nathanhoad/godot_dialogue_manager` | Writer-friendly `.dialogue` files, balloons, conditions. Feed it INTO `npc_dialogue_ui` (WordOfMouth greetings stay ours) rather than replacing it. Biggest content-velocity win for build-order step 7. |
| **Phantom Camera** | `ramokz/phantom-camera` | Declarative camera hosts/tweens. Blessing-door reveals, venture-wizard beats, arena intros, quest cinematics — without hand-rolled camera code. |
| **Beehave** | `bitbrain/beehave` | Behavior trees in GDScript. Exactly what the KNOLL bot tiers (STATIC/REACTIVE/ADAPTIVE) and `WorldEntity`/zone-boss AI want as they grow past if-chains. |
| **Maaack's Menus Template** | `Maaack/Godot-Menus-Template` | Settings/audio/video/input-remap/credits scenes, wired. Saves a week of UI plumbing; skin with `aaa_theme.gd`. |
| **Virtual Joystick** | `MarcoFazioRandom/Virtual-Joystick-Godot` | Polished, configurable stick to upgrade the bare ColorRect stick in `touch_controls.gd` (keep our static-state contract). |
| **Panku Console** | `Ark2000/PankuConsole` | In-game runtime console + expression eval. Testing layer pulls, economy grants, quest triggers in the running game. Dev builds only — strip from release. |
| **gdUnit4** | `MikeSchulze/gdUnit4` | GDScript unit tests. Protect the invariants that keep breaking silently: currency math, quest triggers, Periliminal difficulty(), seeded determinism. |

## GDExtension — powerful but web-gated (verify before adopting)

| Addon | Why tempting | Caveat |
|---|---|---|
| **LimboAI** | BT + hierarchical state machines, editor debugger | GDExtension; confirm web template or skip — Beehave covers 80% |
| **Terrain3D** | Real terrain editing/LOD | Our `ProceduralTerrain` already streams infinite seeded chunks — only revisit if terrain becomes the bottleneck |
| **Godot Jolt** | Faster physics | Default physics is fine at our scale; no web story |
| **DebugDraw3D** | Runtime debug geometry | Dev-only; never ship in the web build |

## Shaders (free, renderer-agnostic, huge mood-per-hour)

**godotshaders.com** — filter by Godot 4, most are MIT/CC0. Shaders are
plain GLSL-in-Godot and run fine on `gl_compatibility`:

- **CRT / VHS / analog-glitch** post shaders → Periliminal dread; layer
  under `reality_bend.gdshader`'s overlay at high bend values.
- **Dither / posterize** → the Liminal's "something is wrong with this
  place" grade, dirt cheap on mobile GPUs.
- **Stylized water, fake volumetric fog cards, scrolling neon** →
  Hyperliminal casino floor and Neon Alley without Forward+ features
  (keeps the `RenderCaps.is_compatibility()` rule honest).

## Audio (beyond the Suno music plan)

| Source | License | Slot it into |
|---|---|---|
| **Kenney audio packs** (UI, impacts, casino, interface) | CC0 | `assets/audio/` sound slots — chips, cards, buttons, slots reels |
| **Sonniss GDC Game Audio bundles** (annual, ~30GB free) | Royalty-free | city_traffic, city_crowd, neon_hum, machine_hum beds |
| **freesound.org** (CC0 filter ON) | CC0 (filtered) | one-shots: footsteps, doors, creature vocals |

Remember `AssetLibrary.sound()` auto-loops ogg/wav — ambience beds just
need the right filename.

## 2D / UI

- **Kenney Input Prompts** (CC0) — keyboard/gamepad/touch glyphs for every
  platform; needed the moment mobile + desktop share tutorials.
- **Kenney Playing Cards + Boardgame packs** (CC0) — cards, chips, dice
  art for blackjack/poker/paw-poker upgrades.
- **Kenney Particle Pack** (CC0) — sprites for skill VFX blueprints.

## Tooling / CI (repos, not runtime deps)

- **`abarichello/godot-ci`** (Docker) or **`chickensoft-games/setup-godot`**
  (GitHub Action) — headless export automation so `builds/html5` (build
  order step 4) comes out of CI, not a hand-run editor.
- **heroiclabs/nakama-godot** (official client) — read-only reference to
  reconcile the low-confidence endpoints flagged in
  `addons/nakama-godot-4/README`.
- **`godotengine/godot-demo-projects`** — the TPS/platformer demos our
  controller derives from; useful when tuning feel.
- **GLoot** (`peter-kish/gloot`) — inventory framework. Reference only:
  `InventoryManager` exists; steal ideas, not the addon.

## Suggested adoption order

1. Kenney/Quaternius/KayKit model drop per SHIPPING.md §3 (zero code).
2. Kenney + Sonniss audio into the existing sound slots (zero code).
3. Maaack's menus + Virtual Joystick (bounded UI work, big polish).
4. Dialogue Manager for step-7 content velocity.
5. gdUnit4 + godot-ci once the project parses clean (protects step 1
   forever).
6. Beehave when bosses/dungeon AI land (build order step 6).
