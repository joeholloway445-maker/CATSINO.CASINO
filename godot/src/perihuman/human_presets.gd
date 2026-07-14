class_name HumanPresets
## The preset gallery — PeriHuman's counterpart to the MetaHuman Creator
## starting-face wall. Each entry is a hand-tuned HumanDNA dict spanning a
## wide range of phenotypes; the Character Studio blends any three of them
## into a new genome, exactly like Epic's blend workflow.
##
## Genes omitted from an entry sit at their HumanDNA defaults.

const PRESETS := [
	{
		"name": "Aiyana", "eye_color": "3d2817", "hair_color": "0d0a08", "hair_style": "long",
		"genes": {"height": 0.42, "build": 0.35, "hip_width": 0.58, "shoulder_width": 0.38,
			"head_width": 0.55, "cheekbone_height": 0.72, "cheekbone_width": 0.66,
			"eye_tilt": 0.62, "nose_width": 0.42, "nose_bridge": 0.35, "lip_fullness": 0.6,
			"jaw_width": 0.38, "chin_length": 0.42, "skin_melanin": 0.55, "skin_redness": 0.42,
			"brow_thickness": 0.55, "age": 0.22},
	},
	{
		"name": "Bjorn", "eye_color": "2a5470", "hair_color": "b8945c", "hair_style": "short",
		"genes": {"height": 0.85, "build": 0.68, "muscle": 0.75, "shoulder_width": 0.82,
			"chest_depth": 0.7, "neck_thickness": 0.72, "head_width": 0.6, "head_depth": 0.58,
			"brow_depth": 0.72, "jaw_width": 0.75, "chin_protrusion": 0.65, "chin_length": 0.6,
			"nose_length": 0.6, "nose_bridge": 0.68, "mouth_width": 0.55, "lip_fullness": 0.3,
			"skin_melanin": 0.12, "skin_redness": 0.5, "stubble": 0.7, "age": 0.4},
	},
	{
		"name": "Chidi", "eye_color": "241509", "hair_color": "0a0806", "hair_style": "buzz",
		"genes": {"height": 0.7, "build": 0.52, "muscle": 0.68, "shoulder_width": 0.68,
			"leg_length": 0.62, "head_depth": 0.55, "forehead_height": 0.58,
			"nose_width": 0.72, "nose_bridge": 0.35, "nose_length": 0.45, "lip_fullness": 0.75,
			"mouth_width": 0.6, "cheekbone_height": 0.62, "jaw_width": 0.58,
			"skin_melanin": 0.88, "skin_redness": 0.25, "brow_thickness": 0.6, "age": 0.3},
	},
	{
		"name": "Dara", "eye_color": "4a4f58", "hair_color": "1c1410", "hair_style": "bob",
		"genes": {"height": 0.5, "build": 0.42, "head_size": 0.48, "head_width": 0.46,
			"forehead_height": 0.6, "eye_size": 0.62, "eye_spacing": 0.55, "eye_tilt": 0.58,
			"nose_length": 0.38, "nose_width": 0.38, "nose_tip": 0.62, "lip_fullness": 0.55,
			"cheek_fullness": 0.55, "jaw_width": 0.42, "chin_length": 0.38,
			"skin_melanin": 0.42, "skin_redness": 0.35, "age": 0.18},
	},
	{
		"name": "Esteban", "eye_color": "3a2410", "hair_color": "14100c", "hair_style": "topknot",
		"genes": {"height": 0.62, "build": 0.55, "muscle": 0.6, "chest_depth": 0.58,
			"head_depth": 0.52, "brow_depth": 0.6, "brow_thickness": 0.72,
			"eye_depth": 0.62, "nose_length": 0.68, "nose_bridge": 0.72, "nose_width": 0.5,
			"mouth_width": 0.52, "lip_fullness": 0.42, "jaw_width": 0.6, "chin_protrusion": 0.55,
			"cheekbone_height": 0.58, "skin_melanin": 0.48, "skin_redness": 0.4,
			"stubble": 0.55, "age": 0.35},
	},
	{
		"name": "Freja", "eye_color": "6b8fa8", "hair_color": "d9c49a", "hair_style": "ponytail",
		"genes": {"height": 0.6, "build": 0.38, "muscle": 0.52, "shoulder_width": 0.48,
			"head_width": 0.44, "forehead_height": 0.55, "eye_size": 0.55, "eye_spacing": 0.48,
			"nose_length": 0.48, "nose_width": 0.35, "nose_bridge": 0.6, "nose_tip": 0.55,
			"cheekbone_height": 0.65, "cheek_fullness": 0.35, "lip_fullness": 0.48,
			"jaw_width": 0.44, "chin_length": 0.52, "skin_melanin": 0.06, "skin_redness": 0.45,
			"freckles": 0.55, "age": 0.25},
	},
	{
		"name": "Goro", "eye_color": "1f1710", "hair_color": "0b0a09", "hair_style": "none",
		"genes": {"height": 0.55, "build": 0.85, "muscle": 0.8, "shoulder_width": 0.75,
			"hip_width": 0.6, "chest_depth": 0.82, "neck_thickness": 0.85,
			"head_size": 0.58, "head_width": 0.65, "cheek_fullness": 0.7,
			"eye_size": 0.4, "eye_depth": 0.42, "nose_width": 0.6, "nose_length": 0.42,
			"mouth_width": 0.48, "jaw_width": 0.8, "chin_length": 0.35, "chin_protrusion": 0.4,
			"skin_melanin": 0.35, "skin_redness": 0.45, "brow_thickness": 0.65, "age": 0.5},
	},
	{
		"name": "Hana", "eye_color": "2b1c10", "hair_color": "100d0b", "hair_style": "long",
		"genes": {"height": 0.38, "build": 0.32, "shoulder_width": 0.36, "hip_width": 0.48,
			"head_width": 0.52, "head_depth": 0.46, "forehead_height": 0.52,
			"eye_size": 0.52, "eye_spacing": 0.58, "eye_tilt": 0.68, "eye_depth": 0.35,
			"nose_length": 0.35, "nose_width": 0.4, "nose_bridge": 0.32,
			"cheekbone_width": 0.6, "cheek_fullness": 0.5, "lip_fullness": 0.5,
			"jaw_width": 0.4, "chin_length": 0.4, "skin_melanin": 0.28, "skin_redness": 0.3,
			"brow_thickness": 0.45, "age": 0.15},
	},
	{
		"name": "Idris", "eye_color": "33230f", "hair_color": "1a1512", "hair_style": "short",
		"genes": {"height": 0.75, "build": 0.48, "muscle": 0.62, "arm_length": 0.6,
			"leg_length": 0.6, "head_depth": 0.6, "forehead_height": 0.55, "forehead_slope": 0.55,
			"brow_depth": 0.55, "eye_depth": 0.58, "nose_length": 0.58, "nose_width": 0.55,
			"nose_bridge": 0.55, "lip_fullness": 0.62, "mouth_width": 0.55,
			"cheekbone_height": 0.68, "jaw_width": 0.55, "chin_protrusion": 0.6,
			"skin_melanin": 0.72, "skin_redness": 0.3, "stubble": 0.45, "age": 0.38},
	},
	{
		"name": "June", "eye_color": "44614a", "hair_color": "6e3a14", "hair_style": "bob",
		"genes": {"height": 0.48, "build": 0.5, "hip_width": 0.62, "chest_depth": 0.52,
			"head_size": 0.5, "eye_size": 0.58, "eye_spacing": 0.45,
			"nose_length": 0.45, "nose_width": 0.48, "nose_tip": 0.68,
			"cheek_fullness": 0.68, "lip_fullness": 0.65, "mouth_width": 0.45,
			"jaw_width": 0.48, "chin_length": 0.35, "skin_melanin": 0.2, "skin_redness": 0.58,
			"freckles": 0.8, "age": 0.28},
	},
	{
		"name": "Kalinda", "eye_color": "26170b", "hair_color": "0e0b09", "hair_style": "topknot",
		"genes": {"height": 0.58, "build": 0.44, "muscle": 0.55, "shoulder_width": 0.52,
			"head_width": 0.5, "forehead_height": 0.62, "brow_height": 0.6,
			"eye_size": 0.6, "eye_tilt": 0.55, "nose_length": 0.52, "nose_width": 0.5,
			"nose_bridge": 0.62, "lip_fullness": 0.68, "mouth_width": 0.52,
			"cheekbone_height": 0.72, "cheekbone_width": 0.58, "jaw_width": 0.45,
			"chin_length": 0.55, "skin_melanin": 0.62, "skin_redness": 0.35,
			"brow_thickness": 0.62, "age": 0.3},
	},
	{
		"name": "Lars", "eye_color": "5a6a75", "hair_color": "8f8f92", "hair_style": "short",
		"genes": {"height": 0.68, "build": 0.4, "muscle": 0.35, "shoulder_width": 0.55,
			"head_depth": 0.55, "forehead_height": 0.68, "forehead_slope": 0.6,
			"brow_depth": 0.5, "eye_depth": 0.65, "eye_size": 0.42,
			"nose_length": 0.65, "nose_bridge": 0.75, "nose_width": 0.42, "nose_tip": 0.35,
			"cheek_fullness": 0.22, "cheekbone_height": 0.6, "lip_fullness": 0.28,
			"mouth_width": 0.48, "jaw_width": 0.5, "chin_length": 0.62, "chin_protrusion": 0.58,
			"skin_melanin": 0.1, "skin_redness": 0.38, "stubble": 0.3, "age": 0.78},
	},
]

static func count() -> int:
	return PRESETS.size()

static func names() -> PackedStringArray:
	var out := PackedStringArray()
	for p in PRESETS:
		out.append(p.name)
	return out

static func get_preset(index: int) -> HumanDNA:
	var entry: Dictionary = PRESETS[clampi(index, 0, PRESETS.size() - 1)]
	return HumanDNA.from_dict(entry)

static func by_name(preset_name: String) -> HumanDNA:
	for i in PRESETS.size():
		if PRESETS[i].name == preset_name:
			return get_preset(i)
	return HumanDNA.new()
