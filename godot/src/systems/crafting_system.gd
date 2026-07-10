extends Node
class_name CraftingSystem

signal recipe_unlocked(recipe_id: String)
signal craft_started(recipe_id: String)
signal craft_completed(recipe_id: String, result_id: String)
signal craft_failed(recipe_id: String, reason: String)

const RECIPES = {
	# ARMOR CRAFTING
	"recipe_crown_chest": {
		"id": "recipe_crown_chest",
		"name": "Crown Enforcer Chestplate",
		"result": "armor_crown_chest",
		"category": "armor",
		"tier": 2,
		"materials": {
			"material_crystal_shard": 10,
			"material_essence_fire": 5
		},
		"tools_required": ["workbench"],
		"time_to_craft": 300,
		"xp_reward": 500,
		"description": "Craft protective Crown armor"
	},
	"recipe_veil_chest": {
		"id": "recipe_veil_chest",
		"name": "Veiled Silks",
		"result": "armor_veil_chest",
		"category": "armor",
		"tier": 2,
		"materials": {
			"material_crystal_shard": 8,
			"material_spirit_dust": 3
		},
		"tools_required": ["loom"],
		"time_to_craft": 240,
		"xp_reward": 450,
		"description": "Weave ethereal armor"
	},
	"recipe_wild_chest": {
		"id": "recipe_wild_chest",
		"name": "Primal Hide Mantle",
		"result": "armor_wild_chest",
		"category": "armor",
		"tier": 2,
		"materials": {
			"material_crystal_shard": 12,
			"material_essence_fire": 6
		},
		"tools_required": ["tanning_station"],
		"time_to_craft": 280,
		"xp_reward": 520,
		"description": "Process beast hide into protection"
	},

	# WEAPON CRAFTING
	"recipe_crown_sword": {
		"id": "recipe_crown_sword",
		"name": "Crown Edict Blade",
		"result": "weapon_crown_sword",
		"category": "weapon",
		"tier": 3,
		"materials": {
			"material_crystal_shard": 15,
			"material_essence_fire": 8,
			"material_void_thread": 2
		},
		"tools_required": ["anvil", "forge"],
		"time_to_craft": 600,
		"xp_reward": 1000,
		"description": "Forge an epic Crown weapon"
	},
	"recipe_veil_dagger": {
		"id": "recipe_veil_dagger",
		"name": "Whisper Blade",
		"result": "weapon_veil_dagger",
		"category": "weapon",
		"tier": 3,
		"materials": {
			"material_crystal_shard": 12,
			"material_spirit_dust": 5,
			"material_void_thread": 1
		},
		"tools_required": ["anvil", "enchanting_table"],
		"time_to_craft": 500,
		"xp_reward": 900,
		"description": "Craft a shadow-bound weapon"
	},
	"recipe_wild_axe": {
		"id": "recipe_wild_axe",
		"name": "Evolution Greataxe",
		"result": "weapon_wild_axe",
		"category": "weapon",
		"tier": 3,
		"materials": {
			"material_crystal_shard": 20,
			"material_essence_fire": 10,
			"material_void_thread": 3
		},
		"tools_required": ["anvil", "forge"],
		"time_to_craft": 700,
		"xp_reward": 1200,
		"description": "Forge a primal weapon"
	},

	# POTION CRAFTING
	"recipe_health_potion": {
		"id": "recipe_health_potion",
		"name": "Health Potion",
		"result": "potion_health",
		"category": "potion",
		"tier": 1,
		"quantity": 5,
		"materials": {
			"material_crystal_shard": 2
		},
		"tools_required": ["alchemist_table"],
		"time_to_craft": 60,
		"xp_reward": 50,
		"description": "Brew basic healing potions"
	},
	"recipe_mana_potion": {
		"id": "recipe_mana_potion",
		"name": "Mana Potion",
		"result": "potion_mana",
		"category": "potion",
		"tier": 1,
		"quantity": 5,
		"materials": {
			"material_spirit_dust": 2
		},
		"tools_required": ["alchemist_table"],
		"time_to_craft": 60,
		"xp_reward": 50,
		"description": "Brew mana restoration potions"
	},
	"recipe_strength_elixir": {
		"id": "recipe_strength_elixir",
		"name": "Strength Elixir",
		"result": "elixir_strength",
		"category": "potion",
		"tier": 2,
		"quantity": 3,
		"materials": {
			"material_essence_fire": 3,
			"material_crystal_shard": 5
		},
		"tools_required": ["alchemist_table"],
		"time_to_craft": 120,
		"xp_reward": 150,
		"description": "Brew buff-granting elixirs"
	}
}

