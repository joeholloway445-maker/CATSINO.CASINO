extends Control

const SETTINGS_PATH := "user://settings.json"

var _settings: Dictionary = {
	"audio_master": 1.0,
	"audio_music": 0.8,
	"audio_sfx": 1.0,
	"graphics_quality": 2,  # 0=Low, 1=Med, 2=High, 3=Ultra
	"show_fps": false,
	"vsync": true,
	"fullscreen": false,
	"chat_filter": true,
	"notifications_events": true,
	"notifications_social": true,
	"auto_claim_daily": false,
	"language": "en",
}

func _ready() -> void:
	_load_settings()
	_build_ui()
	_apply_settings()
	UINav.add_back_button(self)

func _build_ui() -> void:
	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var root = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.custom_minimum_size = Vector2(400, 0)
	scroll.add_child(root)

	var title = Label.new()
	title.text = "SETTINGS"
	title.add_theme_font_size_override("font_size", 22)
	root.add_child(title)

	_add_section(root, "🔊 AUDIO")
	_add_slider(root, "Master Volume", "audio_master", 0.0, 1.0)
	_add_slider(root, "Music Volume", "audio_music", 0.0, 1.0)
	_add_slider(root, "SFX Volume", "audio_sfx", 0.0, 1.0)

	_add_section(root, "🖥️ GRAPHICS")
	_add_option(root, "Quality Preset", "graphics_quality", ["Low", "Medium", "High", "Ultra"])
	_add_toggle(root, "Show FPS", "show_fps")
	_add_toggle(root, "VSync", "vsync")
	_add_toggle(root, "Fullscreen", "fullscreen")

	_add_section(root, "💬 SOCIAL")
	_add_toggle(root, "Chat Word Filter", "chat_filter")
	_add_toggle(root, "Event Notifications", "notifications_events")
	_add_toggle(root, "Social Notifications", "notifications_social")

	_add_section(root, "🎮 GAMEPLAY")
	_add_toggle(root, "Auto-Claim Daily Bonus", "auto_claim_daily")

	var save_btn = Button.new()
	save_btn.text = "SAVE SETTINGS"
	save_btn.custom_minimum_size = Vector2(0, 48)
	save_btn.pressed.connect(_save_settings)
	root.add_child(save_btn)

	var reset_btn = Button.new()
	reset_btn.text = "Reset to Defaults"
	reset_btn.pressed.connect(_reset_settings)
	root.add_child(reset_btn)

func _add_section(parent: VBoxContainer, title: String) -> void:
	var sep = HSeparator.new()
	parent.add_child(sep)
	var lbl = Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", 14)
	parent.add_child(lbl)

func _add_slider(parent: VBoxContainer, label: String, key: String, min_val: float, max_val: float) -> void:
	var row = HBoxContainer.new()
	parent.add_child(row)
	var lbl = Label.new()
	lbl.text = label
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.value = _settings.get(key, max_val)
	slider.custom_minimum_size = Vector2(150, 0)
	slider.value_changed.connect(func(v): _settings[key] = v; _apply_settings())
	row.add_child(slider)

func _add_toggle(parent: VBoxContainer, label: String, key: String) -> void:
	var row = HBoxContainer.new()
	parent.add_child(row)
	var lbl = Label.new()
	lbl.text = label
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	var check = CheckButton.new()
	check.button_pressed = _settings.get(key, false)
	check.toggled.connect(func(v): _settings[key] = v; _apply_settings())
	row.add_child(check)

func _add_option(parent: VBoxContainer, label: String, key: String, options: Array[String]) -> void:
	var row = HBoxContainer.new()
	parent.add_child(row)
	var lbl = Label.new()
	lbl.text = label
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	var opt = OptionButton.new()
	for o in options:
		opt.add_item(o)
	opt.selected = _settings.get(key, 2)
	opt.item_selected.connect(func(i): _settings[key] = i; _apply_settings())
	row.add_child(opt)

func _apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(_settings.get("audio_master", 1.0)))
	# Additional audio bus indices assumed: 1=music, 2=sfx
	if AudioServer.bus_count > 1:
		AudioServer.set_bus_volume_db(1, linear_to_db(_settings.get("audio_music", 0.8)))
	if AudioServer.bus_count > 2:
		AudioServer.set_bus_volume_db(2, linear_to_db(_settings.get("audio_sfx", 1.0)))
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if _settings.get("vsync", true) else DisplayServer.VSYNC_DISABLED
	)
	if _settings.get("fullscreen", false):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _save_settings() -> void:
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_settings))

func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			for key in parsed:
				_settings[key] = parsed[key]

func _reset_settings() -> void:
	_settings = {
		"audio_master": 1.0, "audio_music": 0.8, "audio_sfx": 1.0,
		"graphics_quality": 2, "show_fps": false, "vsync": true,
		"fullscreen": false, "chat_filter": true, "notifications_events": true,
		"notifications_social": true, "auto_claim_daily": false, "language": "en",
	}
	_build_ui()
	_apply_settings()
