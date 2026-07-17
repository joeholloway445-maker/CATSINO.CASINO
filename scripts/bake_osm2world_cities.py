#!/usr/bin/env python3
"""Bake OSM2World 3D shells for each DFW hub, aligned to OsmCityLayout space.

Pipeline:
  1. Fetch OSM XML for the hub bbox via Overpass (with mirror fallbacks)
  2. Convert with OSM2World (FILE mode) using the futuristic style props
  3. Blender: Z-up→Y-up, uniform scale to match godot/world_data/osm/<hub>.json,
     SW corner at origin, cool emissive material pass
  4. Install as godot/assets/models/osm2world_<hub>.glb
  5. IMPORTANT: do NOT Draco-compress for Godot 4.3 stock import — Godot
     cannot load KHR_draco_mesh_compression. If you compress for transfer,
     decode with `gltf-transform copy` before committing.

Requires:
  - Java 17+ and OSM2World (default /tmp/studio_quality/osm2world)
  - Blender 4.x (default /tmp/gap_assets/blender/blender)
  - Network to an Overpass mirror

Usage:
  python3 scripts/bake_osm2world_cities.py
  python3 scripts/bake_osm2world_cities.py --hub dallas
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import textwrap
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OSM_DIR = ROOT / "godot" / "world_data" / "osm"
OUT_MODELS = ROOT / "godot" / "assets" / "models"
WORK = Path(os.environ.get("OSM2WORLD_WORK", "/tmp/studio_quality/o2w_work"))
O2W_DIR = Path(os.environ.get("OSM2WORLD_HOME", "/tmp/studio_quality/osm2world"))
BLENDER = Path(os.environ.get("BLENDER", "/tmp/gap_assets/blender/blender"))
# Prefer the copy inside OSM2World so relative texture paths in
# standard.properties resolve; fall back to the repo copy.
STYLE = Path(
	os.environ.get(
		"OSM2WORLD_STYLE",
		str(O2W_DIR / "futuristic.properties"),
	)
)
if not STYLE.exists():
	STYLE = ROOT / "scripts" / "osm2world_futuristic.properties"
USER_AGENT = "PeriliminalStudio/1.0 (+https://github.com/joeholloway445-maker/CATSINO.CASINO)"

OVERPASS_URLS = [
	os.environ.get("OVERPASS_URL", "").strip(),
	"https://maps.mail.ru/osm/tools/overpass/api/interpreter",
	"https://overpass-api.de/api/interpreter",
	"https://overpass.kumi.systems/api/interpreter",
]
OVERPASS_URLS = [u for u in OVERPASS_URLS if u]

# south, west, north, east — same as fetch_osm_cities.py
HUBS = {
	"dallas": (32.7750, -96.8120, 32.7920, -96.7900),
	"fort_worth": (32.7480, -97.3350, 32.7600, -97.3200),
	"arlington": (32.7400, -97.1000, 32.7600, -97.0700),
	"denton": (33.2100, -97.1400, 33.2200, -97.1250),
}


def run(cmd: list[str], cwd: Path | None = None) -> None:
	print("+", " ".join(cmd), flush=True)
	subprocess.check_call(cmd, cwd=str(cwd) if cwd else None)


def fetch_osm(hub_id: str, bbox: tuple[float, float, float, float]) -> Path:
	"""Download OSM XML for the bbox (buildings/highways-first for reliability)."""
	WORK.mkdir(parents=True, exist_ok=True)
	out = WORK / f"{hub_id}.osm"
	if out.exists() and out.stat().st_size > 50_000:
		print(f"reuse cached {out} ({out.stat().st_size / 1e6:.2f} MB)", flush=True)
		return out

	south, west, north, east = bbox
	# Prefer buildings+highways — full dumps include landcover that trips
	# OSM2World SurfaceAreaModule NPEs on some downtown tags.
	queries = [
		f"""
[out:xml][timeout:180];
(
  way["building"]({south},{west},{north},{east});
  way["building:part"]({south},{west},{north},{east});
  way["highway"]({south},{west},{north},{east});
  relation["building"]({south},{west},{north},{east});
);
(._;>;);
out body;
""",
		f"""
