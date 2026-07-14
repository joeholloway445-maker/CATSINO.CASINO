extends Control
class_name PeriHumanCreatorUI
## The PeriHuman Character Studio — Periliminal's in-engine answer to the
## MetaHuman Creator web app. Everything happens live against a real
## PeriHumanRig in an orbitable viewport:
##
##   Presets    — the starting-face gallery + 3-way preset DNA blending
##   Body/Face  — every HumanDNA gene as a live sculpt slider
##   Appearance — skin, eyes, hair, grooming
##   Expression — test the facial morphs before you commit
##
## Genomes save as JSON under user://perihuman/ and "Use This Human" writes
## the genome onto PlayerProfile, where MetahumanCharacter picks it up as
## the player's body.

const SAVE_DIR := "user://perihuman"
const REBUILD_DELAY := 0.15

var _dna: HumanDNA
var _rig: PeriHumanRig
var _viewport: SubViewport
var _camera: Camera3D
var _rebuild_timer: Timer
var _syncing := false

var _name_edit: LineEdit
var _gene_sliders: Dictionary = {}   # gene id -> HSlider
var _eye_picker: ColorPickerButton
var _hair_picker: ColorPickerButton
var _hair_option: OptionButton
var _blend_options: Array[OptionButton] = []
var _blend_sliders: Array[HSlider] = []
var _saved_list: ItemList
var _race_option: OptionButton
var _frame_option: OptionButton
var _mod_option: OptionButton

var _cam_yaw := 0.0
var _cam_pitch := 0.05
var _cam_dist := 2.6
var _cam_focus := Vector3(0, 1.0, 0)

func _ready() -> void:
	_dna = HumanPresets.get_preset(0)
	if PlayerProfile and not PlayerProfile.perihuman_dna.is_empty():
		_dna = HumanDNA.from_dict(PlayerProfile.perihuman_dna)
	_rebuild_timer = Timer.new()
	_rebuild_timer.one_shot = true
	_rebuild_timer.wait_time = REBUILD_DELAY
	_rebuild_timer.timeout.connect(_rebuild_now)
	add_child(_rebuild_timer)
	_build_ui()
	_sync_ui_from_dna()
	_update_camera()

# ----------------------------------------------------------------- UI build

func _build_ui() -> void:
	var root := HBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# ---- left: toolbar + live 3D preview
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(left)

	var bar := HBoxContainer.new()
	left.add_child(bar)
	_add_button(bar, "← Back", func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	var title := Label.new()
	title.text = "  🧬 PERIHUMAN CHARACTER STUDIO"
	title.add_theme_font_size_override("font_size", 18)
	bar.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	_name_edit = LineEdit.new()
	_name_edit.custom_minimum_size = Vector2(180, 0)
	_name_edit.placeholder_text = "Name"
	_name_edit.text_changed.connect(func(t: String): _dna.display_name = t)
	bar.add_child(_name_edit)
	_add_button(bar, "🎲 Randomize", _on_randomize)
	_add_button(bar, "💾 Save", _on_save)
	_add_button(bar, "✅ Use This Human", _on_use)

	var vp_container := SubViewportContainer.new()
	vp_container.stretch = true
	vp_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vp_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vp_container.gui_input.connect(_on_viewport_input)
	left.add_child(vp_container)
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	vp_container.add_child(_viewport)
	_build_stage()

	var frame_bar := HBoxContainer.new()
	left.add_child(frame_bar)
	_add_button(frame_bar, "👤 Frame Face", func(): _frame(true))
	_add_button(frame_bar, "🧍 Frame Body", func(): _frame(false))
	var hint := Label.new()
	hint.text = "   drag to orbit · wheel to zoom"
	hint.modulate = Color(1, 1, 1, 0.6)
	frame_bar.add_child(hint)

	# ---- right: tabbed genome editor
	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(430, 0)
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(tabs)
	_build_identity_tab(tabs)
	_build_presets_tab(tabs)
	_build_gene_tab(tabs, "Body", ["Body"])
	_build_gene_tab(tabs, "Face", ["Head", "Brow", "Eyes", "Nose", "Cheeks", "Mouth", "Jaw"])
	_build_appearance_tab(tabs)
	_build_saved_tab(tabs)

func _add_button(parent: Node, text: String, handler: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.pressed.connect(handler)
	parent.add_child(btn)
	return btn

func _scroll_vbox(tabs: TabContainer, tab_name: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = tab_name
	tabs.add_child(scroll)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	return vbox

func _build_stage() -> void:
	var stage := Node3D.new()
	_viewport.add_child(stage)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.09, 0.09, 0.12)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.58, 0.68)
	e.ambient_light_energy = 0.6
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	stage.add_child(env)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, 30, 0)
	key.light_energy = 1.4
	key.shadow_enabled = true
	stage.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, 205, 0)
	rim.light_energy = 0.7
	rim.light_color = Color(0.7, 0.8, 1.0)
	stage.add_child(rim)

	var pedestal := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.7
	disc.bottom_radius = 0.8
	disc.height = 0.06
	pedestal.mesh = disc
	pedestal.position.y = -0.03
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.15, 0.15, 0.19)
	pmat.roughness = 0.9
	pedestal.material_override = pmat
	stage.add_child(pedestal)

	_camera = Camera3D.new()
	_camera.fov = 40
	stage.add_child(_camera)

	_rig = PeriHumanRig.new()
	_rig.dna = _dna
	stage.add_child(_rig)

