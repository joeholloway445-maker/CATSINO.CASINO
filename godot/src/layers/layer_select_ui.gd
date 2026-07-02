extends Control
## The layer gate: pick where in the cosmology to be. Entry rules enforced
## by LayerManager (the Periliminal shows as unenterable on purpose — it
## takes you, you don't take it).

func _ready() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var title := Label.new()
	title.text = "🌀 REALITY LAYERS"
	title.add_theme_font_size_override("font_size", 24)
	root.add_child(title)

	var wallet := Label.new()
	var parts: Array[String] = []
	for cid in EconomyManager.CURRENCIES.keys():
		var c: Dictionary = EconomyManager.CURRENCIES[cid]
		parts.append("%s %d" % [c.icon, EconomyManager.get_balance(cid)])
	wallet.text = "  ".join(parts)
	wallet.modulate = Color(0.8, 0.8, 0.8)
	root.add_child(wallet)

	root.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	for layer in RealityLayers.LAYERS:
		var card := VBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = layer.name
		name_lbl.add_theme_font_size_override("font_size", 18)
		card.add_child(name_lbl)

		var desc := Label.new()
		desc.text = layer.desc
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.modulate = Color(0.75, 0.75, 0.75)
		card.add_child(desc)

		var cur: Dictionary = EconomyManager.CURRENCIES.get(str(layer.currency), {})
		if not cur.is_empty():
			var cur_lbl := Label.new()
			cur_lbl.text = "%s %s — earned: %s" % [cur.icon, cur.name, cur.earned_by]
			cur_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			cur_lbl.modulate = Color(0.6, 0.75, 0.9)
			card.add_child(cur_lbl)

		var btn := Button.new()
		var check: Dictionary = LayerManager.can_enter(layer.id)
		if layer.id == LayerManager.current_layer_id:
			btn.text = "You are here"
			btn.disabled = true
		elif check.ok:
			btn.text = "Enter"
			var lid: String = layer.id
			btn.pressed.connect(func(): LayerManager.transition_to(lid))
		else:
			btn.text = "🔒 " + check.reason
			btn.disabled = true
		card.add_child(btn)
		list.add_child(card)
		list.add_child(HSeparator.new())

	var back := Button.new()
	back.text = "⬅ Back"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	root.add_child(back)
