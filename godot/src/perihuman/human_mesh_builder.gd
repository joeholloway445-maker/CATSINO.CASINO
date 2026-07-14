class_name HumanMeshBuilder
## Turns a HumanDNA genome into a skinned, morphable human body mesh —
## entirely procedural, no imported assets, no Unreal.
##
## Construction: every body part is a loft of elliptical cross-section
## rings; the head is a dense lat/lon dome whose radius field is modulated
## by gaussian feature bumps (brow ridge, sockets, nose, cheekbones, lips,
## chin, ears) driven by the genome. Because vertex topology depends only
## on LOD — never on genes or expression — the SAME generator evaluated
## with an expression pose produces the facial morph targets (blink,
## jaw_open, smile, brow_raise) as blend-shape deltas.
##
## The generated body wears a neutral charcoal base layer (tank + shorts)
## painted in vertex color, so every human is presentable before any
## outfit system dresses them.
##
## Everything is emitted in the T-pose model space of HumanSkeletonBuilder,
## with 2-bone-per-vertex skin weights.

const MORPHS := ["blink", "jaw_open", "smile", "brow_raise"]
const LOD_COUNT := 3
const RADIAL := [16, 10, 7]              # ring segments for torso/limbs per LOD
const HEAD_GRID := [[26, 34], [16, 20], [10, 12]]  # [lat rows, lon columns] per LOD

const SKIN := Color(1, 1, 1)
const CLOTH := Color(0.20, 0.21, 0.24)

# ------------------------------------------------------------------ emitter

class Emitter:
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	var indices := PackedInt32Array()
	var out_refs := PackedVector3Array()  # outward hints to orient normals

	func vertex(p: Vector3, col: Color, out_ref: Vector3, b0: int, w0: float, b1: int = 0, w1: float = 0.0) -> int:
		var id := verts.size()
		verts.append(p)
		colors.append(col)
		out_refs.append(out_ref)
		var total := maxf(w0 + w1, 0.0001)
		bones.append_array(PackedInt32Array([b0, b1, 0, 0]))
		weights.append_array(PackedFloat32Array([w0 / total, w1 / total, 0.0, 0.0]))
		return id

	func tri(a: int, b: int, c: int) -> void:
		indices.append(a)
		indices.append(b)
		indices.append(c)

	func quad(a: int, b: int, c: int, d: int) -> void:
		tri(a, b, c)
		tri(a, c, d)

	## Smooth per-vertex normals: accumulate face normals, then orient each
	## along its recorded outward hint (winding-agnostic — the skin material
	## renders double-sided anyway).
	func normals() -> PackedVector3Array:
		var acc := PackedVector3Array()
		acc.resize(verts.size())
		for t in range(0, indices.size(), 3):
			var a := verts[indices[t]]
			var fn := (verts[indices[t + 1]] - a).cross(verts[indices[t + 2]] - a)
			for k in 3:
				acc[indices[t + k]] += fn
		for i in acc.size():
			var n := acc[i]
			var ref := out_refs[i]
			if n.length_squared() < 1e-12:
				n = ref
			elif ref.length_squared() > 1e-12 and n.dot(ref) < 0.0:
				n = -n
			acc[i] = n.normalized() if n.length_squared() > 1e-12 else Vector3.UP
		return acc

# ------------------------------------------------------------ loft primitives

static func _ring(em: Emitter, center: Vector3, u: Vector3, v: Vector3, ru: float, rv: float,
		col: Color, segs: int, b0: int, w0: float, b1: int = 0, w1: float = 0.0) -> PackedInt32Array:
	var ids := PackedInt32Array()
	for k in segs:
		var a := TAU * float(k) / float(segs)
		var p := center + u * (cos(a) * ru) + v * (sin(a) * rv)
		ids.append(em.vertex(p, col, p - center, b0, w0, b1, w1))
	return ids

static func _bridge(em: Emitter, a: PackedInt32Array, b: PackedInt32Array) -> void:
	var n := a.size()
	for k in n:
		var k2 := (k + 1) % n
		em.quad(a[k], a[k2], b[k2], b[k])

