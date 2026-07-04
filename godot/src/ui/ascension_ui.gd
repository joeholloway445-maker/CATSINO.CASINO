extends Control
## The Ascension screen: at level 50 (Champion trial complete) you choose a
## SECOND frame — your senses double, the sensoria blend into a duet, and
## your build space multiplies x20. Shows every frame's light/sound
## signature and previews the blend before committing. The choice is
## permanent per ascension.

var _list: VBoxContainer
var _header: Label
var _preview: Label

func _ready() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	_header = Label.new()
	_header.add_theme_font_size_override("font_size", 22)
	root.add_child(_header)

	var rarity := Label.new()
	rarity.text = IdentityLens.rarity_text()
	rarity.modulate = Color(1.0, 0.85, 0.4)
	root.add_child(rarity)

	_preview = Label.new()
	_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview.modulate = Color(0.75, 0.85, 1.0)
	root.add_child(_preview)

	root.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	var back := Button.new()
	back.text = "⬅ Back"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	root.add_child(back)

	_refresh()

func _refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
	var base := PlayerProfile.selected_frame
	var current := PlayerProfile.ascended_frame
	if current != "":
		_header.text = "🌗 ASCENDED: %s + %s" % [base.capitalize(), current.capitalize()]
		_preview.text = FrameSensorium.blend(base, current).desc
	elif PlayerProfile.level >= 50 and CrownManager.title_of("local_player") == "":
		_header.text = "🌗 ASCENSION — the Champion trial awaits"
		_preview.text = "Opt in, survive 4 hours of provisional PvP (the PVXC counts), and the second frame is yours to choose."
		var trial := Button.new()
		trial.text = "⚔️ Begin Champion Trial"
		trial.pressed.connect(func():
			CrownManager.start_champion_trial("local_player", PlayerProfile.level)
			_refresh())
		_list.add_child(trial)
		return
	elif PlayerProfile.level >= 50:
		_header.text = "🌗 ASCENSION — choose your second frame"
		_preview.text = "Your %s senses will keep 60%% authority; the second frame colors them. This multiplies your build space twentyfold." % base.capitalize()
	else:
		_header.text = "🌗 ASCENSION — sealed until level 50"
		_preview.text = "Now: %s" % FrameSensorium.of(base).desc

	if PlayerProfile.level < 50 or current != "":
		return

	for frame in FrameModData.FRAMES:
		var fid: String = frame.id
		if fid == base:
			continue
		var card := VBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = "%s (%s)" % [frame.name, frame.type]
		name_lbl.add_theme_font_size_override("font_size", 16)
		card.add_child(name_lbl)

		var blend := FrameSensorium.blend(base, fid)
		var desc := Label.new()
		desc.text = blend.desc
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.modulate = Color(0.7, 0.7, 0.8)
		card.add_child(desc)

		var btn := Button.new()
		if AscensionTrial.locked_out():
			btn.text = "Trial sealed — %d min (one server day per failure)" % (AscensionTrial.lockout_remaining() / 60)
			btn.disabled = true
		else:
			btn.text = "⚔️ Trial for %s (3 rounds — lose and drop everything)" % frame.name
			btn.pressed.connect(func(): AscensionTrial.begin(fid))
		card.add_child(btn)
		_list.add_child(card)
		_list.add_child(HSeparator.new())
