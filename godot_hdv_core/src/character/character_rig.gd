extends Node3D
## Procedural PBR humanoid rig — Godot-native counterpart to buildFigure()
## in CharacterPreview3DCanvas.tsx. Builds primitive body parts sized by
## frame_type (light/heavy) and shaded per race texture_type, using real
## Forward+ lighting/SSAO/glow instead of three.js's basic renderer.
##
## TODO(assets): swap build_from_loadout()'s primitive meshes for rigged
## glTF imports (Mixamo/Kenney/Quaternius) once available outside the
## sandbox's network restrictions — keep race/frame id plumbing identical.

const TextureMaterials = preload("res://src/character/texture_materials.gd")

var _parts: Array[MeshInstance3D] = []

func build_from_loadout(race: Dictionary, frame: Dictionary, mod: Dictionary = {}) -> void:
	clear()
	if race.is_empty() or frame.is_empty():
		return

	var heavy: bool = frame.get("frame_type", "light") == "heavy"
	var scale_mult := 1.25 if heavy else 1.0
	var limb_thickness := 0.16 if heavy else 0.11

	var mod_scale := Vector3.ONE
	if not mod.is_empty():
		mod_scale = _scale_from_mod(mod.get("id", ""))

	var material := TextureMaterials.build_material(race.get("texture_type", ""), race.get("primary_color", Color.WHITE))

	# Torso
	var torso := _add_part(CapsuleMesh.new(), material)
	(torso.mesh as CapsuleMesh).radius = 0.22 * scale_mult
	(torso.mesh as CapsuleMesh).height = 0.62 * scale_mult
	torso.position = Vector3(0, 1.05, 0) * mod_scale
	torso.scale = mod_scale

	# Head
	var head := _add_part(SphereMesh.new(), material)
	(head.mesh as SphereMesh).radius = 0.16 * scale_mult
	head.position = Vector3(0, 1.55, 0) * mod_scale * Vector3(1, 1.0 / max(mod_scale.y, 0.01), 1)
	head.position.y = (1.05 + 0.31 * scale_mult) * mod_scale.y

	# Hips
	var hips := _add_part(CapsuleMesh.new(), material)
	(hips.mesh as CapsuleMesh).radius = 0.2 * scale_mult
	(hips.mesh as CapsuleMesh).height = 0.3 * scale_mult
	hips.position = Vector3(0, 0.72, 0) * mod_scale

	# Arms
	for side in [-1.0, 1.0]:
		var arm := _add_part(CapsuleMesh.new(), material)
		(arm.mesh as CapsuleMesh).radius = limb_thickness * scale_mult
		(arm.mesh as CapsuleMesh).height = 0.55 * scale_mult
		arm.position = Vector3(side * 0.32 * scale_mult, 1.0, 0) * Vector3(1, mod_scale.y, 1)

	# Legs
	for side in [-1.0, 1.0]:
		var leg := _add_part(CapsuleMesh.new(), material)
		(leg.mesh as CapsuleMesh).radius = (limb_thickness + 0.02) * scale_mult
		(leg.mesh as CapsuleMesh).height = 0.6 * scale_mult
		leg.position = Vector3(side * 0.13 * scale_mult, 0.32, 0) * Vector3(1, mod_scale.y, 1)

	for part in _parts:
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

func clear() -> void:
	for part in _parts:
		part.queue_free()
	_parts.clear()

func _add_part(mesh: Mesh, material: StandardMaterial3D) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	add_child(instance)
	_parts.append(instance)
	return instance

func _scale_from_mod(mod_id: String) -> Vector3:
	match mod_id:
		"towering", "colossus":
			return Vector3(1.0, 1.35, 1.0)
		"compact":
			return Vector3(0.85, 0.8, 0.85)
		"elastic", "serpentine":
			return Vector3(0.95, 1.15, 0.95)
		_:
			return Vector3.ONE
