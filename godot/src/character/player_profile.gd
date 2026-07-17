extends Node
# Persistent player data — level, XP, faction, frame, active companions

signal profile_updated()
signal level_up(new_level: int)

const SAVE_PATH = "user://profile.json"
const XP_PER_LEVEL_BASE = 500

var username: String = "CatPlayer"
var level: int = 1
var xp: int = 0
var faction: String = "Factionless"
var selected_race_id: String = "tabby"
var selected_frame: String = "veil"
## Second frame, chosen at Champion ascension (level 50+). Empty until then.
var ascended_frame: String = ""
var selected_mod: String = ""
## True once CharacterCreatorLogic.apply_creation has actually run — the
## title screen's "Continue Expedition" only lights up once this is true;
## a fresh install always starts at "Start New Venture" no matter what
## selected_race_id's default happens to be.
var has_expedition: bool = false
var active_companion_ids: Array[String] = []
var titles: Array[String] = []
var active_title: String = ""
var playtime_seconds: float = 0.0
## Soft state for TitleEffects / dialogue gates (not all persisted yet).
var _stat_modifiers: Dictionary = {}
var _unlocked_abilities: Array[String] = []

## Compat: first equipped companion id (quest/dialogue legacy field).
var selected_companion: String:
	get:
		return active_companion_ids[0] if not active_companion_ids.is_empty() and not active_companion_ids[0].is_empty() else ""

## Compat: race of the equipped companion if known, else player race.
var selected_companion_race: String:
	get:
		if selected_companion.is_empty():
			return ""
		var entry: Dictionary = CompanionRegistry.get_by_id(selected_companion)
		if not entry.is_empty():
			return str(entry.get("race", entry.get("species", selected_race_id)))
		return selected_race_id

var _session_start: float = 0.0

func _ready() -> void:
	_session_start = Time.get_unix_time_from_system()
	_load()

func _exit_tree() -> void:
	playtime_seconds += Time.get_unix_time_from_system() - _session_start
	_save()

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if not data is Dictionary: return
	username = data.get("username", username)
	level = data.get("level", 1)
	xp = data.get("xp", 0)
	faction = data.get("faction", "Factionless")
	selected_race_id = data.get("selected_race_id", "tabby")
	selected_frame = data.get("selected_frame", "veil")
	ascended_frame = data.get("ascended_frame", "")
	selected_mod = data.get("selected_mod", "")
	active_companion_ids = Array(data.get("active_companions", []), TYPE_STRING, "", null)
	titles = Array(data.get("titles", []), TYPE_STRING, "", null)
	active_title = data.get("active_title", "")
	# Migration: saves from before this flag existed still have a real
	# character if they've clearly played (leveled up, left the default
	# frame/mod, or picked up a companion) — don't lock returning players
	# out of "Continue Expedition" just because the flag predates them.
	has_expedition = bool(data.get("has_expedition",
		level > 1 or selected_frame != "veil" or selected_mod != "" or not active_companion_ids.is_empty()))
	playtime_seconds = float(data.get("playtime_seconds", 0))

func _save() -> void:
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({
		"username": username,
		"level": level,
		"xp": xp,
		"faction": faction,
		"selected_race_id": selected_race_id,
		"selected_frame": selected_frame,
		"ascended_frame": ascended_frame,
		"selected_mod": selected_mod,
		"has_expedition": has_expedition,
		"active_companions": active_companion_ids,
		"titles": titles,
		"active_title": active_title,
		"playtime_seconds": playtime_seconds,
	}))
	f.close()

func add_xp(amount: int) -> void:
	xp += amount
	var threshold = xp_for_level(level + 1)
	while xp >= threshold:
		level += 1
		level_up.emit(level)
		SkillManager.grant_points(1, "level %d" % level)
		threshold = xp_for_level(level + 1)
	_save()
	profile_updated.emit()

func xp_for_level(lv: int) -> int:
	return XP_PER_LEVEL_BASE * lv * lv

func xp_progress() -> float:
	var current_thresh = xp_for_level(level)
	var next_thresh = xp_for_level(level + 1)
	var span = next_thresh - current_thresh
	if span <= 0: return 1.0
	return clampf(float(xp - current_thresh) / float(span), 0.0, 1.0)

func set_faction(new_faction: String) -> void:
	faction = new_faction
	_save()
	profile_updated.emit()

func set_race(race_id: String) -> void:
	selected_race_id = race_id
	_save()
	profile_updated.emit()

func set_frame(frame_id: String) -> void:
	selected_frame = frame_id
	_save()
	profile_updated.emit()

## Ascension frame: only choosable once Champion (level 50+); multiplies
## the build space x20 and blends the frame sensorium into a duet.
func set_ascended_frame(frame_id: String) -> bool:
	if level < 50:
		NotificationUI.notify_error("A second frame is chosen at Champion ascension (level 50).")
		return false
	ascended_frame = frame_id
	_save()
	profile_updated.emit()
	return true

func set_mod(mod_id: String) -> void:
	selected_mod = mod_id
	_save()
	profile_updated.emit()

func add_title(title: String) -> void:
	if title not in titles:
		titles.append(title)
		_save()
		# Apply TitleEffects immediately so identity/faction/ability shifts land.
		TitleEffects.apply_title_effects({
			"titles": titles,
			"active_title": active_title,
		})
		profile_updated.emit()

func set_active_title(title: String) -> void:
	active_title = title
	_save()
	TitleEffects.apply_title_effects({
		"titles": titles,
		"active_title": active_title,
	})
	profile_updated.emit()

func set_active_companions(ids: Array[String]) -> void:
	active_companion_ids = ids
	_save()
	profile_updated.emit()

func add_stat_modifier(stat: String, amount: float) -> void:
	_stat_modifiers[stat] = float(_stat_modifiers.get(stat, 0.0)) + amount
	profile_updated.emit()

func get_stat_modifier(stat: String) -> float:
	return float(_stat_modifiers.get(stat, 0.0))

func unlock_ability(ability_id: String) -> void:
	if ability_id.is_empty() or ability_id in _unlocked_abilities:
		return
	_unlocked_abilities.append(ability_id)
	profile_updated.emit()

func has_ability(ability_id: String) -> bool:
	return ability_id in _unlocked_abilities

func get_display_name() -> String:
	if active_title.is_empty():
		return username
	return "[%s] %s" % [active_title, username]
