extends Node
# Seasonal battle pass with free and premium tracks

signal tier_unlocked(tier: int, reward: Dictionary, is_premium: bool)

const SAVE_PATH = "user://battlepass.json"

const FREE_TRACK: Array[Dictionary] = [
	{tier=1,  xp=0,    reward={type="coins", amount=200}},
	{tier=2,  xp=500,  reward={type="coins", amount=300}},
	{tier=3,  xp=1200, reward={type="companion", id="FL001"}},
	{tier=4,  xp=2000, reward={type="coins", amount=500}},
	{tier=5,  xp=3000, reward={type="item", id="charm_luck"}},
	{tier=6,  xp=4200, reward={type="coins", amount=750}},
	{tier=7,  xp=5600, reward={type="gems", amount=5}},
	{tier=8,  xp=7200, reward={type="coins", amount=1000}},
	{tier=9,  xp=9000, reward={type="companion", id="WA001"}},
	{tier=10, xp=11000, reward={type="title", text="Season Veteran"}},
]

const PREMIUM_TRACK: Array[Dictionary] = [
	{tier=1,  xp=0,    reward={type="coins", amount=500}},
	{tier=2,  xp=500,  reward={type="companion", id="SC010"}},
	{tier=3,  xp=1200, reward={type="gems", amount=10}},
	{tier=4,  xp=2000, reward={type="item", id="ring_speed"}},
	{tier=5,  xp=3000, reward={type="coins", amount=1500}},
	{tier=6,  xp=4200, reward={type="companion", id="VC010"}},
	{tier=7,  xp=5600, reward={type="gems", amount=20}},
	{tier=8,  xp=7200, reward={type="item", id="goggles_neon"}},
	{tier=9,  xp=9000, reward={type="companion", id="SC050"}},
	{tier=10, xp=11000, reward={type="title", text="Season Champion 👑"}},
]

var _xp: int = 0
var _claimed_free: Array[int] = []
var _claimed_premium: Array[int] = []
var _has_premium: bool = false

func _ready() -> void:
	_load()

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if not data is Dictionary: return
	_xp = data.get("xp", 0)
	_claimed_free = Array(data.get("claimed_free", []), TYPE_INT, "", null)
	_claimed_premium = Array(data.get("claimed_premium", []), TYPE_INT, "", null)
	_has_premium = data.get("has_premium", false)

func _save() -> void:
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({
		"xp": _xp,
		"claimed_free": _claimed_free,
		"claimed_premium": _claimed_premium,
		"has_premium": _has_premium,
	}))
	f.close()

func add_xp(amount: int) -> void:
	_xp += amount
	_check_unlocks()
	_save()

func _check_unlocks() -> void:
	for t in FREE_TRACK:
		if t.tier not in _claimed_free and _xp >= t.xp:
			_apply_reward(t.reward)
			_claimed_free.append(t.tier)
			tier_unlocked.emit(t.tier, t.reward, false)

	if _has_premium:
		for t in PREMIUM_TRACK:
			if t.tier not in _claimed_premium and _xp >= t.xp:
				_apply_reward(t.reward)
				_claimed_premium.append(t.tier)
				tier_unlocked.emit(t.tier, t.reward, true)

func _apply_reward(reward: Dictionary) -> void:
	match reward.get("type", ""):
		"coins":
			if EconomyManager: EconomyManager.add_coins(reward.get("amount", 0))
		"gems":
			if EconomyManager: EconomyManager.add_gems(reward.get("amount", 0))
		"item":
			if InventoryManager: InventoryManager.add_item(reward.get("id", ""))
		"companion":
			if CompanionManager: CompanionManager.unlock_companion(reward.get("id", ""))
		"title":
			pass # handled by profile system

func get_xp() -> int: return _xp
func get_current_tier() -> int:
	var tier = 0
	for t in FREE_TRACK:
		if _xp >= t.xp: tier = t.tier
	return tier

func activate_premium() -> void:
	_has_premium = true
	_check_unlocks()
	_save()

func has_premium() -> bool: return _has_premium
