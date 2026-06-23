extends Node
## Receiving half of the THE-HDV-CORE <-> CATSINO.CASINO cross-process
## handoff. THE-HDV-CORE's ExternalGameLauncher launches this game with
## `--player-id=<id>` and `--return-to=<hdv_world_id>` when a player enters
## Catsino Casino from the Space Station portal. Parsed once at startup;
## other systems (AccountManager, etc.) can read incoming_player_id /
## return_to_world_id to log the player in under the same identity and to
## know where to send them back.

var incoming_player_id: String = ""
var return_to_world_id: String = ""

## Per-machine override: directory containing THE-HDV-CORE's exported build,
## used by return_to_hdv_core(). Local-machine-specific, not committed.
@export var hdv_core_executable_dir: String = ""

const HDV_CORE_EXECUTABLE_NAMES := {
	"Windows": "periliminal.exe",
	"Linux": "periliminal.x86_64",
	"macOS": "periliminal.app",
}

func _ready() -> void:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--player-id="):
			incoming_player_id = arg.substr("--player-id=".length())
		elif arg.begins_with("--return-to="):
			return_to_world_id = arg.substr("--return-to=".length())

func has_incoming_handoff() -> bool:
	return not incoming_player_id.is_empty()

## Launches THE-HDV-CORE's executable and quits this process, sending the
## player back to whichever world they came from (return_to_world_id).
func return_to_hdv_core() -> bool:
	if hdv_core_executable_dir.is_empty():
		push_warning("ExternalHandoff: no hdv_core_executable_dir configured — return to THE-HDV-CORE manually for now.")
		return false
	var exe_name: String = HDV_CORE_EXECUTABLE_NAMES.get(OS.get_name(), "")
	if exe_name.is_empty():
		push_warning("ExternalHandoff: no known THE-HDV-CORE executable name for platform '%s'." % OS.get_name())
		return false
	var exe_path := hdv_core_executable_dir.path_join(exe_name)
	var args := PackedStringArray(["--player-id=%s" % incoming_player_id, "--enter-world=%s" % return_to_world_id])
	var pid := OS.create_process(exe_path, args)
	if pid <= 0:
		push_warning("ExternalHandoff: failed to start THE-HDV-CORE process at '%s'." % exe_path)
		return false
	get_tree().quit()
	return true
