extends Node

signal item_added(item: Dictionary)
signal item_equipped(item: Dictionary)
signal item_crafted(item: Dictionary)
signal inventory_loaded(items: Array)

enum ItemRarity { COMMON, RARE, EPIC, LEGENDARY, MYTHIC }
enum ItemType { COSMETIC_SKIN, COMPANION_ACCESSORY, TRAIL_EFFECT, TITLE, EMOTE }

class Item:
	var id: String
	var name: String
	var type: int  # ItemType
	var rarity: int  # ItemRarity
	var equipped: bool = false
	var metadata: Dictionary = {}

	func _init(data: Dictionary) -> void:
		id = data.get("id", "")
		name = data.get("name", "")
		type = data.get("type", ItemType.COSMETIC_SKIN)
		rarity = data.get("rarity", ItemRarity.COMMON)
		equipped = data.get("equipped", false)
		metadata = data.get("metadata", {})

	func to_dict() -> Dictionary:
		return {
			"id": id, "name": name, "type": type,
			"rarity": rarity, "equipped": equipped, "metadata": metadata
		}

var _items: Dictionary = {}  # id -> Item

const CRAFT_RECIPES: Dictionary = {
	"rare_skin_001": ["common_shard", "common_shard", "common_shard"],
	"epic_trail_001": ["rare_shard", "rare_shard"],
	"legendary_emote_001": ["epic_shard", "common_essence"]
}

## Wipes the whole inventory — the Periliminal keeps what it kills.
func clear_all() -> void:
	_items.clear()
	inventory_loaded.emit([])

func add_item(item_data: Dictionary) -> bool:
	var item_id: String = item_data.get("id", "")
	if item_id == "" or item_id in _items:
		return false
	var new_item = Item.new(item_data)
	_items[item_id] = new_item
	item_added.emit(new_item.to_dict())
	return true

func remove_item(item_id: String) -> bool:
	if item_id not in _items:
		return false
	_items.erase(item_id)
	return true

func equip(item_id: String) -> bool:
	if item_id not in _items:
		return false
	var item: Item = _items[item_id]
	# Unequip current item of same type
	for other_id in _items:
		var other: Item = _items[other_id]
		if other.type == item.type and other.equipped:
			other.equipped = false
	item.equipped = true
	item_equipped.emit(item.to_dict())
	return true

func unequip(item_id: String) -> void:
	if item_id in _items:
		_items[item_id].equipped = false

func get_equipped_by_type(type: ItemType) -> Dictionary:
	for item_id in _items:
		var item: Item = _items[item_id]
		if item.type == type and item.equipped:
			return item.to_dict()
	return {}

func get_all_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id in _items:
		result.append(_items[item_id].to_dict())
	return result

func craft_item(ingredient_ids: Array[String]) -> Dictionary:
	# Determine recipe match
	var target_id: String = ""
	for recipe_id in CRAFT_RECIPES:
		var required: Array = CRAFT_RECIPES[recipe_id]
		var sorted_required = required.duplicate()
		var sorted_input = ingredient_ids.duplicate()
		sorted_required.sort()
		sorted_input.sort()
		if sorted_required == sorted_input:
			target_id = recipe_id
			break
	if target_id == "":
		return {"success": false, "error": "no_matching_recipe"}
	# Check all ingredients exist
	for ing_id in ingredient_ids:
		if ing_id not in _items:
			return {"success": false, "error": "missing_ingredient", "id": ing_id}
	# Consume ingredients
	for ing_id in ingredient_ids:
		remove_item(ing_id)
	# Create crafted item
	var crafted_data: Dictionary = {
		"id": target_id,
		"name": target_id.replace("_", " ").capitalize(),
		"type": ItemType.COSMETIC_SKIN,
		"rarity": ItemRarity.RARE,
		"equipped": false,
		"metadata": {"crafted": true}
	}
	add_item(crafted_data)
	item_crafted.emit(crafted_data)
	return {"success": true, "item": crafted_data}

func save_to_nakama() -> void:
	var payload: Array = []
	for item_id in _items:
		payload.append(_items[item_id].to_dict())
	await CasinoHTTPClient.post_json("/v1/storage/inventory", {"items": payload})

func load_from_nakama() -> void:
	var response = await CasinoHTTPClient.get_json("/v1/storage/inventory")
	if response and "items" in response:
		_items.clear()
		for item_data in response["items"]:
			var item = Item.new(item_data)
			_items[item.id] = item
		inventory_loaded.emit(get_all_items())