static func _cap(em: Emitter, ring: PackedInt32Array, center: Vector3, dir: Vector3,
		col: Color, b0: int, w0: float, b1: int = 0, w1: float = 0.0) -> void:
	var c := em.vertex(center, col, dir, b0, w0, b1, w1)
	var n := ring.size()
	for k in n:
		em.tri(ring[k], ring[(k + 1) % n], c)

static func _r(c: Vector3, ru: float, rv: float, col: Color, b0: int, w0: float, b1: int = 0, w1: float = 0.0) -> Dictionary:
	return {"c": c, "ru": ru, "rv": rv, "col": col, "b0": b0, "w0": w0, "b1": b1, "w1": w1}

static func _tube(em: Emitter, rings: Array, u: Vector3, v: Vector3, segs: int,
		cap_start: bool, cap_end: bool) -> void:
	var prev := PackedInt32Array()
	for i in rings.size():
		var r: Dictionary = rings[i]
		var ids := _ring(em, r.c, u, v, r.ru, r.rv, r.col, segs, r.b0, r.w0, r.b1, r.w1)
		if i == 0 and cap_start and rings.size() > 1:
			var dir: Vector3 = ((rings[0].c as Vector3) - (rings[1].c as Vector3)).normalized()
			_cap(em, ids, r.c, dir, r.col, r.b0, r.w0, r.b1, r.w1)
		if i > 0:
			_bridge(em, prev, ids)
		prev = ids
	if cap_end and rings.size() > 1:
		var last: Dictionary = rings[rings.size() - 1]
		var dir2: Vector3 = ((last.c as Vector3) - (rings[rings.size() - 2].c as Vector3)).normalized()
		_cap(em, prev, last.c, dir2, last.col, last.b0, last.w0, last.b1, last.w1)

static func _bump(x: float, center: float, width: float) -> float:
	var t := (x - center) / width
	return exp(-t * t)

static func _expr() -> Dictionary:
	return {"blink": 0.0, "jaw_open": 0.0, "smile": 0.0, "brow_raise": 0.0}

# ----------------------------------------------------------------- face field

## Derived facial constants shared by the head loft, the hair shell, the
## brow strips and the eye placement — one source of truth for the field.
static func face_params(dna: HumanDNA, m: Dictionary) -> Dictionary:
	var ry: float = m.head_h * 0.5
	return {
		"dna": dna,
		"ry": ry,
		"rx": ry * 0.74 * dna.gene_lerp("head_width", 0.88, 1.14),
		"rz": ry * 0.80 * dna.gene_lerp("head_depth", 0.90, 1.12),
		"phi_eye": 0.03,
		"eye_theta": dna.gene_lerp("eye_spacing", 0.34, 0.55),
		"eye_s": dna.gene_lerp("eye_size", 0.80, 1.25),
		"eye_r": ry * 0.115 * dna.gene_lerp("eye_size", 0.85, 1.15),
		"phi_brow": 0.24 + (dna.get_gene("brow_height") - 0.5) * 0.14,
		"phi_mouth": -0.55,
		"mouth_w": dna.gene_lerp("mouth_width", 0.20, 0.42),
		"tip_phi": -0.24 + (dna.get_gene("nose_tip") - 0.5) * 0.08,
		"jaw_f": dna.gene_lerp("jaw_width", 0.82, 1.14),
		"forehead_lift": (dna.get_gene("forehead_height") - 0.5) * 0.22,
		"forehead_slope": maxf(0.0, dna.get_gene("forehead_slope") - 0.35) * 0.30,
	}

