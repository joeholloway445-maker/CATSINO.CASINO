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

**Done (verified CC0, downloaded, wired):** vehicle bodies (car/boat/
spacecraft) and city slots (tower/lowrise/house/industrial/road/sidewalk/
streetlight/prop) — all from Kenney's Car Kit, Watercraft Kit, Space Kit,
and the four City Kit packs. Full source list + exact file mapping in
[`godot/assets/models/ATTRIBUTION.md`](../godot/assets/models/ATTRIBUTION.md).
`vehicle_aircraft_body.glb` stays empty — no equivalent CC0 aircraft
pack was found (Kenney has teased one, unreleased as of this writing).

**Checked and rejected/deferred for realistic HUMANS** (the ESO-realism
bar needs photoreal proportions, not stylized/toon):

| Source | Verdict |
|---|---|
| Kenney (Blocky/Mini Characters) | CC0, but stylized/low-poly — fails the realism bar |
| Quaternius (Ultimate Modular Men, etc.) | CC0, but stylized — same issue |
| Poly Pizza / OpenGameArt "CC0 humanoids" | CC0, but low-poly/cartoonish across everything checked |
| **Blender Studio Human Base Meshes** | **CC0, genuinely photorealistic** (male/female + parts) — ships as `.blend` only, needs a Blender export-to-glTF step. No Blender available in this pass. Best lead for a future session with Blender: `blender.org/download/demo-files/#assets` |
| **MakeHuman** (+ MPFB2 for Blender) | **CC0 exports**, purpose-built parametric realistic humans with age/body/ethnicity sliders and native glTF export — but it's a desktop app you run, not a fetchable file. Recommended pipeline once someone has it installed |
| Mixamo | Free, semi-realistic, commonly used in shipped games, but requires Adobe login (no anonymous download) and its EULA restricts *standalone* redistribution (fine embedded in a shipped build, gray area for a forkable public repo). Project rule is CC0/MIT only — treat as an explicit opt-in exception, not a default |
| Sketchfab (CC0-tagged realistic humans exist) | Individual models are real and some are CC0, but downloads are login-gated per-model; licenses vary model-to-model and must be checked individually — not something to bulk-pull |
| RenderPeople free samples | Realistic, but license explicitly forbids redistribution/transfer of the 3D data — do not use |

**Net result:** until MetaHuman exports land (or someone runs the Blender/
MakeHuman pipeline above), the player and all 1,000+ generated NPCs share
one mesh (`player_human.glb`). This is a real gap, not a code gap —
`MetahumanCharacter`/`NpcBody` already pick up new files automatically.

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
