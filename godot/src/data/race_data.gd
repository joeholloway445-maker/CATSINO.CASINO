class_name RaceData
# Race track definitions and metadata

const TRACKS: Array[Dictionary] = [
	{
		id="neon_canal", name="Neon Canal Circuit", district="neon_alley",
		laps=3, distance=1200.0, description="The classic VeiledCurrent waterway race.",
		entry_fee=200, difficulty="beginner"
	},
	{
		id="paw_strip", name="Paws Vegas Strip", district="paw_vegas",
		laps=1, distance=2000.0, description="A straight-line drag race down the strip.",
		entry_fee=500, difficulty="intermediate"
	},
	{
		id="forest_path", name="Forest Wild Run", district="cat_forest",
		laps=2, distance=1800.0, description="Twisting paths through ancient trees.",
		entry_fee=400, difficulty="intermediate"
	},
	{
		id="coliseum_track", name="Coliseum Grand Prix", district="cat_coliseum",
		laps=5, distance=3000.0, description="The ultimate endurance race in the arena.",
		entry_fee=1000, difficulty="expert"
	},
	{
		id="galaxy_circuit", name="Arcade Galaxy Dash", district="arcade_galaxy",
		laps=1, distance=500.0, description="A short chaotic course through the floating arcade.",
		entry_fee=100, difficulty="beginner"
	},
]

## Player level required to enter each difficulty tier.
const UNLOCK_LEVELS = {"beginner": 1, "intermediate": 5, "expert": 12}

static func get_track(track_id: String) -> Dictionary:
	for t in TRACKS:
		if t.id == track_id: return t.duplicate()
	return {}

static func unlock_level(track: Dictionary) -> int:
	return UNLOCK_LEVELS.get(str(track.get("difficulty", "beginner")), 1)

static func is_unlocked(track: Dictionary, player_level: int) -> bool:
	return player_level >= unlock_level(track)
