class_name ArenaModes
## Every minigame mode hosted by Arlington's Arena hub. These are MODES of
## one hub, not separate reality layers — they share matchmaking, the arena
## economy, and spectators, and entering one is a lobby hop rather than a
## layer transition. (If one ever outgrows the arena — persistent worlds,
## its own economy — promote it to a layer then.)

const MODES: Array[Dictionary] = [
	{id="moba", name="Paws of the Ancients", desc="5v5 lane-push MOBA with entity companions as summons.", team_size=5, uses_entities=true},
	{id="conflict", name="Faction Conflict", desc="Large team battles — alliance vs alliance warm-ups for the Supraliminal war.", team_size=12, uses_entities=true},
	{id="survival", name="Last Cat Standing", desc="Shrinking-zone survival. Loot, hide, pounce.", team_size=1, uses_entities=false},
	{id="zombies", name="Feral Horde", desc="Co-op waves of feral entities. How long can four cats last?", team_size=4, uses_entities=true},
	{id="ctf", name="Yarn Rush", desc="Capture the yarn ball. Fast respawns, faster grudges.", team_size=6, uses_entities=false},
	{id="race_arena", name="Arena Circuit", desc="Stadium racing bracket — feeds the tournament system.", team_size=1, uses_entities=false},
]

static func by_id(mode_id: String) -> Dictionary:
	for m in MODES:
		if m.id == mode_id: return m
	return {}
