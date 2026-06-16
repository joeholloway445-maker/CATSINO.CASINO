extends Node

class_name LiveOpsManager

# ── Battlepass ────────────────────────────────────────────────────────────────
const MAX_BP_TIERS := 100
const BP_XP_PER_TIER := 1000

class BattlepassTier:
	var tier: int
	var free_reward: Dictionary   # {type, amount/item_id}
	var premium_reward: Dictionary
	var claimed_free := false
	var claimed_premium := false

class Battlepass:
	var season: int = 1
	var xp: int = 0
	var current_tier: int = 0
	var premium_unlocked := false
	var tiers: Array[BattlepassTier] = []

# ── Event ─────────────────────────────────────────────────────────────────────
class LiveEvent:
	var id: String
	var name: String
	var description: String
	var start_time: int   # unix timestamp
	var end_time: int
	var reward: Dictionary
	var eligibility_level: int = 1
	var active := false

	func is_live() -> bool:
		var now := Time.get_unix_time_from_system()
		return now >= start_time and now <= end_time

# ── State ─────────────────────────────────────────────────────────────────────
var _battlepass: Battlepass = Battlepass.new()
var _events: Array[LiveEvent] = []
var _season: int = 1
var _season_end: int = 0
var _initialized := false

# ── Signals ───────────────────────────────────────────────────────────────────
signal event_started(event_id: String)
signal event_ended(event_id: String)
signal battlepass_tier_unlocked(tier: int)
signal battlepass_xp_gained(amount: int, total: int)
signal season_ended(season: int)
signal reward_claimed(reward: Dictionary)

# ── Init ──────────────────────────────────────────────────────────────────────
func initialize() -> void:
	if _initialized:
		return
	_seed_battlepass()
	_seed_events()
	_initialized = true
	print("[LiveOpsManager] Season %d, %d events, %d BP tiers" % [
		_season, _events.size(), _battlepass.tiers.size()
	])

func _seed_battlepass() -> void:
	_battlepass.season = _season
	for i in range(MAX_BP_TIERS):
		var tier := BattlepassTier.new()
		tier.tier = i + 1
		tier.free_reward = {"type": "coins", "amount": 100 + i * 25}
		tier.premium_reward = {
			"type": "gems" if i % 5 == 0 else "cosmetic",
			"amount": 50 if i % 5 == 0 else 1,
			"item_id": "bp_s%d_t%d_premium" % [_season, i + 1]
		}
		_battlepass.tiers.append(tier)

func _seed_events() -> void:
	var now := int(Time.get_unix_time_from_system())
	var event_templates := [
		{"id": "paw_parade", "name": "Paw Parade Festival", "eligibility_level": 1,
		 "reward": {"type": "coins", "amount": 5000}},
		{"id": "neon_derby", "name": "Neon Derby Race Week", "eligibility_level": 5,
		 "reward": {"type": "cosmetic", "item_id": "racer_helm_neon"}},
		{"id": "coliseum_clash", "name": "Coliseum Clash Tournament", "eligibility_level": 10,
		 "reward": {"type": "gems", "amount": 200}},
		{"id": "midnight_jackpot", "name": "Midnight Jackpot Hour", "eligibility_level": 1,
		 "reward": {"type": "coins", "amount": 10000}},
		{"id": "forest_quest", "name": "Cat Forest Expedition", "eligibility_level": 3,
		 "reward": {"type": "companion_xp", "amount": 1000}},
	]
	for i in range(event_templates.size()):
		var ev := LiveEvent.new()
		var tmpl: Dictionary = event_templates[i]
		ev.id = tmpl["id"]
		ev.name = tmpl["name"]
		ev.description = "A limited-time event in CATSINO.CASINO"
		ev.start_time = now - 3600  # started 1hr ago
		ev.end_time = now + 86400 * 7  # 7 days from now
		ev.reward = tmpl["reward"]
		ev.eligibility_level = tmpl["eligibility_level"]
		ev.active = true
		_events.append(ev)

# ── Battlepass ────────────────────────────────────────────────────────────────
func add_battlepass_xp(amount: int) -> void:
	_battlepass.xp += amount
	battlepass_xp_gained.emit(amount, _battlepass.xp)
	var new_tier := _battlepass.xp / BP_XP_PER_TIER
	if new_tier > _battlepass.current_tier:
		_battlepass.current_tier = new_tier
		battlepass_tier_unlocked.emit(new_tier)

func claim_battlepass_reward(tier_idx: int, premium: bool) -> bool:
	if tier_idx < 0 or tier_idx >= _battlepass.tiers.size():
		return false
	var tier: BattlepassTier = _battlepass.tiers[tier_idx]
	if tier.tier > _battlepass.current_tier + 1:
		return false  # not yet unlocked
	if premium:
		if not _battlepass.premium_unlocked:
			push_warning("[LiveOpsManager] Premium BP not unlocked")
			return false
		if tier.claimed_premium:
			return false
		tier.claimed_premium = true
		reward_claimed.emit(tier.premium_reward)
		EconomyManager.grant(tier.premium_reward)
	else:
		if tier.claimed_free:
			return false
		tier.claimed_free = true
		reward_claimed.emit(tier.free_reward)
		EconomyManager.grant(tier.free_reward)
	return true

func unlock_premium_battlepass() -> void:
	_battlepass.premium_unlocked = true

# ── Events ────────────────────────────────────────────────────────────────────
func get_active_events() -> Array:
	return _events.filter(func(e): return e.is_live())

func check_event_eligibility(event_id: String, player_level: int) -> bool:
	for ev in _events:
		if ev.id == event_id:
			return ev.is_live() and player_level >= ev.eligibility_level
	return false

func get_event(event_id: String) -> LiveEvent:
	for ev in _events:
		if ev.id == event_id:
			return ev
	return null

# ── Season ────────────────────────────────────────────────────────────────────
func get_season() -> int:
	return _season

func get_season_end_timestamp() -> int:
	return _season_end

func get_battlepass() -> Battlepass:
	return _battlepass
