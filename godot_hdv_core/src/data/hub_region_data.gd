extends Node
## Hand-authored "always generated" hub regions inside the Supraliminal layer.
## Everything outside these bounds (in chunk-grid coordinates) is generated
## lazily by ProceduralRegionGenerator the first time a player enters it —
## see DiscoveryManager. Hubs are never regenerated or influence-painted by
## the discover mechanic; they're the fixed faction-hub anchors.

const CHUNK_SIZE: int = 64 # world units per chunk cell, used by DiscoveryManager

const HUBS: Array[Dictionary] = [
	{
		"id": "dallas_fort_worth", "name": "Dallas-Fort Worth Replica",
		"faction": "sovereign_crown",
		"description": "Primary faction hub — dense downtown core ringed by sprawl. Anchors the southeast Supraliminal grid.",
		"scene_path": "res://scenes/worlds/hubs/dallas_fort_worth.tscn",
		"chunk_bounds": {"x": 0, "y": 0, "w": 12, "h": 12},
	},
	{
		"id": "denton", "name": "Denton Replica",
		"faction": "wildlands_ascendants",
		"description": "Secondary faction hub — college-town square and surrounding lowlands. Anchors the northwest Supraliminal grid.",
		"scene_path": "res://scenes/worlds/hubs/denton.tscn",
		"chunk_bounds": {"x": -10, "y": -10, "w": 8, "h": 8},
	},
	{
		"id": "arlington", "name": "Arlington Replica",
		"faction": "neutral",
		"description": "Third faction hub, sited between Dallas-Fort Worth and Denton. Houses the Arena, Marketplace, University, and the Station gate to gated/external worlds.",
		"scene_path": "res://scenes/worlds/hubs/arlington.tscn",
		"chunk_bounds": {"x": 0, "y": -10, "w": 8, "h": 8},
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
