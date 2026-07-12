extends SceneTree
## Quick visual proof: identity humanoid on liminal + supraliminal.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var dest := "/opt/cursor/artifacts/screenshots"
	DirAccess.make_dir_recursive_absolute(dest)
	var account: Node = root.get_node_or_null("AccountManager")
	var gm: Node = root.get_node_or_null("GameManager")
	if gm and int(gm.get("game_state")) == 0:
		await gm.initialize()
	if account and not bool(account.get("is_authenticated")):
		await account.auth_guest("ESOLook")
	var profile: Node = root.get_node_or_null("PlayerProfile")
	if profile:
		profile.set("has_expedition", true)
		if profile.has_method("set_race"):
			profile.set_race("KETH")
		if profile.has_method("set_frame"):
			profile.set_frame("VEIL")

	for entry in [
		["eso_01_title", "res://scenes/ui/title_screen.tscn"],
		["eso_02_liminal", "res://scenes/layers/liminal.tscn"],
		["eso_03_supraliminal", "res://scenes/layers/supraliminal.tscn"],
		["eso_04_periliminal", "res://scenes/layers/periliminal.tscn"],
		["eso_05_overworld", "res://scenes/world/overworld.tscn"],
	]:
		var id: String = entry[0]
		var path: String = entry[1]
		print("[eso_shot] ", id)
		change_scene_to_file(path)
		for i in 30:
			await process_frame
		await create_timer(1.2).timeout
		for i in 30:
			await process_frame
		RenderingServer.force_draw()
		await process_frame
		var img: Image = get_root().get_viewport().get_texture().get_image()
		if img:
			var outp := dest.path_join(id + ".png")
			img.save_png(outp)
			print("[eso_shot] wrote ", outp, " ", img.get_width(), "x", img.get_height())
	quit(0)
