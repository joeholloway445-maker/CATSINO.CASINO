extends Control
# Main menu after login — shows district selector and quick access buttons.
# No class_name: maaacks_menus_template also defines MainMenu.

signal enter_district(district_id: String)
signal open_inventory()
signal open_companions()
signal open_shop()
signal open_achievements()
signal open_settings()
signal open_game_modes()

var _player_info_label: Label

const CUSTOM_LOGO_PATH := "res://assets/ui/custom_logo.png"
const CUSTOM_BG_PATH := "res://assets/ui/custom_bg.png"
const THEME_SONG_PATH := "res://assets/audio/theme_song.ogg"

const DISTRICTS = [
	{id="paw_vegas",     name="Paws Vegas",     icon="🎰", desc="Slots, cards, and neon lights."},
	{id="cat_coliseum",  name="Cat Coliseum",   icon="⚔️", desc="Combat arena. Prove yourself."},
	{id="neon_alley",    name="Neon Alley",     icon="🏁", desc="Racing district. High speed."},
	{id="cat_forest",    name="Cat Forest",     icon="🌿", desc="Quests, companions, and mystery."},
	{id="arcade_galaxy", name="Arcade Galaxy",  icon="👾", desc="Mini-games and fortune wheels."},
]

func _ready() -> void:
	_build_ui()
	_play_theme_song()
	_refresh_player_info()

func _build_ui() -> void:
	_add_custom_background()

	var root = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# Header
	var header = HBoxContainer.new()
	root.add_child(header)

	_add_logo(header)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_player_info_label = Label.new()
	_player_info_label.text = "Loading..."
	header.add_child(_player_info_label)

	# Quick actions row
	var quick_row = HBoxContainer.new()
	root.add_child(quick_row)

	for action in [
		{label="🎒 Inventory", sig="open_inventory"},
		{label="🐾 Companions", sig="open_companions"},
		{label="🛒 Shop", sig="open_shop"},
		{label="🏆 Achievements", sig="open_achievements"},
		{label="🌐 Game Modes", sig="open_game_modes", scene="res://scenes/ui/game_mode_store.tscn"},
		{label="🗺️ Overworld", sig="", scene="res://scenes/layers/supraliminal.tscn"},
		{label="🌀 Reality Layers", sig="", scene="res://scenes/layers/layer_select.tscn"},
		{label="🌗 Ascension", sig="", scene="res://scenes/ui/ascension.tscn"},
		{label="🔴 The PVXC", sig="", scene="res://scenes/pvxc/pvxc_gate.tscn"},
		{label="🏟️ Arena", sig="", scene="res://scenes/ui/arena_hub.tscn"},
		{label="👑 Crown Hall", sig="", scene="res://scenes/ui/crown_hall.tscn"},
		{label="📖 Skills", sig="", scene="res://scenes/ui/skill_tree.tscn"},
		{label="🏦 Bank & Guild", sig="", scene="res://scenes/ui/city_services.tscn"},
		{label="🗳️ Wager Hall", sig="", scene="res://scenes/ui/arena_hub.tscn"},
		{label="⚙️ Settings", sig="open_settings"},
	]:
		var btn = Button.new()
		btn.text = action.label
		var sig_name: String = action.sig
		var scene_path: String = action.get("scene", "")
		btn.pressed.connect(func():
			if sig_name != "":
				emit_signal(sig_name)
			if scene_path != "":
				get_tree().change_scene_to_file(scene_path))
		quick_row.add_child(btn)

	# District grid
	var district_title = Label.new()
	district_title.text = "SELECT DISTRICT"
	district_title.add_theme_font_size_override("font_size", 16)
	root.add_child(district_title)

	var grid = GridContainer.new()
	grid.columns = 3
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(grid)

	for district in DISTRICTS:
		var panel = _make_district_button(district)
		grid.add_child(panel)

func _make_district_button(district: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(200, 120)
	btn.text = "%s\n%s\n%s" % [district.icon, district.name, district.desc]
	btn.pressed.connect(func(): enter_district.emit(district.id))
	return btn

func _add_custom_background() -> void:
	if not ResourceLoader.exists(CUSTOM_BG_PATH):
		return
	var texture: Texture2D = ResourceLoader.load(CUSTOM_BG_PATH) as Texture2D
	if texture == null:
		return
	var background := TextureRect.new()
	background.name = "CustomBackground"
	background.texture = texture
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

func _add_logo(header: HBoxContainer) -> void:
	if ResourceLoader.exists(CUSTOM_LOGO_PATH):
		var texture: Texture2D = ResourceLoader.load(CUSTOM_LOGO_PATH) as Texture2D
		if texture != null:
			var logo := TextureRect.new()
			logo.name = "CustomLogo"
			logo.texture = texture
			logo.custom_minimum_size = Vector2(320, 80)
			logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			header.add_child(logo)
			return

	var logo_label := Label.new()
	logo_label.text = "CATSINO.CASINO"
	logo_label.add_theme_font_size_override("font_size", 28)
	header.add_child(logo_label)

func _play_theme_song() -> void:
	if not ResourceLoader.exists(THEME_SONG_PATH):
		return
	var stream: AudioStream = ResourceLoader.load(THEME_SONG_PATH) as AudioStream
	if stream == null:
		return
	stream.set("loop", true)
	var player := AudioStreamPlayer.new()
	player.name = "ThemeSongPlayer"
	player.stream = stream
	add_child(player)
	player.play()

func _refresh_player_info() -> void:
	if not PlayerProfile: return
	_player_info_label.text = "%s | Lv.%d" % [PlayerProfile.get_display_name(), PlayerProfile.level]
	if EconomyManager:
		_player_info_label.text += " | 🪙%d 💎%d" % [EconomyManager.get_coins(), EconomyManager.get_gems()]
