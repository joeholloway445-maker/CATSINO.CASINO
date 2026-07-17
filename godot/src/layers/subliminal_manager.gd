extends Node
## Autoloaded as "SubliminalManager". Each player's private safe zone:
## start screen, UGC studio, and capped item storage. NOTHING auto-spawns
## here — ambient figures require an active creator subscription (pay gate).
## Invites: max 3 outstanding at a time; creator subscription raises the cap.

signal invite_sent(code: String)
signal invite_redeemed(code: String, by_player: String)
signal apartment_updated()
signal storage_changed()
signal ambient_changed()

const SAVE_PATH := "user://subliminal.json"
const FREE_INVITE_CAP := 3
const CREATOR_INVITE_CAP := 10
const CREATOR_SUB_COINS := 2500 # per 30 days

## Private item-storage caps. Free players get a small locker; creator
## subscription and one-time expansions raise the ceiling. Carry inventory
## (InventoryManager) is separate — this is the Subliminal vault.
const FREE_STORAGE_SLOTS := 24
const CREATOR_STORAGE_BONUS := 48
const STORAGE_EXPANSION_SLOTS := 16
const STORAGE_EXPANSION_COINS := 4500
const MAX_STORAGE_EXPANSIONS := 8
const MAX_CREATOR_AMBIENT := 12

## Subliminal tiers: buy the space that fits you. Grid = placeable UGC
## slots; capacity = concurrent guests; public tiers can open to strangers.
## Whatever happens inside a subliminal stays there — unapproved UGC is
## free to be ANYTHING here because it can never touch canon lore.
const TIERS: Array[Dictionary] = [
	{id="studio", name="Studio Flat", grid=Vector2i(8, 6), capacity=4,
		can_public=false, price=0,
		desc="The free starter. One calm room, invite-only, 4 guests."},
	{id="loft", name="Corner Loft", grid=Vector2i(12, 10), capacity=12,
		can_public=false, price=8000,
		desc="Twice the floor, a dozen guests. Still yours alone."},
	{id="gallery", name="Gallery", grid=Vector2i(18, 14), capacity=40,
		can_public=true, price=30000,
		desc="Big enough to exhibit. Can open to the public."},
	{id="hall", name="Grand Hall", grid=Vector2i(26, 20), capacity=120,
		can_public=true, price=90000,
		desc="Events, markets, guild gatherings — 120 souls."},
	{id="pavilion", name="Pavilion", grid=Vector2i(40, 30), capacity=300,
		can_public=true, price=250000,
		desc="A world of your own. 300 concurrent, fully public if you want."},
]

## Legacy constant — code that predates tiers reads this; it now follows
## the owned tier.
var APARTMENT_GRID: Vector2i = Vector2i(8, 6)

var _tier_id: String = "studio"
var is_public: bool = false

static func tier_by_id(tid: String) -> Dictionary:
	for t in TIERS:
		if t.id == tid: return t
	return TIERS[0]

func current_tier() -> Dictionary:
	return tier_by_id(_tier_id)

func capacity() -> int:
	return int(current_tier().capacity)

func buy_tier(tid: String) -> bool:
	var t := tier_by_id(tid)
	if t.id == _tier_id:
		return false
	if int(t.price) > 0 and not await EconomyManager.spend_coins(int(t.price), "subliminal_tier_%s" % tid):
		return false
	_tier_id = str(t.id)
	APARTMENT_GRID = t.grid
	if not t.can_public:
		is_public = false
	_save()
	apartment_updated.emit()
	NotificationUI.notify_win("Your Subliminal is now a %s — %d slots, %d guests." % [t.name, t.grid.x * t.grid.y, t.capacity])
	return true

func set_public(open: bool) -> void:
	if open and not current_tier().can_public:
		NotificationUI.notify_error("This tier can't open to the public — upgrade to a Gallery or larger.")
		return
	is_public = open
	_save()
	NotificationUI.notify_info("Your Subliminal is now %s." % ("PUBLIC" if open else "private"))

var _outstanding_invites: Array[String] = []
var _redeemed_invites: Array[String] = []
var _invited_by: String = ""
var _creator_sub_until: int = 0
var apartment_slots: Dictionary = {} # "x,y" -> {blueprint_id, params}

## Private storage locker (item dicts). Cap = free + creator bonus + expansions.
var storage_items: Array = []
var _storage_expansions_bought: int = 0

