extends SceneTree
## Headless checks for owner-trial kickoff assets (no DCC / GPU required).
## Run: godot --headless --path godot -s res://src/dev/owner_trials_smoke.gd

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("[owner_trials_smoke] start")
	await process_frame
	var ok := true
	for path in [
		"res://assets/music/ascension.mp3",
		"res://assets/music/sanctuary.mp3",
		"res://assets/terrain/hero/periliminal.png",
		"res://assets/terrain/hero/dallas.png",
		"res://assets/models/peri_human_player.glb",
		"res://assets/models/metahuman_npc.glb",
		"res://server_config.production.example.json",
	]:
		var exists := ResourceLoader.exists(path) or FileAccess.file_exists(path)
		print("[owner_trials_smoke] ", path, " =", exists)
		if not exists:
			ok = false
	var mm_script: GDScript = load("res://src/audio/music_manager.gd") as GDScript
	if mm_script == null:
		ok = false
		print("[owner_trials_smoke] music_manager FAIL")
	else:
		print("[owner_trials_smoke] music_manager ok")
	var tw_script: GDScript = load("res://src/world/overworld/terrain_world.gd") as GDScript
	if tw_script == null:
		ok = false
		print("[owner_trials_smoke] TerrainWorld FAIL")
	else:
		print("[owner_trials_smoke] TerrainWorld ok")
	# Dedicated beds must not be aliases of liminal/overworld masters.
	var asc := FileAccess.get_file_as_bytes("res://assets/music/ascension.mp3")
	var noc := FileAccess.get_file_as_bytes("res://assets/music/noclip.mp3")
	var san := FileAccess.get_file_as_bytes("res://assets/music/sanctuary.mp3")
	var tai := FileAccess.get_file_as_bytes("res://assets/music/taillights_fade.mp3")
	if asc.is_empty() or noc.is_empty() or asc == noc:
		ok = false
		print("[owner_trials_smoke] ascension still aliased FAIL")
	else:
		print("[owner_trials_smoke] ascension dedicated ok bytes=", asc.size())
	if san.is_empty() or tai.is_empty() or san == tai:
		ok = false
		print("[owner_trials_smoke] sanctuary still aliased FAIL")
	else:
		print("[owner_trials_smoke] sanctuary dedicated ok bytes=", san.size())
	print("[owner_trials_smoke] RESULT=", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
