extends Node
## Mirrors lib/game/data/races.ts in THE-HDV-CORE (Next.js) repo.
## Source of truth for stats/lore is the TS file; this is the Godot-side
## render/runtime copy. Keep the two in sync by hand until a shared JSON
## export pipeline exists (see scripts/export_game_data.ts, not yet built).

static var RACES: Array[Dictionary] = [
	{
		"id": "lumenari", "name": "Lumenari", "faction": "veiled_current",
		"texture_type": "radiant", "primary_color": Color.html("#ffd24a"),
		"roughness": 0.25, "metalness": 0.5, "transparent": false,
		"passive_name": "Radiant Pulse", "passive_effect": "Small AoE burst at max Focus",
		"drawback": "Focus -15% in darkness",
		"stat_bonus": {"resonance": 2, "frequency": 1},
	},
	{
		"id": "gutterkin", "name": "Gutterkin", "faction": "sovereign_crown",
		"texture_type": "mutated", "primary_color": Color.html("#7fbf3f"),
		"roughness": 0.85, "metalness": 0.05, "transparent": false,
		"passive_name": "Hazard Conversion", "passive_effect": "Hazards restore Focus",
		"drawback": "Vitality Regen -10% in clean zones",
		"stat_bonus": {"power": 2, "agility": 1},
	},
	{
		"id": "deepborne", "name": "Deepborne", "faction": "wildlands_ascendants",
		"texture_type": "abyssal", "primary_color": Color.html("#1f4d6b"),
		"roughness": 0.3, "metalness": 0.6, "transparent": false,
		"passive_name": "Pressure Pulse", "passive_effect": "Knockback when struck",
		"drawback": "Momentum -10% on surface",
		"stat_bonus": {"power": 2, "resonance": 1},
	},
	{
		"id": "ashen_choir", "name": "Ashen Choir", "faction": "veiled_current",
		"texture_type": "spectral", "primary_color": Color.html("#9b8fb5"),
		"roughness": 0.4, "metalness": 0.1, "transparent": true, "opacity": 0.78,
		"passive_name": "Sorrow Amplification", "passive_effect": "Ally damage boost",
		"drawback": "Incoming damage rises after ally death",
		"stat_bonus": {"resonance": 2, "frequency": 1},
	},
	{
		"id": "veilstriders", "name": "Veilstriders", "faction": "sovereign_crown",
		"texture_type": "phasic", "primary_color": Color.html("#6fd0c5"),
		"roughness": 0.35, "metalness": 0.2, "transparent": true, "opacity": 0.7,
		"passive_name": "Phase Skip", "passive_effect": "5% chance to ignore incoming hit",
		"drawback": "Minor random displacement under heavy damage",
		"stat_bonus": {"agility": 2, "frequency": 1},
	},
	{
		"id": "chronarchs", "name": "Chronarchs", "faction": "wildlands_ascendants",
		"texture_type": "temporal", "primary_color": Color.html("#c9a85c"),
		"roughness": 0.3, "metalness": 0.7, "transparent": false,
		"passive_name": "Micro-Rewind", "passive_effect": "Corrects small movement error",
		"drawback": "Ability spam slows movement",
		"stat_bonus": {"resonance": 2, "frequency": 1},
	},
	{
		"id": "nullborn", "name": "Nullborn", "faction": "veiled_current",
		"texture_type": "voidlike", "primary_color": Color.html("#3a3550"),
		"roughness": 0.6, "metalness": 0.3, "transparent": false,
		"passive_name": "Outcome Shift", "passive_effect": "Minor RNG skew",
		"drawback": "Influence reduced",
		"stat_bonus": {"power": 1, "agility": 1, "resonance": 1},
	},
	{
		"id": "thorned", "name": "Thorned", "faction": "sovereign_crown",
		"texture_type": "symbiotic", "primary_color": Color.html("#3f7d2e"),
		"roughness": 0.8, "metalness": 0.0, "transparent": false,
		"passive_name": "Regrowth Armor", "passive_effect": "Accelerated wound regeneration",
		"drawback": "Fire Resistance -20%",
		"stat_bonus": {"power": 2, "agility": 1},
	},
	{
		"id": "echoes", "name": "Echoes", "faction": "wildlands_ascendants",
		"texture_type": "digital", "primary_color": Color.html("#3fd6ff"),
		"roughness": 0.2, "metalness": 0.4, "transparent": false,
		"passive_name": "System Hack", "passive_effect": "Passively destabilizes nearby systems",
		"drawback": "EMP Vulnerability -15%",
		"stat_bonus": {"resonance": 2, "frequency": 1},
	},
	{
		"id": "hollowed", "name": "Hollowed", "faction": "veiled_current",
		"texture_type": "biotech", "primary_color": Color.html("#8a8f99"),
		"roughness": 0.45, "metalness": 0.55, "transparent": false,
		"passive_name": "Extra Item Slot", "passive_effect": "Carries one additional item",
		"drawback": "Maintenance Drain (minor upkeep)",
		"stat_bonus": {"power": 1, "resonance": 1, "frequency": 1},
	},
	{
		"id": "riftspawn", "name": "Riftspawn", "faction": "sovereign_crown",
		"texture_type": "dimensional", "primary_color": Color.html("#7b3fb5"),
		"roughness": 0.3, "metalness": 0.5, "transparent": false,
		"passive_name": "Minor Gravity Pull", "passive_effect": "Pulls nearby targets slightly",
		"drawback": "Spatial instability",
		"stat_bonus": {"agility": 2, "power": 1},
	},
	{
		"id": "mirekin", "name": "Mirekin", "faction": "wildlands_ascendants",
		"texture_type": "amphibious", "primary_color": Color.html("#4d5c33"),
		"roughness": 0.75, "metalness": 0.05, "transparent": false,
		"passive_name": "Hive Awareness", "passive_effect": "Senses nearby allies through terrain",
		"drawback": "Momentum -10%",
		"stat_bonus": {"power": 2, "resonance": 1},
	},
	{
		"id": "sunspun", "name": "Sunspun", "faction": "veiled_current",
		"texture_type": "solar", "primary_color": Color.html("#ffb627"),
		"roughness": 0.2, "metalness": 0.4, "transparent": false,
		"passive_name": "Radiant Burst", "passive_effect": "Burst damage at max Focus",
		"drawback": "Overheat risk",
		"stat_bonus": {"agility": 2, "resonance": 1},
	},
	{
		"id": "coldmarrow", "name": "Coldmarrow", "faction": "sovereign_crown",
		"texture_type": "crystalline", "primary_color": Color.html("#9fe3f0"),
		"roughness": 0.1, "metalness": 0.7, "transparent": false,
		"passive_name": "Freeze Aura", "passive_effect": "Slows nearby enemies",
		"drawback": "Momentum -15%",
		"stat_bonus": {"power": 2, "frequency": 1},
	},
	{
		"id": "pulseborn", "name": "Pulseborn", "faction": "wildlands_ascendants",
		"texture_type": "electric", "primary_color": Color.html("#f4f000"),
		"roughness": 0.25, "metalness": 0.3, "transparent": false,
		"passive_name": "Shock Dash", "passive_effect": "AoE detonation on dash",
		"drawback": "Nervous Overload (self-damage on overuse)",
		"stat_bonus": {"agility": 2, "frequency": 1},
	},
	{
		"id": "dreamflesh", "name": "Dreamflesh", "faction": "veiled_current",
		"texture_type": "morphic", "primary_color": Color.html("#d98fc9"),
		"roughness": 0.4, "metalness": 0.1, "transparent": false,
		"passive_name": "Minor Morph Shift", "passive_effect": "Subtle adaptive reshaping",
		"drawback": "Sleep cycle fluctuation",
		"stat_bonus": {"resonance": 1, "agility": 1, "frequency": 1},
	},
	{
		"id": "crownless", "name": "Crownless", "faction": "sovereign_crown",
		"texture_type": "regal", "primary_color": Color.html("#b08d3e"),
		"roughness": 0.4, "metalness": 0.6, "transparent": false,
		"passive_name": "Authority Override", "passive_effect": "Overrides nearby command structures",
		"drawback": "Faction hostility events",
		"stat_bonus": {"resonance": 2, "power": 1},
	},
	{
		"id": "rotweavers", "name": "Rotweavers", "faction": "wildlands_ascendants",
		"texture_type": "decayed", "primary_color": Color.html("#5c4a33"),
		"roughness": 0.9, "metalness": 0.0, "transparent": false,
		"passive_name": "Decay Conversion", "passive_effect": "Extra loot from decay/kills",
		"drawback": "Influence -10%",
		"stat_bonus": {"power": 1, "frequency": 2},
	},
	{
		"id": "glassborn", "name": "Glassborn", "faction": "veiled_current",
		"texture_type": "crystal", "primary_color": Color.html("#bfe8ff"),
		"roughness": 0.05, "metalness": 0.8, "transparent": true, "opacity": 0.9,
		"passive_name": "Mirror Shield", "passive_effect": "Reflects a portion of incoming damage",
		"drawback": "Shatter threshold vulnerability",
		"stat_bonus": {"power": 2, "resonance": 1},
	},
	{
		"id": "starfall", "name": "Starfall", "faction": "sovereign_crown",
		"texture_type": "celestial", "primary_color": Color.html("#5c6bff"),
		"roughness": 0.2, "metalness": 0.6, "transparent": false,
		"passive_name": "Impact Entry", "passive_effect": "Fall damage becomes AoE",
		"drawback": "Meteor Reveal Burst (reveals position)",
		"stat_bonus": {"power": 1, "agility": 2},
	},
]

static func by_id(id: String) -> Dictionary:
	for race in RACES:
		if race["id"] == id:
			return race
	return {}
