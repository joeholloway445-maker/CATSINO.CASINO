extends Node
# Live events: double XP, jackpot hour, faction wars, bonus spin windows

signal event_started(event: Dictionary)
signal event_ended(event_id: String)

const EVENTS: Array[Dictionary] = [
	{
		id="jackpot_hour",
		name="Jackpot Hour 🎰",
		desc="Slot payouts doubled for 1 hour",
		duration_seconds=3600,
		effect="slot_mult_x2",
		icon="🎰",
	},
	{
		id="double_xp",
		name="Double XP Weekend",
		desc="All XP rewards doubled",
		duration_seconds=172800,
		effect="xp_x2",
		icon="⚡",
	},
	{
		id="faction_war",
		name="Faction War",
		desc="Compete for faction dominance. Top faction earns bonus coins.",
		duration_seconds=86400,
		effect="faction_score_boost",
		icon="⚔️",
	},
	{
		id="companion_safari",
		name="Companion Safari 🐾",
		desc="New companions appear in the wild. Unlock chance increased.",
		duration_seconds=43200,
		effect="companion_unlock_boost",
		icon="🐾",
	},
	{
		id="lucky_streak",
		name="Lucky Streak 🍀",
		desc="LCK stat contributes 50% more in all games",
		duration_seconds=7200,
		effect="lck_boost_50",
		icon="🍀",
	},
	{
		id="neon_race_cup",
		name="Neon Race Cup 🏁",
		desc="Race entry fees waived, top 3 win bonus coins",
		duration_seconds=10800,
		effect="race_free_entry",
		icon="🏁",
	},
	{
		id="void_surge",
		name="Void Surge ⚫",
		desc="Void-element companions gain +50% stats",
		duration_seconds=5400,
		effect="void_stat_boost",
		icon="⚫",
	},
]

var _active_events: Dictionary = {}

func _ready() -> void:
	_schedule_events()

func _schedule_events() -> void:
	# Cycle events deterministically based on current day/hour
	var unix = int(Time.get_unix_time_from_system())
	var hour_slot = (unix / 3600) % EVENTS.size()
	var event = EVENTS[hour_slot]
	_start_event(event)

func _start_event(event: Dictionary) -> void:
	var eid = event.get("id", "")
	if eid in _active_events: return
	_active_events[eid] = {
		"event": event,
		"started_at": Time.get_unix_time_from_system(),
		"ends_at": Time.get_unix_time_from_system() + event.get("duration_seconds", 3600),
	}
	event_started.emit(event)
	var timer = get_tree().create_timer(float(event.get("duration_seconds", 3600)))
	timer.timeout.connect(func(): _end_event(eid))

func _end_event(event_id: String) -> void:
	_active_events.erase(event_id)
	event_ended.emit(event_id)

func get_active_events() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for eid in _active_events:
		result.append(_active_events[eid])
	return result

func is_effect_active(effect: String) -> bool:
	for eid in _active_events:
		if _active_events[eid].get("event", {}).get("effect", "") == effect:
			return true
	return false

func get_slot_multiplier() -> float:
	return 2.0 if is_effect_active("slot_mult_x2") else 1.0

func get_xp_multiplier() -> float:
	return 2.0 if is_effect_active("xp_x2") else 1.0

func get_lck_boost() -> float:
	return 1.5 if is_effect_active("lck_boost_50") else 1.0
