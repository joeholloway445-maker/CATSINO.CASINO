extends Node

signal achievement_unlocked(achievement: Dictionary)

const SAVE_PATH := "user://achievements.json"

const ACHIEVEMENTS: Array[Dictionary] = [
	{id="first_win", name="First Blood", desc="Win your first game", icon="🏆", xp=50, category="games"},
	{id="high_roller", name="High Roller", desc="Place a bet of 1000 coins", icon="💰", xp=100, category="economy"},
	{id="jackpot", name="Jackpot!", desc="Hit a 25x multiplier or higher", icon="🎰", xp=500, category="games"},
	{id="streak_3", name="Hot Streak", desc="Win 3 games in a row", icon="🔥", xp=150, category="games"},
	{id="streak_7", name="Seven Lives", desc="Win 7 games in a row", icon="⭐", xp=500, category="games"},
	{id="companion_1", name="Found a Friend", desc="Unlock your first companion", icon="🐱", xp=100, category="companions"},
	{id="companion_10", name="Pack Leader", desc="Unlock 10 companions", icon="🐾", xp=300, category="companions"},
	{id="companion_50", name="Army of Cats", desc="Unlock 50 companions", icon="👑", xp=1000, category="companions"},
	{id="evolve_1", name="Evolution", desc="Evolve a companion to stage 1", icon="✨", xp=200, category="companions"},
	{id="evolve_max", name="Apex Form", desc="Evolve a companion to stage 3", icon="🌟", xp=1000, category="companions"},
	{id="faction_bonus", name="Faction Pride", desc="Apply a faction bonus in combat", icon="⚔️", xp=100, category="factions"},
	{id="district_explore", name="Tourist", desc="Visit all 5 districts", icon="🗺️", xp=200, category="world"},
	{id="race_win", name="Fast Cat", desc="Win your first race", icon="🏎️", xp=150, category="racing"},
	{id="race_3", name="Speed Demon", desc="Win 3 races", icon="⚡", xp=300, category="racing"},
	{id="daily_7", name="Creature of Habit", desc="Claim daily bonus 7 days straight", icon="📅", xp=250, category="economy"},
	{id="daily_30", name="Devoted", desc="Claim daily bonus 30 days in a row", icon="🌙", xp=1000, category="economy"},
	{id="guild_join", name="Pack Member", desc="Join a guild", icon="🤝", xp=100, category="social"},
	{id="guild_create", name="Alpha", desc="Create a guild", icon="🏰", xp=200, category="social"},
	{id="friend_5", name="Social Cat", desc="Add 5 friends", icon="💬", xp=150, category="social"},
	{id="battlepass_10", name="Dedicated", desc="Reach Battle Pass tier 10", icon="🎖️", xp=200, category="battlepass"},
	{id="battlepass_50", name="Halfway There", desc="Reach Battle Pass tier 50", icon="🥈", xp=500, category="battlepass"},
	{id="battlepass_100", name="Season Complete", desc="Reach Battle Pass tier 100", icon="🥇", xp=2000, category="battlepass"},
	{id="tournament_enter", name="Contender", desc="Enter a tournament", icon="🎭", xp=100, category="coliseum"},
	{id="tournament_win", name="Champion", desc="Win a tournament", icon="🏅", xp=1000, category="coliseum"},
	{id="sleeper_burst", name="Awakened", desc="Trigger a sleeper burst in combat", icon="💥", xp=300, category="combat"},
	{id="coins_1000", name="Coin Collector", desc="Accumulate 1,000 coins", icon="🪙", xp=50, category="economy"},
	{id="coins_10000", name="Wealthy Cat", desc="Accumulate 10,000 coins", icon="💎", xp=200, category="economy"},
	{id="coins_100000", name="Fat Cat", desc="Accumulate 100,000 coins", icon="👑", xp=1000, category="economy"},
	{id="scratch_big", name="Lucky Scratch", desc="Win 500+ coins from Catnip Cash", icon="🌿", xp=200, category="games"},
	{id="slots_crown", name="Crown Chaser", desc="Land CROWN in all 3 slots reels", icon="👑", xp=500, category="games"},
]

var _unlocked: Dictionary = {}  # id -> unlock timestamp
var _win_streak: int = 0

func _ready() -> void:
	_load_achievements()

