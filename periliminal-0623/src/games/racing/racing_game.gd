extends Node2D

signal race_finished(place: int, time: float)

const BASE_SPEED: float = 200.0
const MAX_SPEED: float = 600.0
const ACCELERATION: float = 150.0
const BRAKE_FORCE: float = 300.0
const STEER_SPEED: float = 3.0
const LAP_COUNT: int = 3
const OPPONENT_COUNT: int = 4

var _player_char: CharacterData
var _player_speed: float = 0.0
var _player_angle: float = 0.0
var _player_pos: Vector2 = Vector2(300, 400)
var _current_lap: int = 0
var _lap_time: float = 0.0
var _total_time: float = 0.0
var _race_active: bool = false
var _checkpoint_index: int = 0
var _place: int = 1

var _opponent_positions: Array[Vector2] = []
var _opponent_speeds: Array[float] = []
var _opponent_angles: Array[float] = []
var _opponent_chars: Array[CharacterData] = []

const CHECKPOINTS: Array[Vector2] = [
	Vector2(400, 200), Vector2(800, 150), Vector2(1100, 300),
	Vector2(1050, 550), Vector2(700, 650), Vector2(300, 600), Vector2(150, 400)
]

func _ready() -> void:
	_spawn_opponents()

func setup(player: CharacterData) -> void:
	_player_char = player
	_player_pos = Vector2(300, 400)
	_player_angle = 0.0
	_player_speed = 0.0
	_current_lap = 0
	_total_time = 0.0
	_lap_time = 0.0
	_checkpoint_index = 0
	_race_active = true

func _spawn_opponents() -> void:
	for i in range(OPPONENT_COUNT):
		var opp = CharacterData.new()
		opp.character_name = "Racer_%d" % i
		opp.spd = randi_range(50, 90)
		opp.lck = randi_range(20, 50)
		_opponent_chars.append(opp)
		_opponent_positions.append(Vector2(300 + (i + 1) * 40, 400 + i * 20))
		_opponent_speeds.append(0.0)
		_opponent_angles.append(0.0)

func _physics_process(delta: float) -> void:
	if not _race_active:
		return
	_total_time += delta
	_lap_time += delta
	_process_player_input(delta)
	_process_opponents(delta)
	_check_checkpoints()

func _process_player_input(delta: float) -> void:
	var spd_multiplier: float = 1.0 + (_player_char.spd if _player_char else 50) / 200.0
	if Input.is_key_pressed(KEY_W):
		_player_speed = move_toward(_player_speed, MAX_SPEED * spd_multiplier, ACCELERATION * delta)
	elif Input.is_key_pressed(KEY_S):
		_player_speed = move_toward(_player_speed, 0.0, BRAKE_FORCE * delta)
	else:
		_player_speed = move_toward(_player_speed, 0.0, ACCELERATION * 0.3 * delta)
	if Input.is_key_pressed(KEY_A):
		_player_angle -= STEER_SPEED * delta * (_player_speed / MAX_SPEED)
	if Input.is_key_pressed(KEY_D):
		_player_angle += STEER_SPEED * delta * (_player_speed / MAX_SPEED)
	var direction = Vector2(cos(_player_angle), sin(_player_angle))
	_player_pos += direction * _player_speed * delta
	queue_redraw()

func _process_opponents(delta: float) -> void:
	for i in range(_opponent_chars.size()):
		var opp = _opponent_chars[i]
		var top_speed: float = BASE_SPEED + opp.spd * 2.0
		_opponent_speeds[i] = move_toward(_opponent_speeds[i], top_speed, ACCELERATION * delta)
		var target: Vector2 = CHECKPOINTS[_checkpoint_index % CHECKPOINTS.size()]
		var to_target: Vector2 = (target - _opponent_positions[i]).normalized()
		var target_angle: float = to_target.angle()
		_opponent_angles[i] = lerp_angle(_opponent_angles[i], target_angle, 2.0 * delta)
		var dir = Vector2(cos(_opponent_angles[i]), sin(_opponent_angles[i]))
		_opponent_positions[i] += dir * _opponent_speeds[i] * delta

func _check_checkpoints() -> void:
	if CHECKPOINTS.is_empty():
		return
	var next_cp: Vector2 = CHECKPOINTS[_checkpoint_index % CHECKPOINTS.size()]
	if _player_pos.distance_to(next_cp) < 80.0:
		_checkpoint_index += 1
		if _checkpoint_index % CHECKPOINTS.size() == 0:
			_current_lap += 1
			_lap_time = 0.0
			if _current_lap >= LAP_COUNT:
				_finish_race()

func _finish_race() -> void:
	_race_active = false
	_place = _calculate_place()
	var prize_map: Dictionary = {1: 500, 2: 200, 3: 100, 4: 50}
	var prize: int = prize_map.get(_place, 0)
	if prize > 0:
		EconomyManager.add_coins(prize)
	race_finished.emit(_place, _total_time)

func _calculate_place() -> int:
	var player_progress: float = _checkpoint_index
	var ahead: int = 0
	for i in range(_opponent_chars.size()):
		var opp_progress: float = _opponent_positions[i].distance_to(CHECKPOINTS[0])
		if opp_progress < player_progress:
			ahead += 1
	return ahead + 1

func _draw() -> void:
	draw_circle(_player_pos, 12.0, Color.CYAN)
	for i in range(_opponent_positions.size()):
		draw_circle(_opponent_positions[i], 10.0, Color.RED)
	for cp in CHECKPOINTS:
		draw_circle(cp, 6.0, Color.YELLOW)
