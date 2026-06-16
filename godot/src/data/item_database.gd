class_name ItemDatabase
# All equippable items and consumables in CATSINO

enum ItemRarity { COMMON=1, UNCOMMON=2, RARE=3, EPIC=4, LEGENDARY=5 }
enum ItemType { WEAPON, ARMOR, ACCESSORY, CONSUMABLE, COSMETIC, COMPANION_GEAR }

const ITEMS: Array[Dictionary] = [
	# Weapons
	{id="claw_basic", type=ItemType.WEAPON, rarity=ItemRarity.COMMON, name="Basic Claw", stat_bonus={pow=5}, price=100, desc="Standard issue combat claws."},
	{id="claw_steel", type=ItemType.WEAPON, rarity=ItemRarity.UNCOMMON, name="Steel Claw", stat_bonus={pow=12, spd=3}, price=500, desc="Reinforced steel tips."},
	{id="claw_neon", type=ItemType.WEAPON, rarity=ItemRarity.RARE, name="Neon Claw", stat_bonus={pow=20, sty=10}, price=1500, desc="Glows neon cyan in the dark."},
	{id="claw_void", type=ItemType.WEAPON, rarity=ItemRarity.EPIC, name="Void Claw", stat_bonus={pow=30, lck=8, sty=15}, price=5000, desc="Forged from void shards. Hits between realities."},
	{id="claw_crown", type=ItemType.WEAPON, rarity=ItemRarity.LEGENDARY, name="Crown Saber", stat_bonus={pow=45, res=10, sty=25}, price=15000, desc="The SovereignCrown's legendary weapon."},
	{id="bite_enhanced", type=ItemType.WEAPON, rarity=ItemRarity.UNCOMMON, name="Enhanced Bite", stat_bonus={pow=10, res=5}, price=400, desc="Tooth reinforcement mod."},
	{id="tail_whip_plasma", type=ItemType.WEAPON, rarity=ItemRarity.RARE, name="Plasma Tail", stat_bonus={pow=18, spd=8}, price=2000, desc="Plasma-charged tail strike."},
	{id="scratch_matrix", type=ItemType.WEAPON, rarity=ItemRarity.EPIC, name="Scratch Matrix", stat_bonus={pow=28, lck=12}, price=6000, desc="Multi-directional scratch pattern."},
	# Armor
	{id="vest_basic", type=ItemType.ARMOR, rarity=ItemRarity.COMMON, name="Basic Vest", stat_bonus={res=5}, price=100, desc="Light protective vest."},
	{id="vest_reinforced", type=ItemType.ARMOR, rarity=ItemRarity.UNCOMMON, name="Reinforced Vest", stat_bonus={res=15, spd=-3}, price=600, desc="Heavy padding reduces SPD slightly."},
	{id="shield_energy", type=ItemType.ARMOR, rarity=ItemRarity.RARE, name="Energy Shield", stat_bonus={res=25, sty=8}, price=2000, desc="Projects an energy barrier."},
	{id="armor_obsidian", type=ItemType.ARMOR, rarity=ItemRarity.EPIC, name="Obsidian Plate", stat_bonus={res=40, spd=-8}, price=7000, desc="Near-impenetrable obsidian armor."},
	{id="armor_void", type=ItemType.ARMOR, rarity=ItemRarity.LEGENDARY, name="Void Mail", stat_bonus={res=50, lck=15, sty=20}, price=20000, desc="Armor that exists between dimensions."},
	# Accessories
	{id="charm_luck", type=ItemType.ACCESSORY, rarity=ItemRarity.COMMON, name="Lucky Charm", stat_bonus={lck=8}, price=200, desc="A classic lucky paw charm."},
	{id="ring_speed", type=ItemType.ACCESSORY, rarity=ItemRarity.UNCOMMON, name="Speed Ring", stat_bonus={spd=10}, price=500, desc="Accelerates limb movement."},
	{id="collar_faction", type=ItemType.ACCESSORY, rarity=ItemRarity.RARE, name="Faction Collar", stat_bonus={lck=6, sty=12}, price=1500, desc="Displays faction allegiance with pride."},
	{id="goggles_neon", type=ItemType.ACCESSORY, rarity=ItemRarity.UNCOMMON, name="Neon Goggles", stat_bonus={spd=6, sty=15}, price=800, desc="See in the dark. Look amazing."},
	{id="crystal_prism", type=ItemType.ACCESSORY, rarity=ItemRarity.EPIC, name="Prism Crystal", stat_bonus={lck=20, sty=18, pow=5}, price=8000, desc="Refracts luck through probability prism."},
	{id="crown_signet", type=ItemType.ACCESSORY, rarity=ItemRarity.LEGENDARY, name="Crown Signet", stat_bonus={pow=15, res=15, lck=15, sty=30}, price=25000, desc="Royal signet ring. Actual Crown artifact."},
	# Consumables
	{id="potion_speed", type=ItemType.CONSUMABLE, rarity=ItemRarity.COMMON, name="Speed Potion", stat_bonus={spd=20}, price=50, desc="+20 SPD for 1 battle. Single use.", duration_battles=1},
	{id="potion_power", type=ItemType.CONSUMABLE, rarity=ItemRarity.COMMON, name="Power Potion", stat_bonus={pow=20}, price=50, desc="+20 POW for 1 battle. Single use.", duration_battles=1},
	{id="elixir_luck", type=ItemType.CONSUMABLE, rarity=ItemRarity.UNCOMMON, name="Luck Elixir", stat_bonus={lck=30}, price=200, desc="+30 LCK for 3 battles.", duration_battles=3},
	{id="mega_boost", type=ItemType.CONSUMABLE, rarity=ItemRarity.RARE, name="Mega Boost", stat_bonus={pow=25, spd=25, res=15}, price=500, desc="All stats up for 1 battle.", duration_battles=1},
	{id="daily_token", type=ItemType.CONSUMABLE, rarity=ItemRarity.COMMON, name="Daily Token", stat_bonus={}, price=0, desc="Doubles next daily bonus claim.", special="daily_double"},
	# Companion gear
	{id="treat_basic", type=ItemType.COMPANION_GEAR, rarity=ItemRarity.COMMON, name="Companion Treat", stat_bonus={}, price=100, desc="Restores companion fatigue.", special="companion_heal"},
	{id="bond_crystal", type=ItemType.COMPANION_GEAR, rarity=ItemRarity.RARE, name="Bond Crystal", stat_bonus={lck=5, sty=5}, price=1000, desc="+10% companion synergy bonus.", special="synergy_boost"},
	{id="evolution_catalyst", type=ItemType.COMPANION_GEAR, rarity=ItemRarity.EPIC, name="Evolution Catalyst", stat_bonus={}, price=2500, desc="Evolves a companion to next stage.", special="force_evolve"},
]

static func get_item(item_id: String) -> Dictionary:
	for item in ITEMS:
		if item.id == item_id: return item.duplicate()
	return {}

static func get_items_by_type(item_type: ItemType) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in ITEMS:
		if item.get("type") == item_type:
			result.append(item.duplicate())
	return result

static func get_items_by_rarity(rarity: ItemRarity) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in ITEMS:
		if item.get("rarity") == rarity:
			result.append(item.duplicate())
	return result

static func apply_item_bonus(item_id: String, stats: Dictionary) -> Dictionary:
	var item = get_item(item_id)
	if item.is_empty(): return stats
	var result = stats.duplicate()
	for stat in item.get("stat_bonus", {}).keys():
		result[stat] = result.get(stat, 0) + item["stat_bonus"][stat]
	return result
