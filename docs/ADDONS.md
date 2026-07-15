# Godot addon stack

Recommended community addons for Periliminal.Space. **Web export first:**
every installed addon below is pure GDScript (no GDExtension runtime in
the shipped client). GDExtension tools stay native-only — see
[`ASSET_SHOPPING_LIST.md`](ASSET_SHOPPING_LIST.md) and
[`ASSET_PIPELINE.md`](ASSET_PIPELINE.md).

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
| `gloot` | `godot/addons/gloot` | [peter-kish/gloot](https://github.com/peter-kish/gloot) | **v2.4.13** | Future UI only — do **not** replace live inventory yet |

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

## Assets that pair with this stack (installed)

| Item | Location | Notes |
|---|---|---|
| Kenney Input Prompts | `assets/ui/input_prompts/` | Touch + Keyboard; `InputPrompts` helper |
| Kenney Casino / UI / Interface SFX | `assets/audio/` | `AssetLibrary.sound()` slots |
| CRT / VHS / dither shaders | `assets/shaders/` | Layered by `RealityBendOverlay` |
| Poly Haven HDRI | `assets/environments/` | Optional sky/env upgrade |
| Poly Haven PBR | `assets/textures/` | City facades / ground |

## Native-only (desktop AAA — Web keeps GDScript fallbacks)

| Addon | Repo | Fallback |
|---|---|---|
| **Terrain3D** (vendored `addons/terrain_3d`, Godot 4.3 build) | [TokisanGames/Terrain3D](https://github.com/TokisanGames/Terrain3D) | `ProceduralTerrain` via `TerrainBridge` |
| LimboAI | [limbonaut/limboai](https://github.com/limbonaut/limboai) | Beehave — **do not install** |

**Characters:** MetaHuman exports (UE Creator → GLB). Shaders from community
[MetaHumanGodot](https://github.com/ibrews/MetaHumanGodot) under
`assets/shaders/metahuman/`. See [`VISUAL_DIRECTION_ESO.md`](VISUAL_DIRECTION_ESO.md).

## Do not duplicate (already covered)

| Item | Why skip / how covered |
|---|---|
| **Terrain3D on Web** | Web uses `ProceduralTerrain`; Terrain3D is excluded from HTML5 export |
| **LimboAI** | Beehave is the GDScript BT path |
| **GLoot as live inventory** | Keep `inventory_manager` / `inventory_system`; GLoot is future UI only |
| **Virtual Joystick addon** | `TouchControls` already owns mobile move/look/actions |

## CI

[`.github/workflows/godot-ci.yml`](../.github/workflows/godot-ci.yml)
(via `barichello/godot-ci`) exports Web → `builds/html5/` and runs
gdUnit4 when `godot/addons/gdUnit4` + `godot/test/` exist.

Godot 4.3 headless often crashes on shutdown after a successful pack
(exit 132/139). The workflow treats `builds/html5/index.html` as success.
The Web export preset excludes `gdUnit4`, `panku_console`, `terrain_3d`,
and addon `examples/` / `test/` / `docs/` so editor-only tooling is not
shipped.

## Licenses

Stack addons are MIT / CC0 / MPL-2.0 — keep each addon's `LICENSE` file
inside its folder untouched.
