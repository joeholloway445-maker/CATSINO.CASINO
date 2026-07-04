extends Node
## Autoloaded as "SubliminalManager". The invite-only start layer: every
## player gets one small apartment — their start screen AND their UGC studio.
## Invites: max 3 outstanding at a time; a creator subscription (gems) raises
## the cap. All creator-mode/UGC building routes through here.

signal invite_sent(code: String)
signal invite_redeemed(code: String, by_player: String)
signal apartment_updated()

const SAVE_PATH := "user://subliminal.json"
const FREE_INVITE_CAP := 3
const CREATOR_INVITE_CAP := 10
const CREATOR_SUB_COINS := 2500 # per 30 days

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

func _ready() -> void:
	_load()

func has_apartment_access() -> bool:
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
	NotificationUI.notify_win("Creator subscription active — %d invites, full studio tools! 🛠️" % CREATOR_INVITE_CAP)
	return true

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
