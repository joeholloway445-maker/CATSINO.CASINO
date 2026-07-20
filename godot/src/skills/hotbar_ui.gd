class_name HotbarUI
extends CanvasLayer
## The combat hotbar: 5 actives (keys 1-5) + ultimate (R), bar swap (Tab).
## Shows cooldown sweeps, flux bar, ultimate charge, element tint, and a
## brief cast windup flash. Emits cast_requested — the hosting scene resolves
## the effect (it knows its targets).

signal cast_requested(skill: Dictionary)

var _cooldowns: Dictionary = {} # skill_id -> seconds left
var _slots: Array[Button] = []
var _ult_btn: Button
var _flux_bar: ProgressBar
var _ult_bar: ProgressBar
var _bar_label: Label
var _cast_label: Label
var _casting := false

func _ready() -> void:
	var root := HBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	root.position.y -= 90
	add_child(root)

	_bar_label = Label.new()
	_bar_label.text = "I"
	_bar_label.add_theme_font_size_override("font_size", 22)
	root.add_child(_bar_label)

	for i in range(5):
		var b := Button.new()
		b.custom_minimum_size = Vector2(64, 64)
		var idx := i
		b.pressed.connect(func(): _cast_slot(idx))
		root.add_child(b)
		_slots.append(b)

	_ult_btn = Button.new()
	_ult_btn.custom_minimum_size = Vector2(80, 64)
	_ult_btn.pressed.connect(_cast_ultimate)
	root.add_child(_ult_btn)

	var bars := VBoxContainer.new()
	bars.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	bars.position.y -= 20
	bars.custom_minimum_size = Vector2(420, 0)
	add_child(bars)
	_flux_bar = ProgressBar.new()
	_flux_bar.show_percentage = false
	_flux_bar.custom_minimum_size = Vector2(420, 8)
	_flux_bar.modulate = Color(0.4, 0.7, 1.0)
	bars.add_child(_flux_bar)
	_ult_bar = ProgressBar.new()
	_ult_bar.show_percentage = false
	_ult_bar.custom_minimum_size = Vector2(420, 6)
	_ult_bar.modulate = Color(1.0, 0.8, 0.2)
	bars.add_child(_ult_bar)
	_cast_label = Label.new()
	_cast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cast_label.add_theme_font_size_override("font_size", 14)
	_cast_label.modulate = Color(1.0, 0.92, 0.55)
	bars.add_child(_cast_label)

	SkillManager.bar_swapped.connect(func(_b): _refresh())
	SkillManager.ultimate_ready.connect(func(): NotificationUI.notify_info("⚡ ULTIMATE READY"))
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: _cast_slot(0)
			KEY_2: _cast_slot(1)
			KEY_3: _cast_slot(2)
			KEY_4: _cast_slot(3)
			KEY_5: _cast_slot(4)
			KEY_R: _cast_ultimate()
			KEY_TAB: SkillManager.swap_bar()

func _cast_slot(i: int) -> void:
	if _casting:
		return
	var sid: String = SkillManager.current_bar().actives[i]
	if sid == "":
		return
	if _cooldowns.get(sid, 0.0) > 0.0:
		return
	var sk := SkillManager.resolved(sid)
	if sk.is_empty():
		return
	if not SkillManager.try_pay_flux(float(sk.get("cost", 20))):
		NotificationUI.notify_info("Not enough flux.")
		return
	_cooldowns[sid] = float(sk.get("cooldown", 5.0))
	SkillManager.add_skill_xp(sid)
	_flash_cast(sk)
	cast_requested.emit(sk)

func _cast_ultimate() -> void:
	if _casting:
		return
	var sid: String = SkillManager.current_bar().ultimate
	if sid == "":
		return
	var sk := SkillManager.resolved(sid)
	if not SkillManager.try_pay_ultimate(float(sk.get("ult_cost", 100))):
		NotificationUI.notify_info("Ultimate still charging.")
		return
	SkillManager.add_skill_xp(sid, 20)
	_flash_cast(sk)
	cast_requested.emit(sk)

func _flash_cast(sk: Dictionary) -> void:
	_casting = true
	var elem := str(sk.get("element", ""))
	var tint := SkillCastResolver.element_color(elem)
	var sname := str(sk.get("name", "?"))
	_cast_label.text = "▸ %s%s" % [sname, (" · " + elem.capitalize()) if elem != "" else ""]
	if tint.a > 0.0:
		_cast_label.modulate = tint
	var wind := SkillCastResolver.windup_for(sk)
	get_tree().create_timer(maxf(wind, 0.18)).timeout.connect(func():
		_casting = false
		_cast_label.text = "")

func _process(delta: float) -> void:
	for sid in _cooldowns.keys():
		_cooldowns[sid] = maxf(_cooldowns[sid] - delta, 0.0)
	_flux_bar.max_value = SkillManager.flux_max
	_flux_bar.value = SkillManager.flux
	var ult := SkillManager.resolved(SkillManager.current_bar().ultimate)
	_ult_bar.max_value = float(ult.get("ult_cost", 100))
	_ult_bar.value = minf(SkillManager.ultimate_charge, _ult_bar.max_value)
	_refresh_labels()

func _refresh() -> void:
	_bar_label.text = ["I", "II"][SkillManager.active_bar] + (" ⇄" if SkillManager.can_swap() else "")
	_refresh_labels()

func _refresh_labels() -> void:
	var bar := SkillManager.current_bar()
	for i in range(5):
		var sid: String = bar.actives[i]
		var b := _slots[i]
		if sid == "":
			b.text = str(i + 1)
			b.disabled = true
			b.modulate = Color.WHITE
			continue
		b.disabled = false
		var sk := SkillManager.resolved(sid)
		var cd: float = _cooldowns.get(sid, 0.0)
		var elem := str(sk.get("element", ""))
		var tip := (" ·" + elem.left(3).to_upper()) if elem != "" else ""
		b.text = "%d\n%s%s%s" % [i + 1, str(sk.get("name", "?")).left(9), tip,
			("\n%.0fs" % cd) if cd > 0.0 else ""]
		var tint := SkillCastResolver.element_color(elem)
		b.modulate = Color(1, 1, 1).lerp(tint, 0.35) if tint.a > 0.0 else Color.WHITE
		if cd > 0.0:
			b.modulate = b.modulate.darkened(0.35)
	var usid: String = bar.ultimate
	if usid == "":
		_ult_btn.text = "R"
	else:
		_ult_btn.text = "R\n%s" % str(SkillManager.resolved(usid).get("name", "?")).left(12)
