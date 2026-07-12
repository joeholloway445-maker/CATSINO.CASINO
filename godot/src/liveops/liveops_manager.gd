extends Node

# ── Signals ────────────────────────────────────────────────────────────────────
signal event_started(event: Dictionary)
signal event_ended(event_id: String)
signal battlepass_tier_unlocked(tier: int, premium: bool, rewards: Array)
signal season_changed(season_number: int)
signal xp_gained(amount: int, source: String)

# ── Constants ──────────────────────────────────────────────────────────────────
const MAX_BATTLEPASS_TIERS := 100
const SEASON_CACHE_PATH    := "user://liveops_cache.json"

# ── Inner Classes ──────────────────────────────────────────────────────────────
class LiveEvent:
	var id:          String
	var name:        String
	var description: String
	var start_time:  int   # Unix timestamp
	var end_time:    int
	var event_type:  String  # "tournament", "double_xp", "limited_game", "seasonal"
	var requirements: Dictionary
	var rewards:     Array[Dictionary]
	var is_active:   bool

	func _init(p_id: String, p_name: String, p_type: String) -> void:
		id         = p_id
		name       = p_name
		event_type = p_type
		requirements = {}
		rewards    = []
		is_active  = false

	func to_dict() -> Dictionary:
		return {
			"id":           id,
			"name":         name,
			"description":  description,
			"event_type":   event_type,
			"start_time":   start_time,
			"end_time":     end_time,
			"is_active":    is_active,
		}

# ── State ──────────────────────────────────────────────────────────────────────
var active_events:   Array[LiveEvent]   = []
var all_events:      Array[LiveEvent]   = []
var season_number:   int                = 1
var season_end_time: int                = 0
var battlepass_xp:   int                = 0
var battlepass_tier: int                = 0  # Current tier (0-indexed)
var has_premium_pass: bool              = false
var _claimed_tiers:  Array[int]         = []
var _claimed_premium_tiers: Array[int]  = []

# Battlepass tiers: tier -> {free_reward, premium_reward, xp_required}
var battlepass_tiers: Array[Dictionary] = []

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_generate_battlepass_tiers()
	_load_cache()

func initialize() -> void:
	await _fetch_live_data()
	_check_events()

# ── Events ─────────────────────────────────────────────────────────────────────
func get_active_events() -> Array[LiveEvent]:
	return active_events

func check_event_eligibility(player_data: Dictionary) -> bool:
	for event: LiveEvent in active_events:
		if not event.is_active:
			continue
		var reqs := event.requirements
		if "min_level" in reqs and player_data.get("level", 1) < reqs["min_level"]:
			continue
		if "faction" in reqs and player_data.get("faction", "") != reqs["faction"]:
			continue
		return true
	return active_events.size() > 0

func get_event(event_id: String) -> LiveEvent:
	for event: LiveEvent in all_events:
		if event.id == event_id:
			return event
	return null

# ── Battlepass ─────────────────────────────────────────────────────────────────
func get_battlepass_tier() -> int:
	return battlepass_tier

func get_battlepass_xp() -> int:
	return battlepass_xp

func get_xp_for_tier(tier: int) -> int:
	if tier < battlepass_tiers.size():
		return battlepass_tiers[tier].get("xp_required", 1000)
	return 1000

func add_battlepass_xp(amount: int, source: String = "gameplay") -> void:
	battlepass_xp += amount
	emit_signal("xp_gained", amount, source)
	# Check tier unlocks
	while battlepass_tier < MAX_BATTLEPASS_TIERS - 1:
		var next_tier := battlepass_tier + 1
		var needed    := get_xp_for_tier(next_tier)
		if battlepass_xp >= needed:
			battlepass_xp -= needed
			battlepass_tier = next_tier
			var tier_data := battlepass_tiers[next_tier] if next_tier < battlepass_tiers.size() else {}
			emit_signal("battlepass_tier_unlocked", next_tier, false, tier_data.get("free_rewards", []))
		else:
			break
	_save_cache()

func claim_battlepass_reward(tier: int, premium: bool) -> Dictionary:
	if premium and not has_premium_pass:
		push_warning("LiveOpsManager: player does not have premium pass")
		return {}
	if tier > battlepass_tier:
		push_warning("LiveOpsManager: tier %d not yet unlocked (current: %d)" % [tier, battlepass_tier])
		return {}
	var claimed_list := _claimed_premium_tiers if premium else _claimed_tiers
	if tier in claimed_list:
		push_warning("LiveOpsManager: tier %d already claimed (premium=%s)" % [tier, premium])
		return {}
	claimed_list.append(tier)
	var tier_data := battlepass_tiers[tier] if tier < battlepass_tiers.size() else {}
	var reward_key := "premium_rewards" if premium else "free_rewards"
	var rewards = tier_data.get(reward_key, [])
	# Distribute rewards via EconomyManager
	for reward: Dictionary in rewards:
		if reward.get("type") == "coins":
			EconomyManager.earn_coins(reward.get("amount", 0), "battlepass_t%d" % tier)
		elif reward.get("type") == "gems":
			EconomyManager.earn_gems(reward.get("amount", 0), "battlepass_t%d" % tier)
	_save_cache()
	return {"tier": tier, "premium": premium, "rewards": rewards}

