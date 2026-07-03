extends Node3D
## The Subliminal apartment — every player's start screen AND their UGC
## studio, a studio-flat-sized interior (SubliminalManager.APARTMENT_GRID
## slots on the floor). Walls close, lights low, the theme song playing:
## this is the one calm room in the whole cosmology.
##
## - Click a floor slot to cycle it through your unlocked entities as
##   placed BLUEPRINTS (EntityBlueprint forks — remix then submit later).
## - The side panel handles invites (3 outstanding max, creator sub
##   raises it) and shows your build's rarity line.

const SLOT_SIZE := 2.0

var _slots: Dictionary = {} # Vector2i -> MeshInstance3D
var _panel_status: Label

func _ready() -> void:
	LayerManager.current_layer_id = "subliminal"
	_build_room()
	_build_camera()
	add_child(SensoriumAmbience.new())
	_build_panel()
	SubliminalManager.apartment_updated.connect(_refresh_slots)
	_refresh_slots()

func _build_room() -> void:
	var grid: Vector2i = SubliminalManager.APARTMENT_GRID
	var w := grid.x * SLOT_SIZE
	var d := grid.y * SLOT_SIZE

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.04, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.45, 0.6)
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	# Floor — hard mesh, so even your own apartment is made of your race.
	var floor_mi := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(w + 2, 0.4, d + 2)
	floor_mi.mesh = floor_mesh
	floor_mi.position.y = -0.2
	floor_mi.material_override = IdentityLens.world_material(Color(0.35, 0.3, 0.4))
	add_child(floor_mi)

	# Walls
	for wall in [
		{size=Vector3(w + 2, 4, 0.3), pos=Vector3(0, 2, -d / 2 - 1)},
		{size=Vector3(w + 2, 4, 0.3), pos=Vector3(0, 2, d / 2 + 1)},
		{size=Vector3(0.3, 4, d + 2), pos=Vector3(-w / 2 - 1, 2, 0)},
		{size=Vector3(0.3, 4, d + 2), pos=Vector3(w / 2 + 1, 2, 0)},
	]:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = wall.size
		mi.mesh = box
		mi.position = wall.pos
		mi.material_override = IdentityLens.world_material(Color(0.25, 0.22, 0.3), 0.5)
		add_child(mi)

	# One warm lamp — the calm room.
	var lamp := OmniLight3D.new()
	lamp.light_color = IdentityLens.sensorium().light
	lamp.light_energy = 1.4
	lamp.position = Vector3(0, 3.2, 0)
	add_child(lamp)

	# Slot markers
	for x in range(grid.x):
		for y in range(grid.y):
			var slot := _make_slot(Vector2i(x, y), w, d)
			_slots[Vector2i(x, y)] = slot

func _make_slot(gpos: Vector2i, w: float, d: float) -> MeshInstance3D:
	var grid: Vector2i = SubliminalManager.APARTMENT_GRID
	var mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(SLOT_SIZE * 0.85, SLOT_SIZE * 0.85)
	mi.mesh = plane
	mi.position = Vector3(
		(gpos.x - grid.x / 2.0 + 0.5) * SLOT_SIZE, 0.02,
		(gpos.y - grid.y / 2.0 + 0.5) * SLOT_SIZE)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.4, 0.55, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat

	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(SLOT_SIZE * 0.85, 0.5, SLOT_SIZE * 0.85)
	cs.shape = box
	area.add_child(cs)
	area.input_ray_pickable = true
	area.input_event.connect(func(_cam, ev, _pos, _n, _i):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_cycle_slot(gpos))
	mi.add_child(area)
	add_child(mi)
	return mi

## Click cycles the slot: empty -> next unlocked entity blueprint -> empty.
func _cycle_slot(gpos: Vector2i) -> void:
	var key := "%d,%d" % [gpos.x, gpos.y]
	var unlocked: Array[String] = []
	for c in CompanionSystem.roster:
		if c.is_unlocked:
			unlocked.append(str(c.id))
	if unlocked.is_empty():
		NotificationUI.notify_info("Unlock entities first — every one of them is a blueprint waiting.")
		return
	var current: String = SubliminalManager.apartment_slots.get(key, {}).get("blueprint_id", "")
	var idx := unlocked.find(current)
	if idx == unlocked.size() - 1:
		SubliminalManager.clear_apartment_slot(gpos)
	else:
		SubliminalManager.place_in_apartment(gpos, unlocked[idx + 1])

func _refresh_slots() -> void:
	for gpos in _slots.keys():
		var slot: MeshInstance3D = _slots[gpos]
		for child in slot.get_children():
			if child.name == "Placed":
				child.queue_free()
		var key := "%d,%d" % [gpos.x, gpos.y]
		var placed: Dictionary = SubliminalManager.apartment_slots.get(key, {})
		if placed.is_empty():
			continue
		var bp := EntityBlueprint.fork(str(placed.get("blueprint_id", "")))
		var mi := MeshInstance3D.new()
		mi.name = "Placed"
		var caps := CapsuleMesh.new()
		caps.radius = 0.3
		caps.height = 1.0
		mi.mesh = caps
		mi.position.y = 0.6
		var ent := CompanionRegistry.get_by_id(str(placed.get("blueprint_id", "")))
		var profile := {"level": 1, "faction": ent.get("faction", ""), "alignment": "neutral",
			"stats": {"pow": ent.get("pow", 10)}}
		mi.material_override = IdentityLens.perceive_being(profile, Color(0.6, 0.6, 0.8)).material
		mi.set_meta("blueprint", bp)
		slot.add_child(mi)

func _build_camera() -> void:
	var cam := Camera3D.new()
	cam.position = Vector3(0, 9, 11)
	cam.rotation_degrees = Vector3(-42, 0, 0)
	cam.current = true
	add_child(cam)

func _build_panel() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var box := VBoxContainer.new()
	box.position = Vector2(10, 10)
	box.custom_minimum_size = Vector2(320, 0)
	layer.add_child(box)

	var title := Label.new()
	title.text = "🚪 THE APARTMENT"
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)

	var rarity := Label.new()
	rarity.text = IdentityLens.rarity_text()
	rarity.modulate = Color(1.0, 0.85, 0.4)
	box.add_child(rarity)

	var hint := Label.new()
	hint.text = "Click floor slots to place your entities as blueprints."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.7, 0.7, 0.8)
	box.add_child(hint)

	_panel_status = Label.new()
	_panel_status.text = "Invites left: %d / %d" % [SubliminalManager.invites_left(), SubliminalManager.invite_cap()]
	box.add_child(_panel_status)

	var invite := Button.new()
	invite.text = "Send invite ✉️"
	invite.pressed.connect(func():
		var code := SubliminalManager.send_invite()
		if code != "":
			_panel_status.text = "Code %s — invites left: %d / %d" % [
				code, SubliminalManager.invites_left(), SubliminalManager.invite_cap()])
	box.add_child(invite)

	if not SubliminalManager.is_creator():
		var sub := Button.new()
		sub.text = "Creator subscription (%d 🪙/30d)" % SubliminalManager.CREATOR_SUB_COINS
		sub.pressed.connect(func():
			if await SubliminalManager.buy_creator_subscription():
				_panel_status.text = "Creator active — invites left: %d / %d" % [
					SubliminalManager.invites_left(), SubliminalManager.invite_cap()])
		box.add_child(sub)

	var leave := Button.new()
	leave.text = "⬅ Step out"
	leave.pressed.connect(func(): LayerManager.transition_to("hyperliminal"))
	box.add_child(leave)
