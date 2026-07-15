class_name EntityCombatSpawner
extends RefCounted
## Places real, fightable hostile encounters from the 600-entity
## EntityDexData roster into wild chunks. Before this, the roster existed
## purely as lore/name data with zero numeric stats and nothing ever
## instantiated a single entity into the 3D world — combat had no way to
## actually happen outside the disconnected combat_ui.tscn dev scene.
##
## Known remaining gap, deliberately not solved here: there's no dedicated
## combat UI screen popping up on encounter (combat_ui.tscn isn't wired to
## anything reachable either — a separate, pre-existing issue). Once
## CombatRealtime.start_combat() fires, the player's existing ability
## hotbar (1-8, already wired in ThirdPersonController) works immediately;
## feedback surfaces via NotificationUI toasts rather than health bars/
## cooldown rings. Flagged rather than silently left out or rushed.

const ENCOUNTER_CHANCE := 0.15
const INTERACTION_RADIUS := 4.0

## Per-stage base stat scaling. EntityDexData has no numeric stats at all
## (pure lore text) — this is a deliberate, documented simplification, not
## a discovered "real" balance table. Replace once entities gain real
## stat fields.
const STAGE_STAT_BASE := {1: 8, 2: 16, 3: 30}

static func spawn(root: Node3D, chunk: WorldChunk, coord: Vector2i, size: float, terrain: TerrainBridge) -> void:
	if chunk.is_hub:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = _salted_seed(coord)
	if rng.randf() >= ENCOUNTER_CHANCE:
		return

	var line := _pick_line(rng)
	if line.is_empty():
		return
	var stage_index := rng.randi_range(0, mini(2, line.get("stages", []).size() - 1))
	var stage: Dictionary = line["stages"][stage_index]
	if stage.is_empty():
		return

	var px := rng.randf() * size
	var pz := rng.randf() * size
	var y := 0.0
	if terrain != null:
		y = terrain.height_at(root.position.x + px, root.position.z + pz)

	var entity_id: String = "%s_s%d" % [str(line.get("id", "entity")), stage_index + 1]
	var entity_name: String = str(stage.get("name", "Unknown"))

	var marker := Node3D.new()
	marker.name = "Encounter_%s" % entity_id
	marker.position = Vector3(px, y, pz)
	root.add_child(marker)

	var mesh := MeshInstance3D.new()
	var body := CapsuleMesh.new()
	body.radius = 0.4 + stage_index * 0.15
	body.height = 1.4 + stage_index * 0.5
	mesh.mesh = body
	mesh.position.y = body.height * 0.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _faction_color(str(line.get("faction", ""))).darkened(0.1)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 0.3 + stage_index * 0.2
	mesh.material_override = mat
	marker.add_child(mesh)

	var label := Label3D.new()
	label.text = "%s (Stage %d)" % [entity_name, stage_index + 1]
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.01
	label.position = Vector3(0, body.height + 0.4, 0)
	marker.add_child(label)

	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = INTERACTION_RADIUS
	shape.shape = sphere
	area.add_child(shape)
	marker.add_child(area)

	var stat_base: int = STAGE_STAT_BASE.get(stage_index + 1, 10)
	area.body_entered.connect(func(body_node: Node) -> void:
		if not body_node.is_in_group("player"):
			return
		var combat := marker.get_node_or_null("/root/CombatRealtime")
		if combat == null:
			return
		combat.register_actor_stats(entity_id, {"strength": stat_base, "defense": int(stat_base * 0.7)})
		var player_pos_2d := Vector2(body_node.global_position.x, body_node.global_position.z)
		var entity_pos_2d := Vector2(marker.global_position.x, marker.global_position.z)
		combat.start_combat("player", entity_id, player_pos_2d, entity_pos_2d)
		if body_node.has_method("set_target"):
			body_node.set_target(entity_id)
		NotificationUI.notify_info("⚔️ %s engages! Use abilities 1-8." % entity_name)
	)

static func _pick_line(rng: RandomNumberGenerator) -> Dictionary:
	var all_lines: Array = []
	all_lines.append_array(EntityDexData.LINES)
	all_lines.append_array(EntityDexData.FACTIONLESS_LINES)
	if all_lines.is_empty():
		return {}
	return all_lines[rng.randi() % all_lines.size()]

static func _faction_color(faction: String) -> Color:
	match faction:
		"SovereignCrown": return Color(0.85, 0.7, 0.2)
		"VeiledCurrent": return Color(0.3, 0.25, 0.55)
		"WildlandsAscendant": return Color(0.25, 0.5, 0.2)
		_: return Color(0.5, 0.5, 0.5)

static func _salted_seed(coord: Vector2i) -> int:
	const SALT := 0x454e4d59 # "ENMY"
	return SALT ^ (coord.x * 892401091 + coord.y * 216413213)
