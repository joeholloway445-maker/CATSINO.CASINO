# OpenStreetMap attribution

This directory contains map data derived from OpenStreetMap.

© OpenStreetMap contributors

The data is available under the Open Database License (ODbL):
https://www.openstreetmap.org/copyright

Source: OpenStreetMap via the Overpass API
(https://overpass-api.de/ and mirrors), imported by
`scripts/fetch_osm_cities.py` (layout JSON) and
`scripts/bake_osm2world_cities.py` (3D shells via
[OSM2World](https://osm2world.org/), LGPL tooling; geometry remains ODbL).

Shipped visual shells: `godot/assets/models/osm2world_<hub>.glb`.

Any public build or redistributed binary that includes these files (or
geometry derived from them) must retain this attribution credit — in a
credits screen, documentation, or both.
