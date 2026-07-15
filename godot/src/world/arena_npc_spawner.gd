class_name ArenaNPCSpawner
extends Node3D
## Lightweight NPC crowd spawner for standalone test/playtest scenes that
## don't boot the full WorldLoader/district pipeline (that path — see
## NPCSpawner — needs real district data and is the production spawner for
## the actual game world; pulling it into a bare playtest arena would mean
## depending on world-generation machinery unrelated to "can I see NPCs
## when I press Play"). Talks to NPCGenerator directly instead of
## NPCManager, using the same NPC data shape and the same visual-spawn
## pattern as NPCSpawner._create_npc() so swapping to the real spawner
## later is a drop-in change, not a rewrite.

@export var npc_count: int = 40
@export var seed_key: String = "playtest_arena"
@export var layer: String = "hyperliminal"
## "cat" (mandatory in the Catsino — hyperliminal's catsino_main/catsino_vip
## districts), "identity" (default everywhere else), or "" to auto-derive
## from `layer` at _ready(). PvXC PvP phases override this via
## set_visual_mode() on each spawned body's rig owner — not relevant to
## this lightweight spawner, which only ever represents PvE crowds.
@export var visual_mode: String = ""

const INTERACTION_RADIUS := 2.5
const CATSINO_LAYER := "hyperliminal"

var _generator := NPCGenerator.new()
var _spawned: Dictionary = {}  # npc_id -> Node3D

func _ready() -> void:
	add_to_group("npc_crowd_spawner")
	if visual_mode == "":
		visual_mode = "cat" if layer == CATSINO_LAYER else "identity"
	var npcs := _generator.generate_npcs(npc_count, seed_key, layer)
	for npc_data in npcs:
		_create_npc(npc_data)

func _create_npc(data: Dictionary) -> void:
	var npc_id: String = data.get("id", "npc")
	if npc_id in _spawned:
		return

	var pos: Dictionary = data.get("position", {})
	var root := Node3D.new()
	root.name = npc_id
	root.position = Vector3(pos.get("x", 0.0), 0.0, pos.get("z", 0.0))
	add_child(root)

	var label := Label3D.new()
	label.text = "%s\n%s" % [data.get("emoji", "🐱"), data.get("name", "NPC")]
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.008
	label.position = Vector3(0, 1.8, 0)
	root.add_child(label)

	# Body via the same resolver every other character uses (MetaHuman
	# export -> interim humanoid -> Catsino cat GLB -> procedural rig
	# fallback), respecting the cat-vs-identity rule: mandatory cat in the
	# Catsino, identity by default elsewhere — never hardcoded to cat.
	var body := MetahumanCharacter.build_npc(visual_mode)
	root.add_child(body)

	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = INTERACTION_RADIUS
	shape.shape = sphere
	area.add_child(shape)
	root.add_child(area)

	area.body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("player"):
			var ui := get_tree().get_first_node_in_group("npc_dialogue_ui")
			if ui and ui.has_method("open_for_npc"):
				ui.open_for_npc(npc_id)
	)

	_spawned[npc_id] = root
	if has_node("/root/NPCManager"):
		get_node("/root/NPCManager").register_instance(npc_id, root)
