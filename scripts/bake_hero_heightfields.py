#!/usr/bin/env python3
"""Bake authored hero-region heightfields for Terrain3D / ProceduralTerrain.

Cloud agents can't hand-sculpt in the Terrain3D editor (needs local GPU).
This script produces the next-best thing: region maps with carved rivers,
mesa shoulders, hub plazas, and ridge walls — drop-in RF PNGs that
TerrainWorld prefers over pure runtime noise when present.

Usage (repo root):
  python3 scripts/bake_hero_heightfields.py

Writes:
  godot/assets/terrain/hero/<seed_key>.png   (32-bit float RF as RGB encoded)
  godot/assets/terrain/hero/README.md
"""
from __future__ import annotations

import math
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "godot" / "assets" / "terrain" / "hero"
SIZE = 256


def _smoothstep(edge0: float, edge1: float, x: float) -> float:
    t = max(0.0, min(1.0, (x - edge0) / (edge1 - edge0)))
    return t * t * (3.0 - 2.0 * t)


def _hash2(x: int, y: int, seed: int) -> float:
    n = (x * 374761393 + y * 668265263 + seed * 982451653) & 0xFFFFFFFF
    n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
    return (n & 0xFFFFFF) / float(0xFFFFFF)


def _value_noise(x: float, y: float, seed: int) -> float:
    x0, y0 = int(math.floor(x)), int(math.floor(y))
    fx, fy = x - x0, y - y0
    ux = fx * fx * (3.0 - 2.0 * fx)
    uy = fy * fy * (3.0 - 2.0 * fy)
    a = _hash2(x0, y0, seed)
    b = _hash2(x0 + 1, y0, seed)
    c = _hash2(x0, y0 + 1, seed)
    d = _hash2(x0 + 1, y0 + 1, seed)
    return (a + (b - a) * ux) + ((c + (d - c) * ux) - (a + (b - a) * ux)) * uy


def _fbm(x: float, y: float, seed: int, octaves: int = 4) -> float:
    amp, freq, total, norm = 1.0, 1.0, 0.0, 0.0
    for i in range(octaves):
        total += _value_noise(x * freq, y * freq, seed + i * 17) * amp
        norm += amp
        amp *= 0.5
        freq *= 2.0
    return total / max(norm, 1e-6)


def sculpt(seed_key: str) -> list[list[float]]:
    """Return SIZE×SIZE heights in roughly [-1, 1] with hero features."""
    seed = abs(hash(seed_key)) % (2**31)
    half = (SIZE - 1) * 0.5
    plaza_r = 26.0
    # River runs NW→SE; mesa sits NE; ridge wall on south rim.
    img: list[list[float]] = [[0.0] * SIZE for _ in range(SIZE)]
    for y in range(SIZE):
        for x in range(SIZE):
            fx, fy = float(x), float(y)
            nx, ny = (fx - half) / half, (fy - half) / half
            h = (_fbm(fx * 0.018, fy * 0.018, seed) * 2.0 - 1.0) * 0.55
            h += (_fbm(fx * 0.05, fy * 0.05, seed + 99) * 2.0 - 1.0) * 0.18

            # Soft hub plaza flatten at origin.
            dist = math.hypot(fx - half, fy - half)
            plaza = _smoothstep(plaza_r, plaza_r * 0.35, dist)
            h = h * (1.0 - plaza) + 0.0 * plaza

            # River trench
            river = abs((fx - fy) * 0.012 + math.sin(fy * 0.04) * 0.15)
            river_w = _smoothstep(0.55, 0.05, river)
            h -= river_w * 0.55

            # Mesa plateau (NE)
            mesa_cx, mesa_cy = half + 70.0, half - 55.0
            md = math.hypot(fx - mesa_cx, fy - mesa_cy)
            mesa = _smoothstep(48.0, 18.0, md)
            h = h * (1.0 - mesa * 0.7) + 0.72 * mesa

            # South ridge wall
            ridge = _smoothstep(half + 40.0, half + 90.0, fy) * (
                1.0 - _smoothstep(half - 20.0, half + 20.0, abs(fx - half))
            )
            h += ridge * 0.85

            # Subtle city-shoulder berm around plaza ring
            berm = math.exp(-((dist - plaza_r * 1.15) ** 2) / (2 * 10.0**2))
            h += berm * 0.12

            # Keep in range
            img[y][x] = max(-1.0, min(1.0, h + (nx * 0.02)))
    return img


def _png_rgba_float_as_rf(heights: list[list[float]], path: Path) -> None:
    """Write 16-bit grayscale PNG; TerrainWorld expands to RF heights."""
    # Encode height [-1,1] → u16 [0,65535]
    raw = bytearray()
    for y in range(SIZE):
        raw.append(0)  # filter none
        for x in range(SIZE):
            v = int(round((heights[y][x] * 0.5 + 0.5) * 65535.0))
            v = max(0, min(65535, v))
            raw.append((v >> 8) & 0xFF)
            raw.append(v & 0xFF)

    def chunk(tag: bytes, data: bytes) -> bytes:
        return (
            struct.pack(">I", len(data))
            + tag
            + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        )

    ihdr = struct.pack(">IIBBBBB", SIZE, SIZE, 16, 0, 0, 0, 0)  # 16-bit gray
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", ihdr)
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    path.write_bytes(png)


HERO_SEEDS = [
    "periliminal",
    "liminal",
    "supraliminal",
    "dallas",
    "fort_worth",
    "arlington",
    "denton",
]


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for key in HERO_SEEDS:
        heights = sculpt(key)
        out = OUT / f"{key}.png"
        _png_rgba_float_as_rf(heights, out)
        print(f"wrote {out.relative_to(ROOT)} ({out.stat().st_size} bytes)")
    readme = OUT / "README.md"
    readme.write_text(
        "# Hero heightfields (owner-trial kickoff)\n\n"
        "Authored (script-sculpted) maps for Terrain3D import. Prefer these\n"
        "over pure runtime noise so hub regions read as intentional landforms.\n\n"
        "Rebake: `python3 scripts/bake_hero_heightfields.py`\n\n"
        "Local GPU next step: open Terrain3D editor plugin, load a map, hand-sculpt\n"
        "creeks / plazas, then overwrite the matching PNG / `.res` here.\n",
        encoding="utf-8",
    )
    print(f"wrote {readme.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
