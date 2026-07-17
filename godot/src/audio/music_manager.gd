extends Node
## Autoloaded as "MusicManager". The soundtrack layer — original tracks
## (Suno-produced, more coming over time) mapped to the contexts they were
## written for, with crossfades. "Periliminal Space" is THE theme song.
##
## Context map:
##   theme     -> Periliminal Space (title/main menu — the game's anthem)
##   liminal   -> noclip (falling out of reality; also the Periliminal
##                pull warning uses it — the walls thinning IS this song)
##   racing    -> Ridin' Tonight (race lobby/track)
##   overworld -> Taillights Fade (night driving across the Metroplex)
##   victory   -> Take a Bow for Blake (tournament/championship wins)
##
## New Suno tracks: drop the .mp3 in assets/music/ and add one line to
## TRACKS (or append to a context's list — multiple tracks per context
## rotate via the identity seed so different builds hear different cuts).

const TRACKS: Dictionary = {
	"theme":     ["res://assets/music/periliminal_space.mp3"],
	"liminal":   ["res://assets/music/noclip.mp3"],
	"racing":    ["res://assets/music/ridin_tonight.mp3"],
	"overworld": ["res://assets/music/taillights_fade.mp3"],
	"victory":   ["res://assets/music/take_a_bow_for_blake.mp3"],
	# The PVXC gets NO track by design — nothing comforting down there.
	# An empty list fades the music out; SensoriumAmbience carries the room.
	"pvxc":      [],
	# Next tracks wanted (empty = silence fallback until dropped in):
	#   ascension -> the trial arena, all 3 rounds — wants tension that
	#                doesn't resolve until win/lose calls victory/theme.
	#   sanctuary -> hub interiors (Arlington/Dallas/Fort Worth/Denton) —
	#                distinct from the open-wilds "overworld" track so a
	#                hub audibly feels safe the moment you cross into it.
	# Interim beds until dedicated Suno cuts land — same files, distinct
	# contexts so hub entry / trial arenas already crossfade correctly.
	"ascension": ["res://assets/music/noclip.mp3"],
	"sanctuary": ["res://assets/music/taillights_fade.mp3"],
}

## Which context each reality layer wants when you arrive in it.
const LAYER_CONTEXT: Dictionary = {
	"hyperliminal": "theme",
	"liminal": "liminal",
	"supraliminal": "overworld",
	"periliminal": "liminal",
	"subliminal": "theme",
	"extraliminal": "overworld",
}

const FADE_SECONDS := 2.0

var _a: AudioStreamPlayer
var _b: AudioStreamPlayer
var _active: AudioStreamPlayer
var _current_context := ""

func _ready() -> void:
	_a = AudioStreamPlayer.new()
	_b = AudioStreamPlayer.new()
	for p in [_a, _b]:
		p.bus = "Music" if AudioServer.get_bus_index("Music") != -1 else "Master"
		add_child(p)
	_active = _a
	LayerManager.layer_changed.connect(func(_from, to):
		play_context(LAYER_CONTEXT.get(to, "theme")))
	TournamentManager.tournament_finished.connect(func(winner, _s):
		if winner.get("is_player", false):
			play_context("victory", false))
	# The theme starts with the game.
	play_context("theme")

## Play the track for a context, crossfading from whatever's on. `loop`
## false = play once then return to the previous context (victory stingers).
func play_context(context: String, loop: bool = true) -> void:
	if context == _current_context:
		return
	var paths: Array = TRACKS.get(context, [])
	if paths.is_empty():
		# Silence is a context too: fade out whatever's playing.
		_current_context = context
		var fade := create_tween()
		fade.tween_property(_active, "volume_db", -40.0, FADE_SECONDS)
		fade.tween_callback(_active.stop)
		return
	# Multiple tracks per context rotate deterministically per build —
	# another place two players' games diverge.
	var path: String = paths[IdentityLens.identity_seed() % paths.size()] if paths.size() > 1 else paths[0]
	if not ResourceLoader.exists(path):
		push_warning("MusicManager: missing track %s" % path)
		return
	# CI / fresh checkouts often have .import sidecars but no .godot/imported
	# binaries (no --import). Skip before load() to avoid engine ERROR spam.
	if not _import_binary_ready(path):
		push_warning("MusicManager: track not imported yet %s" % path)
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		push_warning("MusicManager: failed to load %s" % path)
		return
	if stream is AudioStreamMP3:
		stream.loop = loop

	var prev_context := _current_context
	_current_context = context

	var incoming: AudioStreamPlayer = _b if _active == _a else _a
	incoming.stream = stream
	incoming.volume_db = -40.0
	incoming.play()

	var outgoing := _active
	_active = incoming

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(incoming, "volume_db", 0.0, FADE_SECONDS)
	tw.tween_property(outgoing, "volume_db", -40.0, FADE_SECONDS)
	tw.chain().tween_callback(outgoing.stop)

	if not loop:
		incoming.finished.connect(func():
			_current_context = ""
			play_context(LAYER_CONTEXT.get(LayerManager.current_layer_id, "theme")),
			CONNECT_ONE_SHOT)

func current_context() -> String:
	return _current_context

func _import_binary_ready(path: String) -> bool:
	return AutoloadGate.import_binary_ready(path)

## Racing scenes call this on entry/exit.
func enter_racing() -> void: play_context("racing")
func exit_racing() -> void:
	_current_context = ""
	play_context(LAYER_CONTEXT.get(LayerManager.current_layer_id, "theme"))
