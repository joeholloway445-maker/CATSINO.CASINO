class_name OsmCityLayout
## Loads OpenStreetMap-derived downtown layouts written by
## `scripts/fetch_osm_cities.py` into `res://world_data/osm/<hub>.json`.
## MegaCityBuilder prefers these over the procedural HUB_LAYOUT grid so
## each major city is a scaled 1:1 clone of its real street/building plan.
##
## Data is © OpenStreetMap contributors (ODbL). See
## `docs/DFW_METROPLEX_MAP.md` and `godot/world_data/osm/ATTRIBUTION.md`.

const OSM_DIR := "res://world_data/osm/"

## hub_id -> parsed Dictionary (empty if missing/unreadable)
static var _cache: Dictionary = {}

static func has_layout(hub_id: String) -> bool:
	return not load_layout(hub_id).is_empty()

static func load_layout(hub_id: String) -> Dictionary:
	if _cache.has(hub_id):
		return _cache[hub_id]
	var path := OSM_DIR + hub_id + ".json"
	if not FileAccess.file_exists(path):
		_cache[hub_id] = {}
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_cache[hub_id] = {}
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_cache[hub_id] = {}
		return {}
	_cache[hub_id] = parsed
	return parsed

## World-local XZ size of the imported downtown (after rescale).
static func size_of(hub_id: String) -> Vector2:
	var d := load_layout(hub_id)
	if d.is_empty():
		return Vector2.ZERO
	var sz: Dictionary = d.get("size", {})
	return Vector2(float(sz.get("x", 0.0)), float(sz.get("z", 0.0)))

## Landmark id → Vector2(x, z) in city-local space, or Vector2.INF if unknown.
static func landmark_pos(hub_id: String, landmark_id: String) -> Vector2:
	var d := load_layout(hub_id)
	for lm in d.get("landmarks", []):
		if str(lm.get("id", "")) == landmark_id:
			return Vector2(float(lm.x), float(lm.z))
	return Vector2.INF

## Pick a civic venue spot from OSM POIs (bank/marketplace) or fall back to
## a seeded offset inside the city footprint.
static func venue_pos(hub_id: String, kind: String, index: int) -> Vector2:
	var d := load_layout(hub_id)
	if d.is_empty():
		return Vector2.INF
	var needle_map := {
		"bank": ["bank", "credit union"],
		"market": ["market", "supermarket", "grocery", "shop"],
		"armorer": ["police", "museum", "gallery"],
		"blacksmith": ["hardware", "industrial", "workshop"],
		"stockyards": ["park", "stadium", "sports"],
		"wager_hall": ["theatre", "theater", "hall", "civic"],
	}
	var needles: Array = needle_map.get(kind, [])
	var matches: Array = []
	for p in d.get("pois", []):
		var n := str(p.get("name", "")).to_lower()
		var k := str(p.get("kind", "")).to_lower()
		for needle in needles:
			if str(needle) in n or str(needle) in k:
				matches.append(Vector2(float(p.x), float(p.z)))
				break
	if index < matches.size():
		return matches[index]
	# Deterministic fallback: ring around city center.
	var sz := size_of(hub_id)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("venue_" + hub_id + "_" + kind)
	var cx := sz.x * 0.5
	var cz := sz.y * 0.5
	var ang := float(index) * 1.1 + rng.randf() * 0.4
	var rad := mini(sz.x, sz.y) * 0.22
	return Vector2(cx + cos(ang) * rad, cz + sin(ang) * rad)

## Street width in game units from the OSM width_class (0..3).
static func street_width(width_class: int) -> float:
	match width_class:
		3: return 14.0
		2: return 11.0
		0: return 6.0
		_: return 8.5

## Heuristic building profile from OSM footprint + floors/height.
static func profile_for(building: Dictionary) -> String:
	var floors := int(building.get("floors", 0))
	var height_m := float(building.get("height_m", 0.0))
	var sx := float(building.get("sx", 10.0))
	var sz := float(building.get("sz", 10.0))
	var area := sx * sz
	var btype := str(building.get("building", "yes")).to_lower()
	if btype in ["industrial", "warehouse", "manufacture", "hangar"]:
		return "industrial"
	if btype in ["house", "detached", "semidetached_house", "bungalow", "villa"]:
		return "house"
	if floors >= 8 or height_m >= 24.0:
		return "tower"
	if area > 900.0 and floors <= 3:
		return "industrial"
	if floors > 0 and floors <= 2 and area < 120.0:
		return "house"
	if btype in ["apartments", "residential"] and floors <= 3:
		return "lowrise"
	return "lowrise"

## Approximate floor count when OSM has neither floors nor height.
static func floors_for(building: Dictionary, profile_name: String) -> int:
	var floors := int(building.get("floors", 0))
	if floors > 0:
		return clampi(floors, 1, 72)
	var height_m := float(building.get("height_m", 0.0))
	if height_m > 0.0:
		return clampi(int(round(height_m / 3.4)), 1, 72)
	var p := CityData.profile(profile_name)
	# Deterministic mid-range so the same lot rebuilds identically.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("osm_floors_%s_%s" % [building.get("cx", 0), building.get("cz", 0)])
	return rng.randi_range(int(p.min_floors), int(p.max_floors))
