#!/usr/bin/env python3
"""Bake PeriHumans (hair/clothes), cats, crystals; convert Quaternius props.

Run from any cwd after downloading deps into /tmp/gap_assets (see script
constants). Example:

  # Blender 4.2+ + Human Base Meshes bundle already fetched
  /path/to/blender -b -P scripts/bake_visual_gaps.py

Outputs land in /tmp/gap_assets/baked/ — copy into godot/assets/models/.
"""

import bpy
import bmesh
import os
import math
from mathutils import Vector

BUNDLE = "/tmp/gap_assets/human-base/human-base-meshes-bundle-v1.4.1/human_base_meshes_bundle.blend"
OUT = "/tmp/gap_assets/baked"
os.makedirs(OUT, exist_ok=True)


def clear():
	bpy.ops.wm.read_factory_settings(use_empty=True)


def append(names):
	with bpy.data.libraries.load(BUNDLE, link=False) as (data_from, data_to):
		data_to.objects = [n for n in names if n in data_from.objects]
	for o in data_to.objects:
		if o:
			bpy.context.collection.objects.link(o)


def mat(name, col, rough=0.5, sub=0.0, metallic=0.0):
	m = bpy.data.materials.new(name)
	m.use_nodes = True
	b = m.node_tree.nodes.get("Principled BSDF")
	b.inputs["Base Color"].default_value = col
	b.inputs["Roughness"].default_value = rough
	b.inputs["Metallic"].default_value = metallic
	if sub and "Subsurface Weight" in b.inputs:
		b.inputs["Subsurface Weight"].default_value = sub
		if "Subsurface Radius" in b.inputs:
			b.inputs["Subsurface Radius"].default_value = (1.0, 0.2, 0.1)
	return m


def set_mat(o, m):
	o.data.materials.clear()
	o.data.materials.append(m)


def bounds(objs):
	mn = Vector((1e9, 1e9, 1e9))
	mx = Vector((-1e9, -1e9, -1e9))
	for o in objs:
		for c in o.bound_box:
			w = o.matrix_world @ Vector(c)
			mn = Vector((min(mn.x, w.x), min(mn.y, w.y), min(mn.z, w.z)))
			mx = Vector((max(mx.x, w.x), max(mx.y, w.y), max(mx.z, w.z)))
	return mn, mx


def decimate(o, ratio):
	bpy.ops.object.select_all(action="DESELECT")
	bpy.context.view_layer.objects.active = o
	o.select_set(True)
	for mod in list(o.modifiers):
		o.modifiers.remove(mod)
	m = o.modifiers.new("D", "DECIMATE")
	m.ratio = ratio
	bpy.ops.object.modifier_apply(modifier="D")


def cloth_band(body, z0, z1, name, material, thick=0.012, soft=0.03):
	"""Body-derived cloth shell with soft Z falloff (keep verts near band)."""
	bpy.ops.object.select_all(action="DESELECT")
	body.select_set(True)
	bpy.context.view_layer.objects.active = body
	bpy.ops.object.duplicate()
	cloth = bpy.context.active_object
	cloth.name = name
	bpy.ops.object.mode_set(mode="EDIT")
	bm = bmesh.from_edit_mesh(cloth.data)
	mw = cloth.matrix_world
	kill = []
	for v in bm.verts:
		z = (mw @ v.co).z
		if z < z0 - soft or z > z1 + soft:
			kill.append(v)
	bmesh.ops.delete(bm, geom=kill, context="VERTS")
	bmesh.update_edit_mesh(cloth.data)
	bpy.ops.object.mode_set(mode="OBJECT")
	if len(cloth.data.vertices) < 30:
		bpy.data.objects.remove(cloth, do_unlink=True)
		return None
	# Smooth jagged cut edges a little
	bpy.ops.object.mode_set(mode="EDIT")
	bpy.ops.mesh.select_all(action="SELECT")
	bpy.ops.mesh.vertices_smooth(factor=0.35, repeat=2)
	bpy.ops.object.mode_set(mode="OBJECT")
	s = cloth.modifiers.new("S", "SOLIDIFY")
	s.thickness = thick
	s.offset = 1.0
	bpy.context.view_layer.objects.active = cloth
	bpy.ops.object.modifier_apply(modifier="S")
	set_mat(cloth, material)
	return cloth


