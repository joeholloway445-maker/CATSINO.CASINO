#!/usr/bin/env python3
"""Fetch real downtown street/building geometry for Periliminal DFW hubs.

Queries the public Overpass API (OpenStreetMap), projects lat/lon to local
XZ meters, uniformly rescales each hub to fit the in-game city footprint,
and writes compact JSON that MegaCityBuilder / OsmCityLayout can load.

Usage:
  python3 scripts/fetch_osm_cities.py
  python3 scripts/fetch_osm_cities.py --hub dallas

Requires network access to overpass-api.de (or OVERPASS_URL).
Attribution: © OpenStreetMap contributors (ODbL).
"""

from __future__ import annotations

import argparse
import json
import math
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "godot" / "world_data" / "osm"
OVERPASS_URL = os.environ.get(
    "OVERPASS_URL", "https://overpass-api.de/api/interpreter"
)

# Target in-game city span (meters). Hub chunks are 384–512 units; keep the
# downtown core comfortably inside that without hub-to-hub travel becoming
# real-world duration. Matches docs/DFW_METROPLEX_MAP.md compression intent.
TARGET_SPAN = 280.0

# Downtown cores — tight boxes around the recognizable centers called out
# in docs/DFW_METROPLEX_MAP.md (Arts District, Sundance Square, stadium
# district, courthouse square). south,west,north,east (Overpass bbox order).
HUBS = {
    "dallas": {
        "name": "New Dallas",
        "real_world": "Dallas",
        "bbox": (32.7750, -96.8120, 32.7920, -96.7900),
        "landmark_queries": [
            "Reunion Tower",
            "Bank of America Plaza",
            "Margaret Hunt Hill Bridge",
        ],
    },
    "fort_worth": {
        "name": "Hell's Half Acre",
        "real_world": "Fort Worth",
        "bbox": (32.7480, -97.3350, 32.7600, -97.3200),
        "landmark_queries": [
            "Tarrant County Courthouse",
            "Fort Worth Stockyards",
            "Sundance Square",
        ],
    },
    "arlington": {
        "name": "Soulless Sanctuary",
        "real_world": "Arlington",
        "bbox": (32.7400, -97.1000, 32.7600, -97.0700),
        "landmark_queries": [
            "AT&T Stadium",
            "Globe Life Field",
            "University of Texas at Arlington",
            "Choctaw Stadium",
        ],
    },
    "denton": {
        "name": "Sky Fjord",
        "real_world": "Denton",
        "bbox": (33.2100, -97.1400, 33.2200, -97.1250),
        "landmark_queries": [
            "Denton County Courthouse",
            "Courthouse-on-the-Square",
            "University of North Texas",
        ],
    },
}

STREET_HIGHWAYS = {
    "motorway",
    "trunk",
    "primary",
    "secondary",
    "tertiary",
    "unclassified",
    "residential",
    "living_street",
    "service",
    "motorway_link",
    "trunk_link",
    "primary_link",
    "secondary_link",
    "tertiary_link",
}

WIDTH_CLASS = {
    "motorway": 3,
    "trunk": 3,
    "primary": 2,
    "secondary": 2,
    "tertiary": 1,
    "unclassified": 1,
    "residential": 1,
    "living_street": 1,
    "service": 0,
    "motorway_link": 2,
    "trunk_link": 2,
    "primary_link": 2,
    "secondary_link": 1,
    "tertiary_link": 1,
}


def overpass_query(bbox: tuple[float, float, float, float]) -> str:
    s, w, n, e = bbox
    return f"""
[out:json][timeout:90];
(
  way["highway"]({s},{w},{n},{e});
  way["building"]({s},{w},{n},{e});
  node["name"]["tourism"]({s},{w},{n},{e});
  node["name"]["amenity"]({s},{w},{n},{e});
  node["name"]["leisure"]({s},{w},{n},{e});
  way["name"]["tourism"]({s},{w},{n},{e});
  way["name"]["amenity"]({s},{w},{n},{e});
  way["name"]["leisure"]({s},{w},{n},{e});
  way["name"]["building"]({s},{w},{n},{e});
);
out body;
>;
out skel qt;
"""


def http_post(url: str, body: str, retries: int = 4) -> dict:
    form = urllib.parse.urlencode({"data": body}).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=form,
        headers={
            "Content-Type": "application/x-www-form-urlencoded",
            "User-Agent": "PeriliminalSpace-OSMCityFetch/1.0 (game map import)",
        },
        method="POST",
    )
    delay = 4.0
    last_err: Exception | None = None
    for attempt in range(retries):
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError) as err:
            last_err = err
            print(
                f"  Overpass attempt {attempt + 1}/{retries} failed: {err}",
                file=sys.stderr,
            )
            time.sleep(delay)
            delay *= 2
    raise RuntimeError(f"Overpass fetch failed after {retries} tries: {last_err}")


