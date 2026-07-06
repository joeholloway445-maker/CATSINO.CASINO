class_name CityData
## The Mega-City blueprint. Declares every district of the DFW Metroplex
## hubs as data: block/road layout, the building profiles that fill each
## block, the light rig, and the sound bed — each hard-mesh part naming the
## AssetLibrary MODEL slot, TEXTURE slot, and (for districts) SOUND slots it
## depends on. MegaCityBuilder reads this and builds the whole city; drop
## real models into assets/models/, textures into assets/textures/, audio
## into assets/audio/ against these slot names and the city upgrades with
## zero code change (AssetLibrary handles the swap).
##
## Districts are keyed to real DFW hubs (see hub_region_data.gd). Each hub's
## faction sets the accent palette; the district TYPE sets the massing.

## Per-district block/street layout in world units.
const BLOCK_SIZE := 26.0     # one city block (building lot span)
const STREET_WIDTH := 10.0   # road gap between blocks
const CELL := BLOCK_SIZE + STREET_WIDTH

## Building profiles — massing archetypes. `model_slot` is the AssetLibrary
## model that replaces the procedural shell; `facade_tex`/`accent_tex` are
## texture slots; the rest drive the procedural fallback geometry.
const PROFILES := {
	"tower": {
		"model_slot": "city_tower", "facade_tex": "facade_glass",
		"min_floors": 14, "max_floors": 42, "floor_h": 3.4,
		"footprint": 0.72, "roof": "antenna", "window_glow": 0.9,
		"metallic": 0.65, "roughness": 0.18,
	},
	"lowrise": {
		"model_slot": "city_lowrise", "facade_tex": "facade_concrete",
		"min_floors": 3, "max_floors": 8, "floor_h": 3.6,
		"footprint": 0.85, "roof": "flat", "window_glow": 0.6,
		"metallic": 0.15, "roughness": 0.6,
	},
	"house": {
		"model_slot": "city_house", "facade_tex": "facade_brick",
		"min_floors": 1, "max_floors": 3, "floor_h": 3.2,
		"footprint": 0.6, "roof": "pitched", "window_glow": 0.5,
		"metallic": 0.05, "roughness": 0.8,
	},
	"industrial": {
		"model_slot": "city_industrial", "facade_tex": "facade_metal",
		"min_floors": 1, "max_floors": 2, "floor_h": 6.0,
		"footprint": 0.92, "roof": "sawtooth", "window_glow": 0.25,
		"metallic": 0.5, "roughness": 0.5,
	},
}

## District types: which profiles fill their blocks (weighted), block
## grid size, light rig, and the sound bed layers each district streams.
const DISTRICTS := {
	"downtown_core": {
		"grid": Vector2i(4, 4),
		"mix": {"tower": 0.7, "lowrise": 0.3},
		"streetlight_spacing": 1, "neon_density": 0.8,
		"ground_tex": "asphalt", "accent_energy": 2.4,
		"sounds": {"city_traffic": -10.0, "city_crowd": -14.0, "neon_hum": -20.0},
	},
	"market": {
		"grid": Vector2i(3, 4),
		"mix": {"lowrise": 0.8, "tower": 0.2},
		"streetlight_spacing": 1, "neon_density": 1.0,
		"ground_tex": "asphalt", "accent_energy": 2.0,
		"sounds": {"city_crowd": -8.0, "city_traffic": -16.0, "neon_hum": -18.0},
	},
	"residential": {
		"grid": Vector2i(4, 3),
		"mix": {"house": 0.85, "lowrise": 0.15},
		"streetlight_spacing": 2, "neon_density": 0.15,
		"ground_tex": "asphalt", "accent_energy": 1.2,
		"sounds": {"city_traffic": -20.0, "city_crowd": -22.0},
	},
	"industrial": {
		"grid": Vector2i(3, 3),
		"mix": {"industrial": 0.9, "lowrise": 0.1},
		"streetlight_spacing": 2, "neon_density": 0.2,
		"ground_tex": "asphalt", "accent_energy": 1.0,
		"sounds": {"machine_hum": -10.0, "city_traffic": -18.0},
	},
	"faction_core": {  # the ceremonial heart of a faction hub
		"grid": Vector2i(3, 3),
		"mix": {"tower": 0.5, "lowrise": 0.5},
		"streetlight_spacing": 1, "neon_density": 0.6,
		"ground_tex": "sidewalk", "accent_energy": 3.0,
		"sounds": {"city_crowd": -12.0, "neon_hum": -16.0},
	},
}

## Faction accent palettes (neon + trim). Keyed to the hub's faction; the
## race lens still recolors the base concrete/glass per player on top.
const FACTION_ACCENT := {
	"SovereignCrown":     Color(1.0, 0.82, 0.30),   # gold
	"VeiledCurrent":      Color(0.35, 0.62, 1.0),    # cyan-blue
	"WildlandsAscendant": Color(0.45, 0.95, 0.5),    # verdant green
	"neutral":            Color(0.9, 0.55, 1.0),     # arlington violet
}

## Which districts each hub is composed of, and their offset (in city cells)
## from the hub's origin. This is the literal mega-city floor plan.
const HUB_LAYOUT := {
	"dallas": {
		"faction": "SovereignCrown",
		"districts": [
			{"type": "faction_core", "cell": Vector2i(0, 0)},
			{"type": "downtown_core", "cell": Vector2i(4, 0)},
			{"type": "market", "cell": Vector2i(0, 4)},
			{"type": "downtown_core", "cell": Vector2i(4, 4)},
		],
	},
	"fort_worth": {
		"faction": "VeiledCurrent",
		"districts": [
			{"type": "faction_core", "cell": Vector2i(0, 0)},
			{"type": "market", "cell": Vector2i(3, 0)},
			{"type": "industrial", "cell": Vector2i(0, 3)},
			{"type": "residential", "cell": Vector2i(3, 3)},
		],
	},
	"denton": {
		"faction": "WildlandsAscendant",
		"districts": [
			{"type": "faction_core", "cell": Vector2i(0, 0)},
			{"type": "residential", "cell": Vector2i(3, 0)},
			{"type": "market", "cell": Vector2i(0, 3)},
			{"type": "residential", "cell": Vector2i(3, 3)},
		],
	},
	"arlington": {
		"faction": "neutral",
		"districts": [
			{"type": "downtown_core", "cell": Vector2i(0, 0)},
			{"type": "market", "cell": Vector2i(4, 0)},
			{"type": "market", "cell": Vector2i(0, 4)},
			{"type": "downtown_core", "cell": Vector2i(4, 4)},
		],
	},
}

static func district(type: String) -> Dictionary:
	return DISTRICTS.get(type, DISTRICTS["market"])

static func profile(name: String) -> Dictionary:
	return PROFILES.get(name, PROFILES["lowrise"])

static func accent_for(faction: String) -> Color:
	return FACTION_ACCENT.get(faction, FACTION_ACCENT["neutral"])

## Weighted pick of a building profile name from a district's mix, using a
## deterministic RNG so the same lot always builds the same tower.
static func pick_profile(mix: Dictionary, rng: RandomNumberGenerator) -> String:
	var roll := rng.randf()
	var acc := 0.0
	for name in mix:
		acc += mix[name]
		if roll <= acc:
			return name
	return mix.keys()[0]
