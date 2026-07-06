extends Node
## Hand-authored "always generated" hub regions inside the Supraliminal layer.
## Everything outside these bounds (in chunk-grid coordinates) is generated
## lazily by ProceduralRegionGenerator the first time a player enters it —
## see DiscoveryManager. Hubs are never regenerated or influence-painted by
## the discover mechanic; they're the fixed faction-hub anchors.

const CHUNK_SIZE: int = 64 # world units per chunk cell, used by DiscoveryManager

## DFW Metroplex layout: Arlington is the neutral PvE center (Marketplace,
## Arena, Workshop/University, Space Station districts inside it) and the
## starting hub for the factionless. Dallas, Fort Worth and Denton are the
## three faction hubs, roughly matching real geography on the chunk grid
## (Fort Worth west, Dallas east, Denton north, Arlington between).
## All hub interiors are PvE; every chunk outside hub bounds is PvP and
## claimable via TerritoryControl.
const HUBS: Array[Dictionary] = [
	{
		"id": "arlington", "name": "Soulless Sanctuary",
		"real_world": "Arlington",
		"faction": "neutral",
		"description": "The neutral heart of the Metroplex and the factionless starting city — sanctuary for everyone, home to no one. ONLY city with the Arena, the College, and the Space Station gate; also carries the full civic set (markets, banks, armorers, blacksmiths, stockyards, wager hall).",
		"scene_path": "res://scenes/worlds/hubs/arlington.tscn",
		"chunk_bounds": {"x": -2, "y": -3, "w": 6, "h": 6},
		"districts": ["marketplace", "arena", "university", "space_station"],
	},
	{
		"id": "dallas", "name": "New Dallas",
		"real_world": "Dallas",
		"faction": "SovereignCrown",
		"description": "SovereignCrown seat — the old skyline rebuilt taller, crowned in gold. The spires kept their bones; the city kept nothing else.",
		"scene_path": "res://scenes/worlds/hubs/dallas.tscn",
		"chunk_bounds": {"x": 8, "y": -4, "w": 8, "h": 8},
	},
	{
		"id": "fort_worth", "name": "Hell's Half Acre",
		"real_world": "Fort Worth",
		"faction": "VeiledCurrent",
		"description": "VeiledCurrent haunt — named for the old red-light quarter that never really closed. Stockyards, river channels, and deals made in the dark between them.",
		"scene_path": "res://scenes/worlds/hubs/fort_worth.tscn",
		"chunk_bounds": {"x": -12, "y": -4, "w": 8, "h": 8},
	},
	{
		"id": "denton", "name": "Sky Fjord",
		"real_world": "Denton",
		"faction": "WildlandsAscendant",
		"description": "WildlandsAscendant reach — the courthouse square drowned in green, the lowlands north of the Metroplex carved open to the sky.",
		"scene_path": "res://scenes/worlds/hubs/denton.tscn",
		"chunk_bounds": {"x": -4, "y": -14, "w": 8, "h": 8},
	},
]

static func by_id(id: String) -> Dictionary:
	for hub in HUBS:
		if hub["id"] == id:
			return hub
	return {}

## Returns the hub dictionary whose chunk_bounds contain coord, or {} if coord
## falls outside every hand-authored hub (i.e. it's lazily-generated territory).
static func hub_at_chunk(coord: Vector2i) -> Dictionary:
	for hub in HUBS:
		var b: Dictionary = hub["chunk_bounds"]
		if coord.x >= b["x"] and coord.x < b["x"] + b["w"] and coord.y >= b["y"] and coord.y < b["y"] + b["h"]:
			return hub
	return {}