def project_lonlat(
    lon: float, lat: float, origin_lon: float, origin_lat: float
) -> tuple[float, float]:
    """Equirectangular meters relative to bbox center (fine at city scale)."""
    m_per_deg_lat = 111_320.0
    m_per_deg_lon = 111_320.0 * math.cos(math.radians(origin_lat))
    x = (lon - origin_lon) * m_per_deg_lon
    z = -(lat - origin_lat) * m_per_deg_lat  # +Z south so north is -Z
    return x, z


def simplify_polyline(
    pts: list[tuple[float, float]], min_dist: float = 4.0
) -> list[tuple[float, float]]:
    if len(pts) <= 2:
        return pts
    out = [pts[0]]
    for p in pts[1:-1]:
        ox, oz = out[-1]
        if (p[0] - ox) ** 2 + (p[1] - oz) ** 2 >= min_dist * min_dist:
            out.append(p)
    out.append(pts[-1])
    return out


def poly_area(pts: list[tuple[float, float]]) -> float:
    if len(pts) < 3:
        return 0.0
    a = 0.0
    for i in range(len(pts) - 1):
        x1, z1 = pts[i]
        x2, z2 = pts[i + 1]
        a += x1 * z2 - x2 * z1
    return abs(a) * 0.5


def poly_centroid(pts: list[tuple[float, float]]) -> tuple[float, float]:
    if not pts:
        return 0.0, 0.0
    ring = pts[:-1] if len(pts) > 1 and pts[0] == pts[-1] else pts
    if len(ring) < 3:
        xs = [p[0] for p in ring]
        zs = [p[1] for p in ring]
        return sum(xs) / len(xs), sum(zs) / len(zs)
    a = 0.0
    cx = 0.0
    cz = 0.0
    for i in range(len(ring)):
        x1, z1 = ring[i]
        x2, z2 = ring[(i + 1) % len(ring)]
        cross = x1 * z2 - x2 * z1
        a += cross
        cx += (x1 + x2) * cross
        cz += (z1 + z2) * cross
    if abs(a) < 1e-9:
        xs = [p[0] for p in ring]
        zs = [p[1] for p in ring]
        return sum(xs) / len(xs), sum(zs) / len(zs)
    a *= 0.5
    return cx / (6.0 * a), cz / (6.0 * a)


def bbox_of(pts: list[tuple[float, float]]) -> tuple[float, float, float, float]:
    xs = [p[0] for p in pts]
    zs = [p[1] for p in pts]
    return min(xs), min(zs), max(xs), max(zs)


