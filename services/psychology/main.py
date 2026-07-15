"""
LangGraph psychology profiling service for Periliminal.Space.

Reads hope_telemetry rows from Supabase every POLL_INTERVAL seconds,
runs a per-player LangGraph state machine across three axes
(courage / curiosity / composure), and upserts the result into
psychology_profiles.

State machine summary
---------------------
  ingest  → classify  → update_axes  → detect_anomaly  → write_profile
               ↑_____________________________________|  (loop back if anomaly)

Axis scoring (all axes bounded [0.0, 1.0]):
  courage    — door approach speed, willingness to enter PvP zones
  curiosity  — rate of new chunk discovery, liminal wandering frequency
  composure  — stability of dwell times, low variance in approach speed

Anomaly rules (written to the `player_anomalies` table — not the world
entity registry named `anomalies`):
  - courage  > 0.85  AND recent_pvp_kills > 3    → "apex_aggressor"
  - curiosity > 0.9  AND liminal_entries > 10     → "lost_wanderer"
  - composure < 0.15 AND rapid_door_flips > 5    → "spiraling"

hope_telemetry columns (migration 031): event, context jsonb, drive, ...
Approach lives in context.approach (legacy event_type/approach still accepted).
"""

from __future__ import annotations

import os
import time
import math
import logging
from typing import TypedDict, Optional, List

from dotenv import load_dotenv
from supabase import create_client, Client
from langgraph.graph import StateGraph, END

load_dotenv()

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("psychology")

SUPABASE_URL: str = os.environ["SUPABASE_URL"]
SUPABASE_KEY: str = os.environ["SUPABASE_SERVICE_KEY"]  # service role, bypasses RLS
POLL_INTERVAL: int = int(os.getenv("POLL_INTERVAL", "60"))

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)


# ---------------------------------------------------------------------------
# LangGraph state
# ---------------------------------------------------------------------------

class PsychState(TypedDict):
    player_id: str
    # raw telemetry rows for this player (fetched in `ingest`)
    rows: List[dict]
    # derived counts
    door_count: int
    rushed_count: int
    lingered_count: int
    peeked_count: int
    avoided_count: int
    pvp_kills: int
    liminal_entries: int
    chunk_discoveries: int
    rapid_door_flips: int
    # axis deltas this cycle (bounded [-0.5, 0.5])
    courage_delta: float
    curiosity_delta: float
    composure_delta: float
    # persisted axes loaded from psychology_profiles (start at 0.5)
    courage: float
    curiosity: float
    composure: float
    # anomaly detected this cycle (or None)
    anomaly: Optional[str]
    # friendly summary written to the profile
    dominant_drive: str


# ---------------------------------------------------------------------------
# Node helpers
# ---------------------------------------------------------------------------

def _clamp(v: float, lo: float = 0.0, hi: float = 1.0) -> float:
    return max(lo, min(hi, v))


def _sigmoid_nudge(current: float, signal: float, strength: float = 0.08) -> float:
    """Nudge `current` toward `signal` by `strength`, keeping it in [0,1]."""
    return _clamp(current + (signal - current) * strength)


DRIVE_LABELS = {
    "fear":      "fear",
    "lust":      "lust",
    "boredom":   "boredom",
    "anxiety":   "anxiety",
    "curiosity": "curiosity",
}


def _dominant_drive(rows: List[dict]) -> str:
    counts: dict[str, int] = {}
    for r in rows:
        context = r.get("context") or {}
        data = r.get("data") or {}
        if not isinstance(context, dict):
            context = {}
        if not isinstance(data, dict):
            data = {}
        d = r.get("drive") or context.get("drive") or data.get("drive", "")
        if d in DRIVE_LABELS:
            counts[d] = counts.get(d, 0) + 1
    if not counts:
        return "unknown"
    return max(counts, key=lambda k: counts[k])


# ---------------------------------------------------------------------------
# LangGraph nodes
# ---------------------------------------------------------------------------

def ingest(state: PsychState) -> PsychState:
    """Load the current psychology_profile axes so we update incrementally."""
    pid = state["player_id"]
    resp = (
        supabase.table("psychology_profiles")
        .select("courage, curiosity, composure")
        .eq("player_id", pid)
        .maybe_single()
        .execute()
    )
    profile = resp.data or {}
    state["courage"] = float(profile.get("courage", 0.5))
    state["curiosity"] = float(profile.get("curiosity", 0.5))
    state["composure"] = float(profile.get("composure", 0.5))
    return state


