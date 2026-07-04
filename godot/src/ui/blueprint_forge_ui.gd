class_name BlueprintForgeUI
extends CanvasLayer
## The Blueprint Forge — where every weapon, armor set, skill effect and
## entity becomes YOURS. Left: library + kind tabs. Center: live 3D preview
## (SubViewport, slowly rotating). Right: generic parameter controls built
## from BlueprintData defs — sliders, color pickers, choice buttons — plus
## the audio signature section with a "Hear it" button.
## Open with B anywhere, or add_child(BlueprintForgeUI.new()).

var _kind_tabs: TabBar
var _library_list: ItemList
var _controls_box: VBoxContainer
var _preview_vp: SubViewport
var _preview_root: Node3D
var _preview_pivot: Node3D
var _name_edit: LineEdit
var _current: Dictionary = {} # working copy of the selected blueprint

func _ready() -> void:
	layer = 20
	var root := PanelContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.self_modulate = Color(0.08, 0.07, 0.12, 0.97)
	add_child(root)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 12)
	root.add_child(cols)

	# ---- left: library ----
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 260
	cols.add_child(left)
	var title := Label.new()
	title.text = "BLUEPRINT FORGE"
	title.add_theme_font_size_override("font_size", 22)
	left.add_child(title)
	_kind_tabs = TabBar.new()
	for k in BlueprintData.KINDS:
		_kind_tabs.add_tab(k.capitalize())
	_kind_tabs.tab_changed.connect(func(_i): _refresh_library())
	left.add_child(_kind_tabs)
	_library_list = ItemList.new()
	_library_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_library_list.item_selected.connect(_on_select)
	left.add_child(_library_list)
	var new_btn := Button.new()
	new_btn.text = "+ New Blueprint"
	new_btn.pressed.connect(_on_new)
	left.add_child(new_btn)
	var import_row := HBoxContainer.new()
	left.add_child(import_row)
	var code_edit := LineEdit.new()
	code_edit.placeholder_text = "PL1.… share code"
	code_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	import_row.add_child(code_edit)
	var import_btn := Button.new()
	import_btn.text = "Import"
	import_btn.pressed.connect(func():
		var bp := BlueprintManager.import_code(code_edit.text)
		code_edit.clear()
		if not bp.is_empty():
			_refresh_library())
	import_row.add_child(import_btn)
	var close := Button.new()
	close.text = "Close (B)"
	close.pressed.connect(queue_free)
	left.add_child(close)

	# ---- center: live preview ----
	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(center)
	var vpc := SubViewportContainer.new()
	vpc.stretch = true
	vpc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(vpc)
	_preview_vp = SubViewport.new()
	_preview_vp.size = Vector2i(640, 640)
	_preview_vp.transparent_bg = true
	vpc.add_child(_preview_vp)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.2, 3.2)
	cam.look_at_from_position(cam.position, Vector3(0, 0.9, 0))
	_preview_vp.add_child(cam)
	var light := DirectionalLight3D.new()
	light.rotation = Vector3(-0.9, 0.6, 0)
	_preview_vp.add_child(light)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.05, 0.04, 0.09)
	e.glow_enabled = true
	env.environment = e
	_preview_vp.add_child(env)
	_preview_pivot = Node3D.new()
	_preview_vp.add_child(_preview_pivot)

	# ---- right: params ----
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 360
	cols.add_child(right)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Blueprint name"
	_name_edit.text_changed.connect(func(t):
		if not _current.is_empty(): _current["name"] = t)
	right.add_child(_name_edit)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(scroll)
	_controls_box = VBoxContainer.new()
	_controls_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_controls_box)
	var actions := HBoxContainer.new()
	right.add_child(actions)
	for pair in [["Save", _on_save], ["Fork", _on_fork], ["Equip", _on_equip],
			["Share", _on_share], ["Delete", _on_delete]]:
		var b := Button.new()
		b.text = pair[0]
		b.pressed.connect(pair[1])
		actions.add_child(b)

	_refresh_library()

func _process(delta: float) -> void:
	_preview_pivot.rotation.y += delta * 0.6

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_B:
		queue_free()

func _kind() -> String:
	return BlueprintData.KINDS[_kind_tabs.current_tab]

# ---------------------------------------------------------------- library

func _refresh_library() -> void:
	_library_list.clear()
	for bp in BlueprintManager.by_kind(_kind()):
		_library_list.add_item("%s  (by %s)" % [bp.name, bp.author])
		_library_list.set_item_metadata(_library_list.item_count - 1, bp.id)

func _on_select(idx: int) -> void:
	var bp_id: String = _library_list.get_item_metadata(idx)
	_current = BlueprintManager.get_blueprint(bp_id).duplicate(true)
	_name_edit.text = str(_current.get("name", ""))
	_rebuild_controls()
	_rebuild_preview()

func _on_new() -> void:
	var bp := BlueprintManager.create(_kind(), "custom", "New %s" % _kind().capitalize())
	if bp.is_empty():
		return
	_refresh_library()
	_current = bp.duplicate(true)
	_name_edit.text = bp.name
	_rebuild_controls()
	_rebuild_preview()

# ---------------------------------------------------------------- controls

