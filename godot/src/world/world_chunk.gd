class_name WorldChunk
extends Resource
## One cell of the Supraliminal lazy-generation grid. Hub chunks are
## pre-authored and frozen (is_hub = true, never repainted). Wild chunks start
## ungenerated; DiscoveryManager fills them in the moment a player first
## steps into them, then lets PlayerInfluencePacks repaint dominant_pack over
## repeated visits.

var coord: Vector2i
var is_hub: bool = false
var hub_id: String = ""
var generated: bool = false
var biome: Dictionary = {} # filled by ProceduralRegionGenerator on first discovery

## player_id -> accumulated weight contributed by that player over time.
var influence_weights: Dictionary = {}
## The blended pack currently painted onto this chunk's environment.
var dominant_pack: PlayerInfluencePack = null

func total_influence_weight() -> float:
	var total := 0.0
	for w in influence_weights.values():
		total += w
	return total
