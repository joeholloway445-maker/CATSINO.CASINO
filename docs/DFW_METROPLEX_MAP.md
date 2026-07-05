# DFW Metroplex — map plan (Superliminal layer)

## What exists today

`godot/src/data/hub_region_data.gd` hand-authors four fixed regions on the
chunk grid (`CHUNK_SIZE = 64` world units/chunk):

| Hub | Faction | Chunk bounds (x, y, w, h) | Real-world direction it represents |
|---|---|---|---|
| Arlington | Neutral (factionless start) | (-2, -3, 6, 6) | Between Dallas and Fort Worth |
| Dallas | Sovereign Crown | (8, -4, 8, 8) | East of Arlington |
| Fort Worth | Veiled Current | (-12, -4, 8, 8) | West of Arlington |
| Denton | Wildlands Ascendant | (-4, -14, 8, 8) | North of the metroplex |

Everything **outside** those four rectangles is lazily generated the first
time a player's chunk-stream touches it (`ProceduralRegionGenerator` via
`DiscoveryManager`) — biome, elevation, prop density, all seeded
deterministically per chunk coordinate. That boundary — hub rectangle vs.
everywhere else — **is** the procedural-generation start line, and it
already works today.

The current placement is **directionally correct** (Fort Worth west,
Dallas east, Denton north, Arlington between) but is a stylized
abstraction, not to real-world scale or real street layouts.

## Real-world reference (for scaling/orientation, not literal import)

Approximate real distances between city centers, for calibrating relative
placement if the grid is ever rescaled:

- Dallas ↔ Fort Worth: ~31 miles
- Arlington sits almost exactly on the Dallas–Fort Worth midpoint, ~12
  miles from each
- Denton ↔ Fort Worth: ~40 miles N/NNW
- Denton ↔ Dallas: ~35 miles NNW

At the current `CHUNK_SIZE=64`, 1 chunk ≈ real-world scale is whatever
feels good for on-foot traversal — this project is not aiming for
1:1 real-world scale (that would make hub-to-hub travel take real hours of
play time). The existing bounds compress ~30-40 real miles into a
20-30 chunk span, which is the right instinct: keep the *relative
directions and rough proportions* faithful, compress the *actual
distances* for playability.

## Where real open map data comes in

If/when the hub interiors get upgraded from procedural placeholder rooms
to actually-DFW-flavored layouts, the source should be **OpenStreetMap**
data via the Overpass API — it's free, open (ODbL-licensed, attribution
required, no per-request cost), and has real street grids, block shapes,
and points of interest for all four real cities. Recommended pipeline:

1. Query Overpass for each hub's real-world bounding box (e.g. downtown
   Fort Worth's Sundance Square area, downtown Dallas's Arts District,
   Arlington's entertainment district around the stadiums, Denton's
   courthouse square) — `way["highway"]` for streets,
   `way["building"]` for footprints.
2. Convert the returned lat/lon geometry to local XZ meters (equirectangular
   projection is accurate enough at this scale), then rescale to fit each
   hub's existing chunk-bound footprint.
3. Feed the street graph into `ProceduralTerrain`'s prop-scatter pass as a
   road/plot mask instead of pure noise, so hub streets read as an actual
   street grid while everything beyond the hub boundary stays procedural
   fantasy terrain, exactly as it does today.
4. Attribution: any shipped build using OSM-derived data needs a
   `© OpenStreetMap contributors` credit (in `docs/`, a credits screen, or
   both) per the ODbL.

This is real, incremental work for a future pass — it slots into the
existing hub/procedural boundary without changing that architecture.

## Open questions before building the pipeline

- Which landmarks matter for gameplay (faction hub centerpieces, PvP
  chokepoints, Liminal door placement density) vs. which are just flavor?
- Target hub footprint in chunks — the table above uses 6-8 chunk widths
  today; real downtown cores are much larger relative to the surrounding
  metro than that ratio implies, so some deliberate compression choice is
  needed either way.
