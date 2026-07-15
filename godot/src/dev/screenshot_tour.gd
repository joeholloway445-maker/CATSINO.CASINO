extends SceneTree
## Capture as many game screens as possible for review artifacts.
## Usage:
##   DISPLAY=:1 godot --path godot --display-driver x11 \
##     -s res://src/dev/screenshot_tour.gd
##
## Writes PNGs to user://screenshots/ (and copies to OUT_DIR if set).

const OUT_USER := "user://screenshots"
const WAIT_FRAMES := 12

var _shots: Array[String] = []
var _failed: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir().path_join("screenshots"))
	print("[shot] user_data=", OS.get_user_data_dir())
	DisplayServer.window_set_size(Vector2i(1280, 720))

	# Offline session so Continues / layers that read profile don't blow up.
	var account: Node = root.get_node_or_null("AccountManager")
	var gm: Node = root.get_node_or_null("GameManager")
	if gm and int(gm.get("game_state")) == 0:
		await gm.initialize()
	if account and not bool(account.get("is_authenticated")):
		await account.auth_guest("ScreenshotTour")

	# Seed a minimal expedition so Continue / Subliminal look populated.
	var profile: Node = root.get_node_or_null("PlayerProfile")
	if profile:
		profile.set("has_expedition", true)
		profile.set("username", "ScreenshotTour")
		if profile.has_method("set_race"):
			profile.set_race("KETH")
		if profile.has_method("set_frame"):
			profile.set_frame("VEIL")
		if profile.has_method("set_faction"):
			profile.set_faction("Factionless")
		if profile.has_method("set_mod"):
			profile.set_mod("CATALYST")

	var tour: Array[Dictionary] = [
		{"id": "01_splash", "path": "res://scenes/ui/splash.tscn"},
		{"id": "02_login", "path": "res://scenes/ui/login.tscn"},
		{"id": "03_title", "path": "res://scenes/ui/title_screen.tscn"},
		{"id": "04_venture_wizard", "path": "res://scenes/ui/venture_wizard.tscn"},
		{"id": "05_settings", "path": "res://scenes/ui/settings.tscn"},
		{"id": "06_main_menu", "path": "res://scenes/ui/main_menu.tscn"},
		{"id": "08_profile", "path": "res://scenes/ui/profile.tscn"},
		{"id": "09_inventory", "path": "res://scenes/ui/inventory.tscn"},
		{"id": "10_shop", "path": "res://scenes/ui/shop.tscn"},
		{"id": "11_quest", "path": "res://scenes/ui/quest.tscn"},
		{"id": "12_achievements", "path": "res://scenes/ui/achievements.tscn"},
		{"id": "13_battlepass", "path": "res://scenes/ui/battlepass.tscn"},
		{"id": "14_daily_reward", "path": "res://scenes/ui/daily_reward.tscn"},
		{"id": "15_gacha", "path": "res://scenes/ui/gacha.tscn"},
		{"id": "16_gacha_summon", "path": "res://scenes/ui/gacha_summon.tscn"},
		{"id": "17_leaderboard", "path": "res://scenes/ui/leaderboard.tscn"},
		{"id": "18_tournament", "path": "res://scenes/ui/tournament.tscn"},
		{"id": "19_companion_viewer", "path": "res://scenes/ui/companion_viewer.tscn"},
		{"id": "20_skill_tree", "path": "res://scenes/ui/skill_tree.tscn"},
		{"id": "21_lore", "path": "res://scenes/ui/lore.tscn"},
		{"id": "22_crown_hall", "path": "res://scenes/ui/crown_hall.tscn"},
		{"id": "23_ascension", "path": "res://scenes/ui/ascension.tscn"},
		{"id": "24_arena_hub", "path": "res://scenes/ui/arena_hub.tscn"},
		{"id": "25_game_mode_store", "path": "res://scenes/ui/game_mode_store.tscn"},
		{"id": "26_city_services", "path": "res://scenes/ui/city_services.tscn"},
		{"id": "27_creator_mode", "path": "res://scenes/ui/creator_mode.tscn"},
		{"id": "28_npc_dialogue", "path": "res://scenes/ui/npc_dialogue.tscn"},
		{"id": "29_combat_ui", "path": "res://scenes/ui/combat_ui.tscn"},
		{"id": "30_hud", "path": "res://scenes/ui/hud.tscn"},
		{"id": "31_race_ui", "path": "res://scenes/ui/race_ui.tscn"},
		{"id": "32_layer_select", "path": "res://scenes/layers/layer_select.tscn"},
		{"id": "33_subliminal", "path": "res://scenes/layers/subliminal.tscn"},
		{"id": "34_liminal", "path": "res://scenes/layers/liminal.tscn"},
		{"id": "35_supraliminal", "path": "res://scenes/layers/supraliminal.tscn"},
		{"id": "36_periliminal", "path": "res://scenes/layers/periliminal.tscn"},
		{"id": "37_extraliminal", "path": "res://scenes/layers/extraliminal.tscn"},
		{"id": "38_pvxc_gate", "path": "res://scenes/pvxc/pvxc_gate.tscn"},
		{"id": "39_pvxc_zone", "path": "res://scenes/pvxc/pvxc_zone.tscn"},
		{"id": "41_paw_vegas_hub", "path": "res://scenes/world/paw_vegas_hub.tscn"},
		{"id": "42_neon_alley", "path": "res://scenes/world/neon_alley.tscn"},
		{"id": "43_cat_forest", "path": "res://scenes/world/cat_forest.tscn"},
		{"id": "44_cat_coliseum", "path": "res://scenes/world/cat_coliseum.tscn"},
		{"id": "45_arcade_galaxy", "path": "res://scenes/world/arcade_galaxy.tscn"},
		{"id": "46_combat_zone", "path": "res://scenes/world/combat_zone.tscn"},
		{"id": "47_world_main", "path": "res://scenes/world/main.tscn"},
		{"id": "48_slots", "path": "res://scenes/games/slots/slot_machine.tscn"},
		{"id": "49_blackjack", "path": "res://scenes/games/arcade/blackjack.tscn"},
		{"id": "50_paw_poker", "path": "res://scenes/games/arcade/paw_poker.tscn"},
		{"id": "51_coin_pusher", "path": "res://scenes/games/arcade/coin_pusher.tscn"},
		{"id": "52_fortune_wheel", "path": "res://scenes/games/arcade/fortune_wheel.tscn"},
		{"id": "53_scratch_card", "path": "res://scenes/games/arcade/scratch_card.tscn"},
		{"id": "54_cat_puzzle", "path": "res://scenes/games/arcade/cat_puzzle.tscn"},
		{"id": "55_race_track", "path": "res://scenes/games/racing/race_track.tscn"},
		{"id": "56_race_drive", "path": "res://scenes/games/racing/race_drive.tscn"},
		{"id": "57_paw_ball", "path": "res://scenes/games/sports/paw_ball.tscn"},
		{"id": "58_trial_arena", "path": "res://scenes/ascension/trial_arena.tscn"},
		{"id": "59_character_preview", "path": "res://scenes/character/character_preview.tscn"},
	]

	for entry in tour:
		await _capture_scene(str(entry.id), str(entry.path))

	# Extra: title with Omni Dex overlay if possible
	await _capture_title_with_omni_dex()

	_export_to_artifacts()
	print("[shot] done ok=%d fail=%d" % [_shots.size(), _failed.size()])
	for f in _failed:
		print("[shot] FAIL ", f)
	quit(0 if _shots.size() > 0 else 1)

