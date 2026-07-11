# Asset & addon shopping list

**Rule that beats every pick:** the ship target is **Godot Web export**
(`gl_compatibility`, Web preset with `variant/extensions_support=false`).
Prefer **pure-GDScript** addons. Most GDExtension addons do not ship web
binaries — treat those as **native-only** and keep GDScript fallbacks.

Install web-safe addons with:

```bash
bash scripts/install_addons.sh
```

Details, pins, and enable steps: [`docs/ADDONS.md`](ADDONS.md).

---

## 1. Zero-code visual wins (CC0 model packs)

[`docs/SHIPPING.md`](SHIPPING.md) §3 already maps Kenney / Quaternius /
KayKit packs onto `AssetLibrary` slots under `godot/assets/models/`. Drop
files in — no code changes. Same pattern for city textures
(`godot/assets/textures/`) and city ambience loops
(`godot/assets/audio/`).

---

## 2. Web-safe addons (install into `godot/addons/`)

| Addon | Why | Notes |
|---|---|---|
| **Dialogue Manager** (Nathan Hoad) | Writer-friendly `.dialogue` files — biggest content-velocity win for AGENTS.md build step 7 | Pin **v3.3.3** for Godot 4.3. Leave `npc_dialogue_ui.gd` as authority until migration; keep `WordOfMouth` injection |
| **Phantom Camera** | Declarative camera moves for blessing-door reveals, arena intros, quest cinematics | Wrap target: `third_person_controller.gd` |
| **Beehave** | GDScript behavior trees for KNOLL bot tiers and future zone/world bosses | Map STATIC / REACTIVE / ADAPTIVE → BT templates; do not rewrite `presence_manager.gd` networking |
| **Maaack's Menus Template** | Settings / input-remap / credits scenes | Cherry-pick; keep `title_screen.gd` as the game-specific hero |
| **Panku Console** | In-game console for layer pulls / economy — **dev builds only** | Gate with `OS.is_debug_build()`; never ship in Web release |
| **gdUnit4** | Automated tests + CI | Editor/CI only; tests under `godot/test/` |
| **Gloot** | Inventory UI / protosets — future unifier of dual inventory stacks | Pin **v2.4.x** for Godot 4.3; no migration this pass |

**Skip as a replacement:** Virtual Joystick (MarcoFazioRandom) —
[`touch_controls.gd`](../godot/src/ui/touch_controls.gd) already covers
mobile. Optional: **Kenney Input Prompts** as glyph assets only.

---

## 3. Native-only (document, do not enable on Web)

| Addon | Why interesting | Web rule |
|---|---|---|
| **Terrain3D** (`TokisanGames/Terrain3D`) | Heightmap terrain for hero areas | Keep [`procedural_terrain.gd`](../godot/src/world/overworld/procedural_terrain.gd) for web |
| **LimboAI** (`limbonaut/limboai`) | BT + HSM (C++ GDExtension) | **Beehave** is the web path for KNOLL / bosses |

---

## 4. Shaders & audio

- **CRT / VHS / dither** (godotshaders.com): renderer-agnostic
  `canvas_item` overlays. Stubs live under `godot/assets/shaders/`
  (`crt_overlay.gdshader`, `vhs_overlay.gdshader`). Do **not** replace
  [`reality_bend.gdshader`](../godot/assets/shaders/reality_bend.gdshader) —
  layer them via `RealityBendOverlay` or a sibling CanvasLayer.
- **Kenney audio packs** (casino / UI / footsteps) and **Sonniss GDC**
  bundles → drop into `godot/assets/audio/` slots that
  `AssetLibrary.sound()` already reads. Do not commit multi-GB archives.

---

## 5. Reference (not game content)

- **godotengine/tps-demo** — MIT code / CC-BY art. Do not vendor the
  ~934MB art pack. Borrow patterns (camera shake, enemy FSM) into
  existing controllers; see [`docs/ECOSYSTEM.md`](ECOSYSTEM.md).
- **World builder** — use
  [`apps/catsino-casino/app/world-builder/`](../apps/catsino-casino/app/world-builder/)
  → `godot/world_data/` JSON. Lingbot World is video diffusion for
  dream/preview clips, not level editing.

---

## 6. Do not replace

| Keep | Reason |
|---|---|
| `TouchControls` | Mobile-first static API already wired |
| `ProceduralTerrain` | Web-safe; Terrain3D is native-only |
| `reality_bend.gdshader` | Core psych UX; CRT/VHS augment it |
| `logo_emblem.gd` yield to `assets/ui/logo.png` | Drop key art when ready |
