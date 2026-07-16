extends Node
## Autoloaded as "DungeonRuns". Gate 6 instanced dungeons: same generated-
## then-static seed ledger as PeriliminalRuns, but death ejects to the hub
## with NO wipe. Entry doors are DungeonEntrance nodes in each DFW hub.

signal run_started(dungeon_id: String, seed: int)
signal run_cleared(dungeon_id: String, depth: int)
signal run_ejected(dungeon_id: String, reason: String)

const LEDGER_PATH := "user://dungeon_seeds.json"

var active := false
var dungeon_id := ""
var depth := 0
var _seed := 0
var _ledger: Dictionary = {}

func _ready() -> void:
	_load()

## Stable seed for the active (or named) dungeon ledger entry.
func run_seed(p_dungeon_id: String = "") -> int:
	if p_dungeon_id == "" or p_dungeon_id == dungeon_id:
		return _seed
	return int(_ledger.get(p_dungeon_id, {}).get("seed", 0))

## Begin (or resume) a dungeon. Returns the stable seed.
func begin(p_dungeon_id: String) -> int:
	dungeon_id = p_dungeon_id
	active = true
	depth = 0
	_seed = int(_ledger.get(p_dungeon_id, {}).get("seed", 0))
	if _seed == 0:
		_seed = randi()
		_ledger[p_dungeon_id] = {"seed": _seed, "deepest": 0, "clears": 0}
		_save()
	# Suppress Periliminal wipe while this flag is up — LayerWorld death
	# routes through eject() instead of PeriliminalRuns.member_died.
	Engine.set_meta("dungeon_no_wipe", true)
	if MusicManager != null and MusicManager.has_method("play_context"):
		MusicManager.play_context("liminal")
	run_started.emit(dungeon_id, _seed)
	return _seed

func advance_depth() -> void:
	if not active:
		return
	depth += 1
	var entry: Dictionary = _ledger.get_or_add(dungeon_id, {"seed": _seed, "deepest": 0, "clears": 0})
	if depth > int(entry.get("deepest", 0)):
		entry["deepest"] = depth
		_save()

## Clear at depth 3+ — bank a soft reward and return to sanctuary hub.
func try_clear() -> void:
	if not active or depth < 3:
		return
	var entry: Dictionary = _ledger.get_or_add(dungeon_id, {"seed": _seed, "deepest": 0, "clears": 0})
	entry["clears"] = int(entry.get("clears", 0)) + 1
	_save()
	var reward := 40 + depth * 25
	EconomyManager.earn_currency("fragments", reward, "dungeon_clear")
	EconomyManager.earn_prestige(20, "dungeon_clear")
	QuestManager.update_progress("clear_dungeon")
	run_cleared.emit(dungeon_id, depth)
	NotificationUI.notify_win("Dungeon cleared — +%d fragments. No wipe. Ever." % reward)
	_end("cleared")
	LayerManager.transition_to("supraliminal", true)

## Death / quit — eject, keep inventory and currencies.
func eject(reason: String = "death") -> void:
	if not active:
		return
	run_ejected.emit(dungeon_id, reason)
	NotificationUI.notify_info("Ejected from dungeon (%s). Gear intact." % reason)
	_end(reason)
	# Skip layer hop during headless smokes.
	if Engine.has_meta("headless_smoke"):
		return
	if LayerManager != null and LayerManager.has_method("transition_to"):
		LayerManager.transition_to("supraliminal", true)

func _end(_reason: String) -> void:
	active = false
	dungeon_id = ""
	depth = 0
	if Engine.has_meta("dungeon_no_wipe"):
		Engine.remove_meta("dungeon_no_wipe")

func _save() -> void:
	var f := FileAccess.open(LEDGER_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_ledger))

func _load() -> void:
	if not FileAccess.file_exists(LEDGER_PATH):
		return
	var f := FileAccess.open(LEDGER_PATH, FileAccess.READ)
	if not f:
		return
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		_ledger = d
