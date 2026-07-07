extends Node
## Autoloaded as "WordOfMouth". The personalized-NPC layer over Hope's
## database: how you treat the world's people comes back to you — but as
## WORD OF MOUTH, not a hive mind. Each interaction (kind, cruel,
## flirtatious, a marriage proposal) is remembered by that specific NPC
## immediately, and RUMORS about you spread outward gradually: every NPC
## has their own fixed gossip threshold (hash-seeded, so the same NPC is
## always equally plugged-in), and only starts treating you differently
## once enough has happened for the talk to plausibly reach them.
##
## Everything recorded here also flows into Hope.record — so Knoll knows,
## and the Periliminal reads it when it sets your difficulty.

const SAVE_PATH := "user://word_of_mouth.json"
const TONES := ["nice", "mean", "flirt", "marry"]

signal reputation_changed(tone: String, total: int)

## Global tallies — the "talk of the town" about you.
var _tones := {"nice": 0, "mean": 0, "flirt": 0, "marry": 0}
## Per-NPC firsthand memory: npc_id -> {tone -> count}.
var _met: Dictionary = {}

func _ready() -> void:
	_load()

func record_interaction(npc_id: String, tone: String) -> void:
	if tone not in TONES:
		return
	_tones[tone] = int(_tones.get(tone, 0)) + 1
	if not _met.has(npc_id):
		_met[npc_id] = {}
	_met[npc_id][tone] = int(_met[npc_id].get(tone, 0)) + 1
	_save()
	Hope.record("npc_interaction", {"npc": npc_id, "tone": tone})
	reputation_changed.emit(tone, total())

func total() -> int:
	var t := 0
	for v in _tones.values():
		t += int(v)
	return t

## What the town mostly says about you — "" until anything has happened.
func dominant_tone() -> String:
	var best := ""
	var best_n := 0
	for k in TONES:
		if int(_tones[k]) > best_n:
			best_n = int(_tones[k])
			best = k
	return best

## Share of your reputation that is cruelty — the Periliminal reads this.
func mean_ratio() -> float:
	return float(_tones.get("mean", 0)) / maxf(float(total()), 1.0)

func times(npc_id: String, tone: String) -> int:
	return int(_met.get(npc_id, {}).get(tone, 0))

func has_met(npc_id: String) -> bool:
	return _met.has(npc_id)

## Gossip travels at its own pace: this NPC has heard of you only once
## your total footprint clears THEIR personal threshold. Deterministic per
## npc_id — some people hear everything early, some are the last to know.
func has_heard(npc_id: String) -> bool:
	if has_met(npc_id):
		return true
	var threshold := 4 + absi(hash(npc_id)) % 24
	return total() >= threshold

## The line an NPC opens with once they know you — firsthand memory first,
## rumor second, silence if the talk hasn't reached them yet.
func greeting_line(npc_id: String) -> String:
	if has_met(npc_id):
		var mine: Dictionary = _met[npc_id]
		var best := ""
		var best_n := 0
		for k in TONES:
			if int(mine.get(k, 0)) > best_n:
				best_n = int(mine.get(k, 0))
				best = k
		match best:
			"nice": return "Good to see you again. You were kind to me — people don't forget that."
			"mean": return "...You. I remember exactly how you spoke to me last time."
			"flirt": return "Oh — it's you again. *straightens up a little*"
			"marry": return "You know my answer hasn't changed since you asked. But you keep asking."
		return ""
	if not has_heard(npc_id):
		return ""
	match dominant_tone():
		"nice": return "Wait — I've heard about you. They say you're one of the decent ones."
		"mean": return "I know who you are. Word travels. Watch your tone in here."
		"flirt": return "Ha — so YOU'RE the one everybody keeps gossiping about."
		"marry": return "You're the one going around proposing to people. The whole district talks about it."
	return ""

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"tones": _tones, "met": _met}))

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		var t = d.get("tones", {})
		if t is Dictionary:
			for k in TONES:
				_tones[k] = int(t.get(k, 0))
		var m = d.get("met", {})
		if m is Dictionary:
			_met = m
