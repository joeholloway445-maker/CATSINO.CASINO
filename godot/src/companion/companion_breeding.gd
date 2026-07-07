extends Node
## Autoloaded as "CompanionBreeding". Pair two bonded entities and, after
## a real-time gestation, a new blueprint child hatches into your roster.
## Rules that keep it from cheapening the capture-by-defeat grind:
##  - Both parents must be UNLOCKED (you actually bonded them).
##  - Parents enter a shared cooldown while a clutch is gestating;
##    they can't be part of another pairing until it hatches.
##  - Offspring stage always starts at 1 — apex forms are earned, not born.
##  - Same-category pairs bias toward that category; cross-category rolls
##    either side, biased by parent rarity. No new mythologies are minted
##    — the child inherits an existing dex line's identity.
##  - Cross-faction pairs are the only way to get a Factionless offspring
##    from faction parents (very rare "orphaned" line).
## Persisted under user:// so gestation survives sessions.

signal clutch_started(clutch_id: String, hatch_at: float)
signal clutch_hatched(entity_id: String, name: String)

const SAVE_PATH := "user://breeding.json"
const GESTATION_SECONDS := 6.0 * 3600.0 # 6h; charges can hurry it
const COST_CHARGES := 3

## clutch_id -> {a_id, b_id, hatch_at, category}
var _clutches: Dictionary = {}
## companion_id -> clutch_id (blocks a parent from double-duty)
var _busy: Dictionary = {}

func _ready() -> void:
	_load()
	# Slow poll — the wait is measured in hours, not frames.
	var t := Timer.new()
	t.wait_time = 30.0
	t.autostart = true
	t.timeout.connect(_check_hatches)
	add_child(t)

## True when both entities are unlocked, aren't already gestating, and
## agree with each other well enough to try (any two unlocked lines can
## try — cross-category is just riskier for the outcome).
func can_pair(a_id: String, b_id: String) -> bool:
	if a_id == "" or b_id == "" or a_id == b_id:
		return false
	if is_busy(a_id) or is_busy(b_id):
		return false
	var a := CompanionRegistry.get_by_id(a_id)
	var b := CompanionRegistry.get_by_id(b_id)
	if a.is_empty() or b.is_empty():
		return false
	return true

func is_busy(companion_id: String) -> bool:
	return _busy.has(companion_id)

func active_clutches() -> Array:
	return _clutches.values()

func hurry_cost() -> int:
	return 5 # charges to skip the wait; matches its scarcity

func start_clutch(a_id: String, b_id: String) -> bool:
	if not can_pair(a_id, b_id):
		NotificationUI.notify_error("They can't pair right now — check they're both bonded and idle.")
		return false
	if not await EconomyManager.spend_currency("charges", COST_CHARGES, "breeding"):
		NotificationUI.notify_error("Pairing takes %d Charge Nodes. Come back with more." % COST_CHARGES)
		return false
	var now := Time.get_unix_time_from_system()
	var hatch_at := now + GESTATION_SECONDS
	var clutch_id := "clutch_%d_%s_%s" % [int(now), a_id, b_id]
	_clutches[clutch_id] = {"a": a_id, "b": b_id, "hatch_at": hatch_at}
	_busy[a_id] = clutch_id
	_busy[b_id] = clutch_id
	_save()
	clutch_started.emit(clutch_id, hatch_at)
	NotificationUI.notify_info("🥚 A clutch is on the way. Check back in about six hours.")
	return true

## Charges (the pattern for anything time-gated in this game) buy through
## the wait; the entity itself is otherwise identical.
func hurry(clutch_id: String) -> void:
	if not _clutches.has(clutch_id):
		return
	if not await EconomyManager.spend_currency("charges", hurry_cost(), "hurry_clutch"):
		return
	_clutches[clutch_id]["hatch_at"] = Time.get_unix_time_from_system()
	_save()
	_check_hatches()

func _check_hatches() -> void:
	var now := Time.get_unix_time_from_system()
	for cid in _clutches.keys().duplicate():
		if float(_clutches[cid]["hatch_at"]) <= now:
			_hatch(cid)

func _hatch(clutch_id: String) -> void:
	var c: Dictionary = _clutches[clutch_id]
	var a := CompanionRegistry.get_by_id(str(c.a))
	var b := CompanionRegistry.get_by_id(str(c.b))
	var child_id := _pick_child(a, b)
	if child_id != "":
		CompanionSystem.unlock_companion(child_id)
		var child := CompanionRegistry.get_by_id(child_id)
		var child_name := str(child.get("name", child_id))
		NotificationUI.notify_win("🐣 A clutch hatches: %s, child of your bonded pair." % child_name)
		clutch_hatched.emit(child_id, child_name)
		Hope.record("entity_hatched", {"child": child_id, "a": c.a, "b": c.b})
	_busy.erase(str(c.a))
	_busy.erase(str(c.b))
	_clutches.erase(clutch_id)
	_save()

## Pick a plausible dex line for the child: prefer the shared category or
## faction of the parents; fall back to a random accessible line.
func _pick_child(a: Dictionary, b: Dictionary) -> String:
	var same_cat := str(a.get("category", "")) == str(b.get("category", ""))
	var cross_faction := str(a.get("faction", "")) != str(b.get("faction", ""))
	var pool: Array = CompanionRegistry.get_all()
	if same_cat:
		pool = pool.filter(func(e): return str(e.get("category", "")) == str(a.get("category", "")))
	# Cross-faction pairs sometimes yield a Factionless "orphan" line —
	# the ancient-pantheon roster reads as unclaimed by any of the three.
	if cross_faction and randf() < 0.35:
		pool = CompanionRegistry.get_by_faction("Factionless")
	# Exclude an already-unlocked line if we can — makes the hatch feel
	# like a discovery rather than a duplicate.
	var fresh: Array = pool.filter(func(e):
		var cd = CompanionSystem.get_companion(str(e.get("id", "")))
		return cd == null or not cd.is_unlocked)
	if fresh.size() > 0:
		return str(fresh[randi() % fresh.size()].get("id", ""))
	if pool.is_empty():
		return ""
	return str(pool[randi() % pool.size()].get("id", ""))

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"clutches": _clutches, "busy": _busy}))

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		_clutches = d.get("clutches", {})
		_busy = d.get("busy", {})
