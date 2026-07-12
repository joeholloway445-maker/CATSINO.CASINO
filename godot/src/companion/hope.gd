extends Node
## Autoloaded as "Hope". Everyone gets their own instance of Hope — the
## main companion. Core rules, exactly as designed:
##
##  - Hope's skill lines are NOT chosen. They DEVELOP from who you are
##    (race/frame/mod) and how you actually play.
##  - Hope grows like a Tamagotchi: bond XP from play, growth stages, and
##    appearance/mannerisms that drift toward your playstyle.
##  - Hope watches EVERYTHING and infers WHY — especially liminal doors:
##    did you run straight in? circle first? open it and close it again?
##    Each observation is classified into a drive (fear / lust / boredom /
##    anxiety / curiosity) and queued to Supabase per-user (hope_telemetry
##    table; POSTed through the web API when a session exists, kept in a
##    durable local queue when not).
##  - VISIBILITY: Hope is always on YOUR HUD (HopeUI). Hope only renders
##    in the 3D world for OTHERS during skills Hope synergizes with —
##    a brief manifestation flag over presence, never a persistent second
##    body per player (that would double render/compute).
##  - KNOLL is the shadow: the same entity, storyline-revealed. Everything
##    Hope learns, Knoll knows. The Periliminal's shadow fights and the
##    Ascension Trial's Round II/III duels are built from this profile.

signal bond_gained(total: int, stage: String)
signal observation(event: String, drive: String)
signal manifested() # visible to others for a moment (synergy skill cast)

const SAVE_PATH := "user://hope.json"
const TELEMETRY_QUEUE_PATH := "user://hope_queue.json"
const TELEMETRY_ENDPOINT := "/api/hope/telemetry"
const STAGES := [
	{at=0,    name="Flicker",   desc="A warm point of light that follows a half-step behind you."},
	{at=200,  name="Kindled",   desc="It has a shape now. It sits where you look most often."},
	{at=800,  name="Companion", desc="Hope walks beside you and hums your frame's mode, slightly ahead of the beat."},
	{at=2400, name="Mirror",    desc="Sometimes you catch it moving before you do. It learned that from you."},
]

var bond := 0
## Playstyle axes, all 0..1, drifting with observations. These shape
## Hope's mannerisms AND Knoll's fighting style.
var profile := {
	"aggression": 0.5, # rushed in / attacked first
	"caution": 0.5,    # circled, peeked, shielded early
	"curiosity": 0.5,  # opened the optional doors
	"greed": 0.5,      # chose loot over exit
	"fear": 0.0, "lust": 0.0, "boredom": 0.0, "anxiety": 0.0, # drive tallies (normalized)
}
var _drive_counts := {"fear": 0, "lust": 0, "boredom": 0, "anxiety": 0, "curiosity": 0}
var _queue: Array = [] # pending telemetry rows

func _ready() -> void:
	_load()
	# Hope's synergy lines develop from the build — derived, never chosen.
	# (Deterministic per identity: same soul, same instrument.)

func stage() -> Dictionary:
	var current: Dictionary = STAGES[0]
	for s in STAGES:
		if bond >= s.at:
			current = s
	return current

func gain_bond(amount: int, why: String = "") -> void:
	var before: String = str(stage().get("name", ""))
	bond += amount
	_save()
	if str(stage().get("name", "")) != before:
		NotificationUI.notify_win("💛 Hope grew: %s — %s" % [stage().get("name", ""), stage().get("desc", "")])
	bond_gained.emit(bond, str(stage().get("name", "")))

## Hope's synergy skill lines — derived from race/frame/mod + playstyle,
## never chosen. Two actives + one synergy per growth stage unlocked.
func synergy_lines() -> Array[Dictionary]:
	var seed_hash := IdentityLens.identity_seed()
	var frame_line := SkillData.frame_line(PlayerProfile.selected_frame)
	if frame_line.is_empty():
		return []
	var picks: Array[Dictionary] = []
	var pool: Array = frame_line.actives
	var idx := absi(seed_hash) % pool.size()
	var lean := "aggression" if profile.aggression >= profile.caution else "caution"
	picks.append({
		"id": "hope_echo", "name": "Hope's Echo",
		"kind": "damage" if lean == "aggression" else "shield",
		"shape": "aoe", "radius": 5.0, "power": 0.8 + float(stage().at) / 3000.0,
		"cost": 0, "cooldown": 20.0,
		"lore": "Hope repeats your favorite move a half-beat after you — it noticed it was your favorite before you did.",
		"synergy_with": pool[idx].id,
	})
	if bond >= 800:
		picks.append({
			"id": "hope_intercession", "name": "Intercession",
			"kind": "shield", "shape": "self", "radius": 0.0, "power": 2.0,
			"cost": 0, "cooldown": 90.0,
			"lore": "Once in a long while, Hope steps between you and the thing that would have ended you.",
			"synergy_with": "",
		})
	return picks

