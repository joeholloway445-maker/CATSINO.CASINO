# Texture attribution

All maps below are **CC0** from [Poly Haven](https://polyhaven.com)
(downloaded via their public API, 1k JPG tier — chosen deliberately small
for the Web export target). Renamed to the `AssetLibrary.material()` slot
convention: `<slot>_albedo.jpg`, `<slot>_normal.jpg` (OpenGL-convention
`nor_gl`, which is what Godot expects), `<slot>_rough.jpg`.

| Slot files | Poly Haven asset | Used by |
|---|---|---|
| `facade_brick_*` | [`brick_wall_001`](https://polyhaven.com/a/brick_wall_001) | residential building shells (`BuildingBuilder`, profile `facade_brick`) |
| `facade_concrete_*` | [`concrete_block_wall`](https://polyhaven.com/a/concrete_block_wall) | lowrise/commercial shells |
| `facade_metal_*` | [`factory_wall`](https://polyhaven.com/a/factory_wall) | industrial shells, rooftop HVAC/masts |
| `asphalt_*` | [`asphalt_02`](https://polyhaven.com/a/asphalt_02) | district ground plates + road strips (`ground_tex: "asphalt"`) |
| `sidewalk_*` | [`concrete_pavement`](https://polyhaven.com/a/concrete_pavement) | walkable-district ground (`ground_tex: "sidewalk"`) |
| `grass_*` | [`grass_path_3`](https://polyhaven.com/a/grass_path_3) | ProceduralTerrain plains/overgrowth + Terrain3D grass fallback |
| `dirt_*` | [`forest_ground_04`](https://polyhaven.com/a/forest_ground_04) | ProceduralTerrain ruins/ashland + Terrain3D dirt fallback |
| `sand_*` | [`coast_sand_01`](https://polyhaven.com/a/coast_sand_01) | ProceduralTerrain coastal seabed |

Terrain3D desktop also uses AmbientCG demo maps under
`assets/terrain/demo/textures/` (`ground037_*`, `rock023_*`) — see that
folder's `asset_licenses.txt` (CC0).

Deliberately NOT textured:
- `facade_glass` — glass reads through reflection + the emissive window
  bands `BuildingBuilder` already builds; an albedo texture would fight
  both. Leave procedural.

HDRI sky / IBL: `assets/environments/kloppenheim_06_1k.hdr` (Poly Haven
CC0) is wired into `DayNightSky` when present — see
`assets/environments/ATTRIBUTION.md`.

More slots can be filled the same way with zero code changes — every
`AssetLibrary.material("<slot>", ...)` call site checks
`assets/textures/<slot>_albedo.*` first. Poly Haven's API
(`api.polyhaven.com/assets?t=textures`) is public, no login, all CC0.
