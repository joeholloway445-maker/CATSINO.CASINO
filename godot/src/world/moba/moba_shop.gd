class_name MobaShop
extends RefCounted
## In-match item shop for Paws of the Ancients. Gold is match-scoped
## (not EconomyManager). Purchases buff the local hero combat stats.

signal gold_changed(gold: int)
signal item_bought(item_id: String)

const ITEMS: Array[Dictionary] = [
	{id="claw_edge", name="Claw Edge", price=100, desc="+8 attack damage",
		stats={damage=8}},
	{id="iron_collar", name="Iron Collar", price=120, desc="+5 armor",
		stats={armor=5}},
	{id="vitality_milk", name="Vitality Milk", price=90, desc="+40 max HP (heals +40)",
		stats={max_hp=40, heal=40}},
	{id="swift_whiskers", name="Swift Whiskers", price=110, desc="+25% attack speed",
		stats={attack_speed=0.25}},
	{id="tower_bane", name="Tower Bane", price=150, desc="+20% damage to towers",
		stats={tower_mult=0.20}},
	{id="heal_salve", name="Heal Salve", price=40, desc="Restore 55 HP now",
		stats={heal=55}, consumable=true},
]

var gold: int = 0
var owned: Array[String] = []
## Live hero combat stats mutated by purchases.
var hero: Dictionary = {
	"damage": 14,
	"armor": 2,
	"max_hp": 160,
	"hp": 160,
	"attack_speed": 1.0,
	"tower_mult": 0.0,
	"attack_range": 3.2,
}

func grant_gold(amount: int, _reason: String = "") -> void:
	if amount <= 0:
		return
	gold += amount
	gold_changed.emit(gold)

func can_afford(item_id: String) -> bool:
	var item := by_id(item_id)
	return not item.is_empty() and gold >= int(item.price)

func buy(item_id: String) -> Dictionary:
	var item: Dictionary = by_id(item_id)
	if item.is_empty():
		return {success=false, error="Unknown item"}
	var price: int = int(item.get("price", 0))
	if gold < price:
		return {success=false, error="Need %d gold" % price}
	gold -= price
	gold_changed.emit(gold)
	_apply(item)
	var consumable: bool = bool(item.get("consumable", false))
	if not consumable:
		owned.append(item_id)
	item_bought.emit(item_id)
	return {success=true, item=item, gold=gold}

func by_id(item_id: String) -> Dictionary:
	for it in ITEMS:
		if it.id == item_id:
			return it
	return {}

func catalog() -> Array[Dictionary]:
	return ITEMS.duplicate(true)

func _apply(item: Dictionary) -> void:
	var stats: Dictionary = item.get("stats", {})
	if stats.has("damage"):
		hero.damage = int(hero.damage) + int(stats.damage)
	if stats.has("armor"):
		hero.armor = int(hero.armor) + int(stats.armor)
	if stats.has("max_hp"):
		hero.max_hp = int(hero.max_hp) + int(stats.max_hp)
	if stats.has("attack_speed"):
		hero.attack_speed = float(hero.attack_speed) + float(stats.attack_speed)
	if stats.has("tower_mult"):
		hero.tower_mult = float(hero.tower_mult) + float(stats.tower_mult)
	if stats.has("heal"):
		hero.hp = mini(int(hero.max_hp), int(hero.hp) + int(stats.heal))
