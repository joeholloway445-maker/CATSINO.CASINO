class_name SkillData
## The skill system's data layer — ESO-shaped but native to our cosmology:
##
##  SKILL LINES come from what you ARE, not what you picked up:
##   - Your FRAME line (all 20 frames each carry a full line: 5 actives +
##     1 ultimate + 3 passives). Your frame is your primary line; the
##     ascended frame's line powers your SECOND bar.
##   - Your RACE line (passive-heavy, 2 actives + 1 ultimate).
##   - Your FACTION line (3 actives + 1 ultimate; Factionless get the
##     Lone Wolf line).
##   - The LIMINAL ARTS — the universal line every walker learns, because
##     everyone has stood in the between at least once.
##
##  MORPHS: every active, at rank IV, refracts into one of two variants —
##  lore says a skill practiced long enough starts perceiving YOU back,
##  and it has to choose what it sees. Morph names/effects derive from the
##  skill plus the morphing archetype (offense refraction vs utility
##  refraction).
##
##  Lines are GENERATED from the existing data (frame stat profiles + lore
##  strings, race passives, faction identities) so all 20 frames, 20 races
##  and 4 allegiances have complete lines with consistent depth — then
##  hand-tuned entries can override any generated one later.

## Ability archetypes by dominant stat — verbs, costs, and effect shapes.
const ARCHETYPES := {
	"pow": {verbs=["Strike", "Rend", "Crush", "Overload", "Detonate"], kind="damage",  base_power=1.2, cost=22, cooldown=4.0},
	"res": {verbs=["Ward", "Anchor", "Fortify", "Shell", "Bulwark"],   kind="shield",  base_power=0.9, cost=18, cooldown=8.0},
	"spd": {verbs=["Dash", "Flicker", "Lunge", "Split", "Afterimage"], kind="mobility",base_power=0.8, cost=15, cooldown=5.0},
	"lck": {verbs=["Gamble", "Twist", "Hex", "Wager", "Jackpot"],      kind="chance",  base_power=1.5, cost=20, cooldown=7.0},
	"sty": {verbs=["Flourish", "Resonate", "Mesmer", "Refract", "Encore"], kind="control", base_power=1.0, cost=20, cooldown=6.0},
}

## Slot themes across a line's five actives (index 0-4): the shape each
## ability takes regardless of archetype.
const SLOT_SHAPES := [
	{shape="single", radius=3.0,  mult=1.0,  desc="a focused strike"},
	{shape="aoe",    radius=6.0,  mult=0.6,  desc="a burst around you"},
	{shape="self",   radius=0.0,  mult=1.0,  desc="turned inward"},
	{shape="line",   radius=9.0,  mult=0.8,  desc="thrown forward"},
	{shape="single", radius=4.5,  mult=1.35, desc="an executioner's blow"},
]

static func _dominant_stats(bonus: Dictionary) -> Array:
	var pairs := []
	for k in ["pow", "res", "spd", "lck", "sty"]:
		pairs.append([k, int(bonus.get(k, 0))])
	pairs.sort_custom(func(a, b): return a[1] > b[1])
	return pairs

## ── FRAME LINES: 5 actives + ultimate + passives per frame ─────────────────
static func frame_line(frame_id: String) -> Dictionary:
	var frame := FrameModData.get_frame(frame_id)
	if frame.is_empty():
		return {}
	var sens := FrameSensorium.of(frame_id)
	var stats := _dominant_stats(frame.get("stat_bonus", {}))
	var primary: String = stats[0][0]
	var secondary: String = stats[1][0]
	var actives: Array[Dictionary] = []
	for i in range(5):
		# Alternate primary/secondary archetypes across the line.
		var stat: String = primary if i % 2 == 0 else secondary
		var arch: Dictionary = ARCHETYPES[stat]
		var shape: Dictionary = SLOT_SHAPES[i]
		var aname := "%s %s" % [frame.get("name", "?").replace(" Frame", ""), arch.verbs[i]]
		actives.append({
			"id": "%s_a%d" % [frame_id, i],
			"name": aname,
			"kind": arch.kind, "shape": shape.shape, "radius": shape.radius,
			"power": arch.base_power * shape.mult,
			"cost": arch.cost, "cooldown": arch.cooldown,
			"lore": "%s — %s, %s." % [frame.get("lore", ""), shape.desc, sens.desc.to_lower()],
			"morphs": _morphs_for(aname, arch.kind),
		})
	return {
		"id": "line_frame_%s" % frame_id,
		"name": "%s Discipline" % frame.get("name", "?"),
		"source": "frame", "source_id": frame_id,
		"actives": actives,
		"ultimate": {
			"id": "%s_ult" % frame_id,
			"name": "%s: %s" % [frame.get("name", "?"), "Apotheosis" if frame.get("type") == "light" else "Cataclysm"],
			"kind": "damage", "shape": "aoe", "radius": 12.0,
			"power": 4.0, "ult_cost": 100, "cooldown": 1.0,
			"lore": "For one breath, the frame stops filtering and shows you everything it really is. %s" % frame.get("lore", ""),
		},
		"passives": [
			{"id": "%s_p0" % frame_id, "name": "Attunement", "desc": "+10%% %s effectiveness while this line is on your active bar." % primary.to_upper()},
			{"id": "%s_p1" % frame_id, "name": "Deep Attunement", "desc": "Bar-swapping TO this line refreshes 10%% flux (your senses snapping back sharpens you)."},
			{"id": "%s_p2" % frame_id, "name": "Signature", "desc": "Your sensorium leaks: enemies hit by this line briefly hear your world instead of theirs."},
		],
	}

