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

## ── FACTION LINES — bespoke identities, not generated ──────────────────────
## Sovereign Crown: building & sentries. The Crown holds ground; what it
##   raises, stays raised.
## Veiled Current: liminal arts amplified. The Current was walking the
##   between before anyone named it.
## Wildlands Ascendants: transformation & creation. What survives the wilds
##   becomes the wilds — and then makes more of them.
## Factionless: the Lone Wolf. No banner, no backup, unperceived.
const FACTION_LINES := {
	"SovereignCrown": {
		name="Crown Mandate",
		flavor="The Crown does not chase. It builds where it stands and dares the world to object.",
		actives=[
			{id="fac_sc_a0", name="Raise Bulwark", kind="build", shape="line", radius=4.0,
			 power=1.0, cost=25, cooldown=10.0,
			 lore="A wall of Crown-gold masonry assembles from nothing. Architecture as an argument."},
			{id="fac_sc_a1", name="Crown Sentry", kind="sentry", shape="single", radius=12.0,
			 power=0.8, cost=30, cooldown=14.0,
			 lore="A sentry spire of the old empire, deputized on the spot. It does not sleep, blink, or forgive."},
			{id="fac_sc_a2", name="Royal Fortification", kind="shield", shape="self", radius=0.0,
			 power=1.5, cost=22, cooldown=9.0,
			 lore="You are Crown property now — and the Crown protects its assets."},
		],
		ultimate={id="fac_sc_ult", name="Coronation Bastion", kind="bastion", shape="aoe", radius=10.0,
			power=2.5, ult_cost=150, cooldown=1.0,
			lore="A ring of walls and sentries erupts around you. For thirty seconds, this ground is Dallas."},
		passives=[
			{id="fac_sc_p0", name="Mandate of Stone", desc="Structures you raise last 50%% longer and sentries hit 20%% harder."},
			{id="fac_sc_p1", name="Crown Territory", desc="+5%% all stats inside SovereignCrown-claimed chunks."},
		],
	},
	"VeiledCurrent": {
		name="Current Working",
		flavor="Water finds every crack. The Current was walking the liminal before anyone named it.",
		actives=[
			{id="fac_vc_a0", name="Wrong Step", kind="mobility", shape="self", radius=0.0,
			 power=1.4, cost=14, cooldown=4.0,
			 lore="You step where the floor isn't and arrive where the wall was. The between doesn't mind — you're a regular."},
			{id="fac_vc_a1", name="Veil of the Current", kind="shield", shape="self", radius=0.0,
			 power=1.2, cost=20, cooldown=8.0,
			 lore="You go slightly liminal. Attacks pass through the space you almost occupy."},
			{id="fac_vc_a2", name="Undertow Pull", kind="control", shape="aoe", radius=8.0,
			 power=1.0, cost=24, cooldown=9.0,
			 lore="The Current takes everyone nearby by the ankles. They were standing on water the whole time."},
		],
		ultimate={id="fac_vc_ult", name="Between Tide", kind="damage", shape="aoe", radius=11.0,
			power=3.5, ult_cost=150, cooldown=1.0,
			lore="For one held breath the whole fight happens in the liminal — and the liminal sides with you."},
		passives=[
			{id="fac_vc_p0", name="Currentborn", desc="The Periliminal pull timer runs 25%% slower; liminal doors cost 30%% fewer tokens."},
			{id="fac_vc_p1", name="Slipstream", desc="+5%% all stats inside VeiledCurrent-claimed chunks."},
		],
	},
	"WildlandsAscendant": {
		name="Wild Ascension",
		flavor="What survives the wilds becomes the wilds. What becomes the wilds makes more of them.",
		actives=[
			{id="fac_wa_a0", name="Feral Shift", kind="transform", shape="self", radius=0.0,
			 power=1.3, cost=26, cooldown=12.0,
			 lore="Your frame remembers being something with more teeth. Let it."},
			{id="fac_wa_a1", name="Grow Thicket", kind="build", shape="aoe", radius=5.0,
			 power=0.9, cost=24, cooldown=10.0,
			 lore="You create a thicket where there was floor. It grows like it's making up for lost time."},
			{id="fac_wa_a2", name="Packmate", kind="summon", shape="single", radius=10.0,
			 power=1.0, cost=32, cooldown=16.0,
			 lore="You make a creature — not summon, MAKE. The Ascendants stopped asking permission for creation long ago."},
		],
		ultimate={id="fac_wa_ult", name="Apex Bloom", kind="transform", shape="aoe", radius=9.0,
			power=3.0, ult_cost=150, cooldown=1.0,
			lore="Full transformation. Whatever you become for these twelve seconds, the field remembers it as the apex."},
		passives=[
			{id="fac_wa_p0", name="Green Memory", desc="Transformations last 30%% longer; your creations inherit 20%% of your stats."},
			{id="fac_wa_p1", name="Wildclaim", desc="+5%% all stats inside WildlandsAscendant-claimed chunks."},
		],
	},
	"Factionless": {
		name="Lone Wolf",
		flavor="No banner, no orders, no backup. The only line that scales with what you've survived alone.",
		actives=[
			{id="fac_fl_a0", name="Nobody's Strike", kind="damage", shape="single", radius=4.0,
			 power=1.6, cost=22, cooldown=6.0,
			 lore="Hits harder when no ally is near — which, for you, is always."},
			{id="fac_fl_a1", name="Scavenger's Wager", kind="chance", shape="aoe", radius=6.0,
			 power=1.4, cost=20, cooldown=8.0,
			 lore="You learned to gamble because the alternative was starving. The odds respect that."},
			{id="fac_fl_a2", name="Gone Quiet", kind="mobility", shape="self", radius=0.0,
			 power=1.2, cost=16, cooldown=7.0,
			 lore="Not invisible. Just not worth perceiving. There's a difference, and it keeps you alive."},
		],
		ultimate={id="fac_fl_ult", name="Nobody's Hour", kind="shield", shape="self", radius=0.0,
			power=4.0, ult_cost=175, cooldown=1.0,
			lore="For ten seconds you don't render on anyone's client at all. Unperceived is unkillable."},
		passives=[
			{id="fac_fl_p0", name="Unaligned", desc="+10%% all rewards in open-PvP territory — nobody splits your take."},
		],
	},
}