## Generates a human from the player's actual gameplay identity (race,
## sensorium frame, mod) via HumanIdentity, instead of hand-sculpting.
## This is what a citizen wearing your race/frame/mod actually looks like.
func _build_identity_tab(tabs: TabContainer) -> void:
	var vbox := _scroll_vbox(tabs, "Identity")
	_section(vbox, "GENERATE FROM RACE / FRAME / MOD")
	var note := Label.new()
	note.text = "Builds a human from the same race, sensorium\nframe, and mod your character sheet uses —\nstill editable afterward on every other tab."
	note.modulate = Color(1, 1, 1, 0.6)
	vbox.add_child(note)

	var race_row := HBoxContainer.new()
	vbox.add_child(race_row)
	var race_lbl := Label.new()
	race_lbl.text = "Race"
	race_lbl.custom_minimum_size = Vector2(80, 0)
	race_row.add_child(race_lbl)
	_race_option = OptionButton.new()
	for race in RaceDataCharacter.RACES:
		_race_option.add_item(str(race.name))
	race_row.add_child(_race_option)

	var frame_row := HBoxContainer.new()
	vbox.add_child(frame_row)
	var frame_lbl := Label.new()
	frame_lbl.text = "Frame"
	frame_lbl.custom_minimum_size = Vector2(80, 0)
	frame_row.add_child(frame_lbl)
	_frame_option = OptionButton.new()
	for frame in FrameModData.FRAMES:
		_frame_option.add_item("%s (%s)" % [str(frame.name), str(frame.type)])
	frame_row.add_child(_frame_option)

	var mod_row := HBoxContainer.new()
	vbox.add_child(mod_row)
	var mod_lbl := Label.new()
	mod_lbl.text = "Mod"
	mod_lbl.custom_minimum_size = Vector2(80, 0)
	mod_row.add_child(mod_lbl)
	_mod_option = OptionButton.new()
	_mod_option.add_item("None")
	for mod in FrameModData.MODS:
		_mod_option.add_item(str(mod.name))
	mod_row.add_child(_mod_option)

	_race_option.selected = 0
	_frame_option.selected = 0
	_mod_option.selected = 0
	if PlayerProfile:
		_select_by_id(_race_option, RaceDataCharacter.RACES, PlayerProfile.selected_race_id)
		_select_by_id(_frame_option, FrameModData.FRAMES, PlayerProfile.selected_frame)
		_select_by_id(_mod_option, FrameModData.MODS, PlayerProfile.selected_mod, 1)

	_add_button(vbox, "🧬 Generate", _on_generate_identity)

