extends Control
## The Crown Hall — all 60 crowns, who wears them, what they grant, and
## your own standing (crowns held, bonus multiplier, Triple Crown state,
## ascension title). Hidden crowns show as sealed until someone takes one.

func _ready() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var title := Label.new()
	title.text = "👑 THE CROWN HALL"
	title.add_theme_font_size_override("font_size", 24)
	root.add_child(title)

	var mine := CrownManager.crowns_of("local_player")
	var status := Label.new()
	var t := CrownManager.title_of("local_player")
	status.text = "You hold %d crown%s (x%.2f bonus)%s%s" % [
		mine.size(), "" if mine.size() == 1 else "s",
		CrownManager.crown_bonus_mult("local_player"),
		"  •  TRIPLE CROWN 🔱" if CrownManager.has_triple_crown("local_player") else "",
		("  •  " + t) if t != "" else ""]
	status.modulate = Color(1.0, 0.85, 0.4)
	root.add_child(status)

	root.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	for crown in CrownData.CROWNS:
		var row := VBoxContainer.new()
		var holder: String = CrownManager._holders.get(crown.id, "")
		var name_lbl := Label.new()
		var hidden: bool = crown.type == "hidden"
		if hidden and holder == "":
			name_lbl.text = "🔒 %s — sealed (token required)" % crown.name
			name_lbl.modulate = Color(0.5, 0.45, 0.6)
		else:
			name_lbl.text = "👑 %s — %s" % [crown.name,
				("worn by " + holder) if holder != "" else "unclaimed"]
			name_lbl.modulate = Color(1.0, 0.9, 0.5) if holder == "local_player" else Color.WHITE
		name_lbl.add_theme_font_size_override("font_size", 15)
		row.add_child(name_lbl)

		var detail := Label.new()
		detail.text = "%s  •  %s  •  %s" % [crown.leaderboard, crown.passive_bonus, crown.playstyle_bonus]
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.modulate = Color(0.65, 0.65, 0.7)
		row.add_child(detail)
		list.add_child(row)
		list.add_child(HSeparator.new())

	var back := Button.new()
	back.text = "⬅ Back"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	root.add_child(back)
