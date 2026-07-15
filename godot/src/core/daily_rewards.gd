extends Node
# Daily login reward streak with escalating prizes

signal reward_claimed(day: int, coins: int, gems: int, bonus_item: String)
signal already_claimed()

const SAVE_PATH = "user://daily_rewards.json"
const STREAK_REWARDS: Array[Dictionary] = [
	{day=1,  coins=100,  gems=0, item=""},
	{day=2,  coins=150,  gems=0, item=""},
	{day=3,  coins=200,  gems=1, item=""},
	{day=4,  coins=250,  gems=0, item="potion_speed"},
	{day=5,  coins=300,  gems=1, item=""},
	{day=6,  coins=400,  gems=2, item=""},
	{day=7,  coins=600,  gems=5, item="daily_token"},
	{day=8,  coins=200,  gems=0, item=""},
	{day=9,  coins=250,  gems=1, item=""},
	{day=10, coins=350,  gems=2, item=""},
	{day=11, coins=400,  gems=2, item="elixir_luck"},
	{day=12, coins=500,  gems=3, item=""},
	{day=13, coins=600,  gems=3, item=""},
	{day=14, coins=1000, gems=10, item="bond_crystal"},
]

var _save_data: Dictionary = {}

func _ready() -> void:
	_load()

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_save_data = {"last_claim_date": "", "streak": 0}
		return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	_save_data = parsed if parsed is Dictionary else {"last_claim_date": "", "streak": 0}

func _save() -> void:
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(_save_data))
	f.close()

func can_claim() -> bool:
	var today = Time.get_date_string_from_system()
	return _save_data.get("last_claim_date", "") != today

func claim() -> void:
	if not can_claim():
		already_claimed.emit()
		return

	var today = Time.get_date_string_from_system()
	var last_date = _save_data.get("last_claim_date", "")
	var streak = _save_data.get("streak", 0)

	# Check if streak should continue or reset
	if last_date != "":
		var yesterday = _get_yesterday()
		if last_date != yesterday:
			streak = 0

	streak = (streak % STREAK_REWARDS.size()) + 1
	var reward = STREAK_REWARDS[streak - 1]

	_save_data["last_claim_date"] = today
	_save_data["streak"] = streak
	_save()

	# Apply rewards
	if EconomyManager:
		EconomyManager.add_coins(reward.coins)
		if reward.gems > 0:
			EconomyManager.add_gems(reward.gems)

	if reward.item != "" and InventoryManager:
		InventoryManager.add_item(reward.item)

	reward_claimed.emit(streak, reward.coins, reward.gems, reward.item)

func get_streak() -> int:
	return _save_data.get("streak", 0)

func get_next_reward() -> Dictionary:
	var streak = _save_data.get("streak", 0)
	var next_day = (streak % STREAK_REWARDS.size()) + 1
	return STREAK_REWARDS[next_day - 1]

func _get_yesterday() -> String:
	var now = Time.get_unix_time_from_system()
	var yesterday_unix = now - 86400
	return Time.get_date_string_from_unix_time(yesterday_unix)