def classify(state: PsychState) -> PsychState:
    """Count event types from raw telemetry rows.

    Canonical schema (031_hope_telemetry): columns `event` + `context` jsonb.
    Legacy keys `event_type` / top-level `approach` / `data` are still accepted.
    """
    rows = state["rows"]
    door_count = rushed = lingered = peeked = avoided = 0
    pvp_kills = liminal_entries = chunk_disc = rapid_flips = 0

    prev_approach: Optional[str] = None
    flip_streak = 0

    for r in rows:
        ev = r.get("event") or r.get("event_type") or ""
        context = r.get("context") or {}
        data = r.get("data") or {}
        if not isinstance(context, dict):
            context = {}
        if not isinstance(data, dict):
            data = {}

        if ev in ("door_approach", "liminal_door", "door"):
            door_count += 1
            approach = (
                context.get("approach")
                or r.get("approach")
                or data.get("approach")
                or ""
            )
            if approach == "rushed":
                rushed += 1
            elif approach == "lingered":
                lingered += 1
            elif approach == "peeked":
                peeked += 1
            # rapid flip: alternating rushed/lingered
            if prev_approach and approach != prev_approach and approach in ("rushed", "lingered"):
                flip_streak += 1
                if flip_streak >= 2:
                    rapid_flips += 1
            else:
                flip_streak = 0
            prev_approach = approach

        elif ev in ("door_avoided", "avoided"):
            avoided += 1

        elif ev == "pvp_kill":
            pvp_kills += 1

        elif ev in ("visit_liminal", "liminal_entry"):
            liminal_entries += 1

        elif ev in ("discover_chunk", "chunk_discovery"):
            chunk_disc += 1

        elif ev == "chat":
            pass  # not used for axes yet

    state.update(
        door_count=door_count,
        rushed_count=rushed,
        lingered_count=lingered,
        peeked_count=peeked,
        avoided_count=avoided,
        pvp_kills=pvp_kills,
        liminal_entries=liminal_entries,
        chunk_discoveries=chunk_disc,
        rapid_door_flips=rapid_flips,
    )
    state["dominant_drive"] = _dominant_drive(rows)
    return state


def update_axes(state: PsychState) -> PsychState:
    """Compute per-cycle deltas and nudge the stored axes."""
    total_doors = max(state["door_count"], 1)

    # -- courage --
    # High rushed ratio + pvp activity → courage up
    rush_ratio = state["rushed_count"] / total_doors
    avoid_ratio = state["avoided_count"] / max(total_doors + state["avoided_count"], 1)
    courage_signal = _clamp(rush_ratio * 0.6 + (state["pvp_kills"] / max(state["pvp_kills"] + 1, 1)) * 0.4 - avoid_ratio * 0.5)
    state["courage"] = _sigmoid_nudge(state["courage"], courage_signal)

    # -- curiosity --
    # Liminal wandering + new chunk discovery → curiosity up
    linger_ratio = state["lingered_count"] / total_doors
    disc_signal = _clamp(math.tanh(state["chunk_discoveries"] / 5.0))
    lim_signal = _clamp(math.tanh(state["liminal_entries"] / 3.0))
    curiosity_signal = _clamp(linger_ratio * 0.3 + disc_signal * 0.4 + lim_signal * 0.3)
    state["curiosity"] = _sigmoid_nudge(state["curiosity"], curiosity_signal)

    # -- composure --
    # Low flip count, consistent approach type → composure up
    flip_pressure = _clamp(state["rapid_door_flips"] / max(total_doors, 1))
    peek_ratio = state["peeked_count"] / total_doors
    composure_signal = _clamp(peek_ratio * 0.5 + (1.0 - flip_pressure) * 0.5)
    state["composure"] = _sigmoid_nudge(state["composure"], composure_signal)

    return state


