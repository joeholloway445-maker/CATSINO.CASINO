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

Deliberately NOT textured:
- `facade_glass` — glass reads through reflection + the emissive window
  bands `BuildingBuilder` already builds; an albedo texture would fight
  both. Leave procedural.
- Terrain chunks — `ProceduralTerrain._chunk_material()` doesn't route
  through `AssetLibrary.material()` slots; texturing terrain properly is
  a Terrain3D texture-asset job (see `docs/VISUAL_DIRECTION_ESO.md`), not
  a drop-in file.
- No HDRI — `DayNightSky` is procedural **by design** (its header says
  so: catsino-flavored palette, not a realistic horizon). Don't add one
  without a design decision.

More slots can be filled the same way with zero code changes — every
`AssetLibrary.material("<slot>", ...)` call site checks
`assets/textures/<slot>_albedo.*` first. Poly Haven's API
(`api.polyhaven.com/assets?t=textures`) is public, no login, all CC0.
