extends Node
## Mirrors lib/game/data/frames.ts in THE-HDV-CORE (Next.js) repo.
## Source of truth for stats/lore is the TS file; keep in sync by hand.

const FRAMES: Array[Dictionary] = [
	{
		"id": "skirmisher", "name": "Skirmisher", "role": "Duelist", "frame_type": "light",
		"stats": {"agility": 8, "power": 5, "resonance": 4, "frequency": 6},
		"mobility": "Sharp, weight-forward bursts with a small shield and blade always ready",
		"combat_style": "Duel combat, mobility burst",
		"exclusive_stat_name": "Precision", "exclusive_stat_effect": "Movement crit scaling",
	},
	{
		"id": "strider", "name": "Strider", "role": "Scout", "frame_type": "light",
		"stats": {"agility": 9, "power": 3, "resonance": 4, "frequency": 7},
		"mobility": "Forward-leaning sprint that compounds the longer it runs",
		"combat_style": "Speed scaling",
		"exclusive_stat_name": "Velocity", "exclusive_stat_effect": "Dash cooldown compresses with sustained motion",
	},
	{
		"id": "skybound", "name": "Skybound", "role": "Aerialist", "frame_type": "light",
		"stats": {"agility": 8, "power": 4, "resonance": 5, "frequency": 6},
		"mobility": "Wind-trailing vertical lift with jet-assisted hops",
		"combat_style": "Air dominance",
		"exclusive_stat_name": "Lift", "exclusive_stat_effect": "Jump cooldown reduces with airtime",
	},
	{
		"id": "flicker", "name": "Flicker", "role": "Blink Duelist", "frame_type": "light",
		"stats": {"agility": 9, "power": 4, "resonance": 6, "frequency": 5},
		"mobility": "Short-range blinks that leave fragmented afterimages",
		"combat_style": "Short-range teleport combat",
		"exclusive_stat_name": "Phase Charge", "exclusive_stat_effect": "Blink chain multiplier",
	},
	{
		"id": "marshal", "name": "Marshal", "role": "Tactician", "frame_type": "light",
		"stats": {"agility": 6, "power": 5, "resonance": 7, "frequency": 5},
		"mobility": "Measured, commanding stride backed by holographic displays",
		"combat_style": "Tactical AI leadership",
		"exclusive_stat_name": "Command", "exclusive_stat_effect": "NPC efficiency",
	},
	{
		"id": "bloom", "name": "Bloom", "role": "Adaptive Combatant", "frame_type": "light",
		"stats": {"agility": 7, "power": 4, "resonance": 6, "frequency": 6},
		"mobility": "Light-footed drift, leaving a trail of drifting spores",
		"combat_style": "Adaptive combat",
		"exclusive_stat_name": "Mutation Rate", "exclusive_stat_effect": "Resistance shifts",
	},
	{
		"id": "rewind", "name": "Rewind", "role": "Time Controller", "frame_type": "light",
		"stats": {"agility": 7, "power": 3, "resonance": 8, "frequency": 6},
		"mobility": "Soft glowing trails that bend slightly out of sync with motion",
		"combat_style": "Micro time control",
		"exclusive_stat_name": "Temporal Thread", "exclusive_stat_effect": "Undo window",
	},
	{
		"id": "conduit", "name": "Conduit", "role": "Energy Caster", "frame_type": "light",
		"stats": {"agility": 6, "power": 4, "resonance": 7, "frequency": 7},
		"mobility": "Dynamic casting pose with arcs flowing limb to limb",
		"combat_style": "Energy cycling",
		"exclusive_stat_name": "Flux", "exclusive_stat_effect": "Cooldown compression",
	},
	{
		"id": "shade", "name": "Shade", "role": "Assassin", "frame_type": "light",
		"stats": {"agility": 8, "power": 6, "resonance": 4, "frequency": 4},
		"mobility": "Low, crouched approach that vanishes into shadow",
		"combat_style": "Assassination",
		"exclusive_stat_name": "Obscurity", "exclusive_stat_effect": "Stealth-to-crit scaling",
	},
	{
		"id": "fabricator", "name": "Fabricator", "role": "Engineer", "frame_type": "light",
		"stats": {"agility": 6, "power": 4, "resonance": 5, "frequency": 8},
		"mobility": "Ready-to-build stance, tool limbs unfolding on approach",
		"combat_style": "Deployables & traps",
		"exclusive_stat_name": "Assembly", "exclusive_stat_effect": "Build speed multiplier",
	},
	{
		"id": "bastion", "name": "Bastion", "role": "Defender", "frame_type": "heavy",
		"stats": {"agility": 2, "power": 9, "resonance": 4, "frequency": 3},
		"mobility": "Plants and holds, near-immovable once set",
		"combat_style": "Area defense",
		"exclusive_stat_name": "Fortitude", "exclusive_stat_effect": "Damage reduction while stationary",
	},
	{
		"id": "juggernaut", "name": "Juggernaut", "role": "Bruiser", "frame_type": "heavy",
		"stats": {"agility": 3, "power": 9, "resonance": 3, "frequency": 3},
		"mobility": "Slow build into an unstoppable charge",
		"combat_style": "Charge devastation",
		"exclusive_stat_name": "Impact", "exclusive_stat_effect": "Momentum converts to AoE",
	},
	{
		"id": "gravemind", "name": "Gravemind", "role": "Controller", "frame_type": "heavy",
		"stats": {"agility": 2, "power": 7, "resonance": 6, "frequency": 3},
		"mobility": "Grounded yet imposing, orbiting magnetic orbs",
		"combat_style": "Pull, slam, anti-air",
		"exclusive_stat_name": "Gravity", "exclusive_stat_effect": "CC strength scaling",
	},
	{
		"id": "riftbreaker", "name": "Riftbreaker", "role": "Disruptor", "frame_type": "heavy",
		"stats": {"agility": 2, "power": 7, "resonance": 7, "frequency": 3},
		"mobility": "Imposing stance ringed by dimensional cracks",
		"combat_style": "Map distortion",
		"exclusive_stat_name": "Spatial Integrity", "exclusive_stat_effect": "Portal durability",
	},
	{
		"id": "sovereign", "name": "Sovereign", "role": "Territory Holder", "frame_type": "heavy",
		"stats": {"agility": 2, "power": 7, "resonance": 8, "frequency": 2},
		"mobility": "Commanding, near-seated stance that rarely advances",
		"combat_style": "Zone ownership",
		"exclusive_stat_name": "Dominion", "exclusive_stat_effect": "Territory yield",
	},
	{
		"id": "worldroot", "name": "Worldroot", "role": "Terraformer", "frame_type": "heavy",
		"stats": {"agility": 2, "power": 8, "resonance": 5, "frequency": 4},
		"mobility": "Grounded stance, roots spreading wider the longer it stands",
		"combat_style": "Environmental takeover",
		"exclusive_stat_name": "Spread", "exclusive_stat_effect": "Terrain conversion rate",
	},
	{
		"id": "epoch", "name": "Epoch", "role": "Time Warden", "frame_type": "heavy",
		"stats": {"agility": 2, "power": 6, "resonance": 9, "frequency": 3},
		"mobility": "Gravitational distortions ripple around every step",
		"combat_style": "Macro time control",
		"exclusive_stat_name": "Chrono Weight", "exclusive_stat_effect": "Time dilation",
	},
	{
		"id": "overlord", "name": "Overlord", "role": "Detonator", "frame_type": "heavy",
		"stats": {"agility": 1, "power": 9, "resonance": 6, "frequency": 2},
		"mobility": "Imposing and static, power core glowing brighter the longer it charges",
		"combat_style": "Energy detonation",
		"exclusive_stat_name": "Overheat", "exclusive_stat_effect": "Cataclysm multiplier",
	},
	{
		"id": "obscura", "name": "Obscura", "role": "Veilkeeper", "frame_type": "heavy",
		"stats": {"agility": 2, "power": 6, "resonance": 8, "frequency": 3},
		"mobility": "Static, cloak rippling with area concealment energy",
		"combat_style": "Mass stealth control",
		"exclusive_stat_name": "Veil Density", "exclusive_stat_effect": "Area concealment",
	},
	{
		"id": "architect", "name": "Architect", "role": "Fortifier", "frame_type": "heavy",
		"stats": {"agility": 1, "power": 8, "resonance": 4, "frequency": 6},
		"mobility": "Construction-ready stance, structural plating locking into place",
		"combat_style": "Fortress building",
		"exclusive_stat_name": "Infrastructure", "exclusive_stat_effect": "Structure durability",
	},
]

static func by_id(id: String) -> Dictionary:
	for frame in FRAMES:
		if frame["id"] == id:
			return frame
	return {}
