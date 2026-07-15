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
Blender → GLB drop slots + private vs commit-safe sources:
[`docs/ASSET_PIPELINE.md`](ASSET_PIPELINE.md).

---

## 1. Zero-code visual wins (CC0 model packs)

[`docs/SHIPPING.md`](SHIPPING.md) §3 already maps Kenney / Quaternius /
KayKit packs onto `AssetLibrary` slots under `godot/assets/models/`. Drop
files in — no code changes. Same pattern for city textures
(`godot/assets/textures/`) and city ambience loops
(`godot/assets/audio/`).

**Done (verified CC0, downloaded, wired):**
- Vehicle bodies (car/boat/spacecraft) + city structure slots — Kenney kits
- Variant pools (`data/asset_variants.json`)
- PBR textures — Poly Haven (`assets/textures/`)
- `tree.glb` — Kenney suburban `tree-large` copy
- Casino / UI SFX — Kenney Casino + Interface + UI Audio → `assets/audio/`
- Input glyphs — Kenney Input Prompts (Touch + Keyboard) → `assets/ui/input_prompts/`
- Mood shaders — CRT / VHS / dither overlays (wired in `RealityBendOverlay`)
- HDRI — Poly Haven `kloppenheim_06_1k.hdr` → `assets/environments/`

`vehicle_aircraft_body.glb` stays empty until a CC0 aircraft pack lands.

**Checked and rejected/deferred for realistic HUMANS** (the ESO-realism
bar needs photoreal proportions, not stylized/toon):

| Source | Verdict |
|---|---|
| Kenney (Blocky/Mini Characters) | CC0, but stylized/low-poly — fails the realism bar |
| Quaternius (Ultimate Modular Men, etc.) | CC0, but stylized — same issue |
| Poly Pizza / OpenGameArt "CC0 humanoids" | CC0, but low-poly/cartoonish across everything checked |
| **Blender Studio Human Base Meshes** | **CC0, genuinely photorealistic** — `.blend` only; export via Blender |
| **MakeHuman** (+ MPFB2 for Blender) | **CC0 exports**, desktop app pipeline |
| Mixamo | Free but Adobe login + redistribution gray area for public repos |
| Sketchfab (CC0-tagged realistic humans) | Login-gated; check license per model |
| RenderPeople free samples | Realistic, but license forbids redistribution of 3D data — private only |

**Net result:** until MetaHuman exports land (or Blender/MakeHuman), player
and generated NPCs share `player_human.glb`. Drop MetaHuman GLBs into the
documented slots — `MetahumanCharacter` picks them up automatically.

### Extended source list (owner-provided) — with license verdicts

The critical distinction for THIS repo: **"free to download" ≠ "safe to
commit."** Pushing an asset file to this GitHub repo *redistributes* it.
Many "free" licenses allow embedding in a shipped game build but forbid
redistributing the source files — those enter via
`godot/assets/private/` (gitignored) or a private CI step, never a commit.

| Source | Characters / creatures / NPCs | Vehicles / aircraft / spacecraft | Structures / envs | Verdict for this repo |
|---|---|---|---|---|
| **RenderPeople Free 3D People** | Photoreal scanned humans (posed/rigged/animated) | — | — | ❌ **Never commit.** T&C forbid transfer of 3D data. Private drop only. |
| **DAZ Studio + free Genesis** | Hyper-real customizable humans | — | Some env props | ⚠️ Desktop pipeline; Interactive License often required for games |
| **Sketchfab free filter** | Characters, creatures | Cars, aircraft, some craft | Buildings, interiors | ⚠️ Per-model; **CC0** = commit-safe; CC-BY needs attribution forever |
| **TurboSquid free** | People, props | Cars | Some structures | ❌ RF usually forbids source redistribution |
| **CGTrader free** | PBR humans, creatures | Vehicles | Architecture | ❌ Unless explicitly CC0 |
| **Poly Haven** | — | — | PBR textures + HDRIs | ✅ **CC0 — USED** |
| **Godot Asset Library** | Rigged characters (often stylized) | Some vehicles | Env packs | ✅ If MIT/CC0 labeled |
| **itch.io (Godot-tagged)** | Character packs | Vehicle packs | Structure packs | ✅ If MIT/CC0; often stylized |
| **Reallusion Character Creator 4** (30-day trial) | Photoreal morphs/clothing | — | Possible env integration | ⚠️ Trial export license unresolved; buy + verify before commit |
| **Meshy.ai / Tripo3D / Luma** | Custom chars/creatures | Vehicles / aircraft / spacecraft | Structures | ⚠️ Free-tier ownership varies; keep prompts in attribution |
| **Kenney / Quaternius** | Stylized only | Cars / boats / space | Full city kits | ✅ **CC0 — USED heavily** |
| **MetaHuman (UE → Blender → GLB)** | ESO-bar humans | — | — | Preferred photoreal path; see `VISUAL_DIRECTION_ESO.md` |

