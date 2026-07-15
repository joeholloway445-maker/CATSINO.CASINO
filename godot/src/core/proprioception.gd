extends Node
## Autoloaded as "Proprioception". The avatar's body memory: step cadence,
## turn totals, posture. Everything else in the psychology stack watches
## doors and combat — this watches the walk itself.
##
## It exists for ONE unlabeled thing: the Recall Walk. Seven paces straight
## back, a half-turn to the left, three more paces back, a half-turn to the
## right, kneel (crouch), rise. Performed anywhere in any reality layer it
## returns the player to their own Subliminal, exactly as if they had just
## logged in. Design invariants (law, same weight as the Periliminal rules):
##  - NEVER labeled. No UI, no tutorial, no settings entry, no hint text,
##    no achievement name that gives it away. It spreads by word of mouth
##    or not at all.
##  - The kneel may be held indefinitely — RISING is the trigger. Every
##    other stage times out; the crouch never does.
##  - Works from EVERY layer including the Periliminal: the run simply
##    ends, unbanked and unwiped (escape pays nothing but costs nothing).
##  - First performance ever: a discovery report is queued durably and
##    POSTed to the site (owner notification), and the recall_* quest
##    chain registers + auto-accepts for that player alone — it never
##    appears in anyone else's quest list.

enum Stage { BACK_SEVEN, TURN_LEFT, BACK_THREE, TURN_RIGHT, WAIT_CROUCH, CROUCHED }

const SAVE_PATH := "user://recall.json"
const REPORT_ENDPOINT := "/api/secret/discovery"

const STEP_LENGTH := 0.85        # metres of backward travel per counted pace
const TURN_NEEDED := 2.6         # ~150° — a forgiving 180
const TURN_ABORT := 1.05         # ~60° the wrong way voids the turn
const STAGE_TIMEOUT := 8.0       # seconds without progress (crouch exempt)

var _stage: int = Stage.BACK_SEVEN
var _back_accum := 0.0
var _steps := 0
var _turn_accum := 0.0
var _clock := 0.0
var _last_yaw := 0.0
var _yaw_ready := false

var _found := false
var _layers_recalled: Array = []
var _pending_report: Dictionary = {}

func _ready() -> void:
	_load()
	QuestManager.quest_completed.connect(_on_quest_completed)
	if _found:
		_register_quests()
	if not _pending_report.is_empty():
		_flush_report.call_deferred()

## Fed by ThirdPersonController every physics frame, wherever one exists.
func feed(delta: float, yaw: float, planar_speed: float, backing: bool,
		forwarding: bool, crouching: bool, on_floor: bool) -> void:
	if LayerManager.current_layer_id == "subliminal":
		return # already home
	var dyaw := 0.0
	if _yaw_ready:
		dyaw = wrapf(yaw - _last_yaw, -PI, PI)
	_last_yaw = yaw
	_yaw_ready = true

	if forwarding:
		_reset()
		return

	match _stage:
		Stage.BACK_SEVEN, Stage.BACK_THREE:
			var target := 7 if _stage == Stage.BACK_SEVEN else 3
			if backing and on_floor and planar_speed > 0.5:
				_back_accum += planar_speed * delta
				if int(_back_accum / STEP_LENGTH) > _steps:
					_steps = int(_back_accum / STEP_LENGTH)
					_clock = 0.0
			if _steps >= target:
				# Paces done; the half-turn begins whenever they begin it.
				var want := 1.0 if _stage == Stage.BACK_SEVEN else -1.0
				if dyaw * want > 0.02:
					_stage = Stage.TURN_LEFT if _stage == Stage.BACK_SEVEN else Stage.TURN_RIGHT
					_turn_accum = dyaw
					_clock = 0.0
		Stage.TURN_LEFT, Stage.TURN_RIGHT:
			var turn_sign := 1.0 if _stage == Stage.TURN_LEFT else -1.0
			_turn_accum += dyaw
			if dyaw * turn_sign > 0.01:
				_clock = 0.0
			if _turn_accum * turn_sign >= TURN_NEEDED:
				var was_left := _stage == Stage.TURN_LEFT
				_stage = Stage.BACK_THREE if was_left else Stage.WAIT_CROUCH
				_back_accum = 0.0
				_steps = 0
				_turn_accum = 0.0
				_clock = 0.0
			elif _turn_accum * turn_sign <= -TURN_ABORT:
				_reset()
		Stage.WAIT_CROUCH:
			if crouching:
				_stage = Stage.CROUCHED
				_clock = 0.0
		Stage.CROUCHED:
			if not crouching:
				_perform_recall()
				_reset()
			return # kneel as long as you like — no timeout down here

	_clock += delta
	if _clock > STAGE_TIMEOUT and not (_stage == Stage.BACK_SEVEN and _steps == 0):
		_reset()

