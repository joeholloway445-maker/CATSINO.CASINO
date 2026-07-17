extends Control
## The skill tree: every line your build knows (frame, ascended frame,
## race heritage, faction, Liminal Arts) with full lore, rank progress,
## unlock (skill point), bar slotting, and rank-IV morph choices.

var _points_lbl: Label

func _ready() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var title := Label.new()
	title.text = "📖 SKILL LINES"
	title.add_theme_font_size_override("font_size", 24)
	root.add_child(title)

	_points_lbl = Label.new()
	_points_lbl.modulate = Color(1.0, 0.85, 0.4)
	root.add_child(_points_lbl)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	for line in SkillManager.known_lines():
		_build_line(list, line)

	var back := Button.new()
	back.text = "⬅ Back"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	root.add_child(back)
	_refresh_points()

func _refresh_points() -> void:
	var prestige := 0
	if EconomyManager:
		prestige = EconomyManager.get_balance("prestige")
	_points_lbl.text = "Skill points: %d   •   Prestige: %d 🌟   •   Bar II: %s" % [
		SkillManager.skill_points, prestige,
		"unlocked (ascended)" if SkillManager.can_swap() else "locked — ascend at level 50"]

func _build_line(list: VBoxContainer, line: Dictionary) -> void:
	var header := Label.new()
	var is_prestige: bool = str(line.get("source", "")) == "prestige"
	header.text = "━ %s ━%s" % [line.name, "  (🌟 Prestige)" if is_prestige else ""]
	header.add_theme_font_size_override("font_size", 19)
	header.modulate = Color(1.0, 0.85, 0.45) if is_prestige else Color(0.85, 0.8, 1.0)
	list.add_child(header)
	if is_prestige:
		var note := Label.new()
		note.text = "Unlocks spend Prestige — social leverage & house craft, not combat skill points."
		note.modulate = Color(0.75, 0.7, 0.55)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(note)

	# ATTUNEMENT: every line can channel one of the six entity forces —
	# your unarmed strikes can bend gravity, your gunplay can carry
	# entropy. The element rides every cast of the line (color, sound,
	# and a combat rider — see SkillData.ELEMENTS).
	var att_row := HBoxContainer.new()
	att_row.add_theme_constant_override("separation", 6)
	list.add_child(att_row)
	var att_lbl := Label.new()
	var current := SkillManager.attunement_of(str(line.id))
	att_lbl.text = "Attunement: %s" % (str(SkillData.element(current).get("name", "")) if current != "" else "none")
	att_lbl.custom_minimum_size.x = 170
	att_row.add_child(att_lbl)
	for eid in SkillData.ELEMENTS:
		var e: Dictionary = SkillData.ELEMENTS[eid]
		var eb := Button.new()
		eb.text = str(e.name)
		eb.tooltip_text = str(e.desc)
		eb.modulate = e.color if eid != current else Color.WHITE
		var line_id := str(line.id)
		var element_id := str(eid)
		eb.pressed.connect(func():
			SkillManager.attune_line(line_id, element_id if SkillManager.attunement_of(line_id) != element_id else "")
			get_tree().reload_current_scene())
		att_row.add_child(eb)

	for a in line.actives:
		_build_skill(list, a, false)
	_build_skill(list, line.ultimate, true)

	for p in line.get("passives", []):
		if str(line.get("source", "")) == "prestige":
			_build_prestige_passive(list, p)
		else:
			var pl := Label.new()
			pl.text = "◈ %s — %s" % [p.name, p.desc]
			pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			pl.modulate = Color(0.6, 0.7, 0.6)
			list.add_child(pl)
	list.add_child(HSeparator.new())

func _build_prestige_passive(list: VBoxContainer, p: Dictionary) -> void:
	var row := HBoxContainer.new()
	list.add_child(row)
	var pl := Label.new()
	var owned := SkillManager.is_unlocked(str(p.id))
	pl.text = "%s ◈ %s — %s" % ["✓" if owned else "○", p.name, p.desc]
	pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pl.modulate = Color(0.85, 0.8, 0.5) if owned else Color(0.6, 0.7, 0.6)
	pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(pl)
	if not owned:
		var cost: int = SkillManager.prestige_unlock_cost(str(p.id))
		var ub := Button.new()
		ub.text = "Unlock (%d 🌟)" % cost
		ub.pressed.connect(func():
			if SkillManager.unlock_with_prestige(str(p.id)):
				get_tree().reload_current_scene())
		row.add_child(ub)

func _build_skill(list: VBoxContainer, sk: Dictionary, is_ult: bool) -> void:
	var row := VBoxContainer.new()
	var rank := SkillManager.rank_of(sk.id)
	var name_lbl := Label.new()
	var rank_txt := "" if rank == 0 else "  [rank %s]" % ["I","II","III","IV"][rank - 1]
	name_lbl.text = "%s %s%s" % ["⚡" if is_ult else "◆", SkillManager.resolved(sk.id).get("name", sk.name) if rank > 0 else sk.name, rank_txt]
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.modulate = Color(1.0, 0.9, 0.5) if is_ult else Color.WHITE
	row.add_child(name_lbl)

	var lore := Label.new()
	lore.text = sk.get("lore", "")
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore.modulate = Color(0.62, 0.62, 0.7)
	row.add_child(lore)

	var btns := HBoxContainer.new()
	row.add_child(btns)

	if not SkillManager.is_unlocked(sk.id):
		var unlock := Button.new()
		if SkillManager.is_prestige_skill(sk.id):
			var cost: int = SkillManager.prestige_unlock_cost(sk.id)
			unlock.text = "Unlock (%d 🌟)" % cost
		else:
			unlock.text = "Unlock (1 ✴️)"
		unlock.pressed.connect(func():
			if SkillManager.unlock(sk.id):
				get_tree().reload_current_scene())
		btns.add_child(unlock)
	else:
		for bar in ([0, 1] if SkillManager.can_swap() else [0]):
			if is_ult:
				var ub := Button.new()
				ub.text = "→ Bar %s ult" % ["I", "II"][bar]
				ub.pressed.connect(func(): SkillManager.slot_ultimate(bar, sk.id))
				btns.add_child(ub)
			else:
				for slot in range(5):
					var sb := Button.new()
					sb.text = "%s%d" % [["I", "II"][bar], slot + 1]
					sb.tooltip_text = "Slot on bar %s, key %d" % [["I", "II"][bar], slot + 1]
					sb.pressed.connect(func(): SkillManager.slot_skill(bar, slot, sk.id))
					btns.add_child(sb)
		# Morph choice at rank IV
		if rank >= SkillManager.MAX_RANK and SkillManager.morph_of(sk.id) == "" and not is_ult:
			for morph in sk.get("morphs", []):
				var mb := Button.new()
				mb.text = "🔀 " + morph.name
				mb.tooltip_text = morph.lore
				mb.pressed.connect(func():
					if SkillManager.choose_morph(sk.id, morph.id):
						NotificationUI.notify_win("The skill chose what it sees. %s" % morph.name)
						get_tree().reload_current_scene())
				btns.add_child(mb)
	list.add_child(row)
