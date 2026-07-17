class_name EntityCombatSpawner
extends RefCounted
## Places fightable WorldEntity encounters from EntityDexData into wild chunks.
## Uses the same WorldEntity combat path as layer wildlife (hotbar casts land).

const ENCOUNTER_CHANCE := 0.15

static func spawn(root: Node3D, chunk: WorldChunk, coord: Vector2i, size: float, terrain: TerrainBridge) -> void:
	if chunk.is_hub:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = _salted_seed(coord)
	if rng.randf() > ENCOUNTER_CHANCE:
		return
	var line := _pick_line(rng)
	if line.is_empty():
		return
	var stage_index := rng.randi_range(0, mini(2, line.get("stages", []).size() - 1))
	var stage_num := stage_index + 1

	var px := rng.randf() * size
	var pz := rng.randf() * size
	var y := 0.0
	if terrain != null:
		y = terrain.height_at(root.position.x + px, root.position.z + pz)

	var player: Node3D = null
	if root.has_method("get_local_player"):
		player = root.get_local_player()
	if player == null:
		var tree := root.get_tree()
		if tree:
			for n in tree.get_nodes_in_group("player"):
				if n is Node3D:
					player = n
					break

	var ent := WorldEntity.new()
	ent.name = "Encounter_%s_s%d" % [str(line.get("id", "entity")), stage_num]
	root.add_child(ent)
	ent.global_position = Vector3(root.global_position.x + px, y, root.global_position.z + pz)
	ent.setup(line, stage_num, player)
	if root.has_method("_register_world_entity"):
		root.call("_register_world_entity", ent)
	NotificationUI.notify_info("⚔ Encounter nearby — %s (Stage %d)." % [
		str(ent.stage_info.get("name", "Entity")), stage_num])

static func _pick_line(rng: RandomNumberGenerator) -> Dictionary:
	var all_lines: Array = []
	all_lines.append_array(EntityDexData.LINES)
	all_lines.append_array(EntityDexData.FACTIONLESS_LINES)
	if all_lines.is_empty():
		return {}
	return all_lines[rng.randi() % all_lines.size()]

static func _salted_seed(coord: Vector2i) -> int:
	const SALT := 0x454e4d59 # "ENMY"
	return SALT ^ (coord.x * 892401091 + coord.y * 216413213)
