extends Node
class_name RaceAI
# Client-side race visualization AI — drives NPC racers locally for visual effect
# (actual results come from server — this is purely cosmetic)

const AI_NAMES = [
	"Bolt McFlurry", "Nyx Stardash", "Crimson Fang", "Quantum Leap",
	"Shadow Rider", "Ember Swift", "Aqua Blaze", "Storm Paw",
	"Lunar Strike", "Prism Run", "Verdant Dash", "Void Sprint",
]

const AI_FRAMES = [
	"bolt", "veil", "phantom", "tremor", "surge", "zephyr",
	"bastion", "cinder", "soul", "flux", "crimson", "glacial",
]

class RaceParticipant:
	var name: String = ""
	var frame_id: String = ""
	var position: float = 0.0
	var speed: float = 0.0
	var base_speed: float = 0.0
	var is_player: bool = false

var _participants: Array[RaceParticipant] = []
var _race_running: bool = false
var _finish_order: Array[String] = []

signal participant_updated(name: String, position: float)
signal race_finished_visual(finish_order: Array)

func setup_race(player_frame: String, num_ai: int = 3) -> void:
	_participants.clear()
	_finish_order.clear()

	var player = RaceParticipant.new()
	player.name = "YOU"
	player.frame_id = player_frame
	player.base_speed = _frame_base_speed(player_frame)
	player.is_player = true
	_participants.append(player)

	for i in range(mini(num_ai, AI_NAMES.size())):
		var ai = RaceParticipant.new()
		ai.name = AI_NAMES[i]
		ai.frame_id = AI_FRAMES[i % AI_FRAMES.size()]
		ai.base_speed = _frame_base_speed(ai.frame_id)
		_participants.append(ai)

func start_visual_race() -> void:
	_race_running = true

func _process(delta: float) -> void:
	if not _race_running: return

	for p in _participants:
		if p.name in _finish_order: continue
		var variance = randf_range(-0.05, 0.05)
		p.speed = p.base_speed * (1.0 + variance)
		p.position += p.speed * delta
		participant_updated.emit(p.name, p.position)
		if p.position >= 1.0:
			_finish_order.append(p.name)
			if _finish_order.size() == _participants.size():
				_race_running = false
				race_finished_visual.emit(_finish_order)

static func _frame_base_speed(frame_id: String) -> float:
	match frame_id:
		"bolt":    return 0.14
		"veil":    return 0.12
		"zephyr":  return 0.11
		"phantom": return 0.10
		"flux":    return 0.10
		"cinder":  return 0.09
		"crimson": return 0.09
		"soul":    return 0.09
		"tremor":  return 0.08
		"surge":   return 0.08
		"bastion": return 0.07
		"glacial": return 0.07
		_:         return 0.09

func get_player_position() -> float:
	for p in _participants:
		if p.is_player: return p.position
	return 0.0

func get_participants() -> Array[RaceParticipant]:
	return _participants

## Instant, track-aware race resolution for offline/local play. Each racer's
## finish time is the track distance over their frame speed, with per-lap
## variance so slower frames can still steal a podium. Returns
## {position:int, results:[{id, frame_id, time}], player_time:float} sorted
## by finish time. Difficulty widens the AI speed spread so expert tracks
## field genuinely faster opponents.
static func simulate_race(player_frame: String, track: Dictionary) -> Dictionary:
	var laps: int = int(track.get("laps", 3))
	var distance: float = float(track.get("distance", 1200.0))
	var difficulty: String = str(track.get("difficulty", "beginner"))
	var ai_boost := {"beginner": 0.0, "intermediate": 0.01, "expert": 0.02}.get(difficulty, 0.0)
	var num_ai := {"beginner": 3, "intermediate": 5, "expert": 7}.get(difficulty, 3)

	var entries: Array[Dictionary] = []
	var racers := [{"id": "YOU", "frame_id": player_frame, "boost": 0.0}]
	for i in range(num_ai):
		racers.append({
			"id": AI_NAMES[i % AI_NAMES.size()],
			"frame_id": AI_FRAMES[(i * 3 + laps) % AI_FRAMES.size()],
			"boost": ai_boost,
		})

	for r in racers:
		var speed: float = _frame_base_speed(r["frame_id"]) + r["boost"]
		var time := 0.0
		for lap in range(laps):
			time += (distance / float(laps)) / (speed * 100.0) * randf_range(0.92, 1.08)
		entries.append({"id": r["id"], "frame_id": r["frame_id"], "time": snappedf(time, 0.01)})

	entries.sort_custom(func(a, b): return a["time"] < b["time"])
	var player_pos := entries.size()
	var player_time := 0.0
	for i in range(entries.size()):
		if entries[i]["id"] == "YOU":
			player_pos = i + 1
			player_time = entries[i]["time"]
			break
	return {"position": player_pos, "results": entries, "player_time": player_time}
