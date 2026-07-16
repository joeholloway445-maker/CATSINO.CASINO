#!/usr/bin/env python3
"""Bake studio-quality PeriHuman GLBs via MPFB2 (MakeHuman for Blender).

Requires Blender 4.2+ with the MPFB extension enabled
(`bl_ext.user_default.mpfb`) and MakeHuman CC0 asset packs extracted into
the MPFB user data directory.

Usage:
  python3 scripts/bake_mpfb_characters.py
  BLENDER=/path/to/blender python3 scripts/bake_mpfb_characters.py
"""

from __future__ import annotations

import os
import subprocess
import sys
import textwrap
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "godot" / "assets" / "models"
BLENDER = Path(os.environ.get("BLENDER", "/tmp/gap_assets/blender/blender"))
WORK = Path(os.environ.get("MPFB_WORK", "/tmp/studio_quality/mpfb_bake"))
DATA = Path(
	os.environ.get(
		"MPFB_DATA",
		str(
			Path.home()
			/ ".config/blender/4.2/extensions/.user/user_default/mpfb/data"
		),
	)
)

# Relative to MPFB data dir
ASSETS = {
	"player": {
		"gender": 0.92,  # male-leaning
		"age": 0.45,
		"muscle": 0.62,
		"weight": 0.48,
		"height": 0.55,
		"race": {"caucasian": 0.45, "african": 0.3, "asian": 0.25},
		"skin": "skins/young_caucasian_male/young_caucasian_male.mhmat",
		"eyes": "eyes/high-poly/high-poly.mhclo",
		"teeth": "teeth/teeth_base/teeth_base.mhclo",
		"eyebrows": "eyebrows/mindfront_eyebrows_01/mindfront_eyebrows_01.mhclo",
		"eyelashes": None,  # optional
		"hair": "hair/short01/short01.mhclo",
		"shirt": "clothes/namuhekam_male_polo_shirt/namuhekam_male_polo_shirt.mhclo",
		"pants": "clothes/cortu_cargo_pants/cortu_cargo_pants.mhclo",
		"shoes": "clothes/shoes01/shoes01.mhclo",
		"slots": [
			"peri_human_player.glb",
			"metahuman_player.glb",
			"player_human.glb",
		],
	},
	"npc": {
		"gender": 0.18,  # female-leaning
		"age": 0.5,
		"muscle": 0.45,
		"weight": 0.5,
		"height": 0.48,
		"race": {"caucasian": 0.4, "african": 0.25, "asian": 0.35},
		"skin": "skins/young_caucasian_female/young_caucasian_female.mhmat",
		"eyes": "eyes/high-poly/high-poly.mhclo",
		"teeth": "teeth/teeth_base/teeth_base.mhclo",
		"eyebrows": "eyebrows/mindfront_eyebrows_03/mindfront_eyebrows_03.mhclo",
		"eyelashes": "eyelashes/mindfront_eyelashes_04/mindfront_eyelashes_04.mhclo",
		"hair": "hair/bob01/bob01.mhclo",
		"shirt": "clothes/joepal_crude_t-shirt_female/joepal_crude_t-shirt_female.mhclo",
		"pants": "clothes/toigo_wool_pants/toigo_wool_pants.mhclo",
		"shoes": "clothes/shoes02/shoes02.mhclo",
		"slots": [
			"peri_human_npc.glb",
			"metahuman_npc.glb",
			"npc_human.glb",
		],
	},
}


def _resolve(rel: str | None) -> str | None:
	if not rel:
		return None
	p = DATA / rel
	if p.exists():
		return str(p)
	# eyelashes pack may nest differently
	matches = list(DATA.glob(f"**/{Path(rel).name}"))
	return str(matches[0]) if matches else None


