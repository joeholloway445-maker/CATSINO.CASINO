# Godot addon stack

The recommended community-addon set for Periliminal.Space. Every entry
is pure GDScript (no GDExtension), so the Web export target still works
— the ONE rule that matters more than any specific pick, per the
external Godot guide we're following.

## One-shot install

From the repo root:
```bash
bash scripts/install_addons.sh
```
Then in Godot: **Project → Project Settings → Plugins**, enable each
plugin, and **Editor → Restart**. Idempotent — re-running the script
updates each addon to its pinned tag.

## The stack (in priority order)

| Addon | Why we want it | Notes |
|---|---|---|
| **Dialogue Manager** (Nathan Hoad) | Writer-friendly `.dialogue` files replace `npc_dialogue_ui`'s current JSON blobs; biggest content-velocity win for step 7 of the build order. | Wrap `NPCDialogueUI` around Dialogue Manager's runtime so `WordOfMouth.greeting_line` still injects the word-of-mouth line. |
| **Phantom Camera** | Declarative camera moves — blessing-door reveals, arena intros, quest cinematics, boss phase transitions. | Instantiate a `PhantomCamera3D` at the target framing, tween priority; the main camera follows automatically. |
| **Beehave** | GDScript behavior trees for KNOLL bot tiers, zone bosses, world bosses, dungeon minibosses. | Slots in above `PresenceManager` for adaptive bots and above `WorldEntity` for boss AI. |
| **Maaack's Menus Template** | Settings / input-remap / credits / pause / options scenes — saves a week of UI plumbing. | Adopt for the `main_menu` route; keep `title_screen.gd` as the game-specific hero. |
| **Virtual Joystick** (MarcoFazioRandom) | Battle-tested mobile joystick — either replace `TouchControls`' hand-rolled stick with it or keep ours side-by-side and A/B. | If we adopt it, keep the static field surface (`TouchControls.move_vector`) so nothing downstream changes. |
| **Kenney Input Prompts** | Free glyph pack for controller/keyboard/touch button hints in tutorials and tooltips. | CC0 assets, tiny footprint. |
| **Panku Console** | In-game console to test layer pulls, economy grants, HideoutRegistry state — **dev/editor builds only**. | Autoload only when `OS.is_debug_build()`. NEVER include in the shipped Web export. |
| **gdUnit4** | Unit tests. Wired to CI (`.github/workflows/godot-ci.yml`). | Tests live under `godot/test/`; run locally via `bash godot/addons/gdUnit4/runtest.sh -a godot/test/`. |
| **godotshaders.com CRT/VHS/dither** | Renderer-agnostic shaders — perfect Periliminal/Liminal mood, cheap on mobile. | Drop `.gdshader` files under `godot/src/rendering/`; instantiate as materials over the `RealityBendOverlay`. |
| **Kenney audio packs + Sonniss GDC bundles** | Casino sounds, UI, footsteps, ambience. Drop straight into `godot/assets/audio/` slots that `AssetLibrary.sound()` already reads. | Both CC0; commit selectively so the repo doesn't balloon. |

## What NOT to add

The guide explicitly flags these because our existing systems already
cover them and duplicating would fight ourselves:

- **Terrain3D** — we have `ProceduralTerrain` sized to the layer stack.
- **GLoot** — we have `InventoryManager` + `BlueprintManager`.
- **LimboAI** — Beehave is enough for our AI shape; LimboAI overlaps.

Extend, don't duplicate.

## CI integration

`.github/workflows/godot-ci.yml` (via `barichello/godot-ci`) runs on
every push to `main` and every PR touching `godot/`:

1. **Web export** — headless `godot --export-release "Web"` → uploads
   `builds/html5/` as a build artifact. This is what the nginx `game`
   service expects to serve.
2. **gdUnit4 tests** — runs if the addon is installed and `godot/test/`
   exists; skipped otherwise so the workflow lands green before we've
   written the first test.

The workflow pins Godot **4.3.0**. When you upgrade the editor per
AGENTS.md's newest-stable rule, bump `GODOT_VERSION` at the top of the
workflow to match.

## Licenses

Every addon in this stack is MIT / CC0 / MPL2 — all safe to bundle in a
commercial build. Attribution: keep each addon's original `LICENSE`
file inside its `addons/<name>/` folder untouched (the install script
copies them wholesale).