## ── RACE LINES: 2 actives + ultimate, passive-heavy ────────────────────────
static func race_line(race_id: String) -> Dictionary:
	var race := RaceDataCharacter.get_race(race_id)
	if race.is_empty():
		return {}
	var stats := _dominant_stats({
		"pow": race.get("pow", 0), "res": race.get("res", 0), "spd": race.get("spd", 0),
		"lck": race.get("lck", 0), "sty": race.get("sty", 0)})
	var primary: String = stats[0][0]
	var arch: Dictionary = ARCHETYPES[primary]
	var actives: Array[Dictionary] = []
	for i in range(2):
		var shape: Dictionary = SLOT_SHAPES[i * 3] # single, line
		var aname := "%s %s" % [race.get("name", "?"), arch.verbs[i + 2]]
		actives.append({
			"id": "%s_ra%d" % [race_id, i], "name": aname,
			"kind": arch.kind, "shape": shape.shape, "radius": shape.radius,
			"power": arch.base_power * shape.mult * 0.9,
			"cost": arch.cost, "cooldown": arch.cooldown + 2.0,
			"lore": "Blood memory. %s" % race.get("lore", ""),
			"morphs": _morphs_for(aname, arch.kind),
		})
	return {
		"id": "line_race_%s" % race_id,
		"name": "%s Heritage" % race.get("name", "?"),
		"source": "race", "source_id": race_id,
		"actives": actives,
		"ultimate": {
			"id": "%s_rult" % race_id,
			"name": "True %s" % race.get("name", "?"),
			"kind": "buff", "shape": "self", "radius": 0.0,
			"power": 2.0, "ult_cost": 125, "cooldown": 1.0,
			"lore": "For a moment every hard surface in YOUR world turns to %s — and everyone nearby sees theirs flicker. %s" % [
				race.get("texture_type", "?"), race.get("lore", "")],
		},
		"passives": [
			{"id": "%s_rp0" % race_id, "name": "Substance", "desc": "Your race lens pulls 10%% harder — the world is more yours."},
			{"id": "%s_rp1" % race_id, "name": "Kinship", "desc": "+15%% bond XP with entities sharing your faction."},
		],
	}

## ── FACTION LINES ──────────────────────────────────────────────────────────
const FACTION_LINES := {
	"SovereignCrown": {
		name="Crown Mandate", theme="pow",
		flavor="The Crown does not ask. Skills of command, execution, and the weight of authority.",
		ult_name="Coronation", ult_lore="Every ally under the Mandate strikes as one crown for six seconds.",
	},
	"WildlandsAscendant": {
		name="Wild Ascension", theme="res",
		flavor="What survives the wilds becomes the wilds. Skills of endurance, regrowth, and the pack.",
		ult_name="The Green Tide", ult_lore="The terrain itself rises — roots and regrowth heal the pack and drag enemies down.",
	},
	"VeiledCurrent": {
		name="Current Working", theme="spd",
		flavor="Water finds every crack. Skills of flow, misdirection, and arriving where you weren't.",
		ult_name="Undertow", ult_lore="The Current takes everyone nearby somewhere slightly worse for them.",
	},
	"Factionless": {
		name="Lone Wolf", theme="lck",
		flavor="No banner, no orders, no backup. The Lone Wolf line is the only one that scales with what you've survived alone.",
		ult_name="Nobody's Hour", ult_lore="For ten seconds you don't render on anyone's client at all. The Factionless know: unperceived is unkillable.",
	},
}

