# Godot addon stack

Recommended community addons for Periliminal.Space. **Web export first:**
every installed addon below is pure GDScript (no GDExtension runtime in
the shipped client). GDExtension tools stay native-only — see
[`ASSET_SHOPPING_LIST.md`](ASSET_SHOPPING_LIST.md).

## One-shot install

From the repo root:

```bash
bash scripts/install_addons.sh              # all web-safe addons
bash scripts/install_addons.sh dialogue     # single addon key
```

Then in Godot: **Project → Project Settings → Plugins** → enable each
plugin you want → **Editor → Restart**. Do **not** enable plugins in
`project.godot` until a smoke open confirms zero parse errors.

Idempotent: re-running updates each addon to its pinned tag.

`scripts/repo_factory.sh --addons-only` calls the same installer.

## Pinned stack (Godot 4.3)

| Key | Addon folder | Upstream | Pin | Integration touch-file |
|---|---|---|---|---|
| `dialogue` | `godot/addons/dialogue_manager` | [nathanhoad/godot_dialogue_manager](https://github.com/nathanhoad/godot_dialogue_manager) | **v3.3.3** | `src/ui/npc_dialogue_ui.gd` — keep until `.dialogue` migration |
| `phantom` | `godot/addons/phantom_camera` | [ramokz/phantom-camera](https://github.com/ramokz/phantom-camera) | main | `src/world/overworld/third_person_controller.gd` |
| `beehave` | `godot/addons/beehave` | [bitbrain/beehave](https://github.com/bitbrain/beehave) | **v2.9.2** | `src/multiplayer/presence_manager.gd` (BT templates only) |
| `menus` | `godot/addons/maaacks_menus_template` | [Maaack/Godot-Menus-Template](https://github.com/Maaack/Godot-Menus-Template) | main | Cherry-pick settings/credits; keep `title_screen.gd` |
| `panku` | `godot/addons/panku_console` | [Ark2000/panku_console](https://github.com/Ark2000/panku_console) | main | Dev only — `OS.is_debug_build()` |
| `gdunit` | `godot/addons/gdUnit4` | [MikeSchulze/gdUnit4](https://github.com/MikeSchulze/gdUnit4) | **v4.3.4** | `godot/test/` + `.github/workflows/godot-ci.yml` |
| `gloot` | `godot/addons/gloot` | [peter-kish/gloot](https://github.com/peter-kish/gloot) | **v2.4.13** | Future unifier of `inventory_manager.gd` / `inventory_system.gd` |

### KNOLL → Beehave mapping (stub)

| PresenceManager tier | Intended BT shape |
|---|---|
| STATIC (60%) | Idle / wander leaf only |
| REACTIVE (30%) | Idle → detect → approach / flee |
| ADAPTIVE (10%) | Full tree with `Hope.combat_profile()` blackboard |

Do not replace Nakama presence broadcast paths.

### Panku (dev builds)

Enable only in editor/debug exports. Never include in the shipped Web
release. Useful commands to wire later: layer pull force, economy grant,
hideout dump.

## Native-only (do not install for Web)

| Addon | Repo | Fallback |
|---|---|---|
| Terrain3D | [TokisanGames/Terrain3D](https://github.com/TokisanGames/Terrain3D) | `ProceduralTerrain` |
| LimboAI | [limbonaut/limboai](https://github.com/limbonaut/limboai) | Beehave |

## Skip / assets-only

| Item | Decision |
|---|---|
| Virtual Joystick | Keep existing `TouchControls` |
| Kenney Input Prompts | Optional glyph pack — not an addon dependency |
| CRT/VHS/dither | Stubs in `godot/assets/shaders/`; augment `reality_bend` |
| Kenney / Sonniss audio | Manual drop into `godot/assets/audio/` |

## CI

[`.github/workflows/godot-ci.yml`](../.github/workflows/godot-ci.yml)
(via `barichello/godot-ci`) exports Web → `builds/html5/` and runs
gdUnit4 when `godot/addons/gdUnit4` + `godot/test/` exist.

## Licenses

Stack addons are MIT / CC0 / MPL-2.0 — keep each addon's `LICENSE` file
inside its folder untouched.
