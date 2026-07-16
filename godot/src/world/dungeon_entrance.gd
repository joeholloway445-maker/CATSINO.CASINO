class_name DungeonEntrance
extends Area3D
## Gate 6 — Instanced party dungeon door. Reuses a generated-then-static
## seed ledger (DungeonRuns) but WITHOUT the Periliminal wipe rule.

signal entered(dungeon_id: String, seed: int)

var dungeon_id := ""
var hub_id := ""

static func place_for_hub(city_root: Node3D, p_hub_id: String, base_y: float) -> void:
	var door := DungeonEntrance.new()
	door.hub_id = p_hub_id
	door.dungeon_id = "dungeon_%s" % p_hub_id
	var size := OsmCityLayout.size_of(p_hub_id)
	if size.x > 0.0:
		door.position = Vector3(size.x * 0.82, base_y, size.y * 0.82)
	else:
		door.position = Vector3(3.0 * CityData.CELL, base_y, 3.0 * CityData.CELL)
	city_root.add_child(door)

func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = 0
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4.0, 4.0, 4.0)
	cs.shape = box
	cs.position.y = 2.0
	add_child(cs)
	var visual := AssetLibrary.instance("extraction_gate")
	if visual == null:
		visual = MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(3.2, 4.5, 0.4)
		(visual as MeshInstance3D).mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.15, 0.2, 0.35)
		mat.emission_enabled = true
		mat.emission = Color(0.3, 0.55, 1.0)
		mat.emission_energy_multiplier = 1.4
		(visual as MeshInstance3D).material_override = mat
		visual.position.y = 2.25
	add_child(visual)
	var label := Label3D.new()
	label.text = "DUNGEON"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 5.0
	label.font_size = 42
	label.modulate = Color(0.6, 0.85, 1.0)
	add_child(label)
	body_entered.connect(_on_body)

func _on_body(body: Node) -> void:
	if body == null:
		return
	if not (body is ThirdPersonController or body.is_in_group("player")):
		return
	_enter()

func _enter() -> void:
	var seed := DungeonRuns.begin(dungeon_id)
	var fee := mini(10, EconomyManager.get_balance("fragments"))
	if fee > 0:
		EconomyManager.spend_currency("fragments", fee, "dungeon_entry")
	QuestManager.update_progress("enter_dungeon")
	NotificationUI.notify_info("Dungeon seal opened — seed %d. Death ejects; no wipe." % seed)
	entered.emit(dungeon_id, seed)
	LayerManager.transition_to("periliminal")
