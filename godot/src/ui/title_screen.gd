extends Control
class_name TitleScreen
## The actual front door: shown once, right after login. Periliminal Space
## logo/title fills the upper portion, breathing gently (glow fade in/out)
## over an ambient background until a button is pressed. Below the title:
## an Omni Dex toggle, Settings, and Info button. Center: Start New
## Venture (fresh character -> race/frame/mod -> thrown into the Liminal)
## or Continue Expedition (existing character -> straight to the
## Subliminal), the latter only lit up once a character actually exists.

func _ready() -> void:
	MusicManager.play_context("theme")
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.01, 0.05)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Slow ambient glow breathing behind everything — the "fading in and
	# out" ambience the title sits on until a choice is made.
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
	root.add_theme_constant_override("separation", 18)
	add_child(root)

	# ---- upper portion: title/logo ----
	var upper := VBoxContainer.new()
	upper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	upper.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(upper)

	# The emblem: shadow-god in the broken 9-point star, twin ouroboros.
	# Procedural until final key art lands at assets/ui/logo.png.
	var emblem_center := CenterContainer.new()
	upper.add_child(emblem_center)
	var emblem := LogoEmblem.new()
	emblem.custom_minimum_size = Vector2(300, 300)
	emblem_center.add_child(emblem)

	var title := Label.new()
	title.text = "PERILIMINAL.SPACE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	upper.add_child(title)
	var title_tw := create_tween()
	title_tw.set_loops()
	title_tw.tween_property(title, "modulate:a", 0.65, 2.4).set_trans(Tween.TRANS_SINE)
	title_tw.tween_property(title, "modulate:a", 1.0, 2.4).set_trans(Tween.TRANS_SINE)

	var tagline := Label.new()
	tagline.text = "Six realities. One of you."
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.modulate = Color(0.7, 0.6, 0.9)
	upper.add_child(tagline)

	# ---- toggle row: Omni Dex / Settings / Info ----
	var toggles := HBoxContainer.new()
	toggles.alignment = BoxContainer.ALIGNMENT_CENTER
	toggles.add_theme_constant_override("separation", 12)
	root.add_child(toggles)

	var dex_btn := Button.new()
	dex_btn.text = "📖 Omni Dex"
	dex_btn.pressed.connect(_toggle_omni_dex)
	toggles.add_child(dex_btn)

	var settings_btn := Button.new()
	settings_btn.text = "⚙️ Settings"
	settings_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/settings.tscn"))
	toggles.add_child(settings_btn)

	var info_btn := Button.new()
	info_btn.text = "ℹ️ Info"
	info_btn.pressed.connect(_show_info)
	toggles.add_child(info_btn)

	# ---- middle: the two entry points ----
	var middle := VBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	middle.add_theme_constant_override("separation", 14)
	root.add_child(middle)

	var new_btn := Button.new()
	new_btn.text = "⚔️  Start New Venture"
	new_btn.custom_minimum_size = Vector2(320, 56)
	new_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/ui/venture_wizard.tscn"))
	middle.add_child(new_btn)

	var continue_btn := Button.new()
	continue_btn.text = "🌀  Continue Expedition"
	continue_btn.custom_minimum_size = Vector2(320, 56)
	continue_btn.disabled = not PlayerProfile.has_expedition
	if not PlayerProfile.has_expedition:
		continue_btn.tooltip_text = "No expedition yet — start a new venture first."
	continue_btn.pressed.connect(func():
		if not LayerManager.transition_to("subliminal"):
			# Fallback if can_enter blocks — still honor Continue for local play.
			get_tree().change_scene_to_file("res://scenes/layers/subliminal.tscn"))
	middle.add_child(continue_btn)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	root.add_child(spacer)

func _toggle_omni_dex() -> void:
	if get_node_or_null("OmniDex") != null:
		return
	var dex := OmniDexUI.new()
	dex.name = "OmniDex"
	add_child(dex)

func _show_info() -> void:
	NotificationUI.notify_info("Periliminal.Space — a psychology XRMMORPG across six reality layers. The Catsino is one of them, not the main game.")