def hair_cap(body, name, material, height_frac=0.12):
	"""Hair from uppermost body verts — scalp shell, not a face-covering sphere."""
	bpy.ops.object.select_all(action="DESELECT")
	body.select_set(True)
	bpy.context.view_layer.objects.active = body
	bpy.ops.object.duplicate()
	hair = bpy.context.active_object
	hair.name = name
	mn, mx = bounds([body])
	H = mx.z - mn.z
	# Keep only crown / upper skull
	z_cut = mx.z - H * height_frac
	bpy.ops.object.mode_set(mode="EDIT")
	bm = bmesh.from_edit_mesh(hair.data)
	mw = hair.matrix_world
	kill = [v for v in bm.verts if (mw @ v.co).z < z_cut]
	bmesh.ops.delete(bm, geom=kill, context="VERTS")
	bmesh.update_edit_mesh(hair.data)
	bpy.ops.object.mode_set(mode="OBJECT")
	if len(hair.data.vertices) < 20:
		bpy.data.objects.remove(hair, do_unlink=True)
		return None
	# Inflate slightly upward/outward for volume
	bpy.ops.object.mode_set(mode="EDIT")
	bpy.ops.mesh.select_all(action="SELECT")
	bpy.ops.mesh.vertices_smooth(factor=0.5, repeat=3)
	bpy.ops.object.mode_set(mode="OBJECT")
	s = hair.modifiers.new("S", "SOLIDIFY")
	s.thickness = 0.018
	s.offset = 1.0
	bpy.context.view_layer.objects.active = hair
	bpy.ops.object.modifier_apply(modifier="S")
	# Lift hair a hairline above scalp
	hair.location.z += 0.008
	bpy.ops.object.transform_apply(location=True)
	set_mat(hair, material)
	return hair


def shoe_capsules(body, material):
	"""Simple shoe volumes at each foot from body bounds."""
	mn, mx = bounds([body])
	H = mx.z - mn.z
	W = mx.x - mn.x
	shoes = []
	for side, sx in (("L", -1.0), ("R", 1.0)):
		bpy.ops.mesh.primitive_cube_add(
			size=1.0,
			location=(
				(mn.x + mx.x) * 0.5 + sx * W * 0.16,
				(mn.y + mx.y) * 0.5 + H * 0.02,
				mn.z + H * 0.035,
			),
		)
		shoe = bpy.context.active_object
		shoe.name = f"Shoe_{side}"
		shoe.scale = (W * 0.12, H * 0.10, H * 0.05)
		bpy.ops.object.transform_apply(scale=True)
		bpy.ops.object.mode_set(mode="EDIT")
		bpy.ops.mesh.select_all(action="SELECT")
		bpy.ops.mesh.bevel(offset=0.01, segments=2)
		bpy.ops.object.mode_set(mode="OBJECT")
		set_mat(shoe, material)
		shoes.append(shoe)
	return shoes


