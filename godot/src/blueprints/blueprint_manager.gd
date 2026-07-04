extends Node
## Autoloaded as "BlueprintManager". The player's blueprint library:
## create, fork, edit, equip, persist, and share via compact codes.
##
## Blueprints are FORM only. Equipping a weapon blueprint changes what your
## sword looks and sounds like — its damage still comes from ItemData.
## Equipping a skill blueprint recolors/reshapes the VFX — power still comes
## from SkillData. That keeps the Forge infinitely open without ever
## touching balance.

signal blueprint_saved(bp: Dictionary)
signal blueprint_equipped(kind: String, slot: String, bp_id: String)
signal library_changed()

const SAVE_PATH := "user://blueprints.json"
const MAX_LIBRARY := 200

var _library: Dictionary = {} # bp_id -> blueprint Dictionary
## kind -> { slot_key -> bp_id }. Weapons/armor slot by base_id; skills by
## skill_id; entities by entity role ("companion", "summon", ...).
var _equipped: Dictionary = {"weapon": {}, "armor": {}, "skill": {}, "entity": {}}

func _ready() -> void:
	_load()

# ---------------------------------------------------------------- library

func create(kind: String, base_id: String, display_name: String) -> Dictionary:
	if _library.size() >= MAX_LIBRARY:
		NotificationUI.notify_error("Blueprint library full (%d)." % MAX_LIBRARY)
		return {}
	var bp := BlueprintData.fresh(kind, base_id, display_name)
	_library[bp.id] = bp
	save_library()
	library_changed.emit()
	return bp

func fork(bp_id: String) -> Dictionary:
	# Forking is how designs spread: import a friend's share code, fork it,
	# make it yours. The original author rides along in `author`.
	var src: Dictionary = _library.get(bp_id, {})
	if src.is_empty():
		return {}
	var copy: Dictionary = src.duplicate(true)
	copy["id"] = "%s_fork_%d" % [src.kind, Time.get_ticks_msec()]
	copy["name"] = str(src.name) + " (fork)"
	copy["version"] = 1
	_library[copy.id] = copy
	save_library()
	library_changed.emit()
	return copy

func update(bp: Dictionary) -> void:
	if not _library.has(bp.get("id", "")):
		return
	bp["version"] = int(bp.get("version", 1)) + 1
	_library[bp.id] = bp
	save_library()
	blueprint_saved.emit(bp)

func remove(bp_id: String) -> void:
	_library.erase(bp_id)
	for kind in _equipped:
		for slot in _equipped[kind].keys():
			if _equipped[kind][slot] == bp_id:
				_equipped[kind].erase(slot)
	save_library()
	library_changed.emit()

func get_blueprint(bp_id: String) -> Dictionary:
	return _library.get(bp_id, {})

func by_kind(kind: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for bp in _library.values():
		if bp.get("kind", "") == kind:
			out.append(bp)
	return out

# ---------------------------------------------------------------- equipping

func equip(bp_id: String, slot: String) -> bool:
	var bp := get_blueprint(bp_id)
	if bp.is_empty():
		return false
	_equipped[bp.kind][slot] = bp_id
	save_library()
	blueprint_equipped.emit(bp.kind, slot, bp_id)
	return true

func unequip(kind: String, slot: String) -> void:
	if _equipped.get(kind, {}).erase(slot):
		save_library()
		blueprint_equipped.emit(kind, slot, "")

## The lookup every renderer calls: "does this skill/item/entity have a
## player blueprint over it?" Empty dictionary means use stock visuals.
func equipped_for(kind: String, slot: String) -> Dictionary:
	var bp_id: String = _equipped.get(kind, {}).get(slot, "")
	return get_blueprint(bp_id) if bp_id != "" else {}

# ---------------------------------------------------------------- sharing

## Share codes: PL1.<base64url of JSON>. Colors serialized as hex strings.
func export_code(bp_id: String) -> String:
	var bp := get_blueprint(bp_id)
	if bp.is_empty():
		return ""
	var wire: Dictionary = bp.duplicate(true)
	for k in wire.params:
		if wire.params[k] is Color:
			wire.params[k] = (wire.params[k] as Color).to_html(false)
	var json := JSON.stringify(wire)
	return "PL1." + Marshalls.utf8_to_base64(json).replace("+", "-").replace("/", "_")

func import_code(code: String) -> Dictionary:
	code = code.strip_edges()
	if not code.begins_with("PL1."):
		NotificationUI.notify_error("Not a Periliminal blueprint code.")
		return {}
	var b64 := code.substr(4).replace("-", "+").replace("_", "/")
	var json := Marshalls.base64_to_utf8(b64)
	var parsed = JSON.parse_string(json)
	if not parsed is Dictionary:
		NotificationUI.notify_error("Blueprint code is corrupted.")
		return {}
	var clean := BlueprintData.clamp_params(parsed)
	if clean.is_empty():
		NotificationUI.notify_error("Blueprint code failed validation.")
		return {}
	clean["id"] = "%s_import_%d" % [clean.kind, Time.get_ticks_msec()]
	_library[clean.id] = clean
	save_library()
	library_changed.emit()
	NotificationUI.notify_win("Blueprint '%s' by %s imported." % [clean.name, clean.author])
	Hope.record("blueprint_import", {"kind": clean.kind, "author": clean.author})
	return clean

# ---------------------------------------------------------------- persist

func save_library() -> void:
	var wire := {"library": {}, "equipped": _equipped}
	for id in _library:
		var bp: Dictionary = _library[id].duplicate(true)
		for k in bp.params:
			if bp.params[k] is Color:
				bp.params[k] = (bp.params[k] as Color).to_html(false)
		wire.library[id] = bp
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(wire))

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if not parsed is Dictionary:
		return
	for id in parsed.get("library", {}):
		var clean := BlueprintData.clamp_params(parsed.library[id])
		if not clean.is_empty():
			clean["id"] = id
			_library[id] = clean
	var eq = parsed.get("equipped", {})
	if eq is Dictionary:
		for kind in _equipped:
			if eq.has(kind) and eq[kind] is Dictionary:
				_equipped[kind] = eq[kind]
