class_name SensoriumAmbience
extends Node
## Live-synthesized ambient bed driven by IdentityLens.sound_profile():
## the frame's musical mode picks the scale, its tempo paces the notes,
## its timbre shapes the waveform, and the identity seed picks the exact
## phrase — so even two same-frame players hear different voicings.
## Sits under MusicManager's tracks (quiet, -18dB) as the world's own hum;
## the Suno tracks carry the melody, this carries YOUR build's fingerprint.
## Add to any layer scene: add_child(SensoriumAmbience.new()).

const MODES := {
	"ionian":     [0, 2, 4, 5, 7, 9, 11],
	"dorian":     [0, 2, 3, 5, 7, 9, 10],
	"phrygian":   [0, 1, 3, 5, 7, 8, 10],
	"lydian":     [0, 2, 4, 6, 7, 9, 11],
	"mixolydian": [0, 2, 4, 5, 7, 9, 10],
	"aeolian":    [0, 2, 3, 5, 7, 8, 10],
	"locrian":    [0, 1, 3, 5, 6, 8, 10],
	"chromatic":  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
}
const BASE_HZ := 110.0 # A2

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _rng := RandomNumberGenerator.new()
var _scale: Array = MODES["ionian"]
var _note_seconds := 1.0
var _timbre := "pad"
var _phase := 0.0
var _note_hz := BASE_HZ
var _note_t := 0.0
var _mix_rate := 22050.0

func _ready() -> void:
	var profile: Dictionary = IdentityLens.sound_profile()
	_rng.seed = int(profile.voicing_seed)
	_scale = MODES.get(profile.mode, MODES["ionian"])
	_note_seconds = 60.0 / maxf(float(profile.tempo), 30.0) * 2.0 # half-time feel
	_timbre = str(profile.timbre).split("+")[0]

	var gen := AudioStreamGenerator.new()
	gen.mix_rate = _mix_rate
	gen.buffer_length = 0.5
	_player = AudioStreamPlayer.new()
	_player.stream = gen
	_player.volume_db = -18.0
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback()
	_pick_note()

func _pick_note() -> void:
	var degree: int = _scale[_rng.randi() % _scale.size()]
	var octave: int = _rng.randi() % 2
	_note_hz = BASE_HZ * pow(2.0, (degree + octave * 12) / 12.0)
	_note_t = 0.0

func _process(delta: float) -> void:
	if _playback == null:
		return
	var frames := _playback.get_frames_available()
	for i in range(frames):
		var dt := 1.0 / _mix_rate
		_note_t += dt
		if _note_t >= _note_seconds:
			_pick_note()
		_phase = fmod(_phase + _note_hz * dt, 1.0)
		# Envelope: slow attack, long release — ambience, not melody.
		var env := sin(PI * clampf(_note_t / _note_seconds, 0.0, 1.0))
		var s := _sample(_phase) * env * 0.35
		_playback.push_frame(Vector2(s, s))

func _sample(phase: float) -> float:
	match _timbre:
		"saw", "pulse":
			return 2.0 * phase - 1.0
		"pluck", "bell", "chime", "glass", "anvil", "bone":
			# bright: fundamental + strong 3rd harmonic
			return sin(TAU * phase) * 0.7 + sin(TAU * phase * 3.0) * 0.3
		"sub", "drone", "drum", "roar":
			# dark: fundamental an octave down, softened
			return sin(TAU * phase * 0.5)
		"hiss", "crackle":
			return sin(TAU * phase) * 0.5 + _rng.randf_range(-0.2, 0.2)
		_: # breath/pad/choir/flute/horn/brass — soft sine stack
			return sin(TAU * phase) * 0.8 + sin(TAU * phase * 2.0) * 0.2