## The parametric head surface, relative to head center. phi is latitude
## (-PI/2 chin-bottom .. +PI/2 crown), theta is longitude (0 = face, +Z).
static func head_point(fp: Dictionary, expr: Dictionary, phi: float, theta: float) -> Vector3:
	var dna: HumanDNA = fp.dna
	var ry: float = fp.ry

	# Base ellipsoid with jaw-width pinch and forehead reshaping.
	var jaw_t := clampf((-phi - 0.25) / 0.5, 0.0, 1.0)
	var xscale := lerpf(1.0, fp.jaw_f, jaw_t)
	var fore_t := clampf((phi - 0.35) / 1.2, 0.0, 1.0)
	var yscale := 1.0 + fp.forehead_lift * fore_t
	var pos := Vector3(
		fp.rx * cos(phi) * sin(theta) * xscale,
		ry * sin(phi) * yscale,
		fp.rz * cos(phi) * cos(theta))
	pos.z -= fp.rz * fp.forehead_slope * fore_t * fore_t * maxf(cos(theta), 0.0)

	var d := 0.0            # radial displacement, in units of ry
	var off := Vector3.ZERO # direct offsets (expressions mostly)
	var front := _bump(theta, 0.0, 0.9)

	# Brow ridge (+ brow_raise morph lifts it).
	var brow_lift: float = 0.10 * expr.brow_raise
	d += (0.02 + 0.09 * dna.get_gene("brow_depth") + 0.03 * expr.brow_raise) \
		* _bump(phi, fp.phi_brow + brow_lift, 0.13) * front

	# Eye sockets — with per-side tilt (outer corner rises with eye_tilt).
	var tilt := (dna.get_gene("eye_tilt") - 0.5) * 0.22
	var socket_amp := 0.055 * lerpf(0.5, 1.4, dna.get_gene("eye_depth"))
	for side in [1.0, -1.0]:
		var socket_phi: float = fp.phi_eye + tilt * (absf(theta) - fp.eye_theta) * 2.0
		var mask: float = _bump(phi, socket_phi, 0.10 * fp.eye_s) \
			* _bump(theta, side * fp.eye_theta, 0.17 * fp.eye_s)
		d -= socket_amp * mask
		d += 0.085 * expr.blink * mask  # lids swell shut over the eyeball

	# Nose: bridge -> tip -> nostril flare, all along the front meridian.
	var nose_w := lerpf(0.10, 0.22, dna.get_gene("nose_width"))
	var nose_profile: float = _bump(phi, fp.tip_phi, 0.16) * dna.gene_lerp("nose_length", 0.10, 0.26) \
		+ _bump(phi, 0.0, 0.14) * dna.gene_lerp("nose_bridge", 0.02, 0.11)
	d += nose_profile * _bump(theta, 0.0, nose_w)
	d += _bump(phi, fp.tip_phi - 0.05, 0.06) * dna.get_gene("nose_width") * 0.06 \
		* (_bump(theta, 0.17, 0.08) + _bump(theta, -0.17, 0.08))

	# Cheekbones and cheek fat (age hollows the cheeks).
	var cheek_phi := lerpf(-0.18, -0.02, dna.get_gene("cheekbone_height"))
	var sides: float = _bump(theta, 0.75, 0.28) + _bump(theta, -0.75, 0.28)
	d += 0.06 * dna.gene_lerp("cheekbone_width", 0.3, 1.2) * _bump(phi, cheek_phi, 0.14) * sides
	var fat := dna.get_gene("cheek_fullness") * (1.0 - 0.35 * dna.get_gene("age"))
	d += 0.09 * fat * _bump(phi, -0.45, 0.25) \
		* (_bump(theta, 0.55, 0.35) + _bump(theta, -0.55, 0.35))

	# Lips with a philtrum crease; smile pulls the corners up and out.
	var lipm: float = _bump(phi, fp.phi_mouth, 0.07) * _bump(theta, 0.0, fp.mouth_w * 0.8)
	d += 0.055 * dna.gene_lerp("lip_fullness", 0.3, 1.3) * lipm
	d -= 0.018 * _bump(phi, fp.phi_mouth, 0.022) * _bump(theta, 0.0, fp.mouth_w * 0.7)
	var corners: float = _bump(phi, fp.phi_mouth + 0.03, 0.12) \
		* (_bump(theta, fp.mouth_w, 0.14) + _bump(theta, -fp.mouth_w, 0.14))
	off.y += ry * 0.06 * expr.smile * corners
	d += 0.035 * expr.smile * corners
	d += 0.03 * expr.smile * _bump(phi, -0.35, 0.2) * sides  # smiling lifts the cheeks

	# Jaw open: the lower front face drops and tucks back.
	var jaw_open_m: float = clampf((-phi - 0.42) / 0.5, 0.0, 1.0) * front
	off.y -= ry * 0.20 * expr.jaw_open * jaw_open_m
	off.z -= ry * 0.05 * expr.jaw_open * jaw_open_m

	# Chin.
	d += _bump(phi, -1.02, 0.18) * _bump(theta, 0.0, 0.35) * dna.gene_lerp("chin_protrusion", 0.0, 0.15)
	off.y -= ry * 0.22 * (dna.get_gene("chin_length") - 0.5) * _bump(phi, -1.25, 0.32) * _bump(theta, 0.0, 0.5)

	# Ears — simple flared blobs at the side meridians.
	d += (_bump(theta, 1.62, 0.13) + _bump(theta, -1.62, 0.13)) * _bump(phi, 0.0, 0.17) \
		* dna.gene_lerp("ear_size", 0.03, 0.16)

	var dir := pos.normalized() if pos.length_squared() > 1e-12 else Vector3.UP
	return pos + dir * (d * ry) + off

