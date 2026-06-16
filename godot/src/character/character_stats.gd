extends Resource
class_name CharacterStats
# Base character stats for a cat player — all bonuses stack on top

@export var base_pow: int = 50
@export var base_res: int = 50
@export var base_spd: int = 50
@export var base_lck: int = 50
@export var base_sty: int = 50

var _frame_bonus: Dictionary = {}
var _mod_bonus: Dictionary = {}
var _item_bonuses: Array[Dictionary] = []
var _companion_bonus: Dictionary = {}
var _consumable_bonus: Dictionary = {}
var _faction_mult: float = 1.0

const BASE_STATS = ["pow", "res", "spd", "lck", "sty"]

func get_stat(stat: String) -> int:
	var base = _get_base(stat)
	var total = base
	for d in [_frame_bonus, _mod_bonus, _companion_bonus, _consumable_bonus]:
		total += d.get(stat, 0)
	for item in _item_bonuses:
		total += item.get(stat, 0)
	return max(0, int(total * _faction_mult))

func get_all_stats() -> Dictionary:
	var result = {}
	for s in BASE_STATS:
		result[s] = get_stat(s)
	return result

func _get_base(stat: String) -> int:
	match stat:
		"pow": return base_pow
		"res": return base_res
		"spd": return base_spd
		"lck": return base_lck
		"sty": return base_sty
	return 0

func apply_frame(frame_id: String) -> void:
	_frame_bonus = FrameModData.get_frame(frame_id).get("stat_bonus", {})

func apply_mod(mod_id: String) -> void:
	_mod_bonus = FrameModData.get_mod(mod_id).get("stat_bonus", {})

func apply_item(item_id: String) -> void:
	var bonus = ItemDatabase.get_item(item_id).get("stat_bonus", {})
	if not bonus.is_empty():
		_item_bonuses.append(bonus)

func remove_item_bonuses() -> void:
	_item_bonuses.clear()

func apply_companion_synergy(bonus: Dictionary) -> void:
	_companion_bonus = bonus

func apply_consumable(bonus: Dictionary) -> void:
	_consumable_bonus = bonus

func clear_consumable() -> void:
	_consumable_bonus = {}

func set_faction_mult(mult: float) -> void:
	_faction_mult = mult

func check_sleeper_burst() -> bool:
	return get_stat("lck") >= 80 and _faction_mult >= 1.2

func get_combat_power() -> int:
	var stats = get_all_stats()
	return stats.pow + int(stats.lck * 0.3) + int(stats.sty * 0.1)