func _rebuild_controls() -> void:
	for c in _controls_box.get_children():
		c.queue_free()
	if _current.is_empty():
		return
	_section("FORM")
	for d in BlueprintData.defs_for(_current.kind):
		_add_control(d, _current.params, _rebuild_preview)
	# Governance: status badge, review submission, and the fork opt-in —
	# forking another creator's work is never possible without this.
	_section("GOVERNANCE")
	var status_lbl := Label.new()
	var status: String = str(_current.get("status", "private"))
	status_lbl.text = "Status: %s%s" % [status.to_upper(),
		"" if status == "canon" else "  (usable only in your Subliminal)"]
	status_lbl.modulate = Color(0.5, 1.0, 0.6) if status == "canon" else Color(1.0, 0.8, 0.5)
	_controls_box.add_child(status_lbl)
	var author_lbl := Label.new()
	author_lbl.text = "Creator: %s — sole crafter of every copy" % str(_current.get("author", "?"))
	author_lbl.modulate = Color(0.7, 0.7, 0.9)
	_controls_box.add_child(author_lbl)
	if str(_current.get("author", "")) == PlayerProfile.username:
		var forks := CheckButton.new()
		forks.text = "Allow others to fork this design"
		forks.button_pressed = bool(_current.get("allow_forks", false))
		forks.toggled.connect(func(on):
			_current["allow_forks"] = on
			BlueprintManager.update(_current)
			_current = BlueprintManager.get_blueprint(str(_current.id)).duplicate(true))
		_controls_box.add_child(forks)
		if status in ["private", "rejected"]:
			var submit := Button.new()
			submit.text = "📜 Submit for canon review (Discord mods → dev team)"
			submit.pressed.connect(func():
				BlueprintManager.update(_current)
				if BlueprintManager.submit_for_review(str(_current.id)):
					_current = BlueprintManager.get_blueprint(str(_current.id)).duplicate(true)
					_rebuild_controls())
			_controls_box.add_child(submit)
	var adefs := BlueprintData.audio_defs_for(_current.kind)
	if not adefs.is_empty():
		_section("SOUND SIGNATURE")
		for d in adefs:
			_add_control(d, _current.audio, func(): pass)
		var hear := Button.new()
		hear.text = "🔊 Hear it"
		hear.pressed.connect(func(): BlueprintAudio.play(self, _current))
		_controls_box.add_child(hear)

func _section(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.modulate = Color(0.7, 0.6, 1.0)
	_controls_box.add_child(lbl)

func _add_control(d: Dictionary, target: Dictionary, on_change: Callable) -> void:
	var row := HBoxContainer.new()
	_controls_box.add_child(row)
	var lbl := Label.new()
	lbl.text = d.label
	lbl.custom_minimum_size.x = 130
	row.add_child(lbl)
	match d.type:
		"float":
			var slider := HSlider.new()
			slider.min_value = d.min
			slider.max_value = d.max
			slider.step = (d.max - d.min) / 100.0
			slider.value = float(target.get(d.key, d.def))
			slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			slider.value_changed.connect(func(v):
				target[d.key] = v
				on_change.call())
			row.add_child(slider)
		"color":
			var pick := ColorPickerButton.new()
			pick.color = target.get(d.key, d.def)
			pick.custom_minimum_size = Vector2(120, 28)
			pick.color_changed.connect(func(c):
				target[d.key] = c
				on_change.call())
			row.add_child(pick)
		"choice":
			var opt := OptionButton.new()
			for choice in d.choices:
				opt.add_item(choice)
			opt.selected = d.choices.find(str(target.get(d.key, d.def)))
			opt.item_selected.connect(func(i):
				target[d.key] = d.choices[i]
				on_change.call())
			row.add_child(opt)

# ---------------------------------------------------------------- preview

func _rebuild_preview() -> void:
	for c in _preview_pivot.get_children():
		c.queue_free()
	if _current.is_empty():
		return
	if _current.kind == "skill":
		# Skills preview as a repeating cast on an invisible caster.
		var ground := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(4, 4)
		ground.mesh = pm
		_preview_pivot.add_child(ground)
		_pulse_skill_preview()
	else:
		_preview_pivot.add_child(BlueprintMesh.build(_current))

func _pulse_skill_preview() -> void:
	if _current.is_empty() or _current.kind != "skill" or not is_inside_tree():
		return
	SkillVFX.blueprint_cast(_preview_pivot, Vector3.ZERO, _current)
	get_tree().create_timer(1.2).timeout.connect(_pulse_skill_preview)

# ---------------------------------------------------------------- actions

func _on_save() -> void:
	if _current.is_empty():
		return
	BlueprintManager.update(_current)
	_refresh_library()
	NotificationUI.notify_win("Blueprint saved.")

func _on_fork() -> void:
	if _current.is_empty():
		return
	BlueprintManager.update(_current)
	var copy := BlueprintManager.fork(_current.id)
	if not copy.is_empty():
		_current = copy.duplicate(true)
		_name_edit.text = copy.name
		_refresh_library()

func _on_equip() -> void:
	if _current.is_empty():
		return
	BlueprintManager.update(_current)
	# Slot key: base_id for gear/entities; the skill picker uses skill ids.
	BlueprintManager.equip(_current.id, str(_current.get("base_id", "custom")))
	NotificationUI.notify_win("'%s' equipped — the world now renders your design." % _current.name)

func _on_share() -> void:
	if _current.is_empty():
		return
	BlueprintManager.update(_current)
	var code := BlueprintManager.export_code(_current.id)
	DisplayServer.clipboard_set(code)
	NotificationUI.notify_info("Share code copied to clipboard (%d chars)." % code.length())

func _on_delete() -> void:
	if _current.is_empty():
		return
	BlueprintManager.remove(_current.id)
	_current = {}
	_refresh_library()
	_rebuild_controls()
	_rebuild_preview()