## Vertex-color face paint: lips, brow shadow, stubble, flush, freckles.
static func _head_color(fp: Dictionary, phi: float, theta: float) -> Color:
	var dna: HumanDNA = fp.dna
	var col := SKIN
	var redness := dna.get_gene("skin_redness")

	var lipm: float = _bump(phi, fp.phi_mouth, 0.06) * _bump(theta, 0.0, fp.mouth_w * 0.85)
	col = col.lerp(Color(0.88, 0.52, 0.50), clampf(lipm * (0.45 + redness * 0.35), 0.0, 1.0))

	var browm: float = _bump(phi, fp.phi_brow, 0.05) \
		* (_bump(theta, fp.eye_theta, 0.22) + _bump(theta, -fp.eye_theta, 0.22))
	col = col.lerp(Color(0.48, 0.42, 0.38), clampf(browm * dna.get_gene("brow_thickness") * 0.5, 0.0, 1.0))

	var socketm: float = (_bump(theta, fp.eye_theta, 0.15) + _bump(theta, -fp.eye_theta, 0.15)) \
		* _bump(phi, fp.phi_eye, 0.09)
	col = col.lerp(Color(0.82, 0.78, 0.78), clampf(socketm * 0.4, 0.0, 1.0))

	var stubble := dna.get_gene("stubble")
	if stubble > 0.01:
		var beardm: float = clampf((-phi - 0.32) / 0.28, 0.0, 1.0) * _bump(theta, 0.0, 1.0) * (1.0 - lipm * 2.0)
		col = col.lerp(Color(0.52, 0.48, 0.45), clampf(beardm * stubble * 0.65, 0.0, 1.0))

	var flushm: float = _bump(phi, -0.4, 0.22) * (_bump(theta, 0.6, 0.3) + _bump(theta, -0.6, 0.3))
	col = col.lerp(Color(1.0, 0.82, 0.80), clampf(flushm * redness * 0.35, 0.0, 1.0))

	# Freckles double as the generic "marking" channel: race/mod archetypes
	# (star-flecks, mineral veining, plate seams, sigils, ...) drive the
	# same speckle scatter tinted by marking_color instead of plain brown.
	var freckles := dna.get_gene("freckles")
	if freckles > 0.01:
		var hash_v := absf(fposmod(sin(phi * 127.1 + theta * 311.7) * 43758.5453, 1.0))
		if hash_v < freckles * 0.35 and absf(phi + 0.15) < 0.9 and absf(theta) < 1.3:
			var mark_col := dna.marking_color if dna.marking_color.a > 0.0 else Color(0.72, 0.60, 0.52)
			col = col.lerp(mark_col, 0.5)
	return col

# ------------------------------------------------------------------ body parts

