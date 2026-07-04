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
	# Forking is how designs spread — but ONLY at the creator's discretion.
	# Your own designs fork freely; anyone else's require allow_forks=true,
	# opted in by the creator, never assumed. The original author rides
	# along in `author` on every fork.
	var src: Dictionary = _library.get(bp_id, {})
	if src.is_empty():
		return {}
	var me: String = PlayerProfile.username
	if str(src.get("author", "")) != me and not bool(src.get("allow_forks", false)):
		NotificationUI.notify_error("'%s' is not open to forks — %s has not opted in." % [src.name, src.author])
		return {}
	var copy: Dictionary = src.duplicate(true)
	copy["id"] = "%s_fork_%d" % [src.kind, Time.get_ticks_msec()]
	copy["name"] = str(src.name) + " (fork)"
	copy["version"] = 1
	copy["status"] = "private"
	copy["allow_forks"] = false
	copy["for_sale"] = false
	copy["copies_sold"] = 0
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
##
## GOVERNANCE GATE: unapproved UGC lives only in the Subliminal. Inside
## your own space a blueprint can be ANYTHING — it can't hurt canon lore
## there. Everywhere else, only canon designs render.
func equipped_for(kind: String, slot: String) -> Dictionary:
	var bp_id: String = _equipped.get(kind, {}).get(slot, "")
	if bp_id == "":
		return {}
	var bp := get_blueprint(bp_id)
	if bp.is_empty():
		return {}
	if str(bp.get("status", "private")) != "canon" and LayerManager.current_layer_id != "subliminal":
		return {}
	return bp

# ------------------------------------------------------ review pipeline
## private -> mod_review (Discord mod team balance check)
##         -> dev_review (dev team canon check)
##         -> canon | rejected
## Canonized UGC becomes property of Holloway's Own Providential
## Enterprise Apex Holdings Inc. (see docs/UGC_POLICY.md). The creator
## keeps the blueprint itself: their name stays on every copy, and only
## they can craft from it — unless they sell the blueprint outright.

signal review_status_changed(bp_id: String, status: String)

## The Holdings' cut on each sold copy of canon UGC.
const HOLDINGS_CUT := 0.10
const HOLDINGS_NAME := "Holloway's Own Providential Enterprise Apex Holdings Inc."

func submit_for_review(bp_id: String) -> bool:
	var bp := get_blueprint(bp_id)
	if bp.is_empty():
		return false
	if str(bp.get("author", "")) != PlayerProfile.username:
		NotificationUI.notify_error("Only the creator can submit a design for review.")
		return false
	if str(bp.get("status", "")) in ["mod_review", "dev_review", "canon"]:
		NotificationUI.notify_info("'%s' is already %s." % [bp.name, bp.status])
		return false
	bp["status"] = "mod_review"
	_library[bp_id] = bp
	save_library()
	review_status_changed.emit(bp_id, "mod_review")
	Hope.record("ugc_submitted", {"kind": bp.kind, "name": bp.name})
	NotificationUI.notify_info("'%s' sent to the Discord mod team for its balance check." % bp.name)
	return true

## Called by the moderation backend (Discord bot -> Supabase -> client
## sync). Local calls exist so the pipeline is testable offline.
func review_advance(bp_id: String, verdict: String) -> void:
	var bp := get_blueprint(bp_id)
	if bp.is_empty():
		return
	match [str(bp.status), verdict]:
		["mod_review", "pass"]:
			bp["status"] = "dev_review"
			NotificationUI.notify_info("'%s' passed mod review — dev team is next." % bp.name)
		["dev_review", "pass"]:
			bp["status"] = "canon"
			NotificationUI.notify_win("'%s' is CANON. It joins the lore as property of %s — your name stays on it, and only you can craft it." % [bp.name, HOLDINGS_NAME])
		[_, "fail"]:
			bp["status"] = "rejected"
			NotificationUI.notify_error("'%s' was rejected — edit it in your Subliminal and resubmit." % bp.name)
		_:
			return
	_library[bp_id] = bp
	save_library()
	review_status_changed.emit(bp_id, str(bp.status))

func set_allow_forks(bp_id: String, allowed: bool) -> void:
	var bp := get_blueprint(bp_id)
	if bp.is_empty() or str(bp.get("author", "")) != PlayerProfile.username:
		return
	bp["allow_forks"] = allowed
	_library[bp_id] = bp
	save_library()

func is_canon(bp_id: String) -> bool:
	return str(get_blueprint(bp_id).get("status", "")) == "canon"

## Only the creator crafts copies of their design — that right never
## leaves them unless the blueprint itself is sold.
func can_craft(bp_id: String) -> bool:
	var bp := get_blueprint(bp_id)
	return not bp.is_empty() and str(bp.get("author", "")) == PlayerProfile.username

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
		var raw: Dictionary = parsed.library[id]
		var clean := BlueprintData.clamp_params(raw)
		if not clean.is_empty():
			clean["id"] = id
			# Governance fields survive OUR OWN save (clamp_params resets
			# them because share-code imports must never claim status).
			if str(raw.get("status", "")) in ["private", "mod_review", "dev_review", "canon", "rejected"]:
				clean["status"] = str(raw.status)
			clean["allow_forks"] = bool(raw.get("allow_forks", false))
			clean["for_sale"] = bool(raw.get("for_sale", false))
			clean["price"] = int(raw.get("price", 0))
			clean["copies_sold"] = int(raw.get("copies_sold", 0))
			_library[id] = clean
	var eq = parsed.get("equipped", {})
	if eq is Dictionary:
		for kind in _equipped:
			if eq.has(kind) and eq[kind] is Dictionary:
				_equipped[kind] = eq[kind]