## Creator-paid ambient figures only — never auto-generated. Each entry:
## {id, archetype, display_name, placed_at}
var ambient_npcs: Array = []

func _ready() -> void:
	_load()

func has_apartment_access() -> bool:
	# Expeditions own a Subliminal berth; Continue Expedition must work at L1.
	if PlayerProfile.has_expedition:
		return true
	# You're in if you were invited, or you're already established (any
	# progression implies you got in somehow — keeps old saves working).
	return _invited_by != "" or PlayerProfile.level > 1 or not apartment_slots.is_empty()

func is_creator() -> bool:
	return Time.get_unix_time_from_system() < _creator_sub_until

func invite_cap() -> int:
	return CREATOR_INVITE_CAP if is_creator() else FREE_INVITE_CAP

func invites_left() -> int:
	return invite_cap() - _outstanding_invites.size()

func send_invite() -> String:
	if invites_left() <= 0:
		NotificationUI.notify_error("No invites left (%d outstanding). Creator subscription raises the cap." % _outstanding_invites.size())
		return ""
	var code := "SUB-%06d" % (randi() % 1000000)
	_outstanding_invites.append(code)
	_save()
	invite_sent.emit(code)
	return code

func redeem_invite(code: String, player_id: String) -> bool:
	if code not in _outstanding_invites:
		return false
	_outstanding_invites.erase(code)
	_redeemed_invites.append(code)
	_save()
	invite_redeemed.emit(code, player_id)
	return true

func mark_invited_by(inviter: String) -> void:
	_invited_by = inviter
	_save()

func buy_creator_subscription() -> bool:
	if not await EconomyManager.spend_coins(CREATOR_SUB_COINS, "creator_subscription"):
		return false
	var now := int(Time.get_unix_time_from_system())
	_creator_sub_until = maxi(_creator_sub_until, now) + 30 * 24 * 3600
	_save()
	NotificationUI.notify_win("Creator subscription active — %d invites, ambient spawn, +%d storage. 🛠️" % [CREATOR_INVITE_CAP, CREATOR_STORAGE_BONUS])
	Hope.record("creator_sub", {"until": _creator_sub_until})
	return true

# ── Private item storage (safe zone locker) ───────────────────────────────────

func storage_capacity() -> int:
	var cap := FREE_STORAGE_SLOTS
	if is_creator():
		cap += CREATOR_STORAGE_BONUS
	cap += _storage_expansions_bought * STORAGE_EXPANSION_SLOTS
	return cap

func storage_used() -> int:
	return storage_items.size()

func storage_expansions_bought() -> int:
	return _storage_expansions_bought

func buy_storage_expansion() -> bool:
	if _storage_expansions_bought >= MAX_STORAGE_EXPANSIONS:
		NotificationUI.notify_error("Storage expansion limit reached (%d)." % MAX_STORAGE_EXPANSIONS)
		return false
	if not await EconomyManager.spend_coins(STORAGE_EXPANSION_COINS, "subliminal_storage_expansion"):
		return false
	_storage_expansions_bought += 1
	_save()
	storage_changed.emit()
	Hope.record("storage_expansion", {"bought": _storage_expansions_bought, "cap": storage_capacity()})
	NotificationUI.notify_win("Subliminal locker +%d slots (now %d)." % [STORAGE_EXPANSION_SLOTS, storage_capacity()])
	return true

func store_item(item: Dictionary) -> bool:
	if item.is_empty() or str(item.get("id", "")) == "":
		return false
	if storage_used() >= storage_capacity():
		NotificationUI.notify_error("Subliminal storage full (%d/%d). Buy an expansion or creator sub." % [storage_used(), storage_capacity()])
		return false
	var item_id := str(item.id)
	for existing in storage_items:
		if str(existing.get("id", "")) == item_id:
			NotificationUI.notify_error("That item is already in your Subliminal locker.")
			return false
	storage_items.append(item.duplicate(true))
	_save()
	storage_changed.emit()
	Hope.record("subliminal_store", {"item": item_id})
	return true

func withdraw_item(item_id: String) -> Dictionary:
	for i in range(storage_items.size()):
		if str(storage_items[i].get("id", "")) == item_id:
			var item: Dictionary = storage_items[i]
			storage_items.remove_at(i)
			_save()
			storage_changed.emit()
			Hope.record("subliminal_withdraw", {"item": item_id})
			return item
	return {}