static func _torso(em: Emitter, dna: HumanDNA, rig: Dictionary, segs: int) -> void:
	var m: Dictionary = rig.measure
	var B: Dictionary = rig.bones
	var s: float = m.s
	var hips_y: float = m.hips_y
	var torso: float = m.torso
	var build := dna.get_gene("build")

	var hip_rx: float = m.hip_socket_x + m.leg_r * 1.35
	var hip_rz: float = hip_rx * lerpf(0.60, 0.76, build)
	var waist_rx := lerpf(hip_rx * 0.70, hip_rx * 0.96, build)
	var chest_rx: float = m.shoulder_x * 0.82
	var chest_rz: float = s * dna.gene_lerp("chest_depth", 0.085, 0.145) * lerpf(0.9, 1.15, build)

	var y := func(t: float) -> Vector3: return Vector3(0, hips_y + torso * t, 0)
	var rings := [
		_r(Vector3(0, hips_y - 0.10 * s, 0), hip_rx * 0.62, hip_rz * 0.58, CLOTH, B.Hips, 1.0),
		_r(Vector3(0, hips_y + 0.02 * s, 0), hip_rx, hip_rz, CLOTH, B.Hips, 1.0),
		_r(y.call(0.20), hip_rx * 0.92, hip_rz * 0.86, SKIN, B.Hips, 0.7, B.Spine, 0.3),
		_r(y.call(0.38), waist_rx, waist_rx * 0.72, SKIN, B.Spine, 1.0),
		_r(y.call(0.58), chest_rx * 0.90, chest_rz * 0.95, CLOTH, B.Spine, 0.4, B.Chest, 0.6),
		_r(y.call(0.74), chest_rx, chest_rz, CLOTH, B.Chest, 1.0),
		_r(y.call(0.88), chest_rx * 0.92, chest_rz * 0.88, CLOTH, B.Chest, 1.0),
		_r(y.call(1.0), chest_rx * 0.52, chest_rz * 0.64, SKIN, B.Chest, 1.0),
	]
	_tube(em, rings, Vector3.RIGHT, Vector3.BACK, segs, true, true)

static func _neck(em: Emitter, dna: HumanDNA, rig: Dictionary, segs: int) -> void:
	var m: Dictionary = rig.measure
	var B: Dictionary = rig.bones
	var J: Dictionary = rig.joints
	var base_y: float = (J.neck as Vector3).y - 0.03 * m.s
	var top_y: float = (J.head as Vector3).y + m.head_h * 0.18
	var r: float = m.neck_r
	var rings := [
		_r(Vector3(0, base_y, 0), r * 1.3, r * 1.3, SKIN, B.Chest, 0.4, B.Neck, 0.6),
		_r(Vector3(0, lerpf(base_y, top_y, 0.5), 0), r, r, SKIN, B.Neck, 1.0),
		_r(Vector3(0, top_y, 0.01 * m.s), r * 0.92, r * 0.92, SKIN, B.Neck, 0.35, B.Head, 0.65),
	]
	_tube(em, rings, Vector3.RIGHT, Vector3.BACK, segs, true, true)

static func _head(em: Emitter, dna: HumanDNA, rig: Dictionary, lod: int, expr: Dictionary) -> void:
	var center: Vector3 = rig.joints.head_center
	var fp := face_params(dna, rig.measure)
	var B: Dictionary = rig.bones
	var lat: int = HEAD_GRID[lod][0]
	var lon: int = HEAD_GRID[lod][1]
	var prev := PackedInt32Array()
	for i in range(lat + 1):
		var phi := -PI / 2 + PI * float(i) / float(lat)
		var ids := PackedInt32Array()
		for jj in lon:
			var theta := -PI + TAU * float(jj) / float(lon)
			var p := head_point(fp, expr, phi, theta)
			var col := _head_color(fp, phi, theta)
			var neck_w := clampf((-phi - 1.0) / 0.5, 0.0, 1.0) * 0.35
			ids.append(em.vertex(center + p, col, p, B.Head, 1.0 - neck_w, B.Neck, neck_w))
		if i > 0:
			_bridge(em, prev, ids)
		prev = ids

static func _arm(em: Emitter, dna: HumanDNA, rig: Dictionary, segs: int, side: float) -> void:
	var m: Dictionary = rig.measure
	var B: Dictionary = rig.bones
	var prefix := "Left" if side > 0.0 else "Right"
	var b_up: int = B[prefix + "UpperArm"]
	var b_lo: int = B[prefix + "LowerArm"]
	var b_hand: int = B[prefix + "Hand"]
	var sx: float = m.shoulder_x
	var up: float = m.arm_upper
	var fore: float = m.arm_fore
	var hand: float = m.hand_len
	var y: float = (rig.joints["l_upper_arm"] as Vector3).y
	var r: float = m.arm_r
	var mf := dna.gene_lerp("muscle", 0.90, 1.18)

	var c := func(x: float) -> Vector3: return Vector3(side * x, y, 0)
	var rings := [
		_r(c.call(sx * 0.72), r * 1.32 * mf, r * 1.32 * mf, SKIN, b_up, 1.0),
		_r(c.call(sx + up * 0.18), r * 1.28 * mf, r * 1.28 * mf, SKIN, b_up, 1.0),
		_r(c.call(sx + up * 0.5), r * 1.12 * mf, r * 1.12 * mf, SKIN, b_up, 1.0),
		_r(c.call(sx + up * 0.95), r * 0.92, r * 0.92, SKIN, b_up, 0.5, b_lo, 0.5),
		_r(c.call(sx + up + fore * 0.35), r * 1.02 * mf, r * 1.02 * mf, SKIN, b_lo, 1.0),
		_r(c.call(sx + up + fore * 0.85), r * 0.68, r * 0.68, SKIN, b_lo, 1.0),
		_r(c.call(sx + up + fore), r * 0.60, r * 0.60, SKIN, b_lo, 0.35, b_hand, 0.65),
		_r(c.call(sx + up + fore + hand * 0.5), r * 0.95, r * 0.42, SKIN, b_hand, 1.0),
		_r(c.call(sx + up + fore + hand), r * 0.62, r * 0.28, SKIN, b_hand, 1.0),
	]
	# Rings lie in the Z/Y plane (limb axis is X).
	_tube(em, rings, Vector3.BACK, Vector3.UP, segs, true, true)