func check(trigger_id: String, value: Variant = null) -> void:
	# Aliases from older call sites / combat / quests / casino UI.
	var aliases := {
		"battle_win": "win",
		"quest_completed": "win",
		"visit_district": "district_visited",
		"companion_collect": "companion_unlocked",
		"spin": "win",
		"big_win": "win",
		"race_enter": "tournament_entered",
		"race_podium": "race_won",
		"blackjack": "win",
		"full_house": "win",
		"puzzle_score": "win",
		"big_spender": "bet",
		"win_10": "win",
	}
	if aliases.has(trigger_id):
		trigger_id = aliases[trigger_id]
	match trigger_id:
		"win": _on_win()
		"loss": _win_streak = 0
		"bet": _on_bet(value)
		"multiplier": _on_multiplier(value)
		"companion_unlocked": _on_companion_count()
		"companion_evolved": _on_companion_evolved(value)
		"district_visited": _on_district_visited(str(value) if value != null else "")
		"daily_claimed": _on_daily(value)
		"guild_joined": _try_unlock("guild_join")
		"guild_created": _try_unlock("guild_create")
		"friend_added": _on_friends(value)
		"battlepass_tier": _on_battlepass(value)
		"tournament_entered": _try_unlock("tournament_enter")
		"tournament_won": _try_unlock("tournament_win")
		"sleeper_burst": _try_unlock("sleeper_burst")
		"coins": _on_coins(value)
		"race_won": _on_race_won()
		"faction_bonus": _try_unlock("faction_bonus")
		"scratch_big": _try_unlock("scratch_big")
		"slots_crown": _try_unlock("slots_crown")

func _on_win() -> void:
	_try_unlock("first_win")
	_win_streak += 1
	if _win_streak >= 3: _try_unlock("streak_3")
	if _win_streak >= 7: _try_unlock("streak_7")

func _on_bet(amount) -> void:
	if amount is int and amount >= 1000:
		_try_unlock("high_roller")

func _on_multiplier(mult) -> void:
	if mult is float or mult is int:
		if mult >= 25: _try_unlock("jackpot")

func _on_companion_count() -> void:
	var count = CompanionSystem.get_unlocked_count() if CompanionSystem.has_method("get_unlocked_count") else 0
	if count >= 1: _try_unlock("companion_1")
	if count >= 10: _try_unlock("companion_10")
	if count >= 50: _try_unlock("companion_50")

func _on_companion_evolved(stage) -> void:
	if stage is int:
		if stage >= 1: _try_unlock("evolve_1")
		if stage >= 3: _try_unlock("evolve_max")

func _on_district_visited(_district: String) -> void:
	var visited := 0
	if DistrictManager and DistrictManager.get("_visited_districts") != null:
		visited = DistrictManager._visited_districts.size()
	if visited >= 5:
		_try_unlock("district_explore")

func _on_daily(streak) -> void:
	if streak is int:
		if streak >= 7: _try_unlock("daily_7")
		if streak >= 30: _try_unlock("daily_30")

func _on_friends(count) -> void:
	if count is int and count >= 5:
		_try_unlock("friend_5")

func _on_battlepass(tier) -> void:
	if tier is int:
		if tier >= 10: _try_unlock("battlepass_10")
		if tier >= 50: _try_unlock("battlepass_50")
		if tier >= 100: _try_unlock("battlepass_100")

func _on_coins(amount) -> void:
	if amount is int:
		if amount >= 1000: _try_unlock("coins_1000")
		if amount >= 10000: _try_unlock("coins_10000")
		if amount >= 100000: _try_unlock("coins_100000")

func _on_race_won() -> void:
	_try_unlock("race_win")
	var race_wins = _unlocked.get("_race_win_count", 0) + 1
	_unlocked["_race_win_count"] = race_wins
	if race_wins >= 3: _try_unlock("race_3")

func _try_unlock(id: String) -> void:
	if id in _unlocked:
		return
	var achievement = ACHIEVEMENTS.filter(func(a): return a.id == id)
	if achievement.is_empty():
		return
	_unlocked[id] = Time.get_unix_time_from_system()
	_save_achievements()
	achievement_unlocked.emit(achievement[0])
	# Grant XP through the real progression path (EconomyManager has no add_xp).
	var xp_amt: int = int(achievement[0].get("xp", 0))
	if XPManager:
		XPManager.award_amount(xp_amt, "achievement:%s" % id)
	elif PlayerProfile:
		PlayerProfile.add_xp(xp_amt)
	if NotificationUI:
		NotificationUI.notify_achievement(str(achievement[0].get("name", id)))

func get_all_achievements() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for a in ACHIEVEMENTS:
		var entry = a.duplicate()
		entry["unlocked"] = a.id in _unlocked
		entry["unlock_time"] = _unlocked.get(a.id, 0)
		result.append(entry)
	return result

func get_unlocked_count() -> int:
	return _unlocked.size()

func _save_achievements() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_unlocked))

func _load_achievements() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			_unlocked = parsed