func _select_by_id(option: OptionButton, table: Array, id: String, index_offset: int = 0) -> void:
	for i in table.size():
		if table[i].id == id:
			option.selected = i + index_offset
			return

func _on_generate_identity() -> void:
	var race_id := ""
	if _race_option.selected >= 0:
		race_id = str(RaceDataCharacter.RACES[_race_option.selected].id)
	var frame_id := ""
	if _frame_option.selected >= 0:
		frame_id = str(FrameModData.FRAMES[_frame_option.selected].id)
	var mod_id := ""
	if _mod_option.selected >= 1:
		mod_id = str(FrameModData.MODS[_mod_option.selected - 1].id)
	var seed_value := (PlayerProfile.username.hash() if PlayerProfile else 0) ^ race_id.hash()
	_load_dna(HumanIdentity.build(race_id, frame_id, mod_id, seed_value))

func _build_presets_tab(tabs: TabContainer) -> void:
	var vbox := _scroll_vbox(tabs, "Presets")
	_section(vbox, "STARTING HUMANS")
	var grid := GridContainer.new()
	grid.columns = 3
	vbox.add_child(grid)
	for i in HumanPresets.count():
		var idx := i
		var btn := Button.new()
		btn.text = HumanPresets.PRESETS[i].name
		btn.custom_minimum_size = Vector2(130, 44)
		btn.pressed.connect(func(): _load_dna(HumanPresets.get_preset(idx)))
		grid.add_child(btn)

	_section(vbox, "BLEND THREE HUMANS")
	var note := Label.new()
	note.text = "Mix preset genomes by weight — the\nMetaHuman-Creator blend workflow."
	note.modulate = Color(1, 1, 1, 0.6)
	vbox.add_child(note)
	for i in 3:
		var row := HBoxContainer.new()
		vbox.add_child(row)
		var opt := OptionButton.new()
		for preset_name in HumanPresets.names():
			opt.add_item(preset_name)
		opt.selected = i * 3 % HumanPresets.count()
		opt.item_selected.connect(func(_idx: int): _apply_blend())
		row.add_child(opt)
		_blend_options.append(opt)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
		slider.value = 1.0 if i == 0 else 0.0
		slider.custom_minimum_size = Vector2(200, 0)
		slider.value_changed.connect(func(_v: float): _apply_blend())
		row.add_child(slider)
		_blend_sliders.append(slider)

	_section(vbox, "EXPRESSION TEST (preview only)")
	for morph in HumanMeshBuilder.MORPHS:
		var row := HBoxContainer.new()
		vbox.add_child(row)
		var lbl := Label.new()
		lbl.text = morph.capitalize()
		lbl.custom_minimum_size = Vector2(120, 0)
		row.add_child(lbl)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
		slider.custom_minimum_size = Vector2(200, 0)
		var morph_id := morph
		slider.value_changed.connect(func(v: float): _rig.set_expression(morph_id, v))
		row.add_child(slider)

func _build_gene_tab(tabs: TabContainer, tab_name: String, groups: Array) -> void:
	_build_gene_tab_into(_scroll_vbox(tabs, tab_name), groups)