func _reset() -> void:
	_stage = Stage.BACK_SEVEN
	_back_accum = 0.0
	_steps = 0
	_turn_accum = 0.0
	_clock = 0.0

## ── The recall itself ────────────────────────────────────────────────────
func _perform_recall() -> void:
	var layer := LayerManager.current_layer_id
	if layer == "periliminal":
		PeriliminalRuns.recall_escape()
	Hope.record("recall_walk", {"layer": layer, "first": not _found})
	# Progress fires BEFORE first-time registration on purpose: quest 1
	# asks for one more performance, so discovery itself never completes it.
	QuestManager.update_progress("recall_walk")
	if layer == "periliminal":
		QuestManager.update_progress("recall_from_periliminal")
	if layer not in _layers_recalled:
		_layers_recalled.append(layer)
		QuestManager.update_progress("recall_distinct_layer")
	if not _found:
		_found = true
		_pending_report = {
			"player": PlayerProfile.username,
			"layer": layer,
			"found_at": Time.get_unix_time_from_system(),
		}
		_register_quests()
		QuestManager.accept("recall_001")
		NotificationUI.notify_win("✦ The world holds its breath. Something very old has been waiting for someone to remember the way out.")
		_flush_report()
	_save()
	NotificationUI.notify_info("You walk out the way you came in. The Subliminal takes you back without a word.")
	LayerManager.transition_to("subliminal", true)

## ── Owner notification (durable until delivered) ─────────────────────────
func _flush_report() -> void:
	if _pending_report.is_empty():
		return
	# CasinoHTTPClient is an autoload singleton (no class_name) — call it directly.
	var response: Dictionary = await CasinoHTTPClient.post_json(REPORT_ENDPOINT, _pending_report)
	if response.get("ok", false):
		_pending_report = {}
		_save()

## ── The chain that makes them the chosen one ─────────────────────────────
## Registered ONLY after discovery, so it can never leak through quest
## lists, and re-registered every boot for the discoverer.
func _register_quests() -> void:
	var quests: Array[Dictionary] = [
		{
			id="recall_001", type=QuestManager.QuestType.SIDE, name="The Way You Came",
			desc="Seven paces withdrawn, a half-turn against the sun, three more, a half-turn home. Kneel. Rise. Nobody taught you that. Do it once more, anywhere, so the world knows it wasn't luck.",
			objectives=[{id="recall_walk", type="recall_walk", desc="Perform the walk again", target=1}],
			rewards={coins=2500, xp=800},
			prereq=[],
		},
		{
			id="recall_002", type=QuestManager.QuestType.SIDE, name="Nobody's Path",
			desc="A door only counts if it opens from more than one room. Walk yourself back from three different realities.",
			objectives=[{id="recall_distinct_layer", type="recall_distinct_layer", desc="Recall from 3 different layers", target=3}],
			rewards={coins=5000, xp=1600},
			prereq=["recall_001"],
		},
		{
			id="recall_003", type=QuestManager.QuestType.SIDE, name="Anchor of the Recalled",
			desc="One place has never let anyone leave early. Let it take you — then leave anyway.",
			objectives=[{id="recall_from_periliminal", type="recall_from_periliminal", desc="Walk out of the Periliminal", target=1}],
			rewards={coins=10000, xp=4000},
			prereq=["recall_002"],
		},
	]
	for q in quests:
		QuestManager.register_quest(q)

func _on_quest_completed(quest_id: String, _rewards: Dictionary) -> void:
	match quest_id:
		"recall_001":
			EconomyManager.earn_prestige(25, "recall_chain")
			EconomyManager.earn_currency("charges", 20, "recall_chain")
			QuestManager.accept("recall_002")
			# Layers already walked out of count toward Nobody's Path.
			if _layers_recalled.size() > 0:
				QuestManager.update_progress("recall_distinct_layer", _layers_recalled.size())
			NotificationUI.notify_win("✦ Chosen, then. The walk has more to show you.")
		"recall_002":
			EconomyManager.earn_prestige(60, "recall_chain")
			EconomyManager.earn_currency("charges", 50, "recall_chain")
			QuestManager.accept("recall_003")
			NotificationUI.notify_win("✦ The layers know your gait now. One of them still thinks it can keep you.")
		"recall_003":
			EconomyManager.earn_prestige(150, "recall_chain")
			EconomyManager.earn_currency("charges", 120, "recall_chain")
			NotificationUI.notify_win("✦ Anchor of the Recalled. Even the Periliminal opens for you — backwards.")

## ── Persistence ──────────────────────────────────────────────────────────
func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({
			"found": _found,
			"layers": _layers_recalled,
			"pending_report": _pending_report,
		}))

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text()) if f else null
	if d is Dictionary:
		_found = bool(d.get("found", false))
		var layers = d.get("layers", [])
		if layers is Array:
			_layers_recalled = layers
		var pending = d.get("pending_report", {})
		if pending is Dictionary:
			_pending_report = pending
