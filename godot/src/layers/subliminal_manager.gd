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

## The apartment is a fixed small footprint (roughly a studio flat) —
## a grid of placeable UGC slots rather than open terrain.
const APARTMENT_GRID := Vector2i(8, 6)

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
