class_name RemotePlayer
extends Node3D
## Another player (or offline ghost) in the world: a perceived CharacterRig
## body — scaled and aura'd by the RPS model, blacked to a silhouette if
## they outclass you — plus a floating nameplate that only shows detail
## the perception model allows.

var peer_id := ""
var profile: Dictionary = {}

func setup(id: String, p: Dictionary) -> void:
	peer_id = id
	profile = p

	var body: Node3D = AssetLibrary.instance("npc_cat")
	if body == null:
		var mi := MeshInstance3D.new()
		var caps := CapsuleMesh.new()
		caps.radius = 0.4
		caps.height = 1.2
		mi.mesh = caps
		mi.position.y = 0.6
		body = mi
	var seen: Dictionary = IdentityLens.perceive_being(profile, Color(0.7, 0.6, 0.5))
	if body is MeshInstance3D:
		body.material_override = seen.material
	scale = Vector3.ONE * seen.view.apparent_scale
	add_child(body)

	var plate := Label3D.new()
	plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	plate.position.y = 2.0
	plate.font_size = 48
	plate.outline_size = 8
	if seen.view.loadout_visible:
		plate.text = peer_id.trim_prefix("ghost_").replace("_", " ")
		plate.modulate = seen.view.aura_color
	else:
		plate.text = "???" # outclassed: you don't get their name either
		plate.modulate = Color(0.4, 0.4, 0.45)
	add_child(plate)

func move_to(pos: Vector3, terrain: ProceduralTerrain = null) -> void:
	var target := pos
	if terrain != null:
		target.y = terrain.height_at(pos.x, pos.z) + 0.1
	# Smooth toward the reported position.
	global_position = global_position.lerp(target, 0.2)
