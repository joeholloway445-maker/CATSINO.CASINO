extends Node

signal item_purchased(item: Dictionary)
signal shop_refreshed(shop_id: String)

enum ShopType { COMPANION, COSMETIC, UPGRADE, CONSUMABLE }

const DAILY_REFRESH_SECONDS := 86400  # 24 hours

# Shop catalog
const SHOP_ITEMS: Array[Dictionary] = [
	# Companion unlocks (purchasable with coins)
	{id="shop_companion_random", type=ShopType.COMPANION, name="Mystery Companion", desc="Unlock a random rarity-2+ companion", icon="🎁", price_coins=2500, price_gems=0, stock=3},
	{id="shop_companion_rare", type=ShopType.COMPANION, name="Rare Companion Draw", desc="Unlock a random rarity-4+ companion", icon="⭐", price_coins=0, price_gems=100, stock=1},
	{id="shop_companion_premium", type=ShopType.COMPANION, name="Premium Draw x10", desc="10 companion draws, guaranteed rarity-3+", icon="💎", price_coins=0, price_gems=800, stock=1},
	# Upgrades
	{id="shop_xp_boost", type=ShopType.UPGRADE, name="XP Boost (1hr)", desc="Double XP for 1 hour", icon="⚡", price_coins=500, price_gems=0, stock=5},
	{id="shop_luck_charm", type=ShopType.UPGRADE, name="Lucky Charm", desc="+10 LCK for 24 hours", icon="🍀", price_coins=750, price_gems=0, stock=3},
	{id="shop_speed_boost", type=ShopType.UPGRADE, name="Speed Boost (1 race)", desc="+15 SPD for next race", icon="🏎️", price_coins=300, price_gems=0, stock=5},
	{id="shop_power_crystal", type=ShopType.UPGRADE, name="Power Crystal", desc="+10 POW for next 3 combats", icon="💪", price_coins=400, price_gems=0, stock=5},
	# Cosmetics
	{id="shop_crown_frame", type=ShopType.COSMETIC, name="Crown Profile Frame", desc="Gold crown frame for your profile", icon="👑", price_coins=5000, price_gems=0, stock=1},
	{id="shop_neon_trail", type=ShopType.COSMETIC, name="Neon Trail Effect", desc="Neon cyan trail on your character", icon="✨", price_coins=0, price_gems=50, stock=1},
	{id="shop_void_skin", type=ShopType.COSMETIC, name="Void Skin", desc="Dark void aesthetic for your cat", icon="🌑", price_coins=0, price_gems=200, stock=1},
	{id="shop_golden_skin", type=ShopType.COSMETIC, name="Golden Cat Skin", desc="Pure gold appearance", icon="🥇", price_coins=0, price_gems=500, stock=1},
	# Consumables
	{id="shop_revive", type=ShopType.CONSUMABLE, name="Extra Life", desc="Restore 1 life in Hold'Em or lose-streak modes", icon="❤️", price_coins=250, price_gems=0, stock=3},
	{id="shop_daily_double", type=ShopType.CONSUMABLE, name="Double Daily", desc="Double your next daily bonus claim", icon="📅", price_coins=1000, price_gems=0, stock=1},
	{id="shop_companion_heal", type=ShopType.CONSUMABLE, name="Companion Treat", desc="Restore a companion's battle fatigue", icon="🐟", price_coins=150, price_gems=0, stock=10},
]

var _inventory: Dictionary = {}  # user purchases: item_id -> quantity
var _daily_stock: Dictionary = {}  # item_id -> remaining stock today
var _last_refresh: float = 0.0

func _ready() -> void:
	_load()
	_check_refresh()

func get_available_items() -> Array[Dictionary]:
	_check_refresh()
	var result: Array[Dictionary] = []
	for item in SHOP_ITEMS:
		var remaining = _daily_stock.get(item.id, item.get("stock", 1))
		var entry = item.duplicate()
		entry["stock_remaining"] = remaining
		result.append(entry)
	return result

func purchase(item_id: String) -> Dictionary:
	_check_refresh()
	var item = _find_item(item_id)
	if item.is_empty():
		return {success=false, reason="Item not found"}

	var remaining: int = int(_daily_stock.get(item_id, item.get("stock", 1)))
	if remaining <= 0:
		return {success=false, reason="Out of stock"}

	var price_coins: int = item.get("price_coins", 0)
	var price_gems: int = item.get("price_gems", 0)

	if price_coins > 0 and not await EconomyManager.spend_coins(price_coins):
		return {success=false, reason="Insufficient coins"}
	if price_gems > 0 and not await EconomyManager.spend_gems(price_gems):
		# Refund coins if gems failed
		if price_coins > 0: EconomyManager.add_coins(price_coins)
		return {success=false, reason="Insufficient gems"}

	_daily_stock[item_id] = remaining - 1
	_inventory[item_id] = _inventory.get(item_id, 0) + 1
	_save()
	_apply_purchase(item)
	item_purchased.emit(item)
	return {success=true, item=item}

func _apply_purchase(item: Dictionary) -> void:
	match item.get("type", ShopType.CONSUMABLE):
		ShopType.COMPANION:
			if item.id == "shop_companion_random":
				CompanionSystem.unlock_random(2)
			elif item.id == "shop_companion_rare":
				CompanionSystem.unlock_random(4)
			elif item.id == "shop_companion_premium":
				for i in range(10):
					CompanionSystem.unlock_random(3)
		ShopType.UPGRADE:
			# Store active boosts
			var boosts = _inventory.get("_active_boosts", {})
			boosts[item.id] = Time.get_unix_time_from_system() + 3600  # 1hr or battle-based
			_inventory["_active_boosts"] = boosts
		ShopType.COSMETIC:
			var cosmetics = _inventory.get("_cosmetics", [])
			if item.id not in cosmetics:
				cosmetics.append(item.id)
			_inventory["_cosmetics"] = cosmetics

func has_active_boost(boost_id: String) -> bool:
	var boosts = _inventory.get("_active_boosts", {})
	if boost_id not in boosts:
		return false
	return Time.get_unix_time_from_system() < boosts[boost_id]

func has_cosmetic(cosmetic_id: String) -> bool:
	return cosmetic_id in _inventory.get("_cosmetics", [])

func _check_refresh() -> void:
	var now = Time.get_unix_time_from_system()
	if now - _last_refresh >= DAILY_REFRESH_SECONDS:
		_daily_stock = {}
		for item in SHOP_ITEMS:
			_daily_stock[item.id] = item.get("stock", 1)
		_last_refresh = now
		shop_refreshed.emit("main")
		_save()

func _find_item(item_id: String) -> Dictionary:
	for item in SHOP_ITEMS:
		if item.id == item_id:
			return item
	return {}

func _save() -> void:
	var data = {"inventory": _inventory, "stock": _daily_stock, "last_refresh": _last_refresh}
	var file = FileAccess.open("user://shop.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func _load() -> void:
	if not FileAccess.file_exists("user://shop.json"):
		return
	var file = FileAccess.open("user://shop.json", FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			_inventory = parsed.get("inventory", {})
			_daily_stock = parsed.get("stock", {})
			_last_refresh = parsed.get("last_refresh", 0.0)