static func _leg(em: Emitter, dna: HumanDNA, rig: Dictionary, segs: int, side: float) -> void:
	var m: Dictionary = rig.measure
	var B: Dictionary = rig.bones
	var prefix := "Left" if side > 0.0 else "Right"
	var b_up: int = B[prefix + "UpperLeg"]
	var b_lo: int = B[prefix + "LowerLeg"]
	var b_foot: int = B[prefix + "Foot"]
	var hips_y: float = m.hips_y
	var hx: float = m.hip_socket_x
	var r: float = m.leg_r
	var s: float = m.s

	var c := func(yy: float) -> Vector3: return Vector3(side * hx, yy, 0)
	var rings := [
		_r(c.call(hips_y * 0.97), r * 1.30, r * 1.30, CLOTH, b_up, 1.0),
		_r(c.call(hips_y * 0.78), r * 1.22, r * 1.22, SKIN, b_up, 1.0),
		_r(c.call(hips_y * 0.58), r * 0.90, r * 0.90, SKIN, b_up, 0.6, b_lo, 0.4),
		_r(c.call(hips_y * 0.53), r * 0.85, r * 0.85, SKIN, b_up, 0.5, b_lo, 0.5),
		_r(c.call(hips_y * 0.40), r * 0.96, r * 0.96, SKIN, b_lo, 1.0),
		_r(c.call(hips_y * 0.18), r * 0.62, r * 0.62, SKIN, b_lo, 1.0),
		_r(c.call(m.ankle_y + 0.02 * s), r * 0.48, r * 0.48, SKIN, b_lo, 0.4, b_foot, 0.6),
	]
	_tube(em, rings, Vector3.RIGHT, Vector3.BACK, segs, true, false)

	# Foot: a flattened loft running forward (+Z) from the heel.
	var fc := func(zz: float, yy: float) -> Vector3: return Vector3(side * hx, yy, zz)
	var foot_rings := [
		_r(fc.call(-0.05 * s, 0.05 * s), r * 0.55, 0.05 * s, SKIN, b_foot, 1.0),
		_r(fc.call(0.05 * s, 0.045 * s), r * 0.62, 0.045 * s, SKIN, b_foot, 1.0),
		_r(fc.call(m.foot_len, 0.032 * s), r * 0.60, 0.028 * s, SKIN, b_foot, 1.0),
	]
	_tube(em, foot_rings, Vector3.RIGHT, Vector3.UP, segs, true, true)

# ------------------------------------------------------------------- assembly

static func _emit_body(dna: HumanDNA, rig: Dictionary, lod: int, expr: Dictionary) -> Emitter:
	var em := Emitter.new()
	var segs: int = RADIAL[clampi(lod, 0, LOD_COUNT - 1)]
	_torso(em, dna, rig, segs)
	_neck(em, dna, rig, segs)
	_head(em, dna, rig, clampi(lod, 0, LOD_COUNT - 1), expr)
	for side in [1.0, -1.0]:
		_arm(em, dna, rig, segs, side)
		_leg(em, dna, rig, segs, side)
	return em

