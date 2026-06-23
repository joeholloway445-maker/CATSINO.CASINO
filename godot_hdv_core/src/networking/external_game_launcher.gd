extends Node
## Launches an external Godot-game executable (e.g. CATSINO.CASINO) as a
## separate process, passing a player_id and a --return-to flag so the
## receiving project can (once it implements the matching parser) hand the
## player back to this game's hub when they're done. No shared filesystem/
## URI-scheme convention exists between these repos yet — this is the
## launching half only; CATSINO.CASINO does not yet parse these args
## (confirmed: no OS.get_cmdline_args() usage there as of this writing).

## Per-platform executable basenames, keyed by external_repo id from
## WorldRegistry. Paths are resolved relative to executable_dir, which the
## caller must point at wherever that project's exported build lives —
## there's no install registry, so this can't be auto-discovered.
## Per-machine override: external_repo id -> directory containing that
## project's exported build. Left empty by default since install locations
## are local-machine-specific, not something to commit.
@export var executable_dirs: Dictionary = {}

const EXECUTABLE_NAMES := {
	"CATSINO.CASINO": {
		"Windows": "CATSINO.exe",
		"Linux": "CATSINO.x86_64",
		"macOS": "CATSINO.app",
	},
}

## Attempts to launch `external_repo`'s executable from `executable_dir`.
## Returns true if the process was started, false otherwise (and pushes a
## warning explaining why — most commonly that executable_dir hasn't been
## configured for this machine).
func launch(external_repo: String, player_id: String, return_to: String) -> bool:
	var executable_dir: String = executable_dirs.get(external_repo, "")
	if executable_dir.is_empty():
		push_warning("ExternalGameLauncher: no executable_dir configured for '%s' — launch it separately for now." % external_repo)
		return false
	var names: Dictionary = EXECUTABLE_NAMES.get(external_repo, {})
	var exe_name: String = names.get(OS.get_name(), "")
	if exe_name.is_empty():
		push_warning("ExternalGameLauncher: no known executable name for '%s' on platform '%s'." % [external_repo, OS.get_name()])
		return false
	var exe_path := executable_dir.path_join(exe_name)
	if not FileAccess.file_exists(exe_path) and not DirAccess.dir_exists_absolute(exe_path):
		push_warning("ExternalGameLauncher: executable not found at '%s'." % exe_path)
		return false
	var args := PackedStringArray(["--player-id=%s" % player_id, "--return-to=%s" % return_to])
	var pid := OS.create_process(exe_path, args)
	if pid <= 0:
		push_warning("ExternalGameLauncher: failed to start process at '%s'." % exe_path)
		return false
	return true
