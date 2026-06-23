extends Node
## Selectable timelines for Creator mode. "replay" entries are past canon
## scenes; "forge" is the single open-ended starting point for building a
## brand-new scene from scratch (creator_original mode).

const TIMELINES: Array[Dictionary] = [
	{"id": "spire_first_contact", "name": "The Spire — First Contact", "mode": "replay",
		"description": "Replay the founding moment of supraliminal faction leadership."},
	{"id": "drift_collapse", "name": "The Drift — The Collapse", "mode": "replay",
		"description": "Replay the liminal layer's first major signal-noise collapse event."},
	{"id": "breach_opening", "name": "The Breach — Opening", "mode": "replay",
		"description": "Replay the hyperliminal layer's first reality-overflow incident."},
	{"id": "forge_new_scene", "name": "Forge a New Scene", "mode": "forge",
		"description": "Start from a blank sandbox and build a future scene from scratch."},
]

static func by_id(id: String) -> Dictionary:
	for t in TIMELINES:
		if t["id"] == id:
			return t
	return {}

static func by_mode(mode: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for t in TIMELINES:
		if t["mode"] == mode:
			result.append(t)
	return result