def normalize(h=1.78):
	meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
	bpy.ops.object.select_all(action="DESELECT")
	for o in meshes:
		o.select_set(True)
	bpy.context.view_layer.objects.active = meshes[0]
	if len(meshes) > 1:
		bpy.ops.object.join()
	body = bpy.context.active_object
	body.name = "PeriHuman"
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
	mn, mx = bounds([body])
	s = h / max(mx.z - mn.z, 0.01)
	body.scale = (s, s, s)
	bpy.ops.object.transform_apply(scale=True)
	mn, mx = bounds([body])
	body.location -= Vector(((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, mn.z))
	bpy.ops.object.transform_apply(location=True)


def export(path):
	bpy.ops.object.select_all(action="SELECT")
	bpy.ops.export_scene.gltf(
		filepath=path,
		export_format="GLB",
		use_selection=True,
		export_apply=True,
		export_animations=False,
		export_extras=False,
		export_lights=False,
		export_cameras=False,
	)
	print("EXPORTED", path, round(os.path.getsize(path) / 1e6, 2), "MB")


def build_human(body_n, el, er, skin, shirt, pants, hair_col, shoe_col, out_name, height, hair_frac=0.11):
	clear()
	append([body_n, el, er])
	body = bpy.data.objects[body_n]
	decimate(body, 0.50)
	set_mat(body, mat("Skin", skin, 0.38, 0.28))
	for en in (el, er):
		if en in bpy.data.objects:
			e = bpy.data.objects[en]
			decimate(e, 0.7)
			set_mat(e, mat(en, (0.92, 0.94, 0.97, 1), 0.08))
	mn, mx = bounds([body])
	H = mx.z - mn.z
	# Pants (ankles→waist), shirt (waist→chest, leave neck/face clear), hair crown
	cloth_band(body, mn.z + H * 0.08, mn.z + H * 0.50, "Pants", mat("Pants", pants, 0.88), 0.013, soft=0.02)
	cloth_band(body, mn.z + H * 0.46, mn.z + H * 0.72, "Shirt", mat("Shirt", shirt, 0.82), 0.012, soft=0.02)
	hair_cap(body, "Hair", mat("Hair", hair_col, 0.45), height_frac=hair_frac)
	shoe_capsules(body, mat("Shoes", shoe_col, 0.55, metallic=0.05))
	normalize(height)
	export(os.path.join(OUT, out_name))


def build_cat(out_name, fur=(0.55, 0.42, 0.28, 1), white_chest=True):
	"""Procedural house-cat: realistic proportions, not a capsule."""
	clear()
	parts = []

	def add_sphere(name, loc, scale, material):
		bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=10, radius=1.0, location=loc)
		o = bpy.context.active_object
		o.name = name
		o.scale = scale
		bpy.ops.object.transform_apply(scale=True)
		set_mat(o, material)
		parts.append(o)
		return o

	def add_cone(name, loc, scale, material, rot=(0, 0, 0)):
		bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=1.0, depth=2.0, location=loc)
		o = bpy.context.active_object
		o.name = name
		o.scale = scale
		o.rotation_euler = rot
		bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
		set_mat(o, material)
		parts.append(o)
		return o

	fur_m = mat("Fur", fur, 0.75, 0.05)
	belly_m = mat("Belly", (0.92, 0.90, 0.86, 1), 0.8)
	eye_m = mat("Eye", (0.25, 0.85, 0.35, 1), 0.15)
	nose_m = mat("Nose", (0.85, 0.45, 0.50, 1), 0.4)
	pad_m = mat("Pad", (0.75, 0.40, 0.45, 1), 0.6)

	# Body / chest / hips
	add_sphere("Body", (0, 0, 0.28), (0.22, 0.38, 0.18), fur_m)
	if white_chest:
		add_sphere("Chest", (0, 0.12, 0.26), (0.14, 0.16, 0.14), belly_m)
	# Head
	add_sphere("Head", (0, 0.42, 0.42), (0.16, 0.15, 0.14), fur_m)
	# Muzzle
	add_sphere("Muzzle", (0, 0.54, 0.38), (0.08, 0.07, 0.06), belly_m if white_chest else fur_m)
	add_sphere("Nose", (0, 0.60, 0.40), (0.025, 0.02, 0.02), nose_m)
	# Ears
	add_cone("Ear_L", (-0.09, 0.40, 0.56), (0.05, 0.03, 0.07), fur_m, rot=(0.3, 0, 0.2))
	add_cone("Ear_R", (0.09, 0.40, 0.56), (0.05, 0.03, 0.07), fur_m, rot=(0.3, 0, -0.2))
	# Eyes
	add_sphere("Eye_L", (-0.06, 0.54, 0.45), (0.03, 0.02, 0.03), eye_m)
	add_sphere("Eye_R", (0.06, 0.54, 0.45), (0.03, 0.02, 0.03), eye_m)
	# Legs
	for name, x, y in (
		("FL", -0.10, 0.18),
		("FR", 0.10, 0.18),
		("BL", -0.10, -0.20),
		("BR", 0.10, -0.20),
	):
		add_sphere(f"Leg_{name}", (x, y, 0.12), (0.05, 0.05, 0.12), fur_m)
		add_sphere(f"Paw_{name}", (x, y, 0.03), (0.05, 0.06, 0.03), pad_m)
	# Tail
	add_sphere("Tail", (0, -0.45, 0.36), (0.04, 0.22, 0.04), fur_m)

	# Join + ground
	bpy.ops.object.select_all(action="DESELECT")
	for o in parts:
		o.select_set(True)
	bpy.context.view_layer.objects.active = parts[0]
	bpy.ops.object.join()
	cat = bpy.context.active_object
	cat.name = "Cat"
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
	mn, mx = bounds([cat])
	# ~0.55m tall sitting/standing house cat at game scale (~0.45–0.55)
	target_h = 0.48
	s = target_h / max(mx.z - mn.z, 0.01)
	cat.scale = (s, s, s)
	bpy.ops.object.transform_apply(scale=True)
	mn, mx = bounds([cat])
	cat.location -= Vector(((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, mn.z))
	bpy.ops.object.transform_apply(location=True)
	export(os.path.join(OUT, out_name))


def build_crystal(out_name, tint=(0.45, 0.75, 1.0, 0.9), spikes=7):
	"""Faceted crystal cluster — reads as gemstone, not mushroom."""
	clear()
	parts = []
	crystal_m = mat("Crystal", tint, rough=0.12, metallic=0.15)
	if "Transmission Weight" in crystal_m.node_tree.nodes["Principled BSDF"].inputs:
		crystal_m.node_tree.nodes["Principled BSDF"].inputs["Transmission Weight"].default_value = 0.65
	base_m = mat("CrystalBase", (0.35, 0.32, 0.30, 1), 0.9)

	bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.35, location=(0, 0, 0.15))
	base = bpy.context.active_object
	base.name = "CrystalBase"
	base.scale = (1.0, 1.0, 0.55)
	bpy.ops.object.transform_apply(scale=True)
	set_mat(base, base_m)
	parts.append(base)

	import random

	rng = random.Random(42)
	for i in range(spikes):
		ang = (i / spikes) * math.tau + rng.uniform(-0.15, 0.15)
		r = rng.uniform(0.05, 0.18)
		h = rng.uniform(0.55, 1.35)
		x = math.cos(ang) * r
		y = math.sin(ang) * r
		bpy.ops.mesh.primitive_cone_add(
			vertices=6,
			radius1=rng.uniform(0.08, 0.16),
			radius2=0.01,
			depth=h,
			location=(x, y, h * 0.45),
		)
		sp = bpy.context.active_object
		sp.name = f"Spike_{i}"
		sp.rotation_euler = (rng.uniform(-0.15, 0.15), rng.uniform(-0.15, 0.15), ang)
		bpy.ops.object.transform_apply(rotation=True)
		set_mat(sp, crystal_m)
		parts.append(sp)

	bpy.ops.object.select_all(action="DESELECT")
	for o in parts:
		o.select_set(True)
	bpy.context.view_layer.objects.active = parts[0]
	bpy.ops.object.join()
	cr = bpy.context.active_object
	cr.name = "Crystal"
	mn, mx = bounds([cr])
	cr.location -= Vector(((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, mn.z))
	bpy.ops.object.transform_apply(location=True)
	export(os.path.join(OUT, out_name))


def convert_gltf(src, dest, target_height=None):
	clear()
	bpy.ops.import_scene.gltf(filepath=src)
	meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
	if not meshes:
		print("NO MESH", src)
		return
	# Drop armature-only empties; keep meshes
	bpy.ops.object.select_all(action="DESELECT")
	for o in meshes:
		o.select_set(True)
	bpy.context.view_layer.objects.active = meshes[0]
	if len(meshes) > 1:
		bpy.ops.object.join()
	body = bpy.context.active_object
	# Strip animations for slot size
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
	if target_height:
		mn, mx = bounds([body])
		s = target_height / max(mx.z - mn.z, 0.01)
		body.scale = (s, s, s)
		bpy.ops.object.transform_apply(scale=True)
	mn, mx = bounds([body])
	body.location -= Vector(((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, mn.z))
	bpy.ops.object.transform_apply(location=True)
	export(dest)


# ---- PeriHumans with hair + clothes ----
jobs = [
	(
		"GEO-body_male_realistic",
		"GEO-body_male_realistic.eye.L",
		"GEO-body_male_realistic.eye.R",
		(0.74, 0.54, 0.40, 1),
		(0.18, 0.38, 0.42, 1),
		(0.14, 0.14, 0.16, 1),
		(0.12, 0.09, 0.07, 1),
		(0.10, 0.10, 0.11, 1),
		"peri_human_player.glb",
		1.80,
		0.12,
	),
	(
		"GEO-body_female_realistic",
		"GEO-body_female_realistic.eye.L",
		"GEO-body_female_realistic.eye.R",
		(0.86, 0.72, 0.62, 1),
		(0.36, 0.14, 0.18, 1),
		(0.14, 0.14, 0.16, 1),
		(0.18, 0.10, 0.06, 1),
		(0.12, 0.10, 0.10, 1),
		"peri_human_npc.glb",
		1.68,
		0.14,
	),
	(
		"GEO-body_male_realistic",
		"GEO-body_male_realistic.eye.L",
		"GEO-body_male_realistic.eye.R",
		(0.90, 0.78, 0.68, 1),
		(0.22, 0.28, 0.55, 1),
		(0.18, 0.18, 0.20, 1),
		(0.55, 0.42, 0.22, 1),
		(0.20, 0.18, 0.16, 1),
		"variant_male_fair.glb",
		1.78,
		0.11,
	),
	(
		"GEO-body_male_realistic",
		"GEO-body_male_realistic.eye.L",
		"GEO-body_male_realistic.eye.R",
		(0.45, 0.30, 0.20, 1),
		(0.12, 0.12, 0.14, 1),
		(0.10, 0.10, 0.12, 1),
		(0.05, 0.04, 0.03, 1),
		(0.08, 0.08, 0.09, 1),
		"variant_male_deep.glb",
		1.82,
		0.10,
	),
	(
		"GEO-body_male_realistic",
		"GEO-body_male_realistic.eye.L",
		"GEO-body_male_realistic.eye.R",
		(0.70, 0.52, 0.40, 1),
		(0.08, 0.14, 0.32, 1),
		(0.10, 0.12, 0.18, 1),
		(0.08, 0.08, 0.10, 1),
		(0.05, 0.05, 0.06, 1),
		"variant_male_navy.glb",
		1.79,
		0.11,
	),
	(
		"GEO-body_female_realistic",
		"GEO-body_female_realistic.eye.L",
		"GEO-body_female_realistic.eye.R",
		(0.82, 0.62, 0.48, 1),
		(0.45, 0.22, 0.18, 1),
		(0.16, 0.14, 0.14, 1),
		(0.25, 0.12, 0.06, 1),
		(0.15, 0.12, 0.10, 1),
		"variant_female_tan.glb",
		1.66,
		0.15,
	),
	(
		"GEO-body_female_realistic",
		"GEO-body_female_realistic.eye.L",
		"GEO-body_female_realistic.eye.R",
		(0.42, 0.28, 0.20, 1),
		(0.55, 0.18, 0.28, 1),
		(0.12, 0.10, 0.12, 1),
		(0.06, 0.04, 0.03, 1),
		(0.10, 0.08, 0.08, 1),
		"variant_female_deep.glb",
		1.70,
		0.14,
	),
]

for j in jobs:
	build_human(*j)

# Cats
build_cat("player_cat.glb", fur=(0.72, 0.55, 0.32, 1), white_chest=True)
build_cat("npc_cat.glb", fur=(0.18, 0.18, 0.20, 1), white_chest=False)
build_cat("variant_cat_orange.glb", fur=(0.85, 0.45, 0.15, 1), white_chest=True)
build_cat("variant_cat_gray.glb", fur=(0.55, 0.55, 0.58, 1), white_chest=True)
build_cat("variant_cat_calico.glb", fur=(0.80, 0.55, 0.30, 1), white_chest=True)

# Crystals
build_crystal("crystal.glb", tint=(0.40, 0.78, 1.0, 0.92), spikes=8)
build_crystal("variant_crystal_violet.glb", tint=(0.65, 0.35, 0.95, 0.92), spikes=6)
build_crystal("variant_crystal_amber.glb", tint=(1.0, 0.70, 0.25, 0.92), spikes=7)
build_crystal("variant_crystal_emerald.glb", tint=(0.25, 0.90, 0.55, 0.92), spikes=9)

# Convert Quaternius creatures / aircraft
creatures = [
	("/tmp/gap_assets/monsters/Big/glTF/Demon.gltf", "creature.glb", 2.2),
	("/tmp/gap_assets/monsters/Big/glTF/Yeti.gltf", "variant_yeti.glb", 2.4),
	("/tmp/gap_assets/monsters/Big/glTF/Alien.gltf", "variant_alien.glb", 2.0),
	("/tmp/gap_assets/monsters/Big/glTF/Dino.gltf", "variant_dino.glb", 2.3),
	("/tmp/gap_assets/monsters/Big/glTF/BlueDemon.gltf", "variant_blue_demon.glb", 2.2),
	("/tmp/gap_assets/animals/glTF/Wolf.gltf", "variant_wolf.glb", 1.1),
	("/tmp/gap_assets/animals/glTF/Fox.gltf", "variant_fox.glb", 0.85),
]
for src, name, h in creatures:
	if os.path.exists(src):
		convert_gltf(src, os.path.join(OUT, name), target_height=h)

ships = [
	("/tmp/gap_assets/spaceships/Bob/glTF/Bob.gltf", "vehicle_aircraft_body.glb", 2.5),
]
zenith = "/tmp/gap_assets/spaceships/Zenith/glTF/Zenith.gltf"
if os.path.exists(zenith):
	ships.append((zenith, "variant_aircraft_zenith.glb", 3.0))
for src, name, h in ships:
	if os.path.exists(src):
		convert_gltf(src, os.path.join(OUT, name), target_height=h)

print("DONE", os.listdir(OUT))
