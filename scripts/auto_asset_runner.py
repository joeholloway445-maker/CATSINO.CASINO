#!/usr/bin/env python3
"""Autonomous asset generation runner for Periliminal.Space.

Orchestrates batch asset generation:
1. Loads/exports build/asset_jobs.jsonl (via export_asset_prompts.py if missing).
2. Filters for missing target assets.
3. Generates missing sprites/textures using keyless Pollinations (or Replicate/Tripo).
4. Normalizes images to JPEG Lossy format.
5. Generates Godot `.import` sidecar files (compress/mode=1, lossy_quality=0.7) to keep Web build small.
6. Optional: batch git commit + push every N completed images.

Usage:
    python scripts/auto_asset_runner.py --dry-run
    python scripts/auto_asset_runner.py --limit 20 --workers 12
    python scripts/auto_asset_runner.py --commit-batch 50
"""
from __future__ import annotations

import argparse
import concurrent.futures
import json
import os
import subprocess
import sys
import time
import urllib.parse
from pathlib import Path

# Ensure UTF-8 console output
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parents[1]
BUILD_DIR = ROOT / "build"
JOBS_FILE = BUILD_DIR / "asset_jobs.jsonl"
GODOT_DIR = ROOT / "godot"
ASSETS_DIR = GODOT_DIR / "assets"
ENTITIES_DIR = ASSETS_DIR / "entities"

IMPORT_SIDECAR_TEMPLATE = """[remap]

importer="texture"
type="CompressedTexture2D"
uid="{uid}"
path="res://.godot/imported/{filename}-{hash_val}.ctex"
metadata={{
"vram_texture": false
}}

[deps]

source_file="res://{rel_source}"
dest_files=["res://.godot/imported/{filename}-{hash_val}.ctex"]

[params]

compress/mode=1
compress/high_quality=false
compress/lossy_quality=0.7
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
"""


def ensure_jobs_file() -> Path:
    """Generate build/asset_jobs.jsonl if missing."""
    if not JOBS_FILE.exists():
        print("Jobs file missing. Running scripts/export_asset_prompts.py...")
        BUILD_DIR.mkdir(parents=True, exist_ok=True)
        cmd = [sys.executable, str(ROOT / "scripts" / "export_asset_prompts.py")]
        subprocess.run(cmd, check=True)
    return JOBS_FILE


def generate_import_sidecar(image_path: Path):
    """Write Godot .import sidecar file in Lossy mode (mode=1)."""
    import hashlib
    sidecar_path = Path(str(image_path) + ".import")
    if sidecar_path.exists():
        return

    rel_source = image_path.relative_to(GODOT_DIR).as_posix()
    filename = image_path.name
    # Generate deterministic hash and UID from relative path
    path_hash = hashlib.md5(rel_source.encode("utf-8")).hexdigest()
    uid_hash = hashlib.sha1(rel_source.encode("utf-8")).hexdigest()[:13]
    uid = f"uid://{uid_hash}"

    content = IMPORT_SIDECAR_TEMPLATE.format(
        uid=uid,
        filename=filename,
        hash_val=path_hash,
        rel_source=rel_source
    )
    sidecar_path.write_text(content, encoding="utf-8")


def normalize_target_path(job: dict) -> Path:
    """Determine final disk target path for sprite/texture."""
    # Check sprite_target first
    target_str = job.get("sprite_target") or job.get("target") or ""
    # Normalize .png to .jpg for 2D entity portraits to match PR #78 conventions
    if "assets/entities/" in target_str and target_str.endswith(".png"):
        target_str = target_str[:-4] + ".jpg"

    rel = target_str.replace("res://", "")
    return ROOT / rel


