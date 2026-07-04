extends Node
## Autoloaded as "SkillManager". The ESO-shaped combat progression core:
##
##  RANKS: skills level I→IV by USE (each cast feeds XP). At rank IV the
##  skill refracts — you choose one of two MORPHS, permanently.
##  SKILL POINTS: earned from influence levels and quests; spent to
##  SLOT a skill the first time (unlocking it on your bars).
##  BARS: two bars of 5 actives + 1 ultimate. Bar B unlocks with your
##  ascended frame — swapping bars IS swapping sensoria, so the swap
##  briefly re-tunes your world's light and sound (0.4s of the other
##  frame bleeding in).
##  FLUX: one regenerating resource pool pays for actives (your build's
##  STY/RES raise the cap; SPD raises regen).
##  ULTIMATE: charge builds from dealing and taking damage; each bar's
##  ultimate spends it.

signal skill_ranked_up(skill_id: String, rank: int)
signal morph_ready(skill_id: String)
signal bar_swapped(active_bar: int)
signal ultimate_ready()
signal flux_changed(current: float, maximum: float)

const SAVE_PATH := "user://skills.json"
const RANK_XP := [0, 40, 120, 280] # XP thresholds to reach rank II, III, IV
const MAX_RANK := 4
const CAST_XP := 8

var skill_points := 3 # everyone starts with enough to slot a starter kit
var _ranks: Dictionary = {}   # skill_id -> {rank, xp, morph("m_edge"/"m_still"/"")}
var _unlocked: Dictionary = {} # skill_id -> true (skill point spent)
var bars: Array = [ # two bars: 5 active slot ids + ultimate id ("" = empty)
	{"actives": ["", "", "", "", ""], "ultimate": ""},
	{"actives": ["", "", "", "", ""], "ultimate": ""},
]
var active_bar := 0
var ultimate_charge := 0.0
var flux := 100.0
var flux_max := 100.0
var flux_regen := 8.0

func _ready() -> void:
	_load()
	_recompute_pools()
	PlayerProfile.profile_updated.connect(_recompute_pools)
	_auto_slot_starters()

func _recompute_pools() -> void:
	var stats := CharacterCreatorLogic.build_starting_stats(
		PlayerProfile.selected_race_id, PlayerProfile.faction, PlayerProfile.selected_frame)
	flux_max = 100.0 + float(stats.sty) * 2.0 + float(stats.res)
	flux_regen = 8.0 + float(stats.spd) * 0.25
	flux = minf(flux, flux_max)

func _process(delta: float) -> void:
	if flux < flux_max:
		flux = minf(flux + flux_regen * delta, flux_max)
		flux_changed.emit(flux, flux_max)

## First-time starter kit so combat works out of the box: frame line's
## first two actives + liminal Doorframe + frame ultimate on bar A.
func _auto_slot_starters() -> void:
	if bars[0].actives[0] != "":
		return
	var line := SkillData.frame_line(PlayerProfile.selected_frame)
	if line.is_empty():
		return
	slot_skill(0, 0, line.actives[0].id, true)
	slot_skill(0, 1, line.actives[1].id, true)
	slot_skill(0, 2, "lim_a0", true)
	slot_ultimate(0, line.ultimate.id, true)
	_save()

## ── Lines & lookup ────────────────────────────────────────────────────────
func known_lines() -> Array[Dictionary]:
	return SkillData.lines_for(
		PlayerProfile.selected_race_id, PlayerProfile.selected_frame,
		PlayerProfile.ascended_frame, PlayerProfile.faction)

func find_skill(skill_id: String) -> Dictionary:
	for line in known_lines():
		for a in line.actives:
			if a.id == skill_id:
				return a
		if line.ultimate.id == skill_id:
			return line.ultimate
	return {}

## ── Points, ranks, morphs ─────────────────────────────────────────────────
func grant_points(n: int, why: String = "") -> void:
	skill_points += n
	NotificationUI.notify_info("✴️ +%d skill point%s%s" % [n, "s" if n > 1 else "", (" — " + why) if why else ""])
	_save()

func is_unlocked(skill_id: String) -> bool:
	return _unlocked.get(skill_id, false)

func unlock(skill_id: String) -> bool:
	if is_unlocked(skill_id):
		return true
	if skill_points <= 0:
		NotificationUI.notify_error("No skill points. Influence levels and quests grant them.")
		return false
	skill_points -= 1
	_unlocked[skill_id] = true
	_ranks[skill_id] = {"rank": 1, "xp": 0, "morph": ""}
	_save()
	return true

func rank_of(skill_id: String) -> int:
	return _ranks.get(skill_id, {}).get("rank", 0)

