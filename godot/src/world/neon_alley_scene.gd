extends Node

signal race_finished(place: int, prize_coins: int)

const ENTRY_FEE: int = 50
const CHECKPOINT_COUNT: int = 8

var _ai_racers: Array[CharacterData] = []
var _track_checkpoints: Array[Vector2] = []
var _racer_tweens: Array[Tween] = []
var _particle_emitters: Array[GPUParticles2D] = []
var _bet: int = ENTRY_FEE

func _ready() -> void:
	_spawn_ai_racers()
	_setup_track()
	_start_ambient_particles()

func _spawn_ai_racers() -> void:
	var races = ["tabby", "siamese", "persian", "maine_coon", "bengal", "sphynx"]
	for i in range(6):
		var racer: CharacterData = CharacterData.new()
		racer.character_name = "Racer_%d" % i
		racer.race = races[i % races.size()]
		racer.spd = randi_range(60, 95)
		racer.lck = randi_range(20, 60)
		racer.pow = randi_range(10, 40)
		racer.res = randi_range(10, 40)
		racer.level = randi_range(1, 10)
		_ai_racers.append(racer)

func _setup_track() -> void:
	_track_checkpoints.clear()
	var track_points = [
		Vector2(100, 300), Vector2(300, 100), Vector2(600, 80),
		Vector2(900, 100), Vector2(1100, 300), Vector2(1000, 500),
		Vector2(700, 600), Vector2(400, 550)
	]
	_track_checkpoints = track_points

func _start_ambient_particles() -> void:
	for i in range(4):
		var particles = GPUParticles2D.new()
		particles.amount = 50
		particles.emitting = true
		particles.position = Vector2(randf_range(0, 1200), randf_range(0, 700))
		var mat = ParticleProcessMaterial.new()
		mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		mat.emission_sphere_radius = 30.0
		mat.initial_velocity_min = 20.0
		mat.initial_velocity_max = 80.0
		mat.color = Color(randf(), randf_range(0.5, 1.0), 1.0, 0.8)
		particles.process_material = mat
		add_child(particles)
		_particle_emitters.append(particles)

func start_race(player_char: CharacterData) -> void:
	if not await EconomyManager.spend_coins(ENTRY_FEE):
		push_warning("NeonAlley: Not enough coins for entry fee")
		return
	_bet = ENTRY_FEE
	var all_chars: Array[CharacterData] = []
	all_chars.append(player_char)
	all_chars.append_array(_ai_racers)
	var scores: Array[Dictionary] = []
	for c in all_chars:
		var spd_score: float = c.spd * 1.0
		var lck_variance: float = (randf() - 0.5) * (c.lck * 0.3)
		scores.append({"char": c, "score": spd_score + lck_variance})
	scores.sort_custom(func(a, b): return a["score"] > b["score"])
	var place: int = 1
	for i in range(scores.size()):
		if scores[i]["char"] == player_char:
			place = i + 1
			break
	await _animate_race(scores)
	var prize: int = 0
	match place:
		1: prize = _bet * 5
		2: prize = _bet * 2
		3: prize = _bet * 1
	if prize > 0:
		EconomyManager.add_coins(prize)
	race_finished.emit(place, prize)

func _animate_race(scores: Array[Dictionary]) -> void:
	var duration: float = 3.0 + randf() * 2.0
	var tween = create_tween()
	tween.set_parallel(true)
	for i in range(scores.size()):
		var delay: float = i * 0.1
		tween.tween_interval(delay + duration)
	await tween.finished
