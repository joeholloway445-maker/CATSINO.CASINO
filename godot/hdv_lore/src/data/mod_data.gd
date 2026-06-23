extends Node
## Mirrors lib/game/data/physicalMods.ts in THE-HDV-CORE (Next.js) repo.
## Source of truth for stats/lore is the TS file; keep in sync by hand.

const MODS: Array[Dictionary] = [
	{
		"id": "heavy_siege", "name": "Heavy Siege",
		"visual_effect": "Reinforced plating across a slow, towering industrial silhouette",
		"stat_modifier": {"power": 2, "agility": -2},
		"bonus": "+Stability", "drawback": "-Momentum",
	},
	{
		"id": "swiftburner", "name": "Swiftburner",
		"visual_effect": "Elongated legs trailing kinetic energy at speed",
		"stat_modifier": {"agility": 2, "power": -1, "resonance": -1},
		"bonus": "+Acceleration", "drawback": "-Control",
	},
	{
		"id": "multi_limbed", "name": "Multi-Limbed",
		"visual_effect": "Extra functional limbs folded into a complex action-ready pose",
		"stat_modifier": {"power": 1, "frequency": 1, "resonance": -2},
		"bonus": "+Aux Action Slot", "drawback": "-Energy Stability",
	},
	{
		"id": "towering", "name": "Towering",
		"visual_effect": "Vertically exaggerated proportions with an intimidating presence",
		"stat_modifier": {"power": 2, "agility": -2},
		"bonus": "+Intimidation Radius", "drawback": "-Evasion",
	},
	{
		"id": "compact", "name": "Compact",
		"visual_effect": "Short, dense build held in a low crouched stance",
		"stat_modifier": {"agility": 2, "power": -2},
		"bonus": "+Evasion", "drawback": "-AoE Reach",
	},
	{
		"id": "elastic", "name": "Elastic",
		"visual_effect": "Stretching, elongated limbs caught mid exaggerated motion",
		"stat_modifier": {"agility": 1, "power": 1},
		"bonus": "+Melee Range", "drawback": "",
	},
	{
		"id": "floating_core", "name": "Floating Core",
		"visual_effect": "A suspended central core held aloft in a floating posture",
		"stat_modifier": {"resonance": 2, "power": -1, "agility": -1},
		"bonus": "+Vertical Mastery", "drawback": "-Traction",
	},
	{
		"id": "split_form", "name": "Split Form",
		"visual_effect": "A dual-body silhouette mirrored by an energy separation effect",
		"stat_modifier": {"agility": 1, "frequency": 1, "resonance": -2},
		"bonus": "+Decoy", "drawback": "-Focus Regen",
	},
	{
		"id": "inverted_spine", "name": "Inverted Spine",
		"visual_effect": "An inverted spine giving a back-heavy, off-kilter stance",
		"stat_modifier": {"power": 2, "agility": -2},
		"bonus": "+Backstab Damage", "drawback": "-Front Defense",
	},
	{
		"id": "modular", "name": "Modular",
		"visual_effect": "Interchangeable mechanical parts in a tool-equipped posture",
		"stat_modifier": {"frequency": 2, "power": -2},
		"bonus": "+Item Slot", "drawback": "-Vitality Regen",
	},
	{
		"id": "armored", "name": "Armored",
		"visual_effect": "Tank-like heavy plating across a battle-ready stance",
		"stat_modifier": {"power": 2, "agility": -2},
		"bonus": "+Mitigation", "drawback": "-Momentum",
	},
	{
		"id": "lithe", "name": "Lithe",
		"visual_effect": "A slim silhouette blurred by constant evasive motion",
		"stat_modifier": {"agility": 2, "power": -2},
		"bonus": "+Dodge Window", "drawback": "-Stability",
	},
	{
		"id": "tendril", "name": "Tendril",
		"visual_effect": "Organic tendrils extending outward from the frame",
		"stat_modifier": {"resonance": 2, "power": -2},
		"bonus": "+CC Duration", "drawback": "-Burst Damage",
	},
	{
		"id": "rooted", "name": "Rooted",
		"visual_effect": "Skeletal roots anchoring the lower body to the ground",
		"stat_modifier": {"power": 2, "agility": -2},
		"bonus": "+Control Strength", "drawback": "No Dash",
	},
	{
		"id": "hover_strider", "name": "Hover Strider",
		"visual_effect": "An aerodynamic frame held in a constant hovering pose",
		"stat_modifier": {"agility": 2, "frequency": -1, "power": -1},
		"bonus": "No Fall Damage", "drawback": "-Stamina Regen",
	},
	{
		"id": "centroid", "name": "Centroid",
		"visual_effect": "Perfectly symmetric, neutral proportions in a balanced stance",
		"stat_modifier": {"power": 1, "agility": 1, "resonance": 1, "frequency": 1},
		"bonus": "+5% All Stats", "drawback": "None",
	},
	{
		"id": "shardform", "name": "Shardform",
		"visual_effect": "Reflective angular shards protruding from the frame",
		"stat_modifier": {"resonance": 2, "power": -2},
		"bonus": "+Reflect", "drawback": "Shatter Risk",
	},
	{
		"id": "quadruped", "name": "Quadruped",
		"visual_effect": "A low, four-legged stance built for sprinting",
		"stat_modifier": {"agility": 2, "frequency": -2},
		"bonus": "+Sprint Speed", "drawback": "No Dual-Wield",
	},
	{
		"id": "serpentine", "name": "Serpentine",
		"visual_effect": "A long, coiled frame moving with snake-like flexibility",
		"stat_modifier": {"agility": 1, "resonance": 1, "power": -2},
		"bonus": "+Immobilize Resist", "drawback": "-Jump Height",
	},
	{
		"id": "colossus", "name": "Colossus",
		"visual_effect": "Gigantic towering proportions in a slow, imposing pose",
		"stat_modifier": {"power": 2, "agility": -2},
		"bonus": "+Control", "drawback": "-Momentum",
	},
]

static func by_id(id: String) -> Dictionary:
	for mod in MODS:
		if mod["id"] == id:
			return mod
	return {}