func unlock_premium_pass() -> void:
	has_premium_pass = true
	_save_cache()

# ── Season ─────────────────────────────────────────────────────────────────────
func get_season_number() -> int:
	return season_number

func get_season_end_date() -> String:
	return Time.get_datetime_string_from_unix_time(season_end_time)

func days_remaining_in_season() -> int:
	var now := int(Time.get_unix_time_from_system())
	return maxi(0, (season_end_time - now) / 86400)

# ── Private ────────────────────────────────────────────────────────────────────
func _generate_battlepass_tiers() -> void:
	battlepass_tiers.clear()
	var coin_rewards := [100, 250, 500, 1000, 2500, 5000, 10000, 25000]
	var gem_rewards  := [5, 10, 25, 50, 100]
	for i in range(MAX_BATTLEPASS_TIERS):
		var xp_req := 1000 + i * 200
		battlepass_tiers.append({
			"tier":         i,
			"xp_required":  xp_req,
			"free_rewards": [{"type": "coins", "amount": coin_rewards[i % coin_rewards.size()]}],
			"premium_rewards": [
				{"type": "coins", "amount": coin_rewards[i % coin_rewards.size()] * 2},
				{"type": "gems",  "amount": gem_rewards[i % gem_rewards.size()]},
			],
		})

func _fetch_live_data() -> void:
	if not AccountManager or not AccountManager.is_authenticated:
		_load_mock_events()
		return
	# In production: fetch from Nakama storage or custom RPC
	_load_mock_events()

func _load_mock_events() -> void:
	all_events.clear()
	var now := int(Time.get_unix_time_from_system())
	var events_data := [
		{"id": "double_xp_weekend", "name": "Double XP Weekend",  "type": "double_xp"},
		{"id": "slots_tourney_01",  "name": "Grand Slots Tourney", "type": "tournament"},
		{"id": "cat_festival",      "name": "Cat Festival",        "type": "seasonal"},
	]
	for data: Dictionary in events_data:
		var e := LiveEvent.new(data["id"], data["name"], data["type"])
		e.description = "Special limited event: %s" % data["name"]
		e.start_time  = now - 3600
		e.end_time    = now + 86400 * 7
		e.is_active   = true
		all_events.append(e)
	_check_events()

func _check_events() -> void:
	var now := int(Time.get_unix_time_from_system())
	active_events.clear()
	for event: LiveEvent in all_events:
		if event.start_time <= now and event.end_time > now:
			if not event.is_active:
				event.is_active = true
				emit_signal("event_started", event.to_dict())
			active_events.append(event)
		elif event.is_active and event.end_time <= now:
			event.is_active = false
			emit_signal("event_ended", event.id)

func _save_cache() -> void:
	var data := {
		"battlepass_xp":           battlepass_xp,
		"battlepass_tier":         battlepass_tier,
		"has_premium_pass":        has_premium_pass,
		"claimed_tiers":           _claimed_tiers,
		"claimed_premium_tiers":   _claimed_premium_tiers,
		"season_number":           season_number,
		"season_end_time":         season_end_time,
	}
	var f := FileAccess.open(SEASON_CACHE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func _load_cache() -> void:
	if not FileAccess.file_exists(SEASON_CACHE_PATH):
		season_end_time = int(Time.get_unix_time_from_system()) + 86400 * 90
		return
	var f := FileAccess.open(SEASON_CACHE_PATH, FileAccess.READ)
	if not f:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if not parsed is Dictionary:
		return
	battlepass_xp           = parsed.get("battlepass_xp", 0)
	battlepass_tier         = parsed.get("battlepass_tier", 0)
	has_premium_pass        = parsed.get("has_premium_pass", false)
	_claimed_tiers          = parsed.get("claimed_tiers", [])
	_claimed_premium_tiers  = parsed.get("claimed_premium_tiers", [])
	season_number           = parsed.get("season_number", 1)
	season_end_time         = parsed.get("season_end_time", int(Time.get_unix_time_from_system()) + 86400 * 90)
