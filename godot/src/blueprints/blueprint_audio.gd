class_name BlueprintAudio
## Synthesizes a blueprint's sound signature live via AudioStreamGenerator —
## no samples, so every combination of waveform/pitch/attack/decay/wobble is
## a genuinely unique voice. Used by the Forge's preview button and by
## SkillVFX/weapon swings at runtime.

const MIX_RATE := 22050.0

## Fire-and-forget: plays the blueprint's audio signature at `parent`,
## frees itself when done. Returns the player so callers can reposition it.
static func play(parent: Node, bp: Dictionary, volume_db: float = -8.0) -> AudioStreamPlayer:
	if parent == null or not is_instance_valid(parent) or parent.get_tree() == null:
		return null
	var a: Dictionary = bp.get("audio", {})
	if a.is_empty():
		return null
	var player := AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	var attack: float = float(a.get("attack", 0.03))
	var decay: float = float(a.get("decay", a.get("ring", 0.5)))
	gen.buffer_length = attack + decay + 0.1
	player.stream = gen
	player.volume_db = volume_db
	parent.add_child(player)
	player.play()
	_fill(player.get_stream_playback(), a)
	# Free once the tail is done — instance id so a freed player never trips the lambda.
	var pid := player.get_instance_id()
	parent.get_tree().create_timer(attack + decay + 0.3).timeout.connect(func():
		var n := instance_from_id(pid)
		if n != null:
			n.queue_free())
	return player

static func _fill(pb: AudioStreamGeneratorPlayback, a: Dictionary) -> void:
	if pb == null:
		return
	var pitch: float = float(a.get("pitch", 1.0))
	var attack: float = float(a.get("attack", 0.03))
	var decay: float = float(a.get("decay", a.get("ring", 0.5)))
	var wobble: float = float(a.get("wobble", 0.0))
	var wave: String = str(a.get("waveform", "sine"))
	var base_hz := 220.0 * pitch
	var frames := int(MIX_RATE * (attack + decay))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(wave) + int(pitch * 1000.0)
	var phase := 0.0
	for i in mini(frames, pb.get_frames_available()):
		var t := float(i) / MIX_RATE
		# Envelope: linear attack, exponential decay.
		var env: float
		if t < attack:
			env = t / attack
		else:
			env = exp(-3.0 * (t - attack) / maxf(decay, 0.01))
		var hz := base_hz * (1.0 + sin(t * 6.0 * TAU) * wobble * 0.06)
		phase += hz / MIX_RATE
		var s := _sample(wave, phase, rng)
		pb.push_frame(Vector2.ONE * s * env * 0.6)

static func _sample(wave: String, phase: float, rng: RandomNumberGenerator) -> float:
	var p := fmod(phase, 1.0)
	match wave:
		"sine": return sin(p * TAU)
		"square": return 1.0 if p < 0.5 else -1.0
		"saw": return 2.0 * p - 1.0
		"noise": return rng.randf_range(-1.0, 1.0)
		"choir":
			# Three detuned sines — cheap shimmer.
			return (sin(p * TAU) + sin(p * TAU * 1.01) * 0.6 + sin(p * TAU * 0.99) * 0.6) / 2.2
		# Weapon/armor material timbres: mixtures tuned to read as physical.
		"metal": return (sin(p * TAU) * 0.5 + sin(p * TAU * 2.76) * 0.35 + sin(p * TAU * 5.4) * 0.15)
		"glass": return (sin(p * TAU * 3.0) * 0.6 + sin(p * TAU * 7.1) * 0.4)
		"wood": return (sin(p * TAU) * 0.8 + rng.randf_range(-0.2, 0.2))
		"void": return sin(p * TAU * 0.5) * 0.7 + sin(p * TAU * 0.503) * 0.7
		"chime": return (sin(p * TAU * 2.0) * 0.5 + sin(p * TAU * 2.99) * 0.3 + sin(p * TAU * 4.1) * 0.2)
		"leather": return rng.randf_range(-0.4, 0.4) * sin(p * TAU * 0.5)
		"cloth": return rng.randf_range(-0.15, 0.15)
		"chitin": return (1.0 if p < 0.3 else -0.4) * 0.7
		"silence": return 0.0
		_: return sin(p * TAU)