var _unlocked_recipes: Array[String] = []
var _crafting_queue: Array[Dictionary] = []
var _current_craft: Dictionary = {}
var _craft_timer: float = 0.0

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	if _current_craft.is_empty():
		if _crafting_queue.size() > 0:
			_start_next_craft()
		return

	_craft_timer -= delta
	if _craft_timer <= 0:
		_finish_craft()

func unlock_recipe(recipe_id: String) -> bool:
	if recipe_id in _unlocked_recipes:
		return false

	if recipe_id not in RECIPES:
		return false

	_unlocked_recipes.append(recipe_id)
	recipe_unlocked.emit(recipe_id)
	return true

func can_craft_recipe(recipe_id: String) -> Dictionary:
	if recipe_id not in RECIPES:
		return {"can_craft": false, "reason": "Recipe not found"}

	if recipe_id not in _unlocked_recipes:
		return {"can_craft": false, "reason": "Recipe not unlocked"}

	var recipe = RECIPES[recipe_id]
	var inventory = InventorySystem.get_inventory()

	# Check materials
	for material in recipe["materials"]:
		var needed = recipe["materials"][material]
		var have = inventory.get(material, 0)

		if have < needed:
			return {
				"can_craft": false,
				"reason": "Missing materials: %s (have %d, need %d)" % [material, have, needed]
			}

	return {"can_craft": true}

func craft_recipe(recipe_id: String) -> bool:
	var can_craft = can_craft_recipe(recipe_id)

	if not can_craft["can_craft"]:
		craft_failed.emit(recipe_id, can_craft["reason"])
		return false

	var recipe = RECIPES[recipe_id]

	# Consume materials
	for material in recipe["materials"]:
		InventorySystem.remove_item(material, recipe["materials"][material])

	_crafting_queue.append({
		"recipe_id": recipe_id,
		"time_remaining": recipe["time_to_craft"]
	})

	craft_started.emit(recipe_id)
	return true

func _start_next_craft() -> void:
	if _crafting_queue.size() == 0:
		return

	_current_craft = _crafting_queue.pop_front()
	var recipe = RECIPES[_current_craft["recipe_id"]]
	_craft_timer = recipe["time_to_craft"]

func _finish_craft() -> void:
	if _current_craft.is_empty():
		return

	var recipe_id = _current_craft["recipe_id"]
	var recipe = RECIPES[recipe_id]
	var result_id = recipe["result"]
	var quantity = recipe.get("quantity", 1)

	# Grant result
	InventorySystem.add_item(result_id, quantity)

	# Grant XP
	PlayerProfile.add_xp(recipe["xp_reward"])

	craft_completed.emit(recipe_id, result_id)
	_current_craft = {}

func get_recipe(recipe_id: String) -> Dictionary:
	return RECIPES.get(recipe_id, {})

func get_unlocked_recipes() -> Array[String]:
	return _unlocked_recipes.duplicate()

func get_crafting_queue() -> Array[Dictionary]:
	return _crafting_queue.duplicate()

func get_current_craft() -> Dictionary:
	return _current_craft.duplicate()

func cancel_craft() -> bool:
	if _current_craft.is_empty():
		return false

	# Refund materials
	var recipe_id = _current_craft["recipe_id"]
	var recipe = RECIPES[recipe_id]

	for material in recipe["materials"]:
		InventorySystem.add_item(material, recipe["materials"][material])

	_current_craft = {}
	_craft_timer = 0.0
	return true

# ── Save/Load ──────────────────────────────────────────────────────────────
func save_state() -> Dictionary:
	return {
		"unlocked_recipes": _unlocked_recipes.duplicate(),
		"crafting_queue": _crafting_queue.duplicate(),
		"current_craft": _current_craft.duplicate()
	}

func load_state(data: Dictionary) -> void:
	_unlocked_recipes = data.get("unlocked_recipes", [])
	_crafting_queue = data.get("crafting_queue", [])
	_current_craft = data.get("current_craft", {})
