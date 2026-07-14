class_name HumanDNA
extends Resource
## The genome of a PeriHuman — Periliminal's native answer to Epic's
## MetaHuman DNA file, with zero Unreal in the loop.
##
## Every visual trait of a human is a normalized 0..1 gene (plus a few
## colors and a hairstyle id). The whole genome serializes to a small JSON
## dict, blends linearly between any number of parent genomes (the
## MetaHuman-Creator "blend between presets" workflow), and can be rolled
## randomly from a seed (deterministic NPC faces from an id hash).
##
## Consumers:
##   HumanSkeletonBuilder  — proportions -> Skeleton3D joint layout
##   HumanMeshBuilder      — face/body genes -> skinned ArrayMesh + morphs
##   HumanMaterials        — skin/eye/hair genes -> PBR materials
##   PeriHumanRig          — assembles all of the above into a Node3D

const GENOME_VERSION := 1

const HAIR_STYLES := ["none", "buzz", "short", "bob", "topknot", "ponytail", "long"]

## Every float gene: id -> {group, label, default}. Order here is the
## order the Character Studio renders its sliders in.
const GENES := [
	# ---- body -------------------------------------------------------------
	{"id": "height",          "group": "Body", "label": "Height",          "default": 0.5},
	{"id": "build",           "group": "Body", "label": "Build",           "default": 0.45},
	{"id": "muscle",          "group": "Body", "label": "Muscle Tone",     "default": 0.45},
	{"id": "shoulder_width",  "group": "Body", "label": "Shoulder Width",  "default": 0.5},
	{"id": "hip_width",       "group": "Body", "label": "Hip Width",       "default": 0.5},
	{"id": "chest_depth",     "group": "Body", "label": "Chest Depth",     "default": 0.45},
	{"id": "torso_length",    "group": "Body", "label": "Torso Length",    "default": 0.5},
	{"id": "leg_length",      "group": "Body", "label": "Leg Length",      "default": 0.5},
	{"id": "arm_length",      "group": "Body", "label": "Arm Length",      "default": 0.5},
	{"id": "neck_thickness",  "group": "Body", "label": "Neck Thickness",  "default": 0.45},
	# ---- head shape --------------------------------------------------------
	{"id": "head_size",       "group": "Head", "label": "Head Size",       "default": 0.5},
	{"id": "head_width",      "group": "Head", "label": "Head Width",      "default": 0.5},
	{"id": "head_depth",      "group": "Head", "label": "Head Depth",      "default": 0.5},
	{"id": "forehead_height", "group": "Head", "label": "Forehead Height", "default": 0.5},
	{"id": "forehead_slope",  "group": "Head", "label": "Forehead Slope",  "default": 0.4},
	# ---- brow --------------------------------------------------------------
	{"id": "brow_depth",      "group": "Brow", "label": "Brow Ridge",      "default": 0.4},
	{"id": "brow_height",     "group": "Brow", "label": "Brow Height",     "default": 0.5},
	# ---- eyes --------------------------------------------------------------
	{"id": "eye_size",        "group": "Eyes", "label": "Eye Size",        "default": 0.5},
	{"id": "eye_spacing",     "group": "Eyes", "label": "Eye Spacing",     "default": 0.5},
	{"id": "eye_depth",       "group": "Eyes", "label": "Socket Depth",    "default": 0.5},
	{"id": "eye_tilt",        "group": "Eyes", "label": "Eye Tilt",        "default": 0.5},
	# ---- nose --------------------------------------------------------------
	{"id": "nose_length",     "group": "Nose", "label": "Nose Projection", "default": 0.5},
	{"id": "nose_width",      "group": "Nose", "label": "Nose Width",      "default": 0.45},
	{"id": "nose_bridge",     "group": "Nose", "label": "Bridge Height",   "default": 0.5},
	{"id": "nose_tip",        "group": "Nose", "label": "Tip Upturn",      "default": 0.5},
	# ---- cheeks ------------------------------------------------------------
	{"id": "cheekbone_height","group": "Cheeks", "label": "Cheekbone Height", "default": 0.5},
	{"id": "cheekbone_width", "group": "Cheeks", "label": "Cheekbone Width",  "default": 0.5},
	{"id": "cheek_fullness",  "group": "Cheeks", "label": "Cheek Fullness",   "default": 0.45},
	# ---- mouth -------------------------------------------------------------
	{"id": "mouth_width",     "group": "Mouth", "label": "Mouth Width",    "default": 0.5},
	{"id": "lip_fullness",    "group": "Mouth", "label": "Lip Fullness",   "default": 0.45},
	# ---- jaw / chin / ears ---------------------------------------------------
	{"id": "jaw_width",       "group": "Jaw",  "label": "Jaw Width",       "default": 0.5},
	{"id": "chin_length",     "group": "Jaw",  "label": "Chin Length",     "default": 0.5},
	{"id": "chin_protrusion", "group": "Jaw",  "label": "Chin Protrusion", "default": 0.45},
	{"id": "ear_size",        "group": "Jaw",  "label": "Ear Size",        "default": 0.45},
	# ---- skin / grooming -----------------------------------------------------
	{"id": "skin_melanin",    "group": "Skin", "label": "Skin Melanin",    "default": 0.35},
	{"id": "skin_redness",    "group": "Skin", "label": "Skin Redness",    "default": 0.35},
	{"id": "age",             "group": "Skin", "label": "Age",             "default": 0.3},
	{"id": "freckles",        "group": "Skin", "label": "Freckles",        "default": 0.0},
	{"id": "brow_thickness",  "group": "Skin", "label": "Brow Thickness",  "default": 0.5},
	{"id": "stubble",         "group": "Skin", "label": "Facial Hair",     "default": 0.0},
]

