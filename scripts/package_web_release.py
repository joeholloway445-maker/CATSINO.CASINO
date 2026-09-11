#!/usr/bin/env python3
"""Package and patch Godot Web (HTML5) build for GitHub Releases & Pages.

In Godot 4, index.html contains:
    const GODOT_CONFIG = {"args":[],"canvasResizePolicy":2,"executable":"index",...};

When index.pck / index.wasm exceed GitHub Pages' 100MB file limit (often 200MB-500MB),
we upload index.pck and index.wasm as GitHub Release assets (or to an S3/R2 bucket),
and patch index.html to load executable assets from that remote URL prefix.

Usage:
    python scripts/package_web_release.py --tag prototype_web_v0.4
    python scripts/package_web_release.py --remote-prefix https://cdn.example.com/builds/v0.4/index
    python scripts/package_web_release.py --inspect
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BUILDS_DIR = ROOT / "builds" / "html5"
INDEX_HTML = BUILDS_DIR / "index.html"
RELEASE_ASSETS_DIR = ROOT / "builds" / "release_assets"
PAGES_DIR = ROOT / "builds" / "gh_pages"

# Large binary files to be hosted on Releases / CDN instead of GitHub Pages
HEAVY_EXTENSIONS = {".pck", ".wasm", ".zip"}


def get_repo_slug() -> str:
    """Detect github owner/repo from git or environment."""
    gh_repo = os.environ.get("GITHUB_REPOSITORY")
    if gh_repo:
        return gh_repo
    # fallback from git remote if possible
    git_config = ROOT / ".git" / "config"
    if git_config.exists():
        text = git_config.read_text(encoding="utf-8", errors="replace")
        m = re.search(r"url = .*github\.com[:/]([^/]+/[^/.]+)", text)
        if m:
            return m.group(1).removesuffix(".git")
    return "joeholloway445-maker/Periliminal.Space"


def inspect_build() -> int:
    """Inspect current builds/html5/ contents and print sizes."""
    if not BUILDS_DIR.exists():
        print(f"Error: {BUILDS_DIR} does not exist. Run export_web.sh first.")
        return 1

    print(f"=== Inspecting Web Build at {BUILDS_DIR} ===")
    total_size = 0
    heavy_size = 0
    light_size = 0

    files = sorted(BUILDS_DIR.iterdir())
    for f in files:
        if f.is_file():
            size = f.stat().st_size
            total_size += size
            is_heavy = f.suffix in HEAVY_EXTENSIONS or size > 25 * 1024 * 1024
            tag = "[HEAVY]" if is_heavy else "[LIGHT]"
            if is_heavy:
                heavy_size += size
            else:
                light_size += size
            print(f"  {tag} {f.name:30} : {size / (1024*1024):8.2f} MB")

    print(f"\nTotal size: {total_size / (1024*1024):.2f} MB")
    print(f"  Release binaries (PCK/WASM): {heavy_size / (1024*1024):.2f} MB")
    print(f"  Pages web shell (HTML/JS)  : {light_size / (1024*1024):.2f} MB")

    if heavy_size > 100 * 1024 * 1024:
        print("\nNote: Release binaries exceed GitHub Pages 100MB limit.")
        print("Use --tag <release_tag> to patch index.html for GitHub Release asset hosting.")
    return 0


def patch_and_package(tag: str | None, remote_prefix: str | None) -> int:
    """Patch index.html and organize files into release_assets/ and gh_pages/."""
    if not INDEX_HTML.exists():
        print(f"Error: {INDEX_HTML} not found. Run scripts/export_web.sh first.")
        return 1

    repo = get_repo_slug()
    if remote_prefix:
        exec_prefix = remote_prefix.rstrip("/")
    elif tag:
        clean_tag = tag.removeprefix("refs/tags/")
        exec_prefix = f"https://github.com/{repo}/releases/download/{clean_tag}/index"
    else:
        exec_prefix = "index"

    print(f"Target executable prefix: {exec_prefix}")

    html = INDEX_HTML.read_text(encoding="utf-8", errors="replace")

    # Match "executable":"..." in GODOT_CONFIG
    old_exec_match = re.search(r'"executable"\s*:\s*"([^"]+)"', html)
    if not old_exec_match:
        print("Warning: could not find '\"executable\":\"...\"' in index.html.")
    else:
        current_val = old_exec_match.group(1)
        print(f"Current index.html executable setting: {current_val}")
        html_patched = html.replace(
            f'"executable":"{current_val}"',
            f'"executable":"{exec_prefix}"',
            1
        )
        INDEX_HTML.write_text(html_patched, encoding="utf-8")
        print(f"Updated index.html executable -> {exec_prefix}")

    # Prepare release_assets/
    RELEASE_ASSETS_DIR.mkdir(parents=True, exist_ok=True)
    PAGES_DIR.mkdir(parents=True, exist_ok=True)

    for item in BUILDS_DIR.iterdir():
        if not item.is_file():
            continue
        # Release assets: pck, wasm, or large files
        if item.suffix in HEAVY_EXTENSIONS or item.stat().st_size > 25 * 1024 * 1024:
            dest = RELEASE_ASSETS_DIR / item.name
            shutil.copy2(item, dest)
            print(f"  -> Release asset: {item.name} ({item.stat().st_size / (1024*1024):.2f} MB)")
        else:
            # GitHub Pages assets: html, js, png, ico
            dest = PAGES_DIR / item.name
            shutil.copy2(item, dest)
            print(f"  -> GitHub Pages shell: {item.name}")

    print("\nPackaging complete.")
    print(f"  Release assets dir: {RELEASE_ASSETS_DIR}")
    print(f"  GitHub Pages dir  : {PAGES_DIR}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Package Godot Web release assets.")
    parser.add_argument("--tag", type=str, help="GitHub Release tag (e.g. prototype_web_v0.4 or v0.1.0)")
    parser.add_argument("--remote-prefix", type=str, help="Full remote prefix for executable (e.g. https://.../index)")
    parser.add_argument("--inspect", action="store_true", help="Inspect current build files without modifying")

    args = parser.parse_args()

    if args.inspect:
        return inspect_build()

    return patch_and_package(args.tag, args.remote_prefix)


if __name__ == "__main__":
    sys.exit(main())
