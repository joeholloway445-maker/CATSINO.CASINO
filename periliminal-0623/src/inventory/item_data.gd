class_name ItemData
# Catalogue of all purchasable and droppable items

const ITEMS: Array[Dictionary] = [
	# Consumables
	{id="hp_potion", name="HP Potion", type="consumable", effect="restore_hp", value=30, price=100, desc="Restores 30 HP in combat."},
	{id="xp_boost_small", name="XP Boost (Small)", type="consumable", effect="xp_boost", value=1.5, duration=300, price=250, desc="1.5× XP for 5 minutes."},
	{id="xp_boost_large", name="XP Boost (Large)", type="consumable", effect="xp_boost", value=2.0, duration=600, price=500, desc="2× XP for 10 minutes."},
	{id="luck_charm", name="Lucky Charm", type="consumable", effect="lck_boost", value=10, duration=180, price=200, desc="+10 LCK for 3 minutes."},
	{id="speed_serum", name="Speed Serum", type="consumable", effect="spd_boost", value=8, duration=120, price=150, desc="+8 SPD for 2 minutes."},
	{id="power_shard", name="Power Shard", type="consumable", effect="pow_boost", value=10, duration=120, price=150, desc="+10 POW for 2 minutes."},
	{id="shield_tonic", name="Shield Tonic", type="consumable", effect="res_boost", value=10, duration=120, price=150, desc="+10 RES for 2 minutes."},
	{id="slot_multiplier", name="Slot Multiplier ×2", type="consumable", effect="slot_mult", value=2.0, duration=60, price=400, desc="2× slot payouts for 1 minute."},
	{id="race_nitro", name="Race Nitro", type="consumable", effect="spd_boost", value=15, duration=60, price=300, desc="+15 SPD for next race."},

	# Equipment
	{id="combat_gloves", name="Combat Gloves", type="equipment", stat="pow", bonus=5, price=800, desc="+5 POW."},
	{id="iron_boots", name="Iron Boots", type="equipment", stat="res", bonus=5, price=800, desc="+5 RES."},
	{id="speed_shoes", name="Speed Shoes", type="equipment", stat="spd", bonus=5, price=800, desc="+5 SPD."},
	{id="lucky_ring", name="Lucky Ring", type="equipment", stat="lck", bonus=5, price=800, desc="+5 LCK."},
	{id="style_hat", name="Style Hat", type="equipment", stat="sty", bonus=5, price=600, desc="+5 STY."},
	{id="titanium_gauntlets", name="Titanium Gauntlets", type="equipment", stat="pow", bonus=12, price=2500, desc="+12 POW."},
	{id="crystal_shield", name="Crystal Shield", type="equipment", stat="res", bonus=12, price=2500, desc="+12 RES."},
	{id="sonic_boots", name="Sonic Boots", type="equipment", stat="spd", bonus=12, price=2500, desc="+12 SPD."},
	{id="fortune_amulet", name="Fortune Amulet", type="equipment", stat="lck", bonus=12, price=2500, desc="+12 LCK."},
	{id="crown_tiara", name="Crown Tiara", type="equipment", stat="sty", bonus=15, price=4000, desc="+15 STY. Exclusive cosmetic."},

	# Companion Items
	{id="companion_biscuit", name="Companion Biscuit", type="companion_item", effect="feed_xp", value=100, price=50, desc="Gives 100 XP to a companion."},
	{id="companion_cake", name="Companion Cake", type="companion_item", effect="feed_xp", value=500, price=200, desc="Gives 500 XP to a companion."},
	{id="evolution_crystal", name="Evolution Crystal", type="companion_item", effect="evolve", price=5000, desc="Allows companion evolution at level 10."},
]

static func get_item(item_id: String) -> Dictionary:
	for item in ITEMS:
		if item.id == item_id: return item.duplicate()
	return {}

static func get_by_type(item_type: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in ITEMS:
		if item.get("type") == item_type:
			result.append(item.duplicate())
	return result
