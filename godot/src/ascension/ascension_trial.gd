extends Node
## Autoloaded as "AscensionTrial". Ascension is EARNED — a three-round
## trial, exactly as designed:
##
##  ROUND 1 — Survival waves. Both frames allowed (old bar + candidate
##            frame's line temporarily granted). Outlast the waves.
##  ROUND 2 — NEW frame only, one-on-one against your SHADOW SELF, who
##            fights with your OLD frame. It knows your old habits.
##  ROUND 3 — OLD frame only, against your shadow using your NEW frame.
##            Beat your future with your past.
##
##  LOSE any round: you drop ALL inventory and wait FOUR HOURS — one
##  server day — before retrying. WIN all three: the second frame is
##  yours and the world re-tunes.
##
##  The shadow is KNOLL wearing your face: it fights with everything Hope
##  has learned about you (Hope.combat_profile feeds its stat bias).

signal trial_started(candidate_frame: String)
signal round_won(round_number: int)
signal trial_won(candidate_frame: String)
signal trial_lost(round_number: int)

const SAVE_PATH := "user://ascension_trial.json"
const LOCKOUT_SECONDS := 4 * 3600 # four hours = one server day

var candidate_frame := ""
var current_round := 0
var _lockout_until := 0

func _ready() -> void:
	_load()

func locked_out() -> bool:
	return Time.get_unix_time_from_system() < _lockout_until

func lockout_remaining() -> int:
	return maxi(_lockout_until - int(Time.get_unix_time_from_system()), 0)

## Entry: level 50+, Champion title held, not locked out.
func begin(frame_id: String) -> bool:
	if PlayerProfile.level < 50 or CrownManager.title_of("local_player") == "":
		NotificationUI.notify_error("The trial opens to Champions of level 50.")
		return false
	if locked_out():
		NotificationUI.notify_error("The trial remembers your last failure. %d minutes until the server day turns." % (lockout_remaining() / 60))
		return false
	if PlayerProfile.ascended_frame != "":
		return false
	candidate_frame = frame_id
	current_round = 1
	trial_started.emit(frame_id)
	get_tree().change_scene_to_file("res://scenes/ascension/trial_arena.tscn")
	return true

## Round rules the arena scene reads.
func round_rules() -> Dictionary:
	match current_round:
		1: return {"mode": "waves", "player_frames": [PlayerProfile.selected_frame, candidate_frame],
			"desc": "Round I — survive the waves. Both frames answer you tonight."}
		2: return {"mode": "duel", "player_frames": [candidate_frame],
			"shadow_frame": PlayerProfile.selected_frame,
			"desc": "Round II — the new frame only. Your shadow wears your old one. It remembers everything."}
		3: return {"mode": "duel", "player_frames": [PlayerProfile.selected_frame],
			"shadow_frame": candidate_frame,
			"desc": "Round III — the old frame, one last time. Your shadow already lives in your future."}
		_: return {}

func win_round() -> void:
	round_won.emit(current_round)
	if current_round >= 3:
		_complete()
	else:
		current_round += 1
		NotificationUI.notify_win("Round %d taken. %s" % [current_round - 1, round_rules().desc])
		get_tree().reload_current_scene()

func _complete() -> void:
	var frame := candidate_frame
	candidate_frame = ""
	current_round = 0
	PlayerProfile.set_ascended_frame(frame)
	trial_won.emit(frame)
	NotificationUI.notify_win("🌗 ASCENDED. The trial is over; the duet begins.")
	MusicManager.play_context("victory", false)
	get_tree().change_scene_to_file("res://scenes/ui/ascension.tscn")

## Failure: drop ALL inventory, four-hour lockout, shown the door.
func lose(round_number: int) -> void:
	InventoryManager.clear_all()
	_lockout_until = int(Time.get_unix_time_from_system()) + LOCKOUT_SECONDS
	_save()
	candidate_frame = ""
	current_round = 0
	trial_lost.emit(round_number)
	NotificationUI.notify_error("💀 The trial keeps your inventory and your pride. Return in four hours — one server day.")
	get_tree().change_scene_to_file("res://scenes/ui/ascension.tscn")

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify({"lockout_until": _lockout_until}))

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f: return
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary: _lockout_until = int(d.get("lockout_until", 0))