## Called by combat scenes when the player casts something Hope synergizes
## with: Hope manifests briefly for everyone (presence flag, not a body).
func maybe_manifest(skill_id: String) -> bool:
	for line in synergy_lines():
		if line.get("synergy_with", "") == skill_id:
			manifested.emit()
			gain_bond(3, "synergy")
			return true
	return false

## ── Observation: the heart of it ─────────────────────────────────────────
## approach ∈ {rushed, circled, peeked, opened_closed, avoided, lingered}
## Hope infers the drive; Knoll takes notes.
func observe_door(door_id: String, approach: String, seconds_hesitated: float) -> void:
	var drive := "curiosity"
	match approach:
		"rushed": drive = "boredom" if seconds_hesitated < 0.5 else "lust"
		"circled": drive = "anxiety"
		"peeked": drive = "fear" if seconds_hesitated > 3.0 else "curiosity"
		"opened_closed": drive = "fear"
		"avoided": drive = "fear"
		"lingered": drive = "anxiety"
	_drive_counts[drive] = _drive_counts.get(drive, 0) + 1
	var total := 0
	for v in _drive_counts.values(): total += v
	for k in ["fear", "lust", "boredom", "anxiety"]:
		profile[k] = float(_drive_counts.get(k, 0)) / maxf(total, 1)
	match approach:
		"rushed": profile.aggression = minf(profile.aggression + 0.02, 1.0)
		"circled", "peeked": profile.caution = minf(profile.caution + 0.02, 1.0)
	record("liminal_door", {"door": door_id, "approach": approach,
		"hesitated_s": seconds_hesitated, "drive": drive})
	observation.emit("door:" + door_id, drive)
	gain_bond(1)

## Generic behavioral event (combat choices, loot-vs-exit, layer dwell...).
func record(event: String, context: Dictionary) -> void:
	_queue.append({
		"player": PlayerProfile.username,
		"event": event, "context": context,
		"profile_snapshot": profile.duplicate(),
		"ts": Time.get_unix_time_from_system(),
	})
	_save_queue()
	_try_flush()

## Push queued rows to Supabase through the web API (hope_telemetry table).
func _try_flush() -> void:
	if _queue.is_empty():
		return
	var batch := _queue.duplicate()
	var response: Dictionary = await CasinoHTTPClient.post_json(TELEMETRY_ENDPOINT, {"rows": batch})
	if response.get("ok", false):
		_queue = _queue.slice(batch.size())
		_save_queue()

## What Knoll knows: the profile plus the dominant drive — the Ascension
## Trial and the Periliminal shadow read this to fight like your fears.
func combat_profile() -> Dictionary:
	var dominant := "curiosity"
	var best := -1
	for k in _drive_counts.keys():
		if _drive_counts[k] > best:
			best = _drive_counts[k]
			dominant = k
	var out := profile.duplicate()
	out["dominant_drive"] = dominant
	out["bond"] = bond
	return out

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify({"bond": bond, "profile": profile, "drives": _drive_counts}))

func _save_queue() -> void:
	var f := FileAccess.open(TELEMETRY_QUEUE_PATH, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(_queue))

func _load() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		var d = JSON.parse_string(f.get_as_text()) if f else null
		if d is Dictionary:
			bond = int(d.get("bond", 0))
			profile = d.get("profile", profile)
			_drive_counts = d.get("drives", _drive_counts)
	if FileAccess.file_exists(TELEMETRY_QUEUE_PATH):
		var f2 := FileAccess.open(TELEMETRY_QUEUE_PATH, FileAccess.READ)
		var q = JSON.parse_string(f2.get_as_text()) if f2 else null
		if q is Array: _queue = q