static func faction_line(faction: String) -> Dictionary:
	var f: Dictionary = FACTION_LINES.get(faction, FACTION_LINES["Factionless"])
	var arch: Dictionary = ARCHETYPES[f.theme]
	var actives: Array[Dictionary] = []
	for i in range(3):
		var shape: Dictionary = SLOT_SHAPES[i + 1]
		var aname := "%s: %s" % [f.name, arch.verbs[i]]
		actives.append({
			"id": "fac_%s_a%d" % [faction, i], "name": aname,
			"kind": arch.kind, "shape": shape.shape, "radius": shape.radius,
			"power": arch.base_power * shape.mult,
			"cost": arch.cost, "cooldown": arch.cooldown,
			"lore": f.flavor,
			"morphs": _morphs_for(aname, arch.kind),
		})
	return {
		"id": "line_faction_%s" % faction, "name": f.name,
		"source": "faction", "source_id": faction,
		"actives": actives,
		"ultimate": {
			"id": "fac_%s_ult" % faction, "name": f.ult_name,
			"kind": "damage" if f.theme == "pow" else "buff",
			"shape": "aoe", "radius": 10.0, "power": 3.5, "ult_cost": 150, "cooldown": 1.0,
			"lore": f.ult_lore,
		},
		"passives": [
			{"id": "fac_%s_p0" % faction, "name": "Allegiance", "desc": "+5%% all stats inside your faction's territory."},
		],
	}

## ── THE LIMINAL ARTS: the universal line ───────────────────────────────────
static func liminal_arts() -> Dictionary:
	return {
		"id": "line_liminal", "name": "The Liminal Arts",
		"source": "universal", "source_id": "liminal",
		"actives": [
			{"id": "lim_a0", "name": "Doorframe", "kind": "shield", "shape": "self", "radius": 0.0,
			 "power": 1.2, "cost": 20, "cooldown": 9.0,
			 "lore": "You stand in a doorway that isn't there. Thresholds protect; the between taught you that.",
			 "morphs": _morphs_for("Doorframe", "shield")},
			{"id": "lim_a1", "name": "Wrong Hallway", "kind": "mobility", "shape": "self", "radius": 0.0,
			 "power": 1.0, "cost": 18, "cooldown": 6.0,
			 "lore": "Step through a hallway that shouldn't connect — 12 meters of somewhere else.",
			 "morphs": _morphs_for("Wrong Hallway", "mobility")},
			{"id": "lim_a2", "name": "Hum of the Vents", "kind": "damage", "shape": "aoe", "radius": 7.0,
			 "power": 0.7, "cost": 24, "cooldown": 8.0,
			 "lore": "The drone every liminal wanderer learns to stop hearing — weaponized. Enemies can't stop hearing it.",
			 "morphs": _morphs_for("Hum of the Vents", "damage")},
		],
		"ultimate": {
			"id": "lim_ult", "name": "Noclip",
			"kind": "chance", "shape": "self", "radius": 0.0,
			"power": 5.0, "ult_cost": 200, "cooldown": 1.0,
			"lore": "You fall out of the fight entirely for four seconds and come back somewhere better, holding whatever the between handed you. The song was always instructions.",
		},
		"passives": [
			{"id": "lim_p0", "name": "Wander-hardened", "desc": "The Periliminal pull timer runs 15%% slower for you."},
			{"id": "lim_p1", "name": "Threshold Sense", "desc": "Liminal doors (guild wars) cost 20%% fewer tokens to open."},
		],
	}

## Every skill refracts at rank IV: one morph deepens the effect (the skill
## sees a weapon when it looks at you), one bends it to utility (it sees a
## survivor).
static func _morphs_for(base_name: String, kind: String) -> Array:
	return [
		{"id": "m_edge", "name": base_name + " (Edge)",
		 "effect": "power", "bonus": 1.35,
		 "lore": "Practiced long enough, the skill perceives you back — and this one decided you are a weapon."},
		{"id": "m_still", "name": base_name + " (Still)",
		 "effect": "cost_cooldown", "bonus": 0.7,
		 "lore": "This one looked at you and saw someone who intends to still be here tomorrow." if kind != "shield"
			else "It saw the wall you have been the whole time."},
	]

## Everything a given player build knows about.
static func lines_for(race_id: String, frame_id: String, ascended: String, faction: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.append(frame_line(frame_id))
	if ascended != "" and ascended != frame_id:
		out.append(frame_line(ascended))
	out.append(race_line(race_id))
	out.append(faction_line(faction))
	out.append(liminal_arts())
	return out
