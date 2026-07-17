# Owner trials — kicked off (agent scaffolding + your DCC / GPU / secrets)

You said start them. Cloud agents **cannot** run CC4, Unreal MetaHuman
Creator, DAZ, or Terrain3D hand-sculpt (needs your licenses + local GPU),
and **must not** invent production Nakama secrets. This doc is the runbook
for what already shipped in-repo plus the clicks only you can do.

## Status

| Trial | Agent kickoff (shipped) | Your remaining action |
|---|---|---|
| CC4 / MetaHuman / DAZ cinema faces | Slot verify + `install_cinema_face_drop.sh` | Export GLB → install into slots |
| Terrain3D hero sculpt | Authored heightfields + TerrainWorld loader | Optional: open plugin, hand-sculpt, overwrite PNGs |
| Production Nakama | `server_config.production.example.json` | Fill real host/key into gitignored `server_config.json` |
| gdUnit4 editor plugin | `enable_gdunit4_local.sh` / `disable_…` | Enable locally; never commit enabled |
| Suno `ascension` / `sanctuary` beds | Dedicated MP3s (remixed masters, not aliases) | Optional: replace with new Suno cuts |

## 1) Cinema faces (CC4 / MetaHuman / DAZ)

Slots (overwrite both name families — resolver checks either):

- `godot/assets/models/peri_human_player.glb` + `metahuman_player.glb`
- `godot/assets/models/peri_human_npc.glb` + `metahuman_npc.glb`

```bash
# After you export two GLBs from your DCC tool:
bash scripts/verify_cinema_slots.sh          # baseline
bash scripts/install_cinema_face_drop.sh ~/Exports/player.glb ~/Exports/npc.glb
bash scripts/verify_cinema_slots.sh
```

Export tips:

- **CC4** — FBX/GLB export, Y-up, apply scale; prefer combined mesh or
  Skin/Face/Body/Hair surface names for look-dev shaders.
- **MetaHuman** → Blender → GLB (see `docs/VISUAL_DIRECTION_ESO.md`).
- **DAZ** — Interactive License if you redistribute; otherwise keep private.

Players never install the tool — only the GLBs ship.

## 2) Terrain3D hero regions

```bash
python3 scripts/bake_hero_heightfields.py
```

Writes `godot/assets/terrain/hero/<seed>.png`. `TerrainWorld` loads these
when present (desktop Terrain3D path).

Local sculpt session:

1. Open Godot desktop → Project Settings → Plugins → enable **Terrain3D**
   (do not commit `enabled=`).
2. Load a hero map / sculpt creeks & plazas.
3. Export / overwrite the matching PNG under `assets/terrain/hero/`.
4. Disable the plugin before commit (CI hangs if Terrain3D plugin is on).

## 3) Production Nakama

```bash
cp godot/server_config.production.example.json godot/server_config.json
# edit host / port / server_key — file is gitignored
docker compose -f docker-compose.dev.yml up -d   # local proof
bash scripts/build_nakama_modules.sh
# then headless: godot --headless --path godot -s res://src/dev/gate8_smoke.gd
```

Full public stack already uses `docker-compose.yml` + `.env` `NAKAMA_SERVER_KEY`.

## 4) gdUnit4 (local only)

```bash
bash scripts/enable_gdunit4_local.sh
# … run tests in editor …
bash scripts/disable_gdunit4_local.sh   # BEFORE commit
```

## 5) Music beds

Shipped dedicated files (no longer aliases):

- `godot/assets/music/ascension.mp3` — trial-arena tension bed
- `godot/assets/music/sanctuary.mp3` — hub-interior safety bed

Replace anytime with fresh Suno masters; keep the filenames.

## Related

- `docs/PINNED_LEFT.md` — living checklist
- `docs/VISUAL_DIRECTION_ESO.md` — PeriHuman / Terrain3D bar
- `docs/METAHUMAN_NPC_PIPELINE.md` — NPC scale notes (aspirational)