static func faction_line(faction: String) -> Dictionary:
	var f: Dictionary = FACTION_LINES.get(faction, FACTION_LINES["Factionless"])
	var actives: Array[Dictionary] = []
	for a in f.actives:
		var e: Dictionary = a.duplicate()
		e["lore"] = "%s %s" % [e.get("lore", ""), f.flavor]
		e["morphs"] = _morphs_for(e.name, e.kind)
		actives.append(e)
	return {
		"id": "line_faction_%s" % faction, "name": f.name,
		"source": "faction", "source_id": faction,
		"actives": actives,
		"ultimate": f.ultimate,
		"passives": f.passives,
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

## ── WEAPON DISCIPLINES: trained, not born ──────────────────────────────────
## Unlike frame/race/faction lines (what you ARE), disciplines are what you
## PRACTICE — leveled at any city's Stockyards on the training dummies.
## The mix: ESO-style weapon lines, Marvel-flavored superhuman unarmed,
## CoD-flavored gunplay. Same active/ultimate/morph shape as every line.
static func unarmed_way() -> Dictionary:
	return {
		"id": "line_disc_unarmed", "name": "The Unarmed Way",
		"source": "discipline", "source_id": "unarmed",
		"actives": [
			{"id": "una_a0", "name": "Palm Meteor", "kind": "damage", "shape": "single", "radius": 3.0,
			 "power": 1.15, "cost": 18, "cooldown": 3.5,
			 "lore": "No steel, no sigil — a straight palm that lands like something falling from orbit.",
			 "morphs": _morphs_for("Palm Meteor", "damage")},
			{"id": "una_a1", "name": "Hurricane Sweep", "kind": "damage", "shape": "aoe", "radius": 5.0,
			 "power": 0.75, "cost": 22, "cooldown": 6.0,
			 "lore": "One turned heel, everyone within reach airborne. The body is the whole armory.",
			 "morphs": _morphs_for("Hurricane Sweep", "damage")},
			{"id": "una_a2", "name": "Iron Breath", "kind": "shield", "shape": "self", "radius": 0.0,
			 "power": 1.1, "cost": 20, "cooldown": 9.0,
			 "lore": "Exhale, settle, harden. Skin remembers it used to be stone.",
			 "morphs": _morphs_for("Iron Breath", "shield")},
		],
		"ultimate": {
			"id": "una_ult", "name": "Hundred Fists",
			"kind": "damage", "shape": "single", "radius": 3.0,
			"power": 4.5, "ult_cost": 180, "cooldown": 1.0,
			"lore": "For two seconds your hands are a rumor. Witnesses disagree on how many of you there were.",
		},
		"passives": [
			{"id": "una_p0", "name": "Open Hand", "desc": "+10%% damage while no weapon blueprint is equipped."},
			{"id": "una_p1", "name": "Rooted", "desc": "Knockback against you is reduced 30%%."},
		],
	}

static func gunplay() -> Dictionary:
	return {
		"id": "line_disc_gunplay", "name": "Gunplay",
		"source": "discipline", "source_id": "guns",
		"actives": [
			{"id": "gun_a0", "name": "Deadeye Round", "kind": "damage", "shape": "line", "radius": 14.0,
			 "power": 1.3, "cost": 20, "cooldown": 4.0,
			 "lore": "One shot, one lane. The between makes excellent sightlines.",
			 "morphs": _morphs_for("Deadeye Round", "damage")},
			{"id": "gun_a1", "name": "Suppressing Arc", "kind": "damage", "shape": "aoe", "radius": 8.0,
			 "power": 0.6, "cost": 26, "cooldown": 7.0,
			 "lore": "Nobody moves through a wall of lead. Nobody polite, anyway.",
			 "morphs": _morphs_for("Suppressing Arc", "damage")},
			{"id": "gun_a2", "name": "Combat Slide", "kind": "mobility", "shape": "self", "radius": 0.0,
			 "power": 0.9, "cost": 16, "cooldown": 5.0,
			 "lore": "Reload on the way down, up before the shells land.",
			 "morphs": _morphs_for("Combat Slide", "mobility")},
		],
		"ultimate": {
			"id": "gun_ult", "name": "Killstreak",
			"kind": "damage", "shape": "aoe", "radius": 10.0,
			"power": 4.0, "ult_cost": 200, "cooldown": 1.0,
			"lore": "Everything you've landed this fight comes back at once, from above, uninvited.",
		},
		"passives": [
			{"id": "gun_p0", "name": "Steady Hands", "desc": "Line skills reach 15%% further."},
			{"id": "gun_p1", "name": "Quickdraw", "desc": "First cast each fight costs no flux."},
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
	# Disciplines are universal too — everyone can walk into a Stockyards.
	out.append(unarmed_way())
	out.append(gunplay())
	return out
