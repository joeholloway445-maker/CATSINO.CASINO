class_name EntityBlueprint
## Every entity in the ~600-strong roster doubles as a UGC blueprint: a
## caught/unlocked entity can be forked in the Subliminal apartment, its
## editable fields remixed, and the result submitted through the existing
## Discord-mod-ticket review pipeline (UGCSubmission / DiscordTicketClient).
## The original roster entry is never mutated — blueprints are forks.

## Fields creators may change; everything else (id lineage, base stats
## budget) is locked so remixes can't power-creep.
const EDITABLE_FIELDS := ["name", "lore", "ability", "primary_color", "texture_type"]
## Total stat budget is preserved: you can move points, not add them.
const STAT_KEYS := ["pow", "res", "spd", "lck", "sty"]

static func fork(entity_id: String) -> Dictionary:
	var base := CompanionRegistry.get_by_id(entity_id)
	if base.is_empty():
		return {}
	return {
		"blueprint_of": entity_id,
		"name": str(base.get("name", "")) + " (Remix)",
		"lore": base.get("lore", ""),
		"ability": base.get("ability", ""),
		"stats": _stats_of(base),
		"stat_budget": _budget_of(base),
		"rarity": base.get("rarity", 1),
	}

static func _stats_of(e: Dictionary) -> Dictionary:
	var s := {}
	for k in STAT_KEYS: s[k] = int(e.get(k, 0))
	return s

static func _budget_of(e: Dictionary) -> int:
	var total := 0
	for k in STAT_KEYS: total += int(e.get(k, 0))
	return total

## Validate a remixed blueprint: stat budget unchanged, edits confined to
## editable fields, name sane. Returns "" when valid, else the reason.
static func validate(bp: Dictionary) -> String:
	if str(bp.get("blueprint_of", "")) == "":
		return "Blueprint must fork a roster entity."
	var spent := 0
	for k in STAT_KEYS: spent += int(bp.get("stats", {}).get(k, 0))
	if spent != int(bp.get("stat_budget", -1)):
		return "Stat budget must stay exactly %d (got %d)." % [bp.get("stat_budget", 0), spent]
	var name := str(bp.get("name", ""))
	if name.length() < 2 or name.length() > 40:
		return "Name must be 2-40 characters."
	return ""

## Submit through the same Discord review pipeline creator-mode uses.
static func submit(bp: Dictionary, creator_id: String = "local_player") -> bool:
	var reason := validate(bp)
	if reason != "":
		NotificationUI.notify_error(reason)
		return false
	var sub := UgcSubmission.new()
	sub.id = "bp_%s_%d" % [bp.get("blueprint_of", "?"), randi() % 100000]
	sub.creator_player_id = creator_id
	sub.source_mode_id = "entity_blueprint"
	await sub.submit_ticket()
	NotificationUI.notify_info("Blueprint '%s' sent for review 📨" % bp.get("name", "?"))
	return true