def detect_anomaly(state: PsychState) -> PsychState:
    state["anomaly"] = None

    if state["courage"] > 0.85 and state["pvp_kills"] > 3:
        state["anomaly"] = "apex_aggressor"
    elif state["curiosity"] > 0.9 and state["liminal_entries"] > 10:
        state["anomaly"] = "lost_wanderer"
    elif state["composure"] < 0.15 and state["rapid_door_flips"] > 5:
        state["anomaly"] = "spiraling"

    return state


def write_profile(state: PsychState) -> PsychState:
    """Upsert psychology_profiles and, if anomalous, insert into player_anomalies."""
    pid = state["player_id"]

    profile_row = {
        "player_id": pid,
        "courage": round(state["courage"], 4),
        "curiosity": round(state["curiosity"], 4),
        "composure": round(state["composure"], 4),
        "dominant_drive": state["dominant_drive"],
    }
    supabase.table("psychology_profiles").upsert(profile_row, on_conflict="player_id").execute()

    if state["anomaly"]:
        anomaly_row = {
            "player_id": pid,
            "anomaly_type": state["anomaly"],
            "courage": round(state["courage"], 4),
            "curiosity": round(state["curiosity"], 4),
            "composure": round(state["composure"], 4),
        }
        # World table `anomalies` is the entity registry — player events go here.
        supabase.table("player_anomalies").insert(anomaly_row).execute()
        log.info("anomaly %s → player %s", state["anomaly"], pid)

    log.info(
        "profile %s courage=%.3f curiosity=%.3f composure=%.3f drive=%s",
        pid, state["courage"], state["curiosity"], state["composure"], state["dominant_drive"],
    )
    return state


# ---------------------------------------------------------------------------
# Build LangGraph
# ---------------------------------------------------------------------------

def _build_graph() -> StateGraph:
    g = StateGraph(PsychState)
    g.add_node("ingest", ingest)
    g.add_node("classify", classify)
    g.add_node("update_axes", update_axes)
    g.add_node("detect_anomaly", detect_anomaly)
    g.add_node("write_profile", write_profile)

    g.set_entry_point("ingest")
    g.add_edge("ingest", "classify")
    g.add_edge("classify", "update_axes")
    g.add_edge("update_axes", "detect_anomaly")
    g.add_edge("detect_anomaly", "write_profile")
    g.add_edge("write_profile", END)
    return g.compile()


GRAPH = _build_graph()


# ---------------------------------------------------------------------------
# Polling loop
# ---------------------------------------------------------------------------

# We track the max processed_at so we only pull genuinely new rows each cycle.
_watermark: str = "1970-01-01T00:00:00+00:00"


def _fetch_new_rows() -> dict[str, list[dict]]:
    """Return {player_id: [rows]} for all hope_telemetry rows after _watermark."""
    global _watermark
    resp = (
        supabase.table("hope_telemetry")
        .select("*")
        .gt("created_at", _watermark)
        .order("created_at", desc=False)
        .limit(2000)
        .execute()
    )
    rows = resp.data or []
    if rows:
        _watermark = rows[-1]["created_at"]

    by_player: dict[str, list[dict]] = {}
    for r in rows:
        pid = r.get("player_id", "")
        if not pid:
            continue
        by_player.setdefault(pid, []).append(r)
    return by_player


def run_cycle() -> None:
    by_player = _fetch_new_rows()
    if not by_player:
        log.debug("no new telemetry")
        return

    log.info("processing %d players", len(by_player))
    for pid, rows in by_player.items():
        initial: PsychState = {
            "player_id": pid,
            "rows": rows,
            "door_count": 0,
            "rushed_count": 0,
            "lingered_count": 0,
            "peeked_count": 0,
            "avoided_count": 0,
            "pvp_kills": 0,
            "liminal_entries": 0,
            "chunk_discoveries": 0,
            "rapid_door_flips": 0,
            "courage_delta": 0.0,
            "curiosity_delta": 0.0,
            "composure_delta": 0.0,
            "courage": 0.5,
            "curiosity": 0.5,
            "composure": 0.5,
            "anomaly": None,
            "dominant_drive": "unknown",
        }
        try:
            GRAPH.invoke(initial)
        except Exception as exc:
            log.error("graph error for %s: %s", pid, exc)


def main() -> None:
    log.info("psychology service started — poll every %ds", POLL_INTERVAL)
    while True:
        try:
            run_cycle()
        except Exception as exc:
            log.error("cycle error: %s", exc)
        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    main()