func _capture_scene(id: String, path: String) -> void:
	if not ResourceLoader.exists(path):
		_failed.append("%s missing %s" % [id, path])
		print("[shot] skip missing ", path)
		return
	print("[shot] load ", id, " ", path)
	var err := change_scene_to_file(path)
	if err != OK:
		_failed.append("%s change_scene %s err=%d" % [id, path, err])
		print("[shot] change_scene failed ", err)
		return
	# Let _ready / builders run
	for i in WAIT_FRAMES:
		await process_frame
	# Extra settle for heavy world builders
	if path.contains("/layers/") or path.contains("/world/") or path.contains("pvxc"):
		await create_timer(0.6).timeout
		for i in 20:
			await process_frame
	else:
		await create_timer(0.15).timeout
		for i in 6:
			await process_frame
	await _save_png(id)

func _capture_title_with_omni_dex() -> void:
	if not ResourceLoader.exists("res://scenes/ui/title_screen.tscn"):
		return
	change_scene_to_file("res://scenes/ui/title_screen.tscn")
	for i in WAIT_FRAMES:
		await process_frame
	await create_timer(0.2).timeout
	var scene := current_scene
	if scene and scene.has_method("_toggle_omni_dex"):
		scene.call("_toggle_omni_dex")
		for i in 10:
			await process_frame
		await _save_png("60_title_omni_dex")

func _save_png(id: String) -> void:
	await process_frame
	RenderingServer.force_draw()
	await process_frame
	var img: Image = get_root().get_viewport().get_texture().get_image()
	if img == null:
		_failed.append("%s null image" % id)
		return
	# X11 OpenGL viewport images are already upright — do not flip_y.
	var out_path := OUT_USER.path_join(id + ".png")
	var abs_path := ProjectSettings.globalize_path(out_path)
	var save_err := img.save_png(abs_path)
	if save_err != OK:
		_failed.append("%s save_err=%d" % [id, save_err])
		print("[shot] save failed ", abs_path, " ", save_err)
		return
	_shots.append(abs_path)
	print("[shot] wrote ", abs_path, " ", img.get_width(), "x", img.get_height())

func _export_to_artifacts() -> void:
	var dest := OS.get_environment("SHOT_OUT")
	if dest.is_empty():
		dest = "/opt/cursor/artifacts/screenshots"
	DirAccess.make_dir_recursive_absolute(dest)
	var src_dir := OS.get_user_data_dir().path_join("screenshots")
	var da := DirAccess.open(src_dir)
	if da == null:
		print("[shot] no src dir ", src_dir)
		return
	da.list_dir_begin()
	var fname := da.get_next()
	var n := 0
	while fname != "":
		if not da.current_is_dir() and fname.ends_with(".png"):
			var from_p := src_dir.path_join(fname)
			var to_p := dest.path_join(fname)
			var bytes := FileAccess.get_file_as_bytes(from_p)
			var f := FileAccess.open(to_p, FileAccess.WRITE)
			if f:
				f.store_buffer(bytes)
				n += 1
		fname = da.get_next()
	print("[shot] copied ", n, " pngs to ", dest)
