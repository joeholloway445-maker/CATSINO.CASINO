extends Node
## Autoloaded as "PeriliminalRuns". The psychological layer's run manager.
## Rules, exactly as designed:
##  - You don't choose to enter; the Liminal wander timer pulls you in
##    (LayerManager), solo or with whoever wandered with you.
##  - Chunks are procedurally generated on first entry, then STATIC forever —
##    the seed is recorded and every future visitor sees the same space.
##  - Death loses EVERYTHING: entities, inventory, every currency except
##    prestige (experience is the one thing the layer can't take). In a
##    group, one death is everyone's death (shared fate).
##  - Rewards scale hard with depth — the layer pays out in fragments.

signal run_started(party: Array, depth_seed: int)
signal depth_advanced(depth: int, reward_preview: int)
signal run_survived(depth: int, fragments_earned: int)
signal run_wiped(depth: int, victims: Array)

const SEED_LEDGER_PATH := "user://periliminal_seeds.json"
const FRAGMENTS_PER_DEPTH := 3 # compounding below

var active := false
var party: Array[String] = []
var depth := 0
var _run_seed := 0
var _seed_ledger: Dictionary = {} # seed -> {generated_at, deepest}

func _ready() -> void:
	_load_ledger()
	LayerManager.pulled_into_periliminal.connect(func(): begin_run(["local_player"]))

func begin_run(members: Array[String]) -> void:
	if active:
		return
	active = true
	party = members.duplicate()
	depth = 0
	# Generated-then-static: reuse a prior seed if one exists for this party
	# fingerprint, else mint one and record it forever.
	var fingerprint := "|".join(members)
	_run_seed = int(_seed_ledger.get(fingerprint, {}).get("seed", 0))
	if _run_seed == 0:
		_run_seed = randi()
		_seed_ledger[fingerprint] = {"seed": _run_seed, "deepest": 0}
		_save_ledger()
	run_started.emit(party, _run_seed)
	var drive: String = Hope.combat_profile().get("dominant_drive", "curiosity")
	NotificationUI.notify_info("The Periliminal has you. Somewhere in here, Knoll is wearing your %s. 👁️" % drive)

## Each depth cleared multiplies what's waiting at the exit.
func advance_depth() -> void:
	if not active: return
	depth += 1
	var fp := "|".join(party)
	if depth > int(_seed_ledger.get(fp, {}).get("deepest", 0)):
		_seed_ledger[fp]["deepest"] = depth
		_save_ledger()
	depth_advanced.emit(depth, preview_reward())

func preview_reward() -> int:
	# 3, 9, 18, 30, 45... — quadratic-ish so deep runs feel earned.
	return FRAGMENTS_PER_DEPTH * depth * (depth + 1) / 2

## Walking out alive banks the fragments.
func exit_alive() -> void:
	if not active: return
	var earned := preview_reward()
	EconomyManager.earn_currency("fragments", earned, "periliminal_depth_%d" % depth)
	run_survived.emit(depth, earned)
	active = false
	LayerManager.transition_to("liminal", true)

## ANY party member dying wipes the whole party: entities, inventory, and
## every balance except prestige.
func member_died(player_id: String) -> void:
	if not active or player_id not in party:
		return
	run_wiped.emit(depth, party.duplicate())
	for pid in party:
		if pid == "local_player" or pid == PlayerProfile.username:
			_wipe_local_player()
	active = false
	NotificationUI.notify_error("The Periliminal keeps what it kills. Everything is gone.")
	LayerManager.transition_to("subliminal", true)

func _wipe_local_player() -> void:
	# Entities.
	for c in CompanionSystem.roster:
		if c.is_unlocked:
			c.is_unlocked = false
	PlayerProfile.active_companion_ids.clear()
	# Inventory — and the vaults. The Periliminal keeps what it kills.
	if InventoryManager.has_method("clear_all"):
		InventoryManager.clear_all()
	BankManager.periliminal_seize()
	# Currencies — prestige survives; it's the only thing that does.
	for currency in EconomyManager.CURRENCIES.keys():
		if currency == "prestige":
			continue
		var bal: int = EconomyManager.get_balance(currency)
		if bal > 0:
			await EconomyManager.spend_currency(currency, bal, "periliminal_wipe")
	PlayerProfile.profile_updated.emit()

func _save_ledger() -> void:
	var f := FileAccess.open(SEED_LEDGER_PATH, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(_seed_ledger))

func _load_ledger() -> void:
	if not FileAccess.file_exists(SEED_LEDGER_PATH): return
	var f := FileAccess.open(SEED_LEDGER_PATH, FileAccess.READ)
	if not f: return
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary: _seed_ledger = d