def write_blender_script() -> Path:
	WORK.mkdir(parents=True, exist_ok=True)
	# Resolve asset paths up front
	resolved = {}
	for key, cfg in ASSETS.items():
		r = dict(cfg)
		for field in ("skin", "eyes", "teeth", "eyebrows", "eyelashes", "hair", "shirt", "pants", "shoes"):
			path = _resolve(cfg.get(field))
			if cfg.get(field) and not path:
				print(f"WARN missing {key}.{field}: {cfg.get(field)}", flush=True)
			r[field] = path
		resolved[key] = r

	script = WORK / "bake_mpfb.py"
	script.write_text(
		textwrap.dedent(
			f"""\
			import bpy
			import addon_utils
			from mathutils import Vector
			from pathlib import Path
			import json

			# Enable MPFB extension
			addon_utils.enable('bl_ext.user_default.mpfb', default_set=True, persistent=True)

			from bl_ext.user_default.mpfb.services import (
				HumanService, TargetService, MaterialService, ObjectService
			)

			ASSETS = {resolved!r}
			OUT_DIR = Path({str(WORK)!r})
			SHIP = Path({str(OUT)!r})

			def apply_skin(basemesh, mhmat_path):
				if not mhmat_path:
					return
				try:
					MaterialService.create_v2_skin_material(
						'PeriSkin', blender_object=basemesh, mhmat_file=mhmat_path
					)
					print('SKIN', mhmat_path)
				except Exception as exc:
					print('SKIN_FAIL', mhmat_path, exc)

			def add_asset(basemesh, path, asset_type):
				if not path:
					return
				try:
					HumanService.add_mhclo_asset(
						path, basemesh,
						asset_type=asset_type,
						subdiv_levels=0,
						material_type="MAKESKIN",
						set_up_rigging=False,
						interpolate_weights=False,
						import_subrig=False,
						import_weights=False,
					)
					print('ASSET', asset_type, path)
				except Exception as exc:
					print('ASSET_FAIL', asset_type, path, exc)

			def bake_one(key, cfg):
				bpy.ops.wm.read_factory_settings(use_empty=True)
				addon_utils.enable('bl_ext.user_default.mpfb', default_set=True, persistent=True)
				# re-import after factory reset
				from bl_ext.user_default.mpfb.services import HumanService, TargetService, MaterialService

				macro = TargetService.get_default_macro_info_dict()
				macro['gender'] = float(cfg['gender'])
				macro['age'] = float(cfg['age'])
				macro['muscle'] = float(cfg['muscle'])
				macro['weight'] = float(cfg['weight'])
				macro['height'] = float(cfg['height'])
				macro['race'] = cfg['race']
				basemesh = HumanService.create_human(
					mask_helpers=True,
					detailed_helpers=True,
					extra_vertex_groups=True,
					feet_on_ground=True,
					scale=1.0,  # meter scale for Godot
					macro_detail_dict=macro,
				)
				basemesh.name = f'PeriHuman_{{key}}'
				apply_skin(basemesh, cfg.get('skin'))
				add_asset(basemesh, cfg.get('eyes'), 'Eyes')
				add_asset(basemesh, cfg.get('teeth'), 'Teeth')
				add_asset(basemesh, cfg.get('eyebrows'), 'Eyebrows')
				add_asset(basemesh, cfg.get('eyelashes'), 'Eyelashes')
				add_asset(basemesh, cfg.get('hair'), 'Hair')
				add_asset(basemesh, cfg.get('shirt'), 'Clothes')
				add_asset(basemesh, cfg.get('pants'), 'Clothes')
				add_asset(basemesh, cfg.get('shoes'), 'Clothes')

				# Orient: MPFB is Z-up; Godot Y-up. Rotate -90 X.
				import math
				meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
				bpy.ops.object.select_all(action='DESELECT')
				for o in meshes:
					o.select_set(True)
				bpy.context.view_layer.objects.active = basemesh
				# Parent clothes already under basemesh; rotate root
				basemesh.rotation_euler = (math.radians(-90), 0, 0)
				bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)

				# Ground feet
				mn = Vector((1e9, 1e9, 1e9)); mx = Vector((-1e9, -1e9, -1e9))
				for o in meshes:
					for c in o.bound_box:
						w = o.matrix_world @ Vector(c)
						mn.x, mn.y, mn.z = min(mn.x, w.x), min(mn.y, w.y), min(mn.z, w.z)
						mx.x, mx.y, mx.z = max(mx.x, w.x), max(mx.y, w.y), max(mx.z, w.z)
				for o in meshes:
					o.location.y -= mn.y
				bpy.ops.object.select_all(action='SELECT')
				bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

				out = OUT_DIR / f'{{key}}.glb'
				bpy.ops.export_scene.gltf(
					filepath=str(out),
					export_format='GLB',
					use_selection=False,
					export_apply=True,
					export_animations=False,
					export_lights=False,
					export_cameras=False,
				)
				print('WROTE', out, out.stat().st_size)
				for slot in cfg['slots']:
					dest = SHIP / slot
					dest.write_bytes(out.read_bytes())
					print('INSTALLED', dest)

			for key, cfg in ASSETS.items():
				print('===', key, '===')
				bake_one(key, cfg)
			print('MPFB_BAKE_DONE')
			"""
		)
	)
	return script


def main() -> int:
	if not BLENDER.exists():
		raise SystemExit(f"Blender not found: {BLENDER}")
	if not DATA.exists():
		raise SystemExit(f"MPFB data not found: {DATA} — extract CC0 asset packs first")
	# eyelashes path discovery
	lash = list(DATA.glob("**/eyelashes*.mhclo")) + list(DATA.glob("**/eyelash*.mhclo"))
	if lash and ASSETS["npc"]["eyelashes"] and not (DATA / ASSETS["npc"]["eyelashes"]).exists():
		rel = lash[0].relative_to(DATA)
		ASSETS["npc"]["eyelashes"] = str(rel)
		print("eyelashes →", rel)
	script = write_blender_script()
	print("+", BLENDER, "-b", "-P", script, flush=True)
	subprocess.check_call([str(BLENDER), "-b", "-P", str(script)])
	return 0


if __name__ == "__main__":
	sys.exit(main())
