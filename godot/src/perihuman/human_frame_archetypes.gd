class_name HumanFrameArchetypes
## PeriHuman build traits for the 20 sensorium frames (src/data/frame_mod_data.gd).
## A frame is worn architecture, not species — so it only ever nudges body
## proportions (light = lean/fast, heavy = bulky/armored) and, for a few
## thematically loud frames, a small marking/emissive accent. Consumed by
## HumanIdentity.build(); keyed by FrameModData frame id.

const FRAMES: Dictionary = {
	# ---- Light frames -------------------------------------------------------
	# Gossamer-thin, near-invisible in motion.
	"veil": {"genes": {"build": -0.15, "muscle": -0.08, "shoulder_width": -0.1}},
	# Wind-adapted, zero drag.
	"zephyr": {"genes": {"build": -0.12, "leg_length": 0.05, "arm_length": 0.03}},
	# Strike-optimized for rapid offense.
	"viper": {"genes": {"build": -0.05, "muscle": 0.05, "arm_length": 0.05}},
	# Ethereal construction, partially dematerializes on impact.
	"phantom": {"genes": {"build": -0.15, "muscle": -0.1},
		"skin_material": {"transparent": true, "opacity": 0.9}, "emissive_boost": 0.05},
	# Battle-red chassis, POW-forward but still light.
	"crimson": {"genes": {"muscle": 0.08}, "marking_color": "b3261a"},
	# Ice-tempered, stable at speed.
	"glacial": {"genes": {"build": -0.05, "chest_depth": 0.05}, "marking_color": "a6d9e6"},
	# Maximum velocity configuration — sacrifices everything for speed.
	"bolt": {"genes": {"build": -0.2, "muscle": -0.12, "leg_length": 0.08}},
	# Resonates with companion bond energy.
	"soul": {"genes": {"build": -0.08, "muscle": -0.05}, "marking_color": "e6d9a6", "emissive_boost": 0.08},
	# Ember-forged, runs hot.
	"cinder": {"genes": {"muscle": 0.05, "skin_redness": 0.1}, "emissive_boost": 0.1},
	# Quantum-stable, adaptable — kept intentionally balanced.
	"flux": {"genes": {"build": -0.05}},

	# ---- Heavy frames --------------------------------------------------------
	# Impenetrable fortress configuration.
	"bastion": {"genes": {"build": 0.25, "muscle": 0.2, "shoulder_width": 0.15, "chest_depth": 0.15}},
	# Earth-shaking strike frame.
	"tremor": {"genes": {"build": 0.2, "muscle": 0.25, "jaw_width": 0.05}},
	# Maximum endurance build.
	"behemoth": {"genes": {"build": 0.3, "muscle": 0.2, "chest_depth": 0.2}},
	# Defensive anchor with offensive capability, team-optimized.
	"bulwark": {"genes": {"build": 0.2, "muscle": 0.15, "shoulder_width": 0.1}},
	# Fire-core engine, burns everything it touches.
	"ignis": {"genes": {"build": 0.15, "muscle": 0.15, "skin_redness": 0.2}, "emissive_boost": 0.2},
	# Permafrost armor, cold resistance.
	"glaci": {"genes": {"build": 0.18, "muscle": 0.1, "skin_redness": -0.15}, "marking_color": "cceeff"},
	# Power-burst configuration — athletic-heavy, not just bulky.
	"surge": {"genes": {"build": 0.1, "muscle": 0.2}, "emissive_boost": 0.08},
	# Balanced heavy-assault build.
	"siege": {"genes": {"build": 0.2, "muscle": 0.18}},
	# Toxic warfare chassis, effective but slightly cursed.
	"blight": {"genes": {"build": 0.15, "muscle": 0.1, "skin_redness": -0.1, "freckles": 0.3}, "marking_color": "668c26"},
	# Bone-reinforced maximum defense, oldest heavy design in the archive.
	"ossian": {"genes": {"build": 0.3, "muscle": 0.15, "age": 0.15, "jaw_width": 0.1}},
}

static func get_archetype(frame_id: String) -> Dictionary:
	return FRAMES.get(frame_id, {})
