class_name ShopData
# Full shop catalogue across all districts

const SHOP_ITEMS: Array[Dictionary] = [
	# Paw Vegas — Slot Sam's shop
	{id="hp_potion", shop="slot_sam", district="paw_vegas", name="HP Potion", price=100, type="consumable"},
	{id="luck_charm", shop="slot_sam", district="paw_vegas", name="Lucky Charm", price=200, type="consumable"},
	{id="slot_multiplier", shop="slot_sam", district="paw_vegas", name="Slot Multiplier ×2", price=400, type="consumable"},
	{id="xp_boost_small", shop="slot_sam", district="paw_vegas", name="XP Boost (Small)", price=250, type="consumable"},

	# Neon Alley — Aqua Merchant's frames shop
	{id="bolt", shop="aqua_merchant", district="neon_alley", name="Bolt Frame", price=1000, type="frame"},
	{id="storm", shop="aqua_merchant", district="neon_alley", name="Storm Frame", price=2000, type="frame"},
	{id="wind", shop="aqua_merchant", district="neon_alley", name="Wind Frame", price=4500, type="frame"},
	{id="race_nitro", shop="aqua_merchant", district="neon_alley", name="Race Nitro", price=300, type="consumable"},
	{id="speed_serum", shop="aqua_merchant", district="neon_alley", name="Speed Serum", price=150, type="consumable"},

	# Cat Coliseum — Arena shop (mods & equipment)
	{id="combat_gloves", shop="arena", district="cat_coliseum", name="Combat Gloves", price=800, type="equipment"},
	{id="iron_boots", shop="arena", district="cat_coliseum", name="Iron Boots", price=800, type="equipment"},
	{id="power_core", shop="arena", district="cat_coliseum", name="Power Core Mod", price=500, type="mod"},
	{id="shield_plate", shop="arena", district="cat_coliseum", name="Shield Plate Mod", price=500, type="mod"},
	{id="power_shard", shop="arena", district="cat_coliseum", name="Power Shard", price=150, type="consumable"},
	{id="shield_tonic", shop="arena", district="cat_coliseum", name="Shield Tonic", price=150, type="consumable"},

	# Cat Forest — Companion Keeper's shop
	{id="companion_biscuit", shop="companion_keeper", district="cat_forest", name="Companion Biscuit", price=50, type="companion_item"},
	{id="companion_cake", shop="companion_keeper", district="cat_forest", name="Companion Cake", price=200, type="companion_item"},
	{id="evolution_crystal", shop="companion_keeper", district="cat_forest", name="Evolution Crystal", price=5000, type="companion_item"},
	{id="lucky_ring", shop="companion_keeper", district="cat_forest", name="Lucky Ring", price=800, type="equipment"},

	# Arcade Galaxy — General shop
	{id="xp_boost_large", shop="arcade", district="arcade_galaxy", name="XP Boost (Large)", price=500, type="consumable"},
	{id="sonic_boots", shop="arcade", district="arcade_galaxy", name="Sonic Boots", price=2500, type="equipment"},
	{id="fortune_amulet", shop="arcade", district="arcade_galaxy", name="Fortune Amulet", price=2500, type="equipment"},
	{id="style_hat", shop="arcade", district="arcade_galaxy", name="Style Hat", price=600, type="equipment"},
]

static func get_shop(shop_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in SHOP_ITEMS:
		if item.get("shop") == shop_id:
			result.append(item.duplicate())
	return result

static func get_district_shops(district: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in SHOP_ITEMS:
		if item.get("district") == district:
			result.append(item.duplicate())
	return result