static func _mesh_from_emitter(em: Emitter, skinned: bool, blend_shapes: Array = [], blend_arrays: Array = []) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = em.verts
	arrays[Mesh.ARRAY_NORMAL] = em.normals()
	arrays[Mesh.ARRAY_COLOR] = em.colors
	if skinned:
		arrays[Mesh.ARRAY_BONES] = em.bones
		arrays[Mesh.ARRAY_WEIGHTS] = em.weights
	arrays[Mesh.ARRAY_INDEX] = em.indices
	var mesh := ArrayMesh.new()
	mesh.blend_shape_mode = Mesh.BLEND_SHAPE_MODE_RELATIVE
	for shape_name in blend_shapes:
		mesh.add_blend_shape(shape_name)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, blend_arrays)
	return mesh

## The main entry: a skinned body mesh with facial blend shapes, plus the
## placement metadata the rig needs for eyes/hair/brows.
static func build_body(dna: HumanDNA, rig: Dictionary, lod: int = 0) -> Dictionary:
	var base := _emit_body(dna, rig, lod, _expr())
	var base_normals := base.normals()

	var blend_arrays := []
	for morph in MORPHS:
		var e := _expr()
		e[morph] = 1.0
		var target := _emit_body(dna, rig, lod, e)
		var tn := target.normals()
		var dv := PackedVector3Array()
		var dn := PackedVector3Array()
		dv.resize(base.verts.size())
		dn.resize(base.verts.size())
		for i in base.verts.size():
			dv[i] = target.verts[i] - base.verts[i]
			dn[i] = tn[i] - base_normals[i]
		var ba := []
		ba.resize(Mesh.ARRAY_MAX)
		ba[Mesh.ARRAY_VERTEX] = dv
		ba[Mesh.ARRAY_NORMAL] = dn
		blend_arrays.append(ba)

	var mesh := _mesh_from_emitter(base, true, MORPHS, blend_arrays)

	var fp := face_params(dna, rig.measure)
	var center: Vector3 = rig.joints.head_center
	var e0 := _expr()
	var meta := {"head_center": center, "eye_radius": fp.eye_r, "eyes": {}}
	for entry in [["l", 1.0], ["r", -1.0]]:
		var p := head_point(fp, e0, fp.phi_eye, (entry[1] as float) * fp.eye_theta)
		var dir := p.normalized()
		meta.eyes[entry[0]] = center + p - dir * fp.eye_r * 0.55
	return {"mesh": mesh, "meta": meta}

# ----------------------------------------------------------------------- hair

const HAIR_PARAMS := {
	"buzz":     {"offset": 1.015, "front": 0.35, "skirt": 0.0},
	"short":    {"offset": 1.06,  "front": 0.28, "skirt": 0.02},
	"bob":      {"offset": 1.07,  "front": 0.32, "skirt": 0.14},
	"topknot":  {"offset": 1.02,  "front": 0.35, "skirt": 0.0},
	"ponytail": {"offset": 1.03,  "front": 0.33, "skirt": 0.0},
	"long":     {"offset": 1.07,  "front": 0.32, "skirt": 0.34},
}

