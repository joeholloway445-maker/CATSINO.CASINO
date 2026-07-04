extends Control
class_name MainMenu
# Main menu after login — shows district selector and quick access buttons

signal enter_district(district_id: String)
signal open_inventory()
signal open_companions()
signal open_shop()
signal open_achievements()
signal open_settings()
signal open_game_modes()

var _player_info_label: Label

const DISTRICTS = [
	{id="paw_vegas",     name="Paw Vegas",     icon="🎰", desc="Slots, cards, and neon lights."},
	{id="cat_coliseum",  name="Cat Coliseum",   icon="⚔️", desc="Combat arena. Prove yourself."},
	{id="neon_alley",    name="Neon Alley",     icon="🏁", desc="Racing district. High speed."},
	{id="cat_forest",    name="Cat Forest",     icon="🌿", desc="Quests, companions, and mystery."},
	{id="arcade_galaxy", name="Arcade Galaxy",  icon="👾", desc="Mini-games and fortune wheels."},
]

func _ready() -> void:
	_build_ui()
	_refresh_player_info()

func _build_ui() -> void:
	var root = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# Header
	var header = HBoxContainer.new()
	root.add_child(header)

	var logo = Label.new()
	logo.text = "CATSINO.CASINO"
	logo.add_theme_font_size_override("font_size", 28)
	header.add_child(logo)

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
		{label="🗺️ Overworld", sig="", scene="res://scenes/world/overworld.tscn"},
		{label="🌀 Reality Layers", sig="", scene="res://scenes/layers/layer_select.tscn"},
		{label="🌗 Ascension", sig="", scene="res://scenes/ui/ascension.tscn"},
		{label="🔴 The PVXC", sig="", scene="res://scenes/pvxc/pvxc_gate.tscn"},
		{label="🏟️ Arena", sig="", scene="res://scenes/ui/arena_hub.tscn"},
		{label="👑 Crown Hall", sig="", scene="res://scenes/ui/crown_hall.tscn"},
		{label="📖 Skills", sig="", scene="res://scenes/ui/skill_tree.tscn"},
		{label="🏦 Bank & Guild", sig="", scene="res://scenes/ui/city_services.tscn"},
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

func _refresh_player_info() -> void:
	if not PlayerProfile: return
	_player_info_label.text = "%s | Lv.%d" % [PlayerProfile.get_display_name(), PlayerProfile.level]
	if EconomyManager:
		_player_info_label.text += " | 🪙%d 💎%d" % [EconomyManager.get_coins(), EconomyManager.get_gems()]