# ── Creator-gated ambient NPC placement (never automatic) ─────────────────────

## Place a single ambient figure in YOUR Subliminal. Hard pay-gate: active
## creator subscription required. The world never seeds these for free.
func place_ambient_npc(archetype: String, display_name: String = "") -> Dictionary:
	if not is_creator():
		NotificationUI.notify_error("Ambient figures in your Subliminal require a Creator subscription.")
		return {}
	if ambient_npcs.size() >= MAX_CREATOR_AMBIENT:
		NotificationUI.notify_error("Ambient figure cap reached (%d). Remove one first." % MAX_CREATOR_AMBIENT)
		return {}
	var clean_arch := archetype.strip_edges().to_lower()
	if clean_arch == "":
		clean_arch = "reflection"
	var entry := {
		"id": "sub_amb_%d_%d" % [Time.get_ticks_msec(), ambient_npcs.size()],
		"archetype": clean_arch,
		"display_name": display_name if display_name != "" else clean_arch.capitalize(),
		"placed_at": Time.get_datetime_string_from_system(),
		"layer": "subliminal",
		"district": "player_apartment",
		"auto_spawned": false,
		"creator_paid": true,
	}
	ambient_npcs.append(entry)
	_save()
	ambient_changed.emit()
	Hope.record("subliminal_ambient_place", {"id": entry.id, "archetype": clean_arch})
	NotificationUI.notify_info("Placed '%s' in your Subliminal (creator-gated)." % entry.display_name)
	return entry

func remove_ambient_npc(npc_id: String) -> bool:
	for i in range(ambient_npcs.size()):
		if str(ambient_npcs[i].get("id", "")) == npc_id:
			ambient_npcs.remove_at(i)
			_save()
			ambient_changed.emit()
			Hope.record("subliminal_ambient_remove", {"id": npc_id})
			return true
	return false

func clear_all_ambient() -> void:
	if ambient_npcs.is_empty():
		return
	ambient_npcs.clear()
	_save()
	ambient_changed.emit()

## Place a blueprint instance into an apartment slot. Every roster entity is
## also a blueprint (see EntityBlueprint) — the apartment is where they get
## remixed before submission through the Discord review pipeline.
func place_in_apartment(grid_pos: Vector2i, blueprint_id: String, params: Dictionary = {}) -> bool:
	if grid_pos.x < 0 or grid_pos.y < 0 or grid_pos.x >= APARTMENT_GRID.x or grid_pos.y >= APARTMENT_GRID.y:
		return false
	apartment_slots["%d,%d" % [grid_pos.x, grid_pos.y]] = {
		"blueprint_id": blueprint_id, "params": params,
	}
	_save()
	apartment_updated.emit()
	return true

func clear_apartment_slot(grid_pos: Vector2i) -> void:
	apartment_slots.erase("%d,%d" % [grid_pos.x, grid_pos.y])
	_save()
	apartment_updated.emit()

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({
			"outstanding": _outstanding_invites,
			"redeemed": _redeemed_invites,
			"invited_by": _invited_by,
			"creator_sub_until": _creator_sub_until,
			"apartment": apartment_slots,
			"tier": _tier_id,
			"public": is_public,
			"storage": storage_items,
			"storage_expansions": _storage_expansions_bought,
			"ambient": ambient_npcs,
		}))

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f: return
	var d = JSON.parse_string(f.get_as_text())
	if not d is Dictionary: return
	_outstanding_invites.assign(d.get("outstanding", []))
	_redeemed_invites.assign(d.get("redeemed", []))
	_invited_by = d.get("invited_by", "")
	_creator_sub_until = int(d.get("creator_sub_until", 0))
	apartment_slots = d.get("apartment", {})
	_tier_id = str(d.get("tier", "studio"))
	APARTMENT_GRID = tier_by_id(_tier_id).grid
	is_public = bool(d.get("public", false))
	storage_items = d.get("storage", [])
	if not storage_items is Array:
		storage_items = []
	_storage_expansions_bought = int(d.get("storage_expansions", 0))
	ambient_npcs = d.get("ambient", [])
	if not ambient_npcs is Array:
		ambient_npcs = []
	# Expired creator sub → strip ambient figures (pay gate reasserts).
	if not is_creator() and not ambient_npcs.is_empty():
		ambient_npcs.clear()
