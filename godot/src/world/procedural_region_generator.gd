extends Node
## Deterministic, on-demand content generator for Supraliminal chunks outside
## the hand-authored hub bounds. Same coord always yields the same biome data,
## so revisiting an undiscovered-by-this-client chunk that another player
## already painted still produces consistent terrain underneath the paint.

const BASE_SEED: int = 0x48445643 # "HDVC"

static func generate(coord: Vector2i) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = _coord_seed(coord)

	var biomes := ["plains", "ruins", "crystal_field", "overgrowth", "ashland"]
	var biome: String = biomes[rng.randi() % biomes.size()]

	return {
		"biome": biome,
		"elevation": rng.randf_range(-2.0, 6.0),
		"prop_density": rng.randf_range(0.1, 0.8),
		"prop_seed": rng.randi(),
	}

static func _coord_seed(coord: Vector2i) -> int:
	## Cantor-style pairing so positive/negative coords don't collide.
	var x := coord.x
	var y := coord.y
	return BASE_SEED ^ (x * 374761393 + y * 668265263)
