# Model & code attribution

| File | Source | License |
|---|---|---|
| `interim/tps_player.glb`, `player_human.glb`, `npc_human.glb` | [godotengine/tps-demo](https://github.com/godotengine/tps-demo) player model | **CC-BY 3.0** — assets Copyright (c) 2018 Juan Linietsky, Fernando Miguel Calabró (corrected: previously mislabeled MIT here; the demo's *code* is MIT, its *art assets* are CC-BY 3.0 per the demo's own LICENSE.md) |
| `city_prop.glb`, `ruin_pillar.glb` | godotengine/tps-demo level geometry | CC-BY 3.0, same as above |
| `rock.glb` | Terrain3D demo (Tokisan Games) | MIT |
| `godot/src/player/periliminal_player_controller.gd` | Movement/camera physics pattern adapted from godotengine/tps-demo's `player/player.gd` (single-player rewrite, gun-robot/multiplayer scaffolding removed, wired to our race/frame/mod/combat systems instead) | MIT (code) |

**Target:** replace humanoids with **your MetaHuman GLB exports** at:
- `metahuman_player.glb` (local player identity)
- `metahuman_npc.glb` (generic NPC)
- `metahuman_<race_id>.glb` optional per-race variants

See `docs/VISUAL_DIRECTION_ESO.md`.
