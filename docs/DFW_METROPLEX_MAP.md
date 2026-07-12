# DFW Metroplex — map plan (Superliminal layer)

## City names (canon)

| In-game name | Real city | Faction |
|---|---|---|
| New Dallas | Dallas | Sovereign Crown |
| Hell's Half Acre | Fort Worth | Veiled Current |
| Sky Fjord | Denton | Wildlands Ascendant |
| Soulless Sanctuary | Arlington | Neutral (factionless start) |

"Hell's Half Acre" is the historical name of Fort Worth's 19th-century
red-light quarter — a real public-domain place name, reclaimed as canon.
Ids in code stay `dallas` / `fort_worth` / `denton` / `arlington`
(display names only changed), so saves and references are untouched.

## Inner metroplex vs. outskirts (the generation boundary)

- **Inside hub bounds**: OpenStreetMap-derived downtown clone
  (`godot/world_data/osm/<hub>.json` via `OsmCityLayout` +
  `MegaCityBuilder._build_osm_city`) — real street polylines and building
  footprints for each DFW core, uniformly rescaled to the hub footprint.
  LandmarkBuilder snaps skyline anchors to real OSM coordinates when
  known; CityVenues prefer real bank/market/etc. POIs. Differs per player
  only through texture/light/sound packs and the identity lens. If an OSM
  file is missing, falls back to the procedural `CityData.HUB_LAYOUT`
  district grid.
- **Outside hub bounds**: fully procedural (DiscoveryManager +
  ProceduralRegionGenerator), and PLAYER-COMPILED — every visitor's
  influence pack repaints the chunk's dominant texture tint over repeated
  visits (see `register_party_visit` / `dominant_pack`), so the wilds are
  literally composed of the races/mods of whoever walked them first and
  whoever keeps coming back. Light/sound personalization out there rides
  each client's own lens (frame sensorium + race material), on top of the
  shared influence paint.

## Civic set per city

Every city carries: Market(s), Bank(s), Armorer(s), Blacksmith(s),
Stockyards (combat training — melee, ranged, UNARMED, GUNS disciplines),
and a Wager Hall (storyline/DLC referendum, one vote per ballot per
server day — 4h — no hard cap). **Soulless Sanctuary alone** adds the
Arena, the College, and the Space Station. The Hyperliminal (Catsino)
carries the same civic set in cat form: Shop = market, Bank & Guild =
bank/services, Arena hub = arena games, Wager Hall button on the main
menu = the same referendum floor.


## The mega-city is now built, not just planned

`godot/src/world/city/` builds a **fully functional mega-city** for each
hub the first time the player enters it (`layer_world._ensure_city`):

- **`CityData`** — the blueprint: per-hub district floor plans (fallback
  when OSM data is absent), building profiles, block/road dimensions,
  light rig, and sound bed. Every hard-mesh part names the AssetLibrary
  model + texture + sound slot it depends on.
- **`OsmCityLayout`** — loads `world_data/osm/<hub>.json` (OpenStreetMap
  downtown clones: streets, buildings, POIs, landmark snaps).
- **`MegaCityBuilder`** — assembles a hub from OSM street polylines +
  building footprints when present, else the procedural road grid;
  streetlights, neon signage, plazas, props. Deterministic per hub.
- **`BuildingBuilder`** — one building, real asset or procedural shell,
  with emissive window bands (`build_osm` respects real footprint/floors).
- **`CityLighting`** — rides every window / streetlight / neon on the
  day/night curve (dark by day, lit at dusk).
- **`CityAmbience`** — per-district layered soundscape (real audio if
  installed, synthesized traffic/crowd/neon/machine beds otherwise).

Every surface routes through `AssetLibrary` (models + textures) and
`IdentityLens` (per-race tint), so the whole city upgrades to real art by
dropping asset packs in — no code change. See `docs/SHIPPING.md` for the
exact slot names.

The rest of this doc covers relative metroplex placement and how the
OSM import pipeline works (refresh, attribution, compression).

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

Hub **interiors** are no longer stylized grids: each loads a compressed
1:1 clone of its real downtown from OpenStreetMap (`world_data/osm/`).
Relative placement of the four hubs on the chunk grid stays directionally
correct (Fort Worth west, Dallas east, Denton north, Arlington between)
at compressed metro distances.

## Real-world reference (for scaling/orientation)

Approximate real distances between city centers, for calibrating relative
placement if the grid is ever rescaled:

- Dallas ↔ Fort Worth: ~31 miles
- Arlington sits almost exactly on the Dallas–Fort Worth midpoint, ~12
  miles from each
- Denton ↔ Fort Worth: ~40 miles N/NNW
- Denton ↔ Dallas: ~35 miles NNW

At the current `CHUNK_SIZE=64`, 1 chunk ≈ real-world scale is whatever
feels good for on-foot traversal — this project is not aiming for
1:1 real-world scale *between* hubs (that would make hub-to-hub travel
take real hours of play time). The existing bounds compress ~30-40 real
miles into a 20-30 chunk span. **Inside** each hub, streets and buildings
*are* a uniform-scale clone of the real downtown core (see OSM pipeline).

## OpenStreetMap downtown import (shipped)

Hub interiors come from **OpenStreetMap** via the Overpass API — free,
open (ODbL-licensed, attribution required), with real street grids, block
shapes, and points of interest for all four real cities.

Pipeline (already wired):

1. `scripts/fetch_osm_cities.py` queries Overpass for each hub's real-world
   bounding box (downtown Dallas / Sundance Square / Arlington stadium
   district / Denton courthouse square) — `way["highway"]` for streets,
   `way["building"]` for footprints, named POIs for landmark snaps.
2. Lat/lon → local XZ meters (equirectangular), then uniform rescale to a
   ~280 m `TARGET_SPAN` that fits inside each hub's chunk bounds.
3. JSON lands in `godot/world_data/osm/<hub>.json`. `OsmCityLayout` loads
   it; `MegaCityBuilder` extrudes street polylines and places buildings on
   real footprints (procedural shells via `BuildingBuilder.build_osm`,
   real assets when AssetLibrary has them).
4. Attribution: `godot/world_data/osm/ATTRIBUTION.md` + credits —
   `© OpenStreetMap contributors` (ODbL). Refresh anytime with
   `python3 scripts/fetch_osm_cities.py`.

Outside hub bounds stays procedural fantasy terrain, exactly as before.

## Open questions / next sharpening

- Landmark coverage: some silhouettes (Margaret Hunt Hill Bridge, Fort
  Worth Stockyards, Denton water tower, UTA campus) sit outside the
  current downtown bboxes — widen a hub bbox in the fetch script and
  re-run to snap them.
- Target hub footprint vs. real downtown size — `TARGET_SPAN` is the
  compression knob; raise it if hubs feel too small relative to the wilds.