@export var display_name: String = "New Human"
@export var eye_color: Color = Color(0.30, 0.42, 0.30)
@export var hair_color: Color = Color(0.16, 0.11, 0.07)
@export var hair_style: String = "short"
## id -> 0..1. Only genes that differ from default need to be present.
@export var genes: Dictionary = {}

static var _defaults_cache: Dictionary = {}

static func gene_default(id: String) -> float:
	if _defaults_cache.is_empty():
		for g in GENES:
			_defaults_cache[g.id] = g.default
	return float(_defaults_cache.get(id, 0.5))

func get_gene(id: String) -> float:
	return clampf(float(genes.get(id, gene_default(id))), 0.0, 1.0)

func set_gene(id: String, value: float) -> void:
	genes[id] = clampf(value, 0.0, 1.0)

## Convenience: map a gene onto a real-world range.
func gene_lerp(id: String, from: float, to: float) -> float:
	return lerpf(from, to, get_gene(id))

# --------------------------------------------------------------- serialization

func to_dict() -> Dictionary:
	var g := {}
	for def in GENES:
		var v: float = get_gene(def.id)
		if not is_equal_approx(v, float(def.default)):
			g[def.id] = snappedf(v, 0.001)
	return {
		"version": GENOME_VERSION,
		"name": display_name,
		"eye_color": eye_color.to_html(false),
		"hair_color": hair_color.to_html(false),
		"hair_style": hair_style,
		"genes": g,
	}

static func from_dict(data: Dictionary) -> HumanDNA:
	var dna := HumanDNA.new()
	if data.is_empty():
		return dna
	dna.display_name = str(data.get("name", "New Human"))
	dna.eye_color = Color.from_string(str(data.get("eye_color", "4d6b4d")), dna.eye_color)
	dna.hair_color = Color.from_string(str(data.get("hair_color", "291c12")), dna.hair_color)
	dna.hair_style = str(data.get("hair_style", "short"))
	if dna.hair_style not in HAIR_STYLES:
		dna.hair_style = "short"
	var g: Dictionary = data.get("genes", {})
	for id in g:
		dna.set_gene(str(id), float(g[id]))
	return dna

func duplicate_dna() -> HumanDNA:
	return HumanDNA.from_dict(to_dict())

# --------------------------------------------------------------------- blending

## The MetaHuman-Creator signature move: a new face as a weighted mix of
## parent faces. `parents` is [[HumanDNA, weight], ...]; weights are
## normalized internally. Colors mix linearly; hairstyle follows the
## dominant parent.
static func blend(parents: Array) -> HumanDNA:
	var out := HumanDNA.new()
	if parents.is_empty():
		return out
	var total := 0.0
	for p in parents:
		total += maxf(0.0, float(p[1]))
	if total <= 0.0001:
		return (parents[0][0] as HumanDNA).duplicate_dna()
	var eye := Color(0, 0, 0)
	var hair := Color(0, 0, 0)
	var best_w := -1.0
	for p in parents:
		var parent: HumanDNA = p[0]
		var w: float = maxf(0.0, float(p[1])) / total
		if w <= 0.0:
			continue
		for def in GENES:
			out.genes[def.id] = float(out.genes.get(def.id, 0.0)) + parent.get_gene(def.id) * w
		eye += parent.eye_color * w
		hair += parent.hair_color * w
		if w > best_w:
			best_w = w
			out.hair_style = parent.hair_style
			out.display_name = parent.display_name + " Blend"
	out.eye_color = Color(eye.r, eye.g, eye.b)
	out.hair_color = Color(hair.r, hair.g, hair.b)
	return out

# ------------------------------------------------------------------ randomness

const _EYE_PALETTE := [
	Color(0.24, 0.15, 0.09), Color(0.35, 0.22, 0.11), Color(0.16, 0.32, 0.44),
	Color(0.28, 0.42, 0.28), Color(0.42, 0.36, 0.20), Color(0.30, 0.33, 0.38),
]
const _HAIR_PALETTE := [
	Color(0.05, 0.04, 0.03), Color(0.16, 0.11, 0.07), Color(0.35, 0.22, 0.10),
	Color(0.55, 0.38, 0.18), Color(0.72, 0.58, 0.36), Color(0.42, 0.16, 0.08),
	Color(0.55, 0.55, 0.56), Color(0.85, 0.83, 0.80),
]

## Deterministic random human. Same seed -> same face, so NPC ids can hash
## straight to a citizen.
static func random(seed_value: int) -> HumanDNA:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var dna := HumanDNA.new()
	dna.display_name = "Citizen %04d" % (absi(seed_value) % 10000)
	for def in GENES:
		# Beta-ish: mean of two rolls keeps most faces plausible while the
		# tails still produce striking ones.
		dna.genes[def.id] = clampf((rng.randf() + rng.randf()) * 0.5, 0.0, 1.0)
	# Traits that read badly when centered get their own rolls.
	dna.set_gene("freckles", maxf(0.0, rng.randf() * 1.4 - 0.8))
	dna.set_gene("stubble", maxf(0.0, rng.randf() * 1.6 - 0.9))
	dna.set_gene("age", clampf(rng.randf() * rng.randf() + 0.08, 0.0, 1.0))
	dna.eye_color = _EYE_PALETTE[rng.randi() % _EYE_PALETTE.size()]
	dna.hair_color = _HAIR_PALETTE[rng.randi() % _HAIR_PALETTE.size()]
	var styles := HAIR_STYLES.slice(1)  # "none" stays rare
	dna.hair_style = "none" if rng.randf() < 0.06 else styles[rng.randi() % styles.size()]
	return dna