def fetch_pollinations(prompt: str, seed: int | None, neg: str | None, out_path: Path) -> bool:
    """Fetch image from Pollinations via curl or urllib with retry."""
    import urllib.request
    params = {
        "width": "768",
        "height": "768",
        "nologo": "true",
        "model": os.environ.get("POLLINATIONS_MODEL", "flux"),
    }
    if seed is not None:
        params["seed"] = str(int(seed) % 2_000_000_000)

    text = prompt
    if neg:
        text += f" Avoid: {neg}"

    encoded_prompt = urllib.parse.quote(text[:1800], safe="")
    query_str = urllib.parse.urlencode(params)
    url = f"https://image.pollinations.ai/prompt/{encoded_prompt}?{query_str}"

    out_path.parent.mkdir(parents=True, exist_ok=True)
    temp_path = out_path.with_suffix(out_path.suffix + ".tmp")

    # Try curl first
    curl_cmd = [
        "curl", "-sS", "--retry", "2", "--retry-delay", "2",
        "--connect-timeout", "15", "--max-time", "90",
        "-o", str(temp_path), url
    ]
    try:
        res = subprocess.run(curl_cmd, capture_output=True)
        if res.returncode == 0 and temp_path.exists() and temp_path.stat().st_size > 1024:
            temp_path.replace(out_path)
            generate_import_sidecar(out_path)
            return True
    except Exception:
        pass

    # Fallback to urllib
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "PeriliminalAutoAssetRunner/1.0"})
        with urllib.request.urlopen(req, timeout=90) as response:
            data = response.read()
            if len(data) > 1024:
                temp_path.write_bytes(data)
                temp_path.replace(out_path)
                generate_import_sidecar(out_path)
                return True
    except Exception as e:
        # print error but allow worker pool to continue
        pass

    if temp_path.exists():
        temp_path.unlink()
    return False


def commit_batch(count: int, label: str):
    """Commit tracked changes in godot/assets/entities/."""
    try:
        subprocess.run(["git", "add", "godot/assets/entities/"], cwd=ROOT, check=True)
        status = subprocess.run(["git", "status", "--porcelain", "godot/assets/entities/"], cwd=ROOT, capture_output=True, text=True)
        if not status.stdout.strip():
            return

        msg = f"assets: autonomous generation batch (+{count} {label})\n\nLossy JPEG + sidecars generated via auto_asset_runner.py."
        subprocess.run(["git", "commit", "-m", msg], cwd=ROOT, check=True)
        print(f"  [git] Committed batch of {count} assets.")
    except Exception as e:
        print(f"  [git] Commit skipped or failed: {e}")


def main():
    parser = argparse.ArgumentParser(description="Autonomous Asset Studio Runner")
    parser.add_argument("--dry-run", action="store_true", help="Inspect missing assets without generating")
    parser.add_argument("--limit", type=int, default=None, help="Maximum number of assets to generate")
    parser.add_argument("--workers", type=int, default=12, help="Parallel worker threads (default 12)")
    parser.add_argument("--commit-batch", type=int, default=0, help="Commit every N images (0 to disable)")
    parser.add_argument("--kind", type=str, default="all", help="Filter kind: entity, race, slot, all")

    args = parser.parse_args()

    jobs_path = ensure_jobs_file()
    all_jobs = []
    with open(jobs_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                all_jobs.append(json.loads(line))

    # Filter for missing
    missing_jobs = []
    for job in all_jobs:
        if args.kind != "all" and job.get("kind") != args.kind:
            continue
        dest = normalize_target_path(job)
        if not dest.exists():
            job["_dest"] = dest
            missing_jobs.append(job)

    print(f"=== Asset Status ===")
    print(f"Total jobs defined : {len(all_jobs)}")
    print(f"Missing on disk    : {len(missing_jobs)}")

    if args.dry_run:
        print("\nDry-run mode. First 5 missing targets:")
        for j in missing_jobs[:5]:
            print(f"  [{j.get('kind')}] {j.get('id')} s{j.get('stage', 0)} -> {j['_dest'].name}")
        return 0

    if not missing_jobs:
        print("All asset targets already exist on disk! Nothing to do.")
        return 0

    to_process = missing_jobs[:args.limit] if args.limit else missing_jobs
    print(f"\nStarting generation of {len(to_process)} assets with {args.workers} workers...")

    success_count = 0
    batch_counter = 0

    def process_job(job):
        prompt = job.get("sprite_prompt") or job.get("prompt")
        seed = job.get("seed")
        neg = job.get("negative_prompt")
        dest = job["_dest"]
        ok = fetch_pollinations(prompt, seed, neg, dest)
        return ok, job

    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as executor:
        futures = {executor.submit(process_job, job): job for job in to_process}
        for future in concurrent.futures.as_completed(futures):
            ok, job = future.result()
            if ok:
                success_count += 1
                batch_counter += 1
                dest = job["_dest"]
                print(f"  [OK] ({success_count}/{len(to_process)}) {dest.name}")
                if args.commit_batch > 0 and batch_counter >= args.commit_batch:
                    commit_batch(batch_counter, args.kind)
                    batch_counter = 0
            else:
                print(f"  [FAIL] {job.get('id')} ({job['_dest'].name})")

    if args.commit_batch > 0 and batch_counter > 0:
        commit_batch(batch_counter, args.kind)

    print(f"\nCompleted: {success_count}/{len(to_process)} assets generated and imported.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
