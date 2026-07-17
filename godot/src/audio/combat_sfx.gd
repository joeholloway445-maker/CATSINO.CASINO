class_name CombatSfx
## Fire-and-forget combat one-shots for Gate 5/7 juice. Prefers AssetLibrary
## sound slots (`assets/audio/<slot>.*` — Gate 7 packs); synthesizes a short
## WAV when a slot is empty so cast / hit / boss beats are never silent.
## Called from SkillVFX and WorldEntity so every cast host inherits audio.

const MIX_RATE := 22050
const SLOTS := [
	"skill_cast", "skill_hit", "skill_ult", "skill_shield",
	"boss_spawn", "boss_phase", "boss_death",
]

## Resolve a slot to a playable stream (pack preferred, synth fallback).
static func resolve(slot: String) -> AudioStream:
	var stream := AssetLibrary.sound(slot)
	if stream == null:
		stream = _synth(slot)
	return stream

## Play `slot` attached to a scene-stable anchor under `host`'s tree.
## Pass a world-space `at` for positional 3D; omit (INF) for non-positional.
static func play(host: Node, slot: String, at: Vector3 = Vector3.INF,
		volume_db: float = -6.0) -> void:
	if host == null or not is_instance_valid(host):
		return
	# setup_boss / early callers may fire before the node is in the tree —
	# defer so AudioStreamPlayer actually mixes.
	if not host.is_inside_tree():
		host.tree_entered.connect(
			func(): play(host, slot, at, volume_db), CONNECT_ONE_SHOT)
		return
	var stream := resolve(slot)
	if stream == null:
		return
	# Fresh duplicate per play so concurrent casts don't share cursor state.
	var playable: AudioStream = stream.duplicate() if stream.has_method("duplicate") else stream
	if playable is AudioStreamOggVorbis:
		(playable as AudioStreamOggVorbis).loop = false
	elif playable is AudioStreamWAV:
		(playable as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
	var anchor := _anchor(host)
	if anchor == null or not is_instance_valid(anchor):
		return
	var bus := "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
	if at != Vector3.INF:
		var p3 := AudioStreamPlayer3D.new()
		p3.stream = playable
		p3.volume_db = volume_db
		p3.bus = bus
		p3.max_distance = 48.0
		anchor.add_child(p3)
		p3.global_position = at
		p3.finished.connect(p3.queue_free)
		p3.play()
		_safety_free(anchor, p3.get_instance_id(), 3.0)
	else:
		var p := AudioStreamPlayer.new()
		p.stream = playable
		p.volume_db = volume_db
		p.bus = bus
		anchor.add_child(p)
		p.finished.connect(p.queue_free)
		p.play()
		_safety_free(anchor, p.get_instance_id(), 3.0)

## Timer free by instance id so lambdas never capture a freed Node.
static func _safety_free(anchor: Node, id: int, seconds: float) -> void:
	if anchor == null or not is_instance_valid(anchor):
		return
	var tree := anchor.get_tree()
	if tree == null:
		return
	tree.create_timer(seconds).timeout.connect(func():
		var n := instance_from_id(id)
		if n != null:
			n.queue_free())

static func _anchor(host: Node) -> Node:
	var tree := host.get_tree()
	if tree != null and tree.root != null:
		return tree.root
	return host

## Procedural one-shot per combat slot archetype — 16-bit mono WAV.
static func _synth(slot: String) -> AudioStreamWAV:
	var seconds := 0.28
	match slot:
		"skill_ult", "boss_spawn", "boss_death":
			seconds = 0.75
		"boss_phase":
			seconds = 0.55
		"skill_shield":
			seconds = 0.45
		"skill_hit":
			seconds = 0.16
		_:
			seconds = 0.28
	var frames := int(MIX_RATE * seconds)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(slot)
	var phase := 0.0
	var phase2 := 0.0
	for i in frames:
		var t := float(i) / MIX_RATE
		var env := _envelope(slot, t, seconds)
		var s := 0.0
		match slot:
			"skill_cast":
				# Rising whoosh + bright chirp.
				phase += (420.0 + t * 900.0) / MIX_RATE
				phase2 += 90.0 / MIX_RATE
				s = sin(phase * TAU) * 0.45 + sin(phase2 * TAU) * 0.2
				s += rng.randf_range(-0.15, 0.15) * (1.0 - t / seconds)
			"skill_hit":
				# Tight noise punch with a mid click.
				phase += 180.0 / MIX_RATE
				s = rng.randf_range(-1.0, 1.0) * 0.55 * exp(-t * 28.0)
				s += sin(phase * TAU) * 0.35 * exp(-t * 40.0)
			"skill_ult":
				# Low boom + descending sweep.
				phase += (140.0 - t * 80.0) / MIX_RATE
				phase2 += (700.0 - t * 500.0) / MIX_RATE
				s = sin(phase * TAU) * 0.55 + sin(phase2 * TAU) * 0.25
				s += rng.randf_range(-0.2, 0.2) * exp(-t * 4.0)
			"skill_shield":
				# Glassy shimmer.
				phase += 660.0 / MIX_RATE
				phase2 += 990.0 / MIX_RATE
				s = (sin(phase * TAU) * 0.4 + sin(phase2 * TAU) * 0.3) * (0.7 + 0.3 * sin(t * 28.0))
			"boss_spawn":
				# Deep horn + rumble entrance.
				phase += 55.0 / MIX_RATE
				phase2 += 82.5 / MIX_RATE
				s = sin(phase * TAU) * 0.5 + sin(phase2 * TAU) * 0.35
				s += rng.randf_range(-0.12, 0.12) * 0.5
			"boss_phase":
				# Aggressive ascending stinger.
				phase += (90.0 + t * 220.0) / MIX_RATE
				phase2 += (180.0 + t * 340.0) / MIX_RATE
				s = sin(phase * TAU) * 0.45 + sin(phase2 * TAU) * 0.35
				s += (1.0 if fmod(phase, 1.0) < 0.3 else -0.4) * 0.15
			"boss_death":
				# Crash + long decay.
				phase += (70.0 - t * 40.0) / MIX_RATE
				s = sin(phase * TAU) * 0.4
				s += rng.randf_range(-1.0, 1.0) * 0.45 * exp(-t * 3.5)
				s += sin((phase + 0.37) * TAU * 2.3) * 0.2 * exp(-t * 2.0)
			_:
				phase += 220.0 / MIX_RATE
				s = sin(phase * TAU) * 0.35
		s *= env
		var v := int(clampf(s, -1.0, 1.0) * 32767.0)
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return wav

static func _envelope(slot: String, t: float, seconds: float) -> float:
	var attack := 0.01
	var decay_start := seconds * 0.35
	match slot:
		"skill_hit":
			attack = 0.005
			decay_start = 0.02
		"skill_shield":
			attack = 0.04
			decay_start = seconds * 0.5
		"boss_spawn", "boss_death":
			attack = 0.05
			decay_start = seconds * 0.4
		"skill_ult":
			attack = 0.02
			decay_start = seconds * 0.3
	var a := clampf(t / attack, 0.0, 1.0)
	var d := 1.0
	if t > decay_start:
		d = clampf(1.0 - (t - decay_start) / maxf(seconds - decay_start, 0.01), 0.0, 1.0)
		d *= d
	return a * d
