class_name HumanModArchetypes
## PeriHuman augment traits for the 20 legacy mods (src/data/frame_mod_data.gd).
## A mod is a small installed system, not a body or a build — so unlike
## races and frames it only ever nudges a gene or two and layers a subtle
## marking/emissive accent (an implant glow, a barrier tint, a scar).
## Consumed by HumanIdentity.build() last, so its accents sit on top of
## whatever the race/frame already established. Keyed by FrameModData mod id.

const MODS: Dictionary = {
	# Push all systems past rated limits.
	"overclock": {"genes": {"muscle": 0.05, "skin_redness": 0.08}, "emissive_boost": 0.08},
	# Energy barrier absorbs the first hits.
	"shield_matrix": {"marking_color": "6699e6", "emissive_boost": 0.05},
	# Reaction time enhancement — wide, alert eyes.
	"reflex_booster": {"genes": {"eye_size": 0.03, "eye_tilt": 0.05}},
	# Draws power from void energy — slightly dangerous.
	"void_capacitor": {"eye_color": "331a59", "marking_color": "4d2680", "emissive_boost": 0.06},
	# Tactical AI co-pilot, faint HUD marking at the temple.
	"combat_ai": {"marking_color": "66ccd9", "emissive_boost": 0.04},
	# Heat dissipation vents.
	"thermal_vent": {"genes": {"skin_redness": 0.05, "freckles": 0.15}, "marking_color": "994d26"},
	# Converts speed to strike force.
	"momentum_coil": {"genes": {"muscle": 0.06, "leg_length": 0.03}},
	# Partial optical camouflage.
	"stealth_cloak": {"skin_material": {"transparent": true, "opacity": 0.82}, "marking_color": "8099b3"},
	# Pure probability manipulation.
	"luck_amplifier": {"marking_color": "d9b833", "emissive_boost": 0.05},
	# Upgraded power generation system.
	"power_core_mk2": {"marking_color": "e6cc80", "emissive_boost": 0.12},
	# Self-repairing nanobots smooth over old scarring.
	"nano_repair": {"genes": {"freckles": -0.1}},
	# Resonates with faction energy (visual is neutral until faction-tinted).
	"faction_amplifier": {"marking_color": "b3b3bf", "emissive_boost": 0.03},
	# Deepens companion bond.
	"companion_link": {"marking_color": "cc8091", "emissive_boost": 0.03},
	# Maximum speed burst system.
	"turbo_injector": {"genes": {"build": -0.05, "muscle": -0.02, "leg_length": 0.04}},
	# Observes probability to find optimal paths.
	"quantum_lens": {"eye_color": "8099e6", "marking_color": "7f99e6", "emissive_boost": 0.04},
	# Self-adapts to damage type received — a plated, denser feel.
	"adaptive_armor": {"genes": {"build": 0.05}, "skin_material": {"roughness": 0.55, "metallic": 0.35}},
	# Three seconds of absolute maximum power output.
	"overdrive_pulse": {"genes": {"muscle": 0.08, "skin_redness": 0.1}, "emissive_boost": 0.1},
	# Full stealth system with ghost imaging.
	"ghost_protocol": {"skin_material": {"transparent": true, "opacity": 0.8}, "marking_color": "cceeff", "emissive_boost": 0.05},
	# All combat limiters removed — irreversible, extremely effective.
	"berserker_chip": {"genes": {"muscle": 0.15, "skin_redness": 0.2, "stubble": 0.2, "freckles": 0.2}, "marking_color": "80191a"},
	# Cut from the Harmony Stone — extremely rare, perfectly balanced.
	"harmony_crystal": {"marking_color": "e6d9b3", "emissive_boost": 0.15},
}

static func get_archetype(mod_id: String) -> Dictionary:
	return MODS.get(mod_id, {})
