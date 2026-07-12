extends Node

# ── Signals ────────────────────────────────────────────────────────────────────
signal companion_evolved(companion_id: int, new_level: int)
signal milestone_tracked(companion_id: int, milestone: String)
signal roster_loaded(count: int)

# ── Inner Class ────────────────────────────────────────────────────────────────
class CompanionData:
	var id:              int
	var companion_name:  String
	var faction:         String
	var rarity:          String  # Common, Uncommon, Rare, Epic, Legendary
	var level:           int
	var milestone_count: int
	var milestones:      Array[String]
	var xp:              int
	var xp_to_next:      int
	var is_unlocked:     bool

	func _init(p_id: int, p_name: String, p_faction: String, p_rarity: String) -> void:
		id              = p_id
		companion_name  = p_name
		faction         = p_faction
		rarity          = p_rarity
		level           = 1
		milestone_count = 0
		milestones      = []
		xp              = 0
		xp_to_next      = _xp_curve(1)
		is_unlocked     = false

	func _xp_curve(lvl: int) -> int:
		return int(100 * pow(1.2, lvl - 1))

	func to_dict() -> Dictionary:
		return {
			"id":             id,
			"name":           companion_name,
			"faction":        faction,
			"rarity":         rarity,
			"level":          level,
			"milestone_count":milestone_count,
			"milestones":     milestones,
			"xp":             xp,
			"is_unlocked":    is_unlocked,
		}

# ── Constants ──────────────────────────────────────────────────────────────────
const MAX_COMPANIONS   := 450
const FACTIONS := ["Factionless", "SovereignCrown", "VeiledCurrent", "WildlandsAscendant"]
const RARITIES := ["Common", "Uncommon", "Rare", "Epic", "Legendary"]

const FACTION_SYNERGY_BONUSES: Dictionary = {
	"Factionless":         0.00,
	"SovereignCrown":      0.12,
	"VeiledCurrent":       0.10,
	"WildlandsAscendant":  0.15,
}

# ── State ──────────────────────────────────────────────────────────────────────
var roster: Array[CompanionData] = []
var _companion_index: Dictionary = {}  # id -> CompanionData

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_generate_roster()
	_load_progress()

func initialize() -> void:
	emit_signal("roster_loaded", roster.size())

# ── Public API ─────────────────────────────────────────────────────────────────
# companion_id is untyped: the roster indexes by int, but quest/battlepass
# rewards pass string ids from other id schemes — those resolve to null and
# no-op with a warning instead of hard-crashing on the typed signature.
func get_companion(companion_id) -> CompanionData:
	return _companion_index.get(companion_id, null)

func unlock_companion(companion_id) -> void:
	var c := get_companion(companion_id)
	if c:
		c.is_unlocked = true
		_save_progress()
	else:
		push_warning("CompanionSystem: unlock_companion(%s) — id not in roster, skipping" % str(companion_id))

func evolve(companion_id: int) -> void:
	var c := get_companion(companion_id)
	if not c or not c.is_unlocked:
		push_warning("CompanionSystem: evolve called on invalid/locked companion %d" % companion_id)
		return
	c.level       += 1
	c.xp_to_next   = c._xp_curve(c.level)
	emit_signal("companion_evolved", companion_id, c.level)
	_save_progress()

func add_xp(companion_id: int, amount: int) -> void:
	var c := get_companion(companion_id)
	if not c or not c.is_unlocked:
		return
	c.xp += amount
	while c.xp >= c.xp_to_next:
		c.xp -= c.xp_to_next
		evolve(companion_id)

func track_milestone(companion_id: int, milestone: String) -> void:
	var c := get_companion(companion_id)
	if not c:
		return
	if milestone not in c.milestones:
		c.milestones.append(milestone)
		c.milestone_count += 1
		emit_signal("milestone_tracked", companion_id, milestone)
		_save_progress()

func get_faction_synergy_bonus(player_faction: String) -> float:
	# Count unlocked companions matching player faction
	var matching := 0
	var total_unlocked := 0
	for c: CompanionData in roster:
		if c.is_unlocked:
			total_unlocked += 1
			if c.faction == player_faction:
				matching += 1
	if total_unlocked == 0:
		return 0.0
	var base_bonus: float = FACTION_SYNERGY_BONUSES.get(player_faction, 0.0)
	var density_bonus := float(matching) / float(total_unlocked) * 0.20
	return base_bonus + density_bonus

func get_unlocked_companions() -> Array[CompanionData]:
	var result: Array[CompanionData] = []
	for c: CompanionData in roster:
		if c.is_unlocked:
			result.append(c)
	return result

func get_companions_by_faction(faction: String) -> Array[CompanionData]:
	var result: Array[CompanionData] = []
	for c: CompanionData in roster:
		if c.faction == faction:
			result.append(c)
	return result

# ── Private ────────────────────────────────────────────────────────────────────
func _generate_roster() -> void:
	roster.clear()
	_companion_index.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("CATSINO")  # deterministic

	# Name fragments for procedural generation
	var prefixes := ["Shadow", "Storm", "Ember", "Frost", "Neon", "Void", "Solar",
	                  "Lunar", "Crimson", "Azure", "Vex", "Null", "Prime", "Arc",
	                  "Echo", "Flux", "Surge", "Drift", "Haze", "Bolt"]
	var suffixes := ["Paw", "Fang", "Claw", "Tail", "Mane", "Eye", "Whisker",
	                  "Stride", "Leap", "Prowl", "Snarl", "Purr", "Roar",
	                  "Scratch", "Hiss", "Sprint", "Lunge", "Dash", "Glide", "Pounce"]

	for i in range(MAX_COMPANIONS):
		var faction: String = FACTIONS[rng.randi() % FACTIONS.size()]
		var rarity_roll := rng.randf()
		var rarity: String
		if   rarity_roll < 0.40: rarity = "Common"
		elif rarity_roll < 0.65: rarity = "Uncommon"
		elif rarity_roll < 0.85: rarity = "Rare"
		elif rarity_roll < 0.95: rarity = "Epic"
		else:                    rarity = "Legendary"
		var name_str: String = str(prefixes[rng.randi() % prefixes.size()]) + \
		               str(suffixes[rng.randi() % suffixes.size()])
		var c := CompanionData.new(i, name_str, faction, rarity)
		roster.append(c)
		_companion_index[i] = c

func _save_progress() -> void:
	var data: Array = []
	for c: CompanionData in roster:
		if c.is_unlocked or c.milestone_count > 0:
			data.append(c.to_dict())
	var f := FileAccess.open("user://companion_progress.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func _load_progress() -> void:
	if not FileAccess.file_exists("user://companion_progress.json"):
		return
	var f := FileAccess.open("user://companion_progress.json", FileAccess.READ)
	if not f:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if not parsed is Array:
		return
	for entry: Dictionary in parsed:
		var id: int = entry.get("id", -1)
		var c := get_companion(id)
		if c:
			c.is_unlocked     = entry.get("is_unlocked", false)
			c.level           = entry.get("level", 1)
			c.xp              = entry.get("xp", 0)
			c.milestone_count = entry.get("milestone_count", 0)
			c.milestones      = entry.get("milestones", [])