def fetch_hub(hub_id: str, meta: dict) -> dict:
    bbox = meta["bbox"]
    print(f"Fetching {hub_id} ({meta['real_world']}) bbox={bbox} …")
    raw = http_post(OVERPASS_URL, overpass_query(bbox))
    elements = raw.get("elements", [])
    nodes: dict[int, tuple[float, float]] = {}
    ways: list[dict] = []
    for el in elements:
        if el.get("type") == "node" and "lat" in el and "lon" in el:
            nodes[el["id"]] = (el["lon"], el["lat"])
        elif el.get("type") == "way":
            ways.append(el)

    s, w, n, e = bbox
    origin_lat = (s + n) * 0.5
    origin_lon = (w + e) * 0.5

    streets: list[dict] = []
    buildings: list[dict] = []
    pois: list[dict] = []

    for el in elements:
        if el.get("type") != "node":
            continue
        tags = el.get("tags") or {}
        name = tags.get("name")
        if not name or "lat" not in el:
            continue
        x, z = project_lonlat(el["lon"], el["lat"], origin_lon, origin_lat)
        pois.append(
            {
                "name": name,
                "kind": tags.get("tourism")
                or tags.get("amenity")
                or tags.get("leisure")
                or "poi",
                "x": x,
                "z": z,
            }
        )

    for way in ways:
        tags = way.get("tags") or {}
        nds = way.get("nodes") or []
        pts_ll = [nodes[i] for i in nds if i in nodes]
        if len(pts_ll) < 2:
            continue
        pts = [project_lonlat(lon, lat, origin_lon, origin_lat) for lon, lat in pts_ll]
        highway = tags.get("highway")
        if highway in STREET_HIGHWAYS:
            pts = simplify_polyline(pts, min_dist=6.0)
            if len(pts) < 2:
                continue
            streets.append(
                {
                    "name": tags.get("name", ""),
                    "highway": highway,
                    "width_class": WIDTH_CLASS.get(highway, 1),
                    "points": [[round(x, 2), round(z, 2)] for x, z in pts],
                }
            )
            continue
        if "building" in tags:
            if pts[0] != pts[-1]:
                pts = pts + [pts[0]]
            if poly_area(pts) < 40.0:
                continue
            if len(pts) > 24:
                step = max(1, len(pts) // 20)
                pts = pts[::step]
                if pts[0] != pts[-1]:
                    pts.append(pts[0])
            cx, cz = poly_centroid(pts)
            minx, minz, maxx, maxz = bbox_of(pts)
            levels = tags.get("building:levels") or tags.get("levels")
            try:
                floors = int(float(levels)) if levels else 0
            except ValueError:
                floors = 0
            height = tags.get("height")
            try:
                height_m = float(str(height).replace("m", "").strip()) if height else 0.0
            except ValueError:
                height_m = 0.0
            buildings.append(
                {
                    "name": tags.get("name", ""),
                    "building": tags.get("building", "yes"),
                    "floors": floors,
                    "height_m": round(height_m, 1),
                    "cx": round(cx, 2),
                    "cz": round(cz, 2),
                    "sx": round(max(maxx - minx, 4.0), 2),
                    "sz": round(max(maxz - minz, 4.0), 2),
                }
            )
            if tags.get("name"):
                pois.append(
                    {
                        "name": tags["name"],
                        "kind": tags.get("building", "building"),
                        "x": cx,
                        "z": cz,
                    }
                )

    all_pts: list[tuple[float, float]] = []
    for st in streets:
        all_pts.extend((p[0], p[1]) for p in st["points"])
    for b in buildings:
        all_pts.append((b["cx"], b["cz"]))
    if not all_pts:
        raise RuntimeError(f"No geometry for {hub_id}")

    minx = min(p[0] for p in all_pts)
    maxx = max(p[0] for p in all_pts)
    minz = min(p[1] for p in all_pts)
    maxz = max(p[1] for p in all_pts)
    span = max(maxx - minx, maxz - minz, 1.0)
    scale = TARGET_SPAN / span

    def xf(x: float, z: float) -> tuple[float, float]:
        return (x - minx) * scale, (z - minz) * scale

    for st in streets:
        st["points"] = [
            [round(a, 2), round(b, 2)]
            for a, b in (xf(p[0], p[1]) for p in st["points"])
        ]
    for b in buildings:
        nx, nz = xf(b["cx"], b["cz"])
        b["cx"], b["cz"] = round(nx, 2), round(nz, 2)
        b["sx"] = round(max(b["sx"] * scale, 3.0), 2)
        b["sz"] = round(max(b["sz"] * scale, 3.0), 2)
        if b["height_m"]:
            b["height_m"] = round(b["height_m"] * scale, 1)
    for p in pois:
        nx, nz = xf(p["x"], p["z"])
        p["x"], p["z"] = round(nx, 2), round(nz, 2)

    seen: set[str] = set()
    uniq_pois: list[dict] = []
    for p in pois:
        key = p["name"].strip().lower()
        if not key or key in seen:
            continue
        seen.add(key)
        uniq_pois.append(p)

    landmarks = []
    for q in meta.get("landmark_queries", []):
        qlow = q.lower()
        best = None
        for p in uniq_pois:
            if qlow in p["name"].lower() or p["name"].lower() in qlow:
                best = p
                break
        if best:
            landmarks.append(
                {
                    "query": q,
                    "name": best["name"],
                    "x": best["x"],
                    "z": best["z"],
                }
            )

    # Landmark id map: game LandmarkBuilder ids -> OSM name needles.
    LANDMARK_IDS = {
        "dallas": {
            "reunion_spire": ["reunion tower"],
            "emerald_slab": ["bank of america plaza"],
            "veil_arch": ["margaret hunt hill", "hunt hill bridge"],
        },
        "fort_worth": {
            "acre_clocktower": ["tarrant county courthouse"],
            "longhorn_gate": ["stockyards", "exchange avenue"],
        },
        "arlington": {
            "sanctuary_dome": ["dallas stadium", "at&t stadium", "cowboys stadium"],
            "star_bowl": ["globe life field", "globe life"],
            "college_hall": ["university of texas at arlington"],
            "space_station": ["esports stadium"],
        },
        "denton": {
            "fjord_dome": ["denton county courthouse", "courthouse-on-the-square"],
            "sky_tank": ["water tower", "water tank"],
        },
    }

    # Prefer named buildings when snapping landmarks (skip parking lots).
    id_landmarks = []
    named_features = []
    for b in buildings:
        if b.get("name"):
            named_features.append(
                {"name": b["name"], "x": b["cx"], "z": b["cz"], "kind": "building"}
            )
    named_features.extend(
        {"name": p["name"], "x": p["x"], "z": p["z"], "kind": p.get("kind", "poi")}
        for p in uniq_pois
    )
    for lid, needles in LANDMARK_IDS.get(hub_id, {}).items():
        best = None
        best_score = -1
        for feat in named_features:
            n = feat["name"].lower()
            for needle in needles:
                if needle in n:
                    score = len(needle) - (20 if "parking" in n else 0)
                    if score > best_score:
                        best_score = score
                        best = feat
        if best:
            id_landmarks.append(
                {
                    "id": lid,
                    "query": needles[0],
                    "name": best["name"],
                    "x": best["x"],
                    "z": best["z"],
                    "kind": best["kind"],
                }
            )
    # Keep legacy query-only snaps too, but prefer id-tagged list.
    landmarks = id_landmarks or landmarks

    # Keep landmark-named POIs even when capping the list.
    landmark_names = {l["name"].lower() for l in landmarks}
    priority = [p for p in uniq_pois if p["name"].lower() in landmark_names]
    rest = [p for p in uniq_pois if p["name"].lower() not in landmark_names]
    capped_pois = (priority + rest)[:80]

    buildings.sort(key=lambda b: b["sx"] * b["sz"], reverse=True)
    max_buildings = 220
    if len(buildings) > max_buildings:
        buildings = buildings[:max_buildings]

    streets.sort(key=lambda s: s["width_class"], reverse=True)
    max_streets = 180
    if len(streets) > max_streets:
        streets = streets[:max_streets]

    layout = {
        "hub_id": hub_id,
        "name": meta["name"],
        "real_world": meta["real_world"],
        "source": "OpenStreetMap via Overpass API",
        "attribution": "© OpenStreetMap contributors (ODbL)",
        "bbox_wgs84": {"south": s, "west": w, "north": n, "east": e},
        "origin_wgs84": {"lat": origin_lat, "lon": origin_lon},
        "scale": round(scale, 6),
        "span": TARGET_SPAN,
        "size": {
            "x": round((maxx - minx) * scale, 2),
            "z": round((maxz - minz) * scale, 2),
        },
        "streets": streets,
        "buildings": buildings,
        "pois": capped_pois,
        "landmarks": landmarks,
    }
    print(
        f"  → {len(streets)} streets, {len(buildings)} buildings, "
        f"{len(uniq_pois)} POIs, {len(landmarks)} landmark snaps "
        f"(scale={scale:.4f})"
    )
    return layout


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--hub",
        choices=sorted(HUBS.keys()) + ["all"],
        default="all",
        help="Which hub to fetch (default: all)",
    )
    args = parser.parse_args()
    hubs = list(HUBS.keys()) if args.hub == "all" else [args.hub]

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    index: dict = {
        "attribution": "© OpenStreetMap contributors (ODbL)",
        "source": "OpenStreetMap via Overpass API",
        "target_span": TARGET_SPAN,
        "hubs": {},
    }

    for i, hub_id in enumerate(hubs):
        if i:
            time.sleep(2.0)
        layout = fetch_hub(hub_id, HUBS[hub_id])
        out_path = OUT_DIR / f"{hub_id}.json"
        out_path.write_text(json.dumps(layout, separators=(",", ":")), encoding="utf-8")
        meta_path = OUT_DIR / f"{hub_id}.meta.json"
        meta_path.write_text(
            json.dumps(
                {
                    k: layout[k]
                    for k in (
                        "hub_id",
                        "name",
                        "real_world",
                        "source",
                        "attribution",
                        "bbox_wgs84",
                        "origin_wgs84",
                        "scale",
                        "span",
                        "size",
                        "landmarks",
                    )
                },
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )
        index["hubs"][hub_id] = {
            "file": f"{hub_id}.json",
            "real_world": layout["real_world"],
            "streets": len(layout["streets"]),
            "buildings": len(layout["buildings"]),
            "landmarks": layout["landmarks"],
        }
        print(f"  wrote {out_path.relative_to(ROOT)}")

    index_path = OUT_DIR / "index.json"
    index_path.write_text(json.dumps(index, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {index_path.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