## Hairstyle shell hugging the head surface. Vertices are relative to the
## head CENTER; the rig parents this to a Head bone attachment.
static func build_hair(dna: HumanDNA, m: Dictionary, lod: int = 0) -> ArrayMesh:
	if not HAIR_PARAMS.has(dna.hair_style):
		return null
	var hp: Dictionary = HAIR_PARAMS[dna.hair_style]
	var fp := face_params(dna, m)
	var expr := _expr()
	var em := Emitter.new()
	var lon: int = HEAD_GRID[clampi(lod, 0, LOD_COUNT - 1)][1]
	var cap_rows := 7
	var offset: float = hp.offset
	var ry: float = fp.ry

	var hairline := func(theta: float) -> float:
		var t := clampf((absf(theta) - 0.6) / (PI - 0.6), 0.0, 1.0)
		return lerpf(hp.front, -0.25, t)

	# Scalp cap: rows sweep from the hairline up to just shy of the crown.
	var rows := []
	for i in range(cap_rows + 1):
		var ids := PackedInt32Array()
		for jj in lon:
			var theta := -PI + TAU * float(jj) / float(lon)
			var hl: float = hairline.call(theta)
			var phi := lerpf(hl, 1.48, float(i) / float(cap_rows))
			var wob := 1.0 + 0.012 * sin(float(jj) * 12.9898) * (offset - 1.0) * 30.0
			var p := head_point(fp, expr, phi, theta) * offset * wob
			ids.append(em.vertex(p, Color.WHITE, p, 0, 1.0))
		if i > 0:
			_bridge(em, rows[i - 1], ids)
		rows.append(ids)
	var crown := head_point(fp, expr, PI / 2, 0.0) * offset
	_cap(em, rows[cap_rows], crown, Vector3.UP, Color.WHITE, 0, 1.0)

	# Skirt: hangs from the hairline, kept out of the face.
	var skirt_len: float = hp.skirt
	if skirt_len > 0.001:
		var skirt_rows := 4
		var prev: PackedInt32Array = rows[0]
		for k in range(1, skirt_rows + 1):
			var kt := float(k) / float(skirt_rows)
			var ids2 := PackedInt32Array()
			for jj in lon:
				var theta := -PI + TAU * float(jj) / float(lon)
				var gap := clampf((absf(theta) - 0.55) / 0.25, 0.0, 1.0)  # 0 over the face
				var root := head_point(fp, expr, hairline.call(theta), theta) * offset
				var p := Vector3(root.x * (1.0 - 0.12 * kt), root.y - skirt_len * gap * kt, root.z * (1.0 - 0.12 * kt))
				ids2.append(em.vertex(p, Color.WHITE, Vector3(p.x, 0, p.z), 0, 1.0))
			_bridge(em, prev, ids2)
			prev = ids2

	# Style extras.
	if dna.hair_style == "topknot":
		var bun_c := Vector3(0, ry * 1.14, -fp.rz * 0.05)
		var rb := ry * 0.30
		var bun_rings := []
		for i in 5:
			var phi := -PI / 3 + (2.0 * PI / 3) * float(i) / 4.0
			bun_rings.append(_r(bun_c + Vector3(0, rb * sin(phi), 0), rb * cos(phi) + 0.001, rb * cos(phi) + 0.001, Color.WHITE, 0, 1.0))
		_tube(em, bun_rings, Vector3.RIGHT, Vector3.BACK, 10, true, true)
	elif dna.hair_style == "ponytail":
		var path := [
			Vector3(0, ry * 0.50, -fp.rz * 0.95), Vector3(0, ry * 0.10, -fp.rz * 1.18),
			Vector3(0, -ry * 0.55, -fp.rz * 1.22), Vector3(0, -ry * 1.15, -fp.rz * 1.05),
			Vector3(0, -ry * 1.65, -fp.rz * 0.85),
		]
		var tail_rings := []
		for i in path.size():
			var rr: float = ry * lerpf(0.20, 0.05, float(i) / float(path.size() - 1))
			tail_rings.append(_r(path[i], rr, rr, Color.WHITE, 0, 1.0))
		_tube(em, tail_rings, Vector3.RIGHT, Vector3.BACK, 8, true, true)

	return _mesh_from_emitter(em, false)

## Eyebrow strips riding the head surface (relative to head center).
static func build_brows(dna: HumanDNA, m: Dictionary) -> ArrayMesh:
	var fp := face_params(dna, m)
	var expr := _expr()
	var em := Emitter.new()
	var steps := 8
	var half_w := 0.030 + dna.get_gene("brow_thickness") * 0.045
	var tilt := (dna.get_gene("eye_tilt") - 0.5) * 0.24
	for side in [1.0, -1.0]:
		var top := PackedInt32Array()
		var bot := PackedInt32Array()
		for k in range(steps + 1):
			var t := float(k) / float(steps)
			var theta: float = side * (fp.eye_theta - 0.26 + 0.55 * t)
			var phi_c: float = fp.phi_brow + 0.05 * sin(PI * t) + tilt * (t - 0.5)
			var pt := head_point(fp, expr, phi_c + half_w, theta) * 1.02
			var pb := head_point(fp, expr, phi_c - half_w, theta) * 1.02
			top.append(em.vertex(pt, Color.WHITE, pt, 0, 1.0))
			bot.append(em.vertex(pb, Color.WHITE, pb, 0, 1.0))
			if k > 0:
				em.quad(top[k - 1], top[k], bot[k], bot[k - 1])
	return _mesh_from_emitter(em, false)
