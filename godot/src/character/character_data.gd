extends Resource
class_name CharacterData

# ── Enums ──────────────────────────────────────────────────────────────────────
enum Race {
	KETH, LUMARI, VEX, FEROX, AZHUL, SYLVA, GEARA, NYX,
	AQUIS, IGNI, KRYOS, MYCO, VOLT, PETRA, SANGUIS,
	CHIMERA, ASTRA, FERROS, ETHEREA, GLYPHE
}

enum Frame {
	# Light frames
	VEIL, ZEPHYR, VIPER, PHANTOM, CRIMSON,
	GLACIAL, BOLT, SOUL, CINDER, FLUX,
	# Heavy frames
	BASTION, TREMOR, BEHEMOTH, BULWARK, IGNIS,
	GLACI, SURGE, SIEGE, BLIGHT, OSSIAN
}

enum Mod {
	CATALYST, RESONANCE, PHASE, OVERDRIVE, SINGULARITY,
	ECHO, PRISM, ENTROPY, ZENITH, APEX,
	KINETIC, VOLATILE, STATIC, HARMONIC, VOID_CORE,
	NULL, PRIME, ALPHA, OMEGA, VECTOR
}

enum Faction {
	FACTIONLESS,
	SOVEREIGN_CROWN,
	VEILED_CURRENT,
	WILDLANDS_ASCENDANT
}

enum FrameClass { LIGHT, HEAVY }

# ── Constants ──────────────────────────────────────────────────────────────────
const LIGHT_FRAMES := [
	Frame.VEIL, Frame.ZEPHYR, Frame.VIPER, Frame.PHANTOM, Frame.CRIMSON,
	Frame.GLACIAL, Frame.BOLT, Frame.SOUL, Frame.CINDER, Frame.FLUX
]
const HEAVY_FRAMES := [
	Frame.BASTION, Frame.TREMOR, Frame.BEHEMOTH, Frame.BULWARK, Frame.IGNIS,
	Frame.GLACI, Frame.SURGE, Frame.SIEGE, Frame.BLIGHT, Frame.OSSIAN
]

# Synergy table: [Race, Frame, Mod] combos -> stat bonus key + multiplier
const SYNERGY_RULES: Array[Dictionary] = [
	{"races": [Race.IGNI, Race.FEROX], "frames": [Frame.IGNIS, Frame.CINDER], "stat": "pow", "bonus": 0.20},
	{"races": [Race.NYX, Race.GLYPHE], "mods": [Mod.VOID_CORE, Mod.NULL],     "stat": "spd", "bonus": 0.15},
	{"races": [Race.AQUIS, Race.KRYOS],"frames": [Frame.GLACIAL, Frame.GLACI],"stat": "res", "bonus": 0.18},
	{"races": [Race.VOLT, Race.GEARA], "mods": [Mod.KINETIC, Mod.VOLT],       "stat": "spd", "bonus": 0.22},
	{"races": [Race.LUMARI, Race.ASTRA],"mods": [Mod.PRIME, Mod.ALPHA],       "stat": "lck", "bonus": 0.15},
	{"races": [Race.CHIMERA],           "mods": [Mod.PRISM, Mod.ENTROPY],     "stat": "sty", "bonus": 0.25},
]

# ── Exported Properties ────────────────────────────────────────────────────────
@export var character_name: String = "Unnamed"
@export var race:    Race    = Race.KETH
@export var frame:   Frame   = Frame.VEIL
@export var mod:     Mod     = Mod.CATALYST
@export var faction: Faction = Faction.FACTIONLESS

# Base stats
@export var base_pow: int = 10
@export var base_res: int = 10
@export var base_spd: int = 10
@export var base_lck: int = 10
@export var base_sty: int = 10

# ── Methods ────────────────────────────────────────────────────────────────────
func get_frame_class() -> FrameClass:
	return FrameClass.LIGHT if frame in LIGHT_FRAMES else FrameClass.HEAVY

func compute_synergy_bonus() -> float:
	var total_bonus := 0.0
	for rule: Dictionary in SYNERGY_RULES:
		var race_match  := "races"  not in rule or race  in rule["races"]
		var frame_match := "frames" not in rule or frame in rule["frames"]
		var mod_match   := "mods"   not in rule or mod   in rule["mods"]
		if race_match and frame_match and mod_match:
			total_bonus += rule["bonus"]
	# Generic same-class bonus: +15% if frame class matches a race affinity
	if get_frame_class() == FrameClass.LIGHT and race in [Race.SYLVA, Race.NYX, Race.LUMARI, Race.GLYPHE]:
		total_bonus += 0.15
	if get_frame_class() == FrameClass.HEAVY and race in [Race.FEROX, Race.PETRA, Race.FERROS, Race.SANGUIS]:
		total_bonus += 0.15
	return total_bonus

func compute_total_stats() -> Dictionary:
	var synergy := compute_synergy_bonus()
	var frame_class := get_frame_class()
	# Light frames boost Spd/Lck, Heavy boost Pow/Res
	var pow_mult := 1.0 + (0.10 if frame_class == FrameClass.HEAVY else 0.0) + synergy * 0.5
	var res_mult := 1.0 + (0.10 if frame_class == FrameClass.HEAVY else 0.0) + synergy * 0.3
	var spd_mult := 1.0 + (0.10 if frame_class == FrameClass.LIGHT  else 0.0) + synergy * 0.5
	var lck_mult := 1.0 + (0.05 if frame_class == FrameClass.LIGHT  else 0.0) + synergy * 0.2
	var sty_mult := 1.0 + synergy * 0.4
	return {
		"pow": int(base_pow * pow_mult),
		"res": int(base_res * res_mult),
		"spd": int(base_spd * spd_mult),
		"lck": int(base_lck * lck_mult),
		"sty": int(base_sty * sty_mult),
		"synergy_bonus": synergy,
		"frame_class": FrameClass.keys()[get_frame_class()],
	}

func to_dict() -> Dictionary:
	return {
		"name":    character_name,
		"race":    Race.keys()[race],
		"frame":   Frame.keys()[frame],
		"mod":     Mod.keys()[mod],
		"faction": Faction.keys()[faction],
		"stats":   compute_total_stats(),
	}
