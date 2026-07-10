extends Node
class_name InventorySystem

signal item_added(item_id: String, quantity: int)
signal item_removed(item_id: String, quantity: int)
signal equipment_changed(slot: String, item_id: String)
signal inventory_full()

const ITEM_DATABASE = {
	# ARMOR
	"armor_crown_chest": {
		"name": "Crown Enforcer Chestplate",
		"type": "armor",
		"slot": "chest",
		"rarity": "rare",
		"faction": "SovereignCrown",
		"stats": {"defense": 45, "health": 50},
		"description": "Ornate golden armor bearing Crown insignia"
	},
	"armor_crown_legs": {
		"name": "Crown Enforcer Legguards",
		"type": "armor",
		"slot": "legs",
		"rarity": "rare",
		"faction": "SovereignCrown",
		"stats": {"defense": 35, "agility": 10},
		"description": "Polished leg protection inscribed with Crown decrees"
	},
	"armor_veil_chest": {
		"name": "Veiled Silks",
		"type": "armor",
		"slot": "chest",
		"rarity": "rare",
		"faction": "VeiledCurrent",
		"stats": {"defense": 30, "evasion": 20},
		"description": "Ethereal armor that bends light around the wearer"
	},
	"armor_wild_chest": {
		"name": "Primal Hide Mantle",
		"type": "armor",
		"slot": "chest",
		"rarity": "rare",
		"faction": "WildlandsAscendant",
		"stats": {"defense": 50, "strength": 15},
		"description": "Beast-hide armor infused with evolutionary power"
	},

	# WEAPONS
	"weapon_crown_sword": {
		"name": "Crown Edict Blade",
		"type": "weapon",
		"slot": "mainhand",
		"rarity": "epic",
		"faction": "SovereignCrown",
		"stats": {"attack": 65, "crit_chance": 0.1},
		"description": "Golden blade that enforces order through force",
		"ability_unlock": "precision_strike"
	},
	"weapon_veil_dagger": {
		"name": "Whisper Blade",
		"type": "weapon",
		"slot": "mainhand",
		"rarity": "epic",
		"faction": "VeiledCurrent",
		"stats": {"attack": 45, "crit_chance": 0.25},
		"description": "A dagger that strikes from shadow and dream"
	},
	"weapon_wild_axe": {
		"name": "Evolution Greataxe",
		"type": "weapon",
		"slot": "mainhand",
		"rarity": "epic",
		"faction": "WildlandsAscendant",
		"stats": {"attack": 80, "strength": 20},
		"description": "A primal weapon that embodies evolutionary force",
		"ability_unlock": "primal_fury"
	},

	# ACCESSORIES
	"amulet_crown": {
		"name": "Crown's Blessing Amulet",
		"type": "accessory",
		"slot": "amulet",
		"rarity": "rare",
		"faction": "SovereignCrown",
		"stats": {"mana": 40, "wisdom": 10},
		"description": "Grants favor from the Crown"
	},
	"ring_veil": {
		"name": "Dream Weaver's Ring",
		"type": "accessory",
		"slot": "ring",
		"rarity": "rare",
		"faction": "VeiledCurrent",
		"stats": {"intelligence": 15, "evasion": 10},
		"description": "Enhances connection to the dream realms"
	},

	# CONSUMABLES
	"potion_health": {
		"name": "Health Potion",
		"type": "consumable",
		"rarity": "common",
		"effect": "restore_health",
		"amount": 100,
		"stackable": true,
		"description": "Restores 100 health when consumed"
	},
	"potion_mana": {
		"name": "Mana Potion",
		"type": "consumable",
		"rarity": "common",
		"effect": "restore_mana",
		"amount": 50,
		"stackable": true,
		"description": "Restores 50 mana when consumed"
	},
	"elixir_strength": {
		"name": "Strength Elixir",
		"type": "consumable",
		"rarity": "uncommon",
		"effect": "temporary_buff",
		"stat": "strength",
		"amount": 20,
		"duration": 300,
		"stackable": true,
		"description": "Grants +20 Strength for 5 minutes"
	},

	# CRAFTING MATERIALS
	"material_crystal_shard": {
		"name": "Crystal Shard",
		"type": "material",
		"rarity": "common",
		"stackable": true,
		"description": "Fragment of crystallized energy"
	},
	"material_essence_fire": {
		"name": "Fire Essence",
		"type": "material",
		"rarity": "uncommon",
		"stackable": true,
		"description": "Concentrated essence of flame"
	},
	"material_spirit_dust": {
		"name": "Spirit Dust",
		"type": "material",
		"rarity": "rare",
		"stackable": true,
		"description": "Remnants of defeated spirits"
	},
	"material_void_thread": {
		"name": "Void Thread",
		"type": "material",
		"rarity": "epic",
		"stackable": true,
		"description": "Woven strands from the void between worlds"
	}
}

