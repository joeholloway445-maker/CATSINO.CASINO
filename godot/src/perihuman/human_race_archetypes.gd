class_name HumanRaceArchetypes
## PeriHuman species traits for the 20 canon Periliminal races (see
## docs/LORE_FOUNDATION.md / src/data/race_lore.gd for the full blurbs).
## Each entry translates the race's lore into a HumanDNA-shaped human:
## body-proportion gene nudges, eye/hair color, a default hairstyle, and
## optional skin identity (skin_tint, marking_color, skin_material,
## emissive_boost) carrying over the race's signature material feel
## (crystalline, molten, void-dark, metallic, translucent, ...).
##
## Consumed by HumanIdentity.build(); keyed by the canon race name
## (CanonRaces.RACES / RaceLore keys), not the cat-breed gameplay id.

const RACES: Dictionary = {
	# Shadow-striders of the upper urban canyons — lean, watchful, unseen.
	"Keth": {
		"genes": {"build": -0.12, "muscle": -0.05, "leg_length": 0.08, "cheek_fullness": -0.1, "eye_size": -0.04},
		"eye_color": "0d0d10", "hair_color": "0a0a0a", "hair_style": "short",
		"skin_tint": "5c4f47",
	},
	# Crystal-blooded, bioluminescent, refracted light through fur-nodes.
	"Lumari": {
		"genes": {"cheekbone_height": 0.1, "skin_redness": -0.1},
		"eye_color": "99d9e6", "hair_color": "d9e6f0", "hair_style": "long",
		"skin_tint": "e0dcf0", "marking_color": "b3d999",
		"skin_material": {"roughness": 0.2, "metallic": 0.3, "emissive_strength": 0.9},
		"emissive_boost": 0.2,
	},
	# Phase-capable hunters, semi-material, pass through matter.
	"Vex": {
		"genes": {"build": -0.1, "muscle": -0.08, "eye_depth": -0.05},
		"eye_color": "bfccd9", "hair_color": "a6a6ad", "hair_style": "short",
		"skin_tint": "b8c2cc",
		"skin_material": {"roughness": 0.4, "metallic": 0.15, "transparent": true, "opacity": 0.88},
	},
	# Apex predators of the open wilds — a head taller, scarred, dominant.
	"Ferox": {
		"genes": {"height": 0.22, "build": 0.22, "muscle": 0.25, "shoulder_width": 0.2,
			"jaw_width": 0.15, "brow_depth": 0.15, "chin_protrusion": 0.1, "stubble": 0.3, "freckles": 0.5},
		"eye_color": "8c5920", "hair_color": "2e1c12", "hair_style": "buzz",
		"skin_tint": "9e7350", "marking_color": "ccb3a3",
	},
	# Psionic seers who perceive and nudge probability fields.
	"Azhul": {
		"genes": {"forehead_height": 0.15, "eye_size": 0.1, "eye_spacing": 0.05},
		"eye_color": "80508c", "hair_color": "241a2e", "hair_style": "topknot",
		"skin_tint": "9e94ad", "marking_color": "8c59b3",
		"skin_material": {"emissive_strength": 0.3}, "emissive_boost": 0.15,
	},
	# Forest-born biomancers entwined with living organic networks.
	"Sylva": {
		"genes": {"cheek_fullness": 0.1, "skin_redness": -0.05, "freckles": 0.4},
		"eye_color": "336633", "hair_color": "4d5926", "hair_style": "long",
		"skin_tint": "8c8059", "marking_color": "598c40",
		"skin_material": {"roughness": 0.85},
	},
	# Cybernetically augmented engineers, machine and organism blurred.
	"Geara": {
		"genes": {"build": 0.1, "jaw_width": 0.05, "ear_size": -0.05, "freckles": 0.5},
		"eye_color": "cc8019", "hair_color": "666666", "hair_style": "buzz",
		"skin_tint": "998f80", "marking_color": "e68c26",
		"skin_material": {"roughness": 0.35, "metallic": 0.6}, "emissive_boost": 0.25,
	},
	# Void-touched nocturnal hunters — eyes absorb light and emit none.
	"Nyx": {
		"genes": {"eye_size": 0.1, "brow_depth": 0.05, "cheek_fullness": -0.05},
		"eye_color": "05050a", "hair_color": "030303", "hair_style": "none",
		"skin_tint": "48465c", "marking_color": "261a33",
		"skin_material": {"roughness": 0.6, "metallic": 0.1},
	},
	# Hydromancers of the open ocean — silken, salt-tinged, adaptable.
	"Aquis": {
		"genes": {"skin_redness": -0.05},
		"eye_color": "40809e", "hair_color": "1a4047", "hair_style": "long",
		"skin_tint": "adc2c7", "marking_color": "338c8c",
		"skin_material": {"roughness": 0.3},
	},
	# Pyromancers born in volcanic calderas — run hot, glow when angry.
	"Igni": {
		"genes": {"skin_redness": 0.25, "stubble": 0.15, "freckles": 0.3},
		"eye_color": "d95909", "hair_color": "331a0d", "hair_style": "short",
		"skin_tint": "995940", "marking_color": "d9660d",
		"skin_material": {"roughness": 0.3, "metallic": 0.1, "emissive_strength": 0.6, "emissive_color": "e6590d"},
		"emissive_boost": 0.2,
	},
	# Cryomancers from a glacier-world — patient, methodical, ice-forged.
	"Kryos": {
		"genes": {"skin_redness": -0.2, "age": 0.1},
		"eye_color": "b3d9e6", "hair_color": "d9e6f0", "hair_style": "long",
		"skin_tint": "d1e0e6", "marking_color": "bfe6f2",
		"skin_material": {"roughness": 0.1, "metallic": 0.4},
	},
	# Fungal-symbiote races running a spore-based mycelial network.
	"Myco": {
		"genes": {"skin_redness": -0.1, "freckles": 0.5, "cheek_fullness": 0.05},
		"eye_color": "8c9980", "hair_color": "998059", "hair_style": "short",
		"skin_tint": "b8b3a3", "marking_color": "bfad80",
		"skin_material": {"roughness": 0.8},
	},
	# Bioelectric beings, conductive fur, interface electronics by touch.
	"Volt": {
		"genes": {"eye_size": 0.05, "freckles": 0.35},
		"eye_color": "99e6ff", "hair_color": "cce0f2", "hair_style": "short",
		"skin_tint": "ccd1e0", "marking_color": "80d9ff",
		"skin_material": {"roughness": 0.25, "metallic": 0.2, "emissive_strength": 0.5, "emissive_color": "99e6ff"},
		"emissive_boost": 0.15,
	},
	# Stone-forged beings, silicon-carbide skeletons, oldest race.
	"Petra": {
		"genes": {"build": 0.15, "muscle": 0.1, "age": 0.15, "jaw_width": 0.1, "brow_depth": 0.1, "freckles": 0.45},
		"eye_color": "73706b", "hair_color": "66615c", "hair_style": "none",
		"skin_tint": "807a73", "marking_color": "bfb8ad",
		"skin_material": {"roughness": 0.75, "metallic": 0.1},
	},
	# Hemomancers with precise circulatory control — blood as tool/weapon.
	"Sanguis": {
		"genes": {"skin_redness": 0.3, "lip_fullness": 0.1, "freckles": 0.4},
		"eye_color": "80191f", "hair_color": "330d0d", "hair_style": "short",
		"skin_tint": "996659", "marking_color": "8c191f",
		"skin_material": {"roughness": 0.45},
	},
	# Genetic mosaics with unstable phenotypes — no two alike.
	"Chimera": {
		"chaotic": true,
		"genes": {},
		"eye_color": "cc66cc", "hair_color": "336699", "hair_style": "long",
	},
	# Stellar descendants — vestigial cosmic attunement, plasma streaks.
	"Astra": {
		"genes": {"cheekbone_height": 0.05, "freckles": 0.7},
		"eye_color": "bfccf2", "hair_color": "141433", "hair_style": "long",
		"skin_tint": "b3b8cc", "marking_color": "ccd9ff",
		"skin_material": {"emissive_strength": 0.4, "emissive_color": "99b3ff"}, "emissive_boost": 0.2,
	},
	# Iron-blooded warriors — metallic dermal plating, magnetic fields.
	"Ferros": {
		"genes": {"build": 0.2, "muscle": 0.15, "jaw_width": 0.1, "brow_depth": 0.05, "freckles": 0.4},
		"eye_color": "807d80", "hair_color": "1a1a1a", "hair_style": "buzz",
		"skin_tint": "8c8589", "marking_color": "8c592e",
		"skin_material": {"roughness": 0.35, "metallic": 0.75},
	},
	# Partially incorporeal — exist in the material and ethereal planes.
	"Etherea": {
		"genes": {"build": -0.1, "muscle": -0.1},
		"eye_color": "d9e6f2", "hair_color": "d9d9e0", "hair_style": "long",
		"skin_tint": "e0e0e6", "marking_color": "d9e6ff",
		"skin_material": {"roughness": 0.3, "transparent": true, "opacity": 0.75, "emissive_strength": 0.2},
		"emissive_boost": 0.1,
	},
	# Rune-scribes whose bodies are living inscription surfaces.
	"Glyphe": {
		"genes": {"forehead_height": 0.05, "freckles": 0.6},
		"eye_color": "26192e", "hair_color": "0d0d0d", "hair_style": "short",
		"skin_tint": "bfad8c", "marking_color": "b38c33",
		"skin_material": {"roughness": 0.55, "emissive_strength": 0.25}, "emissive_boost": 0.15,
	},
}

## Palette for Chimera's per-individual chaos roll (see HumanIdentity) —
## unstable phenotypes read as strikingly mixed, not just randomized-plain.
const CHIMERA_EYE_PALETTE := ["cc66cc", "66cc99", "e6b800", "3399ff", "ff6666", "99ff33"]
const CHIMERA_HAIR_PALETTE := ["336699", "996633", "339966", "993399", "cc3333", "336633"]

static func get_archetype(canon_name: String) -> Dictionary:
	return RACES.get(canon_name, {})
