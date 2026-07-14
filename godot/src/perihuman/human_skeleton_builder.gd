class_name HumanSkeletonBuilder
## Builds a Skeleton3D for a PeriHuman from its HumanDNA proportions.
##
## Bone names follow Godot's SkeletonProfileHumanoid (Hips, Spine, Chest,
## Neck, Head, Left/RightShoulder, ...UpperArm, ...LowerArm, ...Hand,
## ...UpperLeg, ...LowerLeg, ...Foot) so imported animation libraries can
## retarget onto generated humans with the stock Godot retarget pipeline.
##
## Rest pose is a T-pose facing +Z (the Godot model-forward convention),
## which is also the pose HumanMeshBuilder generates its skin weights in.
##
## build() returns everything downstream builders need:
##   skeleton — the ready Skeleton3D (poses reset to rest)
##   bones    — bone name -> bone index
##   joints   — joint key -> global rest position (model space)
##   measure  — derived body measurements in meters

static func build(dna: HumanDNA) -> Dictionary:
	var m := measure(dna)
	var j := _joints(m)

	var skel := Skeleton3D.new()
	skel.name = "Skeleton3D"

	var bones := {}
	var defs := [
		# [bone name, parent bone name, joint key]
		["Hips", "", "hips"],
		["Spine", "Hips", "spine"],
		["Chest", "Spine", "chest"],
		["Neck", "Chest", "neck"],
		["Head", "Neck", "head"],
		["LeftShoulder", "Chest", "l_shoulder"],
		["LeftUpperArm", "LeftShoulder", "l_upper_arm"],
		["LeftLowerArm", "LeftUpperArm", "l_lower_arm"],
		["LeftHand", "LeftLowerArm", "l_hand"],
		["RightShoulder", "Chest", "r_shoulder"],
		["RightUpperArm", "RightShoulder", "r_upper_arm"],
		["RightLowerArm", "RightUpperArm", "r_lower_arm"],
		["RightHand", "RightLowerArm", "r_hand"],
		["LeftUpperLeg", "Hips", "l_upper_leg"],
		["LeftLowerLeg", "LeftUpperLeg", "l_lower_leg"],
		["LeftFoot", "LeftLowerLeg", "l_foot"],
		["RightUpperLeg", "Hips", "r_upper_leg"],
		["RightLowerLeg", "RightUpperLeg", "r_lower_leg"],
		["RightFoot", "RightLowerLeg", "r_foot"],
	]
	for def in defs:
		var idx := skel.add_bone(def[0])
		bones[def[0]] = idx
		var parent_pos := Vector3.ZERO
		if def[1] != "":
			skel.set_bone_parent(idx, bones[def[1]])
			parent_pos = _joint_of(j, defs, def[1])
		var rest := Transform3D(Basis.IDENTITY, (j[def[2]] as Vector3) - parent_pos)
		skel.set_bone_rest(idx, rest)
	skel.reset_bone_poses()

	return {"skeleton": skel, "bones": bones, "joints": j, "measure": m}

static func _joint_of(j: Dictionary, defs: Array, bone_name: String) -> Vector3:
	for def in defs:
		if def[0] == bone_name:
			return j[def[2]]
	return Vector3.ZERO

## All body measurements in meters, derived once from the genome so the
## skeleton and the mesh always agree.
static func measure(dna: HumanDNA) -> Dictionary:
	var h := dna.gene_lerp("height", 1.52, 2.02)
	var s := h / 1.75  # global scale unit
	var head_h := h * 0.132 * dna.gene_lerp("head_size", 0.92, 1.08)
	var leg := h * dna.gene_lerp("leg_length", 0.45, 0.51)
	var torso := h * dna.gene_lerp("torso_length", 0.28, 0.335)
	var neck_len := maxf(h * 0.018, h - leg - torso - head_h)
	var arm := h * dna.gene_lerp("arm_length", 0.315, 0.375)
	var shoulder_x := h * dna.gene_lerp("shoulder_width", 0.095, 0.145) \
		* (1.0 + 0.05 * (dna.get_gene("muscle") - 0.5))
	return {
		"height": h,
		"s": s,
		"head_h": head_h,
		"hips_y": leg,
		"torso": torso,
		"neck_len": neck_len,
		"shoulder_x": shoulder_x,
		"hip_socket_x": h * dna.gene_lerp("hip_width", 0.05, 0.078),
		"arm_upper": arm * 0.44,
		"arm_fore": arm * 0.40,
		"hand_len": arm * 0.20,
		"leg_r": lerpf(0.052, 0.082, dna.get_gene("build") * 0.6 + dna.get_gene("muscle") * 0.4) * s,
		"arm_r": lerpf(0.030, 0.048, dna.get_gene("build") * 0.5 + dna.get_gene("muscle") * 0.5) * s,
		"neck_r": dna.gene_lerp("neck_thickness", 0.042, 0.064) * s,
		"ankle_y": 0.055 * s,
		"foot_len": 0.15 * s,
	}

static func _joints(m: Dictionary) -> Dictionary:
	var hips_y: float = m.hips_y
	var torso: float = m.torso
	var neck_y: float = hips_y + torso
	var head_y: float = neck_y + m.neck_len
	var sx: float = m.shoulder_x
	var shoulder_y: float = neck_y - torso * 0.09
	var hx: float = m.hip_socket_x
	var j := {
		"hips": Vector3(0, hips_y, 0),
		"spine": Vector3(0, hips_y + torso * 0.26, 0),
		"chest": Vector3(0, hips_y + torso * 0.60, 0),
		"neck": Vector3(0, neck_y, 0),
		"head": Vector3(0, head_y, 0),
		"head_center": Vector3(0, head_y + m.head_h * 0.5, 0),
	}
	for side in [["l_", 1.0], ["r_", -1.0]]:
		var p: String = side[0]
		var d: float = side[1]
		j[p + "shoulder"] = Vector3(d * sx * 0.28, neck_y - torso * 0.05, 0)
		j[p + "upper_arm"] = Vector3(d * sx, shoulder_y, 0)
		j[p + "lower_arm"] = Vector3(d * (sx + m.arm_upper), shoulder_y, 0)
		j[p + "hand"] = Vector3(d * (sx + m.arm_upper + m.arm_fore), shoulder_y, 0)
		j[p + "upper_leg"] = Vector3(d * hx, hips_y * 0.97, 0)
		j[p + "lower_leg"] = Vector3(d * hx, hips_y * 0.53, 0)
		j[p + "foot"] = Vector3(d * hx, m.ankle_y, 0)
	return j
