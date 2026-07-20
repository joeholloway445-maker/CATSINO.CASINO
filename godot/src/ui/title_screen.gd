extends Control
class_name TitleScreen
## Front door after login. Dark purple ambient is intentional brand —
## not a broken render. Button sizes use PhoneUI.boost() so 1080p
## canvas_items stretch still lands thumb-sized on phones.

func _ready() -> void:
	MusicManager.play_context("theme")
	_build_ui()

func _build_ui() -> void:
	var b := PhoneUI.boost()
	var phone := PhoneUI.is_phone()
	# Cap brand mark so a 3–4× button boost doesn't eat the whole phone screen.
	var emblem_size := minf(200.0 * minf(b, 1.85), 360.0)
	var title_fs := PhoneUI.font(36) if phone else 48
	var btn_w := minf(280.0 * b, 520.0)
	var btn_h := 56.0 * b

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.01, 0.05)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Slow ambient glow — purple haze is the title brand, not a bug.
	var glow := ColorRect.new()
	glow.color = Color(0.35, 0.15, 0.55, 0.25)
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	var glow_tw := create_tween()
	glow_tw.set_loops()
	glow_tw.tween_property(glow, "color:a", 0.05, 3.5).set_trans(Tween.TRANS_SINE)
	glow_tw.tween_property(glow, "color:a", 0.25, 3.5).set_trans(Tween.TRANS_SINE)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", int(18.0 * b))
	# Keep content clear of notches / home indicators.
	var safe := DisplayServer.get_display_safe_area() if DisplayServer.has_method("get_display_safe_area") else Rect2i()
	if safe.size.x > 0:
		root.offset_left = float(safe.position.x) * 0.5
		root.offset_right = -float(DisplayServer.window_get_size().x - safe.end.x) * 0.5
		root.offset_top = float(safe.position.y) * 0.35
		root.offset_bottom = -float(DisplayServer.window_get_size().y - safe.end.y) * 0.35
	add_child(root)

	var upper := VBoxContainer.new()
	upper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	upper.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(upper)

	var emblem_center := CenterContainer.new()
	upper.add_child(emblem_center)
	var emblem := LogoEmblem.new()
	emblem.custom_minimum_size = Vector2(emblem_size, emblem_size)
	emblem_center.add_child(emblem)

	var title := Label.new()
	title.text = "PERILIMINAL.SPACE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", title_fs)
	upper.add_child(title)
	var title_tw := create_tween()
	title_tw.set_loops()
	title_tw.tween_property(title, "modulate:a", 0.65, 2.4).set_trans(Tween.TRANS_SINE)
	title_tw.tween_property(title, "modulate:a", 1.0, 2.4).set_trans(Tween.TRANS_SINE)

	var tagline := Label.new()
	tagline.text = "Six realities. One of you."
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.modulate = Color(0.7, 0.6, 0.9)
	tagline.add_theme_font_size_override("font_size", PhoneUI.font(18))
	upper.add_child(tagline)

	if phone:
		var hint := Label.new()
		hint.text = "Tap PLAY OFFLINE on the login screen first if you haven’t."
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.modulate = Color(0.55, 0.5, 0.65)
		hint.add_theme_font_size_override("font_size", PhoneUI.font(14))
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		upper.add_child(hint)

	var toggles := HBoxContainer.new()
	toggles.alignment = BoxContainer.ALIGNMENT_CENTER
	toggles.add_theme_constant_override("separation", int(12.0 * b))
	root.add_child(toggles)

	for spec in [
		{"text": "📖 Omni Dex", "fn": _toggle_omni_dex},
		{"text": "⚙️ Settings", "fn": func(): get_tree().change_scene_to_file("res://scenes/ui/settings.tscn")},
		{"text": "ℹ️ Info", "fn": _show_info},
	]:
		var tb := Button.new()
		tb.text = str(spec.text)
		tb.custom_minimum_size = Vector2(0, 44.0 * b)
		tb.add_theme_font_size_override("font_size", PhoneUI.font(16))
		tb.pressed.connect(spec.fn)
		toggles.add_child(tb)

	var middle := VBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	middle.add_theme_constant_override("separation", int(14.0 * b))
	root.add_child(middle)

	var new_btn := Button.new()
	new_btn.text = "⚔️  Start New Venture"
	new_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	new_btn.add_theme_font_size_override("font_size", PhoneUI.font(20))
	new_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/ui/venture_wizard.tscn"))
	middle.add_child(new_btn)

	var continue_btn := Button.new()
	continue_btn.text = "🌀  Continue Expedition"
	continue_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	continue_btn.add_theme_font_size_override("font_size", PhoneUI.font(20))
	continue_btn.disabled = not PlayerProfile.has_expedition
	if not PlayerProfile.has_expedition:
		continue_btn.tooltip_text = "No expedition yet — start a new venture first."
	continue_btn.pressed.connect(func():
		if not LayerManager.transition_to("subliminal"):
			get_tree().change_scene_to_file("res://scenes/layers/subliminal.tscn"))
	middle.add_child(continue_btn)

	var proto_btn := Button.new()
	proto_btn.text = "🧪  Play Prototype Spine"
	proto_btn.custom_minimum_size = Vector2(btn_w, btn_h * 0.9)
	proto_btn.add_theme_font_size_override("font_size", PhoneUI.font(18))
	proto_btn.tooltip_text = "Dev prototype: shortened Liminal pull + guaranteed Metroplex exit near spawn."
	proto_btn.pressed.connect(_start_prototype_spine)
	middle.add_child(proto_btn)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24.0 * b)
	root.add_child(spacer)

func _start_prototype_spine() -> void:
	LayerManager.enable_prototype_mode(true)
	if not PlayerProfile.has_expedition:
		PlayerProfile.set_race(PlayerProfile.selected_race_id)
		PlayerProfile.set_frame("veil")
		PlayerProfile.set_mod("catalyst")
		PlayerProfile.set_faction("Factionless")
		PlayerProfile.has_expedition = true
		PlayerProfile._save()
	NotificationUI.notify_info("Prototype spine armed. Walk the Metroplex archway — the Between is already watching.")
	LayerManager.transition_to("liminal", true)

func _toggle_omni_dex() -> void:
	if get_node_or_null("OmniDex") != null:
		return
	var dex := OmniDexUI.new()
	dex.name = "OmniDex"
	add_child(dex)

func _show_info() -> void:
	NotificationUI.notify_info("Periliminal.Space — a psychology XRMMORPG across six reality layers. The Catsino is one of them, not the main game. City streets: © OpenStreetMap contributors (ODbL).")