func _build_appearance_tab(tabs: TabContainer) -> void:
	var vbox := _scroll_vbox(tabs, "Appearance")
	_build_gene_tab_into(vbox, ["Skin"])

	_section(vbox, "EYES")
	var eye_row := HBoxContainer.new()
	vbox.add_child(eye_row)
	var eye_lbl := Label.new()
	eye_lbl.text = "Eye Color"
	eye_lbl.custom_minimum_size = Vector2(150, 0)
	eye_row.add_child(eye_lbl)
	_eye_picker = ColorPickerButton.new()
	_eye_picker.custom_minimum_size = Vector2(80, 0)
	_eye_picker.color_changed.connect(func(c: Color):
		_dna.eye_color = c
		_queue_rebuild())
	eye_row.add_child(_eye_picker)

	_section(vbox, "HAIR")
	var style_row := HBoxContainer.new()
	vbox.add_child(style_row)
	var style_lbl := Label.new()
	style_lbl.text = "Style"
	style_lbl.custom_minimum_size = Vector2(150, 0)
	style_row.add_child(style_lbl)
	_hair_option = OptionButton.new()
	for style in HumanDNA.HAIR_STYLES:
		_hair_option.add_item(style.capitalize())
	_hair_option.item_selected.connect(func(idx: int):
		_dna.hair_style = HumanDNA.HAIR_STYLES[idx]
		_queue_rebuild())
	style_row.add_child(_hair_option)
	var hair_row := HBoxContainer.new()
	vbox.add_child(hair_row)
	var hair_lbl := Label.new()
	hair_lbl.text = "Hair Color"
	hair_lbl.custom_minimum_size = Vector2(150, 0)
	hair_row.add_child(hair_lbl)
	_hair_picker = ColorPickerButton.new()
	_hair_picker.custom_minimum_size = Vector2(80, 0)
	_hair_picker.color_changed.connect(func(c: Color):
		_dna.hair_color = c
		_queue_rebuild())
	hair_row.add_child(_hair_picker)

func _build_gene_tab_into(vbox: VBoxContainer, groups: Array) -> void:
	for group in groups:
		_section(vbox, str(group).to_upper())
		for def in HumanDNA.GENES:
			if def.group != group:
				continue
			var row := HBoxContainer.new()
			vbox.add_child(row)
			var lbl := Label.new()
			lbl.text = def.label
			lbl.custom_minimum_size = Vector2(150, 0)
			row.add_child(lbl)
			var slider := HSlider.new()
			slider.min_value = 0.0
			slider.max_value = 1.0
			slider.step = 0.01
			slider.custom_minimum_size = Vector2(220, 0)
			slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var gene_id: String = def.id
			slider.value_changed.connect(func(v: float): _on_gene_changed(gene_id, v))
			row.add_child(slider)
			_gene_sliders[gene_id] = slider

func _build_saved_tab(tabs: TabContainer) -> void:
	var vbox := _scroll_vbox(tabs, "Saved")
	_section(vbox, "SAVED HUMANS  (user://perihuman)")
	_saved_list = ItemList.new()
	_saved_list.custom_minimum_size = Vector2(0, 320)
	vbox.add_child(_saved_list)
	var row := HBoxContainer.new()
	vbox.add_child(row)
	_add_button(row, "Load", _on_load_selected)
	_add_button(row, "Delete", _on_delete_selected)
	_add_button(row, "Refresh", _refresh_saved_list)
	_refresh_saved_list()