const EQUIPMENT_SLOTS = ["head", "chest", "hands", "legs", "feet", "mainhand", "offhand", "amulet", "ring"]
const INVENTORY_SLOTS = 40

var _inventory: Dictionary = {}  # item_id -> quantity
var _equipment: Dictionary = {}  # slot -> item_id
var _equipment_stats_cache: Dictionary = {}

func _ready() -> void:
	for slot in EQUIPMENT_SLOTS:
		_equipment[slot] = null

func add_item(item_id: String, quantity: int = 1) -> bool:
	if item_id not in ITEM_DATABASE:
		return false

	var item = ITEM_DATABASE[item_id]

	if not item.get("stackable", false):
		if _inventory.size() >= INVENTORY_SLOTS:
			inventory_full.emit()
			return false
		quantity = 1
	else:
		if item_id not in _inventory and _inventory.size() >= INVENTORY_SLOTS:
			inventory_full.emit()
			return false

	_inventory[item_id] = _inventory.get(item_id, 0) + quantity
	item_added.emit(item_id, quantity)
	return true

func remove_item(item_id: String, quantity: int = 1) -> bool:
	if item_id not in _inventory:
		return false

	_inventory[item_id] -= quantity
	if _inventory[item_id] <= 0:
		_inventory.erase(item_id)

	item_removed.emit(item_id, quantity)
	return true

func equip_item(item_id: String) -> bool:
	if item_id not in ITEM_DATABASE:
		return false

	var item = ITEM_DATABASE[item_id]
	var slot = item.get("slot")

	if not slot or slot not in EQUIPMENT_SLOTS:
		return false

	# Check if player has the item
	if _inventory.get(item_id, 0) <= 0:
		return false

	# Unequip current item in slot
	if _equipment[slot]:
		add_item(_equipment[slot], 1)

	_equipment[slot] = item_id
	remove_item(item_id, 1)

	_recalculate_equipment_stats()
	equipment_changed.emit(slot, item_id)
	return true

func unequip_item(slot: String) -> bool:
	if slot not in EQUIPMENT_SLOTS or not _equipment[slot]:
		return false

	var item_id = _equipment[slot]
	_equipment[slot] = null
	add_item(item_id, 1)

	_recalculate_equipment_stats()
	equipment_changed.emit(slot, null)
	return true

func _recalculate_equipment_stats() -> void:
	_equipment_stats_cache = {}

	for slot in EQUIPMENT_SLOTS:
		if _equipment[slot]:
			var item = ITEM_DATABASE[_equipment[slot]]
			var stats = item.get("stats", {})

			for stat in stats:
				_equipment_stats_cache[stat] = _equipment_stats_cache.get(stat, 0) + stats[stat]

	# Apply to player profile
	for stat in _equipment_stats_cache:
		PlayerProfile.add_stat_modifier(stat, _equipment_stats_cache[stat])

func get_equipped_item(slot: String) -> Dictionary:
	var item_id = _equipment.get(slot)
	if item_id:
		return ITEM_DATABASE[item_id]
	return {}

func get_inventory_item(item_id: String) -> Dictionary:
	if item_id not in ITEM_DATABASE:
		return {}
	var item = ITEM_DATABASE[item_id]
	return item.duplicate()

func get_inventory() -> Dictionary:
	return _inventory.duplicate()

func get_equipment() -> Dictionary:
	return _equipment.duplicate()

func get_total_equipment_stats() -> Dictionary:
	return _equipment_stats_cache.duplicate()

func get_inventory_count() -> int:
	return _inventory.size()

# ── Save/Load ──────────────────────────────────────────────────────────────
func save_state() -> Dictionary:
	return {
		"inventory": _inventory.duplicate(),
		"equipment": _equipment.duplicate()
	}

func load_state(data: Dictionary) -> void:
	_inventory = data.get("inventory", {})
	_equipment = data.get("equipment", {})
	_recalculate_equipment_stats()
