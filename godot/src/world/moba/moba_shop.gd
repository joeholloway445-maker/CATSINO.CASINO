class_name MobaShop
extends RefCounted
## In-match item shop. Gold is match-scoped. Inventory capped at 6 slots;
## consumables stack separately; sell returns 50% of price.

signal gold_changed(gold: int)
signal inventory_changed()
signal item_bought(item_id: String)
signal item_sold(item_id: String, slot: int)
signal level_changed(level: int, xp: int, xp_next: int)

const MAX_SLOTS := 6
const SELL_RATIO := 0.5
const PASSIVE_GOLD_PER_SEC := 1.6

const ITEMS: Array[Dictionary] = [
	{id="claw_edge", name="Claw Edge", price=100, cat="offense", desc="+8 attack damage",
		stats={damage=8}},
	{id="razor_fang", name="Razor Fang", price=220, cat="offense", desc="+18 attack damage",
		stats={damage=18}},
	{id="iron_collar", name="Iron Collar", price=120, cat="defense", desc="+5 armor",
		stats={armor=5}},
	{id="obsidian_plate", name="Obsidian Plate", price=240, cat="defense", desc="+12 armor, +30 HP",
		stats={armor=12, max_hp=30}},
	{id="vitality_milk", name="Vitality Milk", price=90, cat="defense", desc="+40 max HP (heals +40)",
		stats={max_hp=40, heal=40}},
	{id="swift_whiskers", name="Swift Whiskers", price=110, cat="utility", desc="+25% attack speed",
		stats={attack_speed=0.25}},
	{id="long_stride", name="Long Stride", price=130, cat="utility", desc="+0.6 attack range",
		stats={attack_range=0.6}},
	{id="tower_bane", name="Tower Bane", price=150, cat="offense", desc="+20% damage to structures",
		stats={tower_mult=0.20}},
	{id="vampiric_yarn", name="Vampiric Yarn", price=180, cat="offense", desc="+12% lifesteal on hits",
		stats={lifesteal=0.12}},
	{id="heal_salve", name="Heal Salve", price=40, cat="consumable", desc="Restore 55 HP now",
		stats={heal=55}, consumable=true},
	{id="mana_biscuit", name="Focus Biscuit", price=35, cat="consumable", desc="+1 level worth of XP",
		stats={xp=60}, consumable=true},
]

var gold: int = 0
var inventory: Array[Dictionary] = [] # {id, name, price, stats}
var _passive_acc: float = 0.0
var hero: Dictionary = {
	"damage": 14,
	"armor": 2,
	"max_hp": 160,
	"hp": 160,
	"attack_speed": 1.0,
	"tower_mult": 0.0,
	"attack_range": 3.2,
	"lifesteal": 0.0,
	"level": 1,
	"xp": 0,
	"xp_next": 100,
	"kills": 0,
	"deaths": 0,
	"assists": 0,
	"cs": 0,
}

func grant_gold(amount: int, _reason: String = "") -> void:
	if amount <= 0:
		return
	gold += amount
	gold_changed.emit(gold)

func tick_passive(delta: float) -> void:
	# Fractional accumulator via int cast of scaled rate.
	_passive_acc += PASSIVE_GOLD_PER_SEC * delta
	if _passive_acc >= 1.0:
		var whole: int = int(_passive_acc)
		_passive_acc -= float(whole)
		grant_gold(whole, "passive")

func can_afford(item_id: String) -> bool:
	var item: Dictionary = by_id(item_id)
	return not item.is_empty() and gold >= int(item.get("price", 0))

func slots_free() -> int:
	return MAX_SLOTS - inventory.size()

func buy(item_id: String) -> Dictionary:
	var item: Dictionary = by_id(item_id)
	if item.is_empty():
		return {success=false, error="Unknown item"}
	var price: int = int(item.get("price", 0))
	if gold < price:
		return {success=false, error="Need %d gold" % price}
	var consumable: bool = bool(item.get("consumable", false))
	if not consumable and inventory.size() >= MAX_SLOTS:
		return {success=false, error="Inventory full (6/6)"}
	gold -= price
	gold_changed.emit(gold)
	_apply(item)
	if not consumable:
		inventory.append({
			id=str(item.id),
			name=str(item.name),
			price=price,
			stats=item.get("stats", {}),
		})
		inventory_changed.emit()
	item_bought.emit(item_id)
	return {success=true, item=item, gold=gold}

func sell(slot: int) -> Dictionary:
	if slot < 0 or slot >= inventory.size():
		return {success=false, error="Empty slot"}
	var entry: Dictionary = inventory[slot]
	var refund: int = int(round(float(entry.get("price", 0)) * SELL_RATIO))
	_unapply(entry.get("stats", {}))
	inventory.remove_at(slot)
	grant_gold(refund, "sell")
	inventory_changed.emit()
	item_sold.emit(str(entry.get("id", "")), slot)
	return {success=true, refund=refund}

func by_id(item_id: String) -> Dictionary:
	for it in ITEMS:
		if it.id == item_id:
			return it
	return {}

func catalog(category: String = "") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for it in ITEMS:
		if category.is_empty() or str(it.get("cat", "")) == category:
			out.append(it)
	return out

func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	hero.xp = int(hero.xp) + amount
	while int(hero.xp) >= int(hero.xp_next):
		hero.xp = int(hero.xp) - int(hero.xp_next)
		hero.level = int(hero.level) + 1
		hero.xp_next = 100 + (int(hero.level) - 1) * 40
		hero.damage = int(hero.damage) + 3
		hero.max_hp = int(hero.max_hp) + 20
		hero.hp = mini(int(hero.max_hp), int(hero.hp) + 20)
		hero.armor = int(hero.armor) + 1
	level_changed.emit(int(hero.level), int(hero.xp), int(hero.xp_next))

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
	if stats.has("attack_range"):
		hero.attack_range = float(hero.attack_range) + float(stats.attack_range)
	if stats.has("lifesteal"):
		hero.lifesteal = float(hero.lifesteal) + float(stats.lifesteal)
	if stats.has("heal"):
		hero.hp = mini(int(hero.max_hp), int(hero.hp) + int(stats.heal))
	if stats.has("xp"):
		add_xp(int(stats.xp))

func _unapply(stats: Dictionary) -> void:
	if stats.has("damage"):
		hero.damage = maxi(1, int(hero.damage) - int(stats.damage))
	if stats.has("armor"):
		hero.armor = maxi(0, int(hero.armor) - int(stats.armor))
	if stats.has("max_hp"):
		hero.max_hp = maxi(1, int(hero.max_hp) - int(stats.max_hp))
		hero.hp = mini(int(hero.hp), int(hero.max_hp))
	if stats.has("attack_speed"):
		hero.attack_speed = maxf(0.2, float(hero.attack_speed) - float(stats.attack_speed))
	if stats.has("tower_mult"):
		hero.tower_mult = maxf(0.0, float(hero.tower_mult) - float(stats.tower_mult))
	if stats.has("attack_range"):
		hero.attack_range = maxf(1.5, float(hero.attack_range) - float(stats.attack_range))
	if stats.has("lifesteal"):
		hero.lifesteal = maxf(0.0, float(hero.lifesteal) - float(stats.lifesteal))
