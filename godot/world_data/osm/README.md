# OpenStreetMap city layouts

Downtown street grids and building footprints for the four DFW hubs,
fetched from the public Overpass API and rescaled to fit each hub's
in-game footprint (~280 m span).

| Hub id | Real city | File |
|---|---|---|
| `dallas` | Dallas (Arts District / downtown) | `dallas.json` |
| `fort_worth` | Fort Worth (Sundance Square) | `fort_worth.json` |
| `arlington` | Arlington (entertainment district) | `arlington.json` |
| `denton` | Denton (courthouse square) | `denton.json` |

## Refresh

```bash
python3 scripts/fetch_osm_cities.py
# or one hub:
python3 scripts/fetch_osm_cities.py --hub dallas
```

`MegaCityBuilder` loads these automatically when present; if a file is
missing it falls back to the procedural `CityData.HUB_LAYOUT` grid.

## Attribution

© OpenStreetMap contributors. Data available under the
[Open Database License (ODbL)](https://www.openstreetmap.org/copyright).

See `ATTRIBUTION.md` in this folder.