func morph_of(skill_id: String) -> String:
	return _ranks.get(skill_id, {}).get("morph", "")

func add_skill_xp(skill_id: String, xp: int = CAST_XP) -> void:
	if not _ranks.has(skill_id):
		return
	var r: Dictionary = _ranks[skill_id]
	if r.rank >= MAX_RANK:
		return
	r.xp += xp
	if r.xp >= RANK_XP[r.rank]:
		r.rank += 1
		skill_ranked_up.emit(skill_id, r.rank)
		var sk := find_skill(skill_id)
		NotificationUI.notify_info("📖 %s → rank %s" % [sk.get("name", skill_id), ["I","II","III","IV"][r.rank - 1]])
		if r.rank == MAX_RANK:
			morph_ready.emit(skill_id)
			NotificationUI.notify_win("🔀 %s refracts — choose its morph (skill tree)." % sk.get("name", skill_id))
	_save()

func choose_morph(skill_id: String, morph_id: String) -> bool:
	var r: Dictionary = _ranks.get(skill_id, {})
	if r.get("rank", 0) < MAX_RANK or r.get("morph", "") != "":
		return false
	r.morph = morph_id
	_save()
	return true

## Effective numbers for a skill including rank scaling (+8%/rank) & morph.
func resolved(skill_id: String) -> Dictionary:
	var sk := find_skill(skill_id).duplicate()
	if sk.is_empty():
		return sk
	var rank := maxi(rank_of(skill_id), 1)
	sk.power = sk.get("power", 1.0) * (1.0 + 0.08 * (rank - 1))
	var m := morph_of(skill_id)
	for morph in sk.get("morphs", []):
		if morph.id == m:
			if morph.effect == "power":
				sk.power *= morph.bonus
			else:
				sk.cost = int(sk.get("cost", 20) * morph.bonus)
				sk.cooldown = sk.get("cooldown", 5.0) * morph.bonus
			sk.name = morph.name
	return sk

## ── Bars ──────────────────────────────────────────────────────────────────
func slot_skill(bar: int, slot: int, skill_id: String, free: bool = false) -> bool:
	if bar == 1 and PlayerProfile.ascended_frame == "":
		NotificationUI.notify_error("Bar II unlocks with your ascended frame.")
		return false
	if not free and not is_unlocked(skill_id) and not unlock(skill_id):
		return false
	if free and not is_unlocked(skill_id):
		_unlocked[skill_id] = true
		_ranks[skill_id] = {"rank": 1, "xp": 0, "morph": ""}
	bars[bar].actives[slot] = skill_id
	_save()
	return true

func slot_ultimate(bar: int, skill_id: String, free: bool = false) -> bool:
	if free and not is_unlocked(skill_id):
		_unlocked[skill_id] = true
		_ranks[skill_id] = {"rank": 1, "xp": 0, "morph": ""}
	elif not is_unlocked(skill_id) and not unlock(skill_id):
		return false
	bars[bar].ultimate = skill_id
	_save()
	return true

func can_swap() -> bool:
	return PlayerProfile.ascended_frame != ""

func swap_bar() -> void:
	if not can_swap():
		NotificationUI.notify_info("A second bar needs a second frame — ascend at level 50.")
		return
	active_bar = 1 - active_bar
	bar_swapped.emit(active_bar)

func current_bar() -> Dictionary:
	return bars[active_bar]

## ── Resources ─────────────────────────────────────────────────────────────
func try_pay_flux(cost: float) -> bool:
	if flux < cost:
		return false
	flux -= cost
	flux_changed.emit(flux, flux_max)
	return true

func gain_ultimate(amount: float) -> void:
	var before := ultimate_charge
	ultimate_charge = minf(ultimate_charge + amount, 500.0)
	var need := float(resolved(current_bar().ultimate).get("ult_cost", 100))
	if before < need and ultimate_charge >= need:
		ultimate_ready.emit()

func try_pay_ultimate(cost: float) -> bool:
	if ultimate_charge < cost:
		return false
	ultimate_charge -= cost
	return true

## ── Persistence ───────────────────────────────────────────────────────────
func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({
			"points": skill_points, "ranks": _ranks, "unlocked": _unlocked, "bars": bars,
		}))

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f: return
	var d = JSON.parse_string(f.get_as_text())
	if not d is Dictionary: return
	skill_points = int(d.get("points", 3))
	_ranks = d.get("ranks", {})
	_unlocked = d.get("unlocked", {})
	var loaded: Array = d.get("bars", [])
	if loaded.size() == 2:
		bars = loaded