[out:xml][timeout:180];
(
  node({south},{west},{north},{east});
  way({south},{west},{north},{east});
  relation({south},{west},{north},{east});
);
out body;
>;
out skel qt;
""",
	]

	last_err: Exception | None = None
	for q_i, query in enumerate(queries):
		for url in OVERPASS_URLS:
			for attempt in range(3):
				try:
					print(f"Overpass {url} query={q_i} attempt={attempt+1} hub={hub_id}", flush=True)
					data = urllib.parse.urlencode({"data": query}).encode()
					req = urllib.request.Request(
						url, data=data, headers={"User-Agent": USER_AGENT}
					)
					with urllib.request.urlopen(req, timeout=240) as resp:
						payload = resp.read()
					if len(payload) < 2000 or b"<osm" not in payload[:200]:
						raise RuntimeError(f"short/invalid OSM from {url}: {len(payload)} bytes")
					out.write_bytes(payload)
					print(f"wrote {out} ({out.stat().st_size / 1e6:.2f} MB)", flush=True)
					return out
				except Exception as exc:  # noqa: BLE001 — mirrors fail variously
					last_err = exc
					print(f"  fail: {exc}", flush=True)
					time.sleep(4 * (attempt + 1))
	raise SystemExit(f"Overpass fetch failed for {hub_id}: {last_err}")


def sanitize_osm(osm_path: Path) -> Path:
	"""Strip landcover tags that crash OSM2World SurfaceAreaModule."""
	import re

	out = osm_path.with_name(osm_path.stem + "_sanitized.osm")
	text = osm_path.read_text(encoding="utf-8", errors="replace")
	for key in ("surface", "landcover", "natural", "landuse", "leisure"):
		text = re.sub(rf'\s*<tag k="{key}" v="[^"]*"/>', "", text)
	out.write_text(text, encoding="utf-8")
	print(f"sanitized {out} ({out.stat().st_size / 1e6:.2f} MB)", flush=True)
	return out


def convert_hub(hub_id: str, osm_path: Path) -> Path:
	WORK.mkdir(parents=True, exist_ok=True)
	raw = WORK / f"{hub_id}_raw.glb"
	if raw.exists():
		raw.unlink()
	o2w = O2W_DIR / "osm2world.sh"
	if not o2w.exists():
		raise SystemExit(f"OSM2World not found at {o2w}")
	clean = sanitize_osm(osm_path)
	# Default style — futuristic look is applied in Blender align pass.
	# Custom properties can still be forced via OSM2WORLD_STYLE.
	style = STYLE if STYLE.exists() else (O2W_DIR / "standard.properties")
	cmd = [
		str(o2w),
		"convert",
		"-i",
		str(clean),
		"-o",
		str(raw),
		"--lod",
		"2",
	]
	# Only pass --config when it's the known-good standard or our futuristic
	# that includes it; skip broken overrides.
	if style.name == "standard.properties" or (
		style.exists() and "include" in style.read_text()[:500]
	):
		# Prefer standard — custom color overrides have crashed SurfaceArea.
		cmd.extend(["--config", str(O2W_DIR / "standard.properties")])
	try:
		run(cmd)
	except subprocess.CalledProcessError as exc:
		# OSM2World is fault-tolerant: some modules throw but still write GLB.
		if raw.exists() and raw.stat().st_size > 1000:
			print(f"OSM2World exited {exc.returncode} but GLB exists — continuing", flush=True)
		else:
			raise
	if not raw.exists() or raw.stat().st_size < 1000:
		raise SystemExit(f"OSM2World produced no usable GLB for {hub_id}: {raw}")
	print(f"raw GLB {raw} ({raw.stat().st_size / 1e6:.2f} MB)", flush=True)
	return raw


def align_with_layout(hub_id: str, raw_glb: Path) -> Path:
	layout_path = OSM_DIR / f"{hub_id}.json"
	if not layout_path.exists():
		raise SystemExit(f"Missing layout JSON {layout_path} — run fetch_osm_cities.py first")
	layout = json.loads(layout_path.read_text())
	target_x = float(layout["size"]["x"])
	target_z = float(layout["size"]["z"])
	out = WORK / f"{hub_id}_aligned.glb"
	script = WORK / f"align_{hub_id}.py"
	script.write_text(
		textwrap.dedent(
			f"""\
			import bpy
			from mathutils import Vector
			import math

			bpy.ops.wm.read_factory_settings(use_empty=True)
			bpy.ops.import_scene.gltf(filepath={raw_glb.as_posix()!r})
			meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
			if not meshes:
				raise SystemExit('no meshes')
			bpy.ops.object.select_all(action='DESELECT')
			for o in meshes:
				o.select_set(True)
			bpy.context.view_layer.objects.active = meshes[0]
			if len(meshes) > 1:
				bpy.ops.object.join()
			body = bpy.context.active_object
			body.name = 'Osm2World_{hub_id}'
			bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

			# OSM2World is Z-up; Godot is Y-up. Rotate -90° around X.
			body.rotation_euler = (math.radians(-90), 0, 0)
			bpy.ops.object.transform_apply(rotation=True)

			mn = Vector((1e9, 1e9, 1e9))
			mx = Vector((-1e9, -1e9, -1e9))
			for c in body.bound_box:
				w = body.matrix_world @ Vector(c)
				mn.x, mn.y, mn.z = min(mn.x, w.x), min(mn.y, w.y), min(mn.z, w.z)
				mx.x, mx.y, mx.z = max(mx.x, w.x), max(mx.y, w.y), max(mx.z, w.z)
			span_x = max(mx.x - mn.x, 0.01)
			span_z = max(mx.z - mn.z, 0.01)
			# Non-uniform XZ so the shell fills OsmCityLayout size (gameplay
			# landmarks/streets). Y uses the mean so tower heights stay sane.
			sx = {target_x} / span_x
			sz = {target_z} / span_z
			sy = (sx + sz) * 0.5
			body.scale = (sx, sy, sz)
			bpy.ops.object.transform_apply(scale=True)
			s = sy  # for log line below

			mn = Vector((1e9, 1e9, 1e9))
			mx = Vector((-1e9, -1e9, -1e9))
			for c in body.bound_box:
				w = body.matrix_world @ Vector(c)
				mn.x, mn.y, mn.z = min(mn.x, w.x), min(mn.y, w.y), min(mn.z, w.z)
				mx.x, mx.y, mx.z = max(mx.x, w.x), max(mx.y, w.y), max(mx.z, w.z)
			body.location -= Vector((mn.x, mn.y, mn.z))
			bpy.ops.object.transform_apply(location=True)

			# Futuristic neon / glass pass
			for slot in body.material_slots:
				mat = slot.material
				if mat is None:
					continue
				mat.use_nodes = True
				nt = mat.node_tree
				bsdf = nt.nodes.get('Principled BSDF')
				if bsdf is None:
					continue
				name = (mat.name or '').lower()
				base = bsdf.inputs['Base Color'].default_value
				is_glass = 'glass' in name or 'window' in name or base[2] > base[0] * 1.08
				is_road = 'asphalt' in name or 'road' in name or 'pavement' in name
				if is_road:
					bsdf.inputs['Base Color'].default_value = (0.06, 0.07, 0.09, 1.0)
					bsdf.inputs['Roughness'].default_value = 0.85
					bsdf.inputs['Metallic'].default_value = 0.05
				elif is_glass:
					bsdf.inputs['Base Color'].default_value = (0.35, 0.55, 0.75, 1.0)
					bsdf.inputs['Metallic'].default_value = 0.55
					bsdf.inputs['Roughness'].default_value = 0.18
					if 'Emission Color' in bsdf.inputs:
						bsdf.inputs['Emission Color'].default_value = (0.25, 0.55, 1.0, 1.0)
						bsdf.inputs['Emission Strength'].default_value = 0.55
				else:
					# Cool metal/concrete towers
					bsdf.inputs['Base Color'].default_value = (
						base[0] * 0.55 + 0.25,
						base[1] * 0.55 + 0.32,
						base[2] * 0.55 + 0.45,
						1.0,
					)
					bsdf.inputs['Metallic'].default_value = max(bsdf.inputs['Metallic'].default_value, 0.28)
					bsdf.inputs['Roughness'].default_value = min(bsdf.inputs['Roughness'].default_value, 0.42)
					if 'Emission Color' in bsdf.inputs and 'roof' not in name:
						bsdf.inputs['Emission Color'].default_value = (0.15, 0.35, 0.7, 1.0)
						bsdf.inputs['Emission Strength'].default_value = 0.12

			bpy.ops.export_scene.gltf(
				filepath={out.as_posix()!r},
				export_format='GLB',
				use_selection=False,
				export_apply=True,
				export_animations=False,
				export_lights=False,
				export_cameras=False,
			)
			print('ALIGNED', {hub_id!r}, 'span_before', span_x, span_z, 'scale', s, '→', {out.as_posix()!r})
			"""
		)
	)
	if not BLENDER.exists():
		raise SystemExit(f"Blender not found at {BLENDER}")
	run([str(BLENDER), "-b", "-P", str(script)])
	if not out.exists():
		raise SystemExit(f"Align failed for {hub_id}")
	return out


def install(hub_id: str, aligned: Path) -> Path:
	OUT_MODELS.mkdir(parents=True, exist_ok=True)
	dest = OUT_MODELS / f"osm2world_{hub_id}.glb"
	dest.write_bytes(aligned.read_bytes())
	print(f"INSTALLED {dest} ({dest.stat().st_size / 1e6:.2f} MB)", flush=True)
	return dest


def main() -> int:
	ap = argparse.ArgumentParser()
	ap.add_argument("--hub", choices=sorted(HUBS), help="Single hub (default: all)")
	ap.add_argument("--skip-fetch", action="store_true", help="Reuse cached .osm files")
	args = ap.parse_args()
	hubs = [args.hub] if args.hub else list(HUBS)
	# Ensure style include path exists
	std = O2W_DIR / "standard.properties"
	if STYLE.exists() and std.exists():
		text = STYLE.read_text()
		if "include =" in text and "/tmp/studio_quality/osm2world/standard.properties" not in text:
			pass
	for hub_id in hubs:
		print(f"=== {hub_id} ===", flush=True)
		bbox = HUBS[hub_id]
		osm = WORK / f"{hub_id}.osm"
		if not (args.skip_fetch and osm.exists()):
			osm = fetch_osm(hub_id, bbox)
		elif not osm.exists():
			osm = fetch_osm(hub_id, bbox)
		raw = convert_hub(hub_id, osm)
		aligned = align_with_layout(hub_id, raw)
		install(hub_id, aligned)
	print("DONE", hubs)
	return 0


if __name__ == "__main__":
	sys.exit(main())