func _section(vbox: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = "\n" + text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.modulate = Color(0.7, 0.85, 1.0)
	vbox.add_child(lbl)

# ------------------------------------------------------------------ actions

func _on_gene_changed(gene_id: String, v: float) -> void:
	if _syncing:
		return
	_dna.set_gene(gene_id, v)
	_queue_rebuild()

func _apply_blend() -> void:
	if _syncing:
		return
	var parents := []
	for i in 3:
		var w := _blend_sliders[i].value
		if w > 0.001:
			parents.append([HumanPresets.get_preset(_blend_options[i].selected), w])
	if parents.is_empty():
		return
	var keep_name := _dna.display_name
	_dna = HumanDNA.blend(parents)
	_dna.display_name = keep_name
	_sync_ui_from_dna()
	_queue_rebuild()

func _load_dna(dna: HumanDNA) -> void:
	_dna = dna
	_sync_ui_from_dna()
	_queue_rebuild()

func _on_randomize() -> void:
	_load_dna(HumanDNA.random(randi()))

func _queue_rebuild() -> void:
	_rebuild_timer.start()

func _rebuild_now() -> void:
	_rig.apply_dna(_dna)

func _sync_ui_from_dna() -> void:
	_syncing = true
	_name_edit.text = _dna.display_name
	for gene_id in _gene_sliders:
		(_gene_sliders[gene_id] as HSlider).value = _dna.get_gene(gene_id)
	_eye_picker.color = _dna.eye_color
	_hair_picker.color = _dna.hair_color
	_hair_option.selected = maxi(0, HumanDNA.HAIR_STYLES.find(_dna.hair_style))
	_syncing = false

# -------------------------------------------------------------- persistence

func _slug() -> String:
	var s := _dna.display_name.to_lower().strip_edges()
	var out := ""
	for c in s:
		out += c if c.is_valid_identifier() or c.is_valid_int() else "_"
	return out if out != "" else "human"

func _on_save() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var path := "%s/%s.json" % [SAVE_DIR, _slug()]
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_notify("Couldn't write " + path, true)
		return
	f.store_string(JSON.stringify(_dna.to_dict(), "\t"))
	f.close()
	_notify("Saved %s" % _dna.display_name)
	_refresh_saved_list()

func _refresh_saved_list() -> void:
	if _saved_list == null:
		return
	_saved_list.clear()
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return
	for file in dir.get_files():
		if file.ends_with(".json"):
			_saved_list.add_item(file.trim_suffix(".json"))

func _on_load_selected() -> void:
	var sel := _saved_list.get_selected_items()
	if sel.is_empty():
		return
	var path := "%s/%s.json" % [SAVE_DIR, _saved_list.get_item_text(sel[0])]
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Dictionary:
		_load_dna(HumanDNA.from_dict(data))

func _on_delete_selected() -> void:
	var sel := _saved_list.get_selected_items()
	if sel.is_empty():
		return
	DirAccess.remove_absolute("%s/%s.json" % [SAVE_DIR, _saved_list.get_item_text(sel[0])])
	_refresh_saved_list()

func _on_use() -> void:
	if PlayerProfile:
		PlayerProfile.set_perihuman_dna(_dna.to_dict())
	_notify("%s is now your human." % _dna.display_name)

func _notify(msg: String, is_error := false) -> void:
	if NotificationUI != null:
		if is_error:
			NotificationUI.notify_error(msg)
		else:
			NotificationUI.notify_info(msg)

# ------------------------------------------------------------------- camera

func _frame(face: bool) -> void:
	var h: float = _dna.gene_lerp("height", 1.52, 2.02)
	if face:
		_cam_focus = Vector3(0, h - 0.09, 0)
		_cam_dist = 0.65
	else:
		_cam_focus = Vector3(0, h * 0.54, 0)
		_cam_dist = 2.6
	_update_camera()

func _on_viewport_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null and (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_cam_yaw -= motion.relative.x * 0.01
		_cam_pitch = clampf(_cam_pitch + motion.relative.y * 0.008, -0.9, 0.9)
		_update_camera()
		return
	var click := event as InputEventMouseButton
	if click != null and click.pressed:
		if click.button_index == MOUSE_BUTTON_WHEEL_UP:
			_cam_dist = maxf(0.35, _cam_dist * 0.9)
			_update_camera()
		elif click.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_cam_dist = minf(6.0, _cam_dist * 1.1)
			_update_camera()

func _update_camera() -> void:
	if _camera == null:
		return
	var dir := Vector3(
		sin(_cam_yaw) * cos(_cam_pitch),
		sin(_cam_pitch),
		cos(_cam_yaw) * cos(_cam_pitch))
	_camera.position = _cam_focus + dir * _cam_dist
	_camera.look_at(_cam_focus)