Practical priority: (1) MetaHuman exports; (2) Blender Studio / MakeHuman
CC0; (3) CC4 if purchased; (4) verified CC0 Sketchfab finds;
(5) AI gens for creatures/props/structures under clear ownership.
RenderPeople / TurboSquid / CGTrader free sections = mood boards +
`assets/private/` experiments only.

---

## 2. Web-safe addons (install into `godot/addons/`)

| Addon | Why | Status |
|---|---|---|
| **Dialogue Manager** (Nathan Hoad) | Writer-friendly `.dialogue` files | ✅ Installed (v3.3.3) |
| **Phantom Camera** | Blessing-door / arena / quest cameras | ✅ Installed |
| **Beehave** | GDScript BTs for KNOLL + bosses | ✅ Installed |
| **Maaack's Menus Template** | Settings / remap / credits | ✅ Installed |
| **Panku Console** | Dev console for layers / economy | ✅ Installed — **dev only** |
| **gdUnit4** + godot-ci | Tests + headless HTML5 export | ✅ Installed + CI |
| **Gloot** | Future inventory UI unifier | ✅ Vendored — **do not replace** live inventory yet |

**Mobile polish (image list):**
| Item | Decision |
|---|---|
| Virtual Joystick (MarcoFazioRandom) | **Do not replace** — `TouchControls` is the authority (floating left stick + big buttons) |
| Kenney Input Prompts | ✅ Installed under `assets/ui/input_prompts/` + `InputPrompts` helper |

---

## 3. Native-only (document, do not enable on Web)

| Addon | Why interesting | Web rule |
|---|---|---|
| **Terrain3D** | Heightmap terrain for hero areas | Keep `ProceduralTerrain` for web — **do not add as Web dependency** |
| **LimboAI** | BT + HSM (C++ GDExtension) | **Beehave** is the web path — **do not add** |

---

## 4. Shaders & audio

- **CRT / VHS / dither** — stubs + dither shader under `godot/assets/shaders/`;
  `RealityBendOverlay` fades them in as layer bend rises (Liminal → Periliminal).
- **Kenney casino / UI / interface** — ✅ dropped into `assets/audio/` slots.
- **Sonniss GDC** — manual drop when available; do not commit multi-GB archives.

---

## 5. Reference (not game content)

- **godotengine/tps-demo** — MIT code / CC-BY art. Do not vendor the
  ~934MB art pack. Borrow patterns into existing controllers.
- **World builder** —
  [`apps/catsino-casino/app/world-builder/`](../apps/catsino-casino/app/world-builder/)
  → `godot/world_data/` JSON.

---

## 6. Do not replace / do not duplicate

| Keep | Reason |
|---|---|
| `TouchControls` | Mobile-first static API already wired |
| `ProceduralTerrain` | Web-safe; Terrain3D is native-only |
| `inventory_manager` / `inventory_system` | Live inventory; GLoot is future UI only |
| `reality_bend.gdshader` | Core psych UX; CRT/VHS/dither augment it |
| `logo_emblem.gd` → `assets/ui/logo.png` | Brand key art |
