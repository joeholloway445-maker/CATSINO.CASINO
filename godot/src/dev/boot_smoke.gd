extends SceneTree
## Headless boot-path smoke for GOTY gate 2.
## Run: godot --headless --path godot -s res://src/dev/boot_smoke.gd
## Autoload singletons are nodes under /root (no class_name) — access via get_node.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("[boot_smoke] start")
	var tree_root := self.root
	var gm: Node = tree_root.get_node_or_null("GameManager")
	var account: Node = tree_root.get_node_or_null("AccountManager")
	if gm == null or account == null:
		push_error("[boot_smoke] missing GameManager/AccountManager autoload")
		print("[boot_smoke] RESULT=FAIL")
		quit(1)
		return

	# GameManager.GameState.LOADING == 0
	if int(gm.get("game_state")) == 0:
		await gm.initialize()
	print("[boot_smoke] state after init: ", gm.get("game_state"))

	var ok: bool = await account.auth_guest("SmokeTester")
	print("[boot_smoke] auth_guest=", ok, " authenticated=", account.get("is_authenticated"))
	await process_frame
	await process_frame

	var scene := current_scene
	var script_path := ""
	if scene and scene.get_script():
		script_path = str(scene.get_script().resource_path)
	print("[boot_smoke] current_scene=", scene.scene_file_path if scene else "", " script=", script_path)

	var is_title := script_path.ends_with("title_screen.gd") \
		or (scene != null and str(scene.scene_file_path).ends_with("title_screen.tscn"))
	if not is_title:
		change_scene_to_file("res://scenes/ui/title_screen.tscn")
		await process_frame
		await process_frame
		scene = current_scene
		script_path = str(scene.get_script().resource_path) if scene and scene.get_script() else ""
		is_title = script_path.ends_with("title_screen.gd")

	print("[boot_smoke] title_ok=", is_title)
	var wizard_ok := ResourceLoader.exists("res://scenes/ui/venture_wizard.tscn")
	var liminal_ok := ResourceLoader.exists("res://scenes/layers/liminal.tscn")
	var sub_ok := ResourceLoader.exists("res://scenes/layers/subliminal.tscn")
	print("[boot_smoke] wizard=", wizard_ok, " liminal=", liminal_ok, " subliminal=", sub_ok)

	var passed := ok and bool(account.get("is_authenticated")) and is_title and wizard_ok and liminal_ok and sub_ok
	print("[boot_smoke] RESULT=", "PASS" if passed else "FAIL")
	quit(0 if passed else 1)
