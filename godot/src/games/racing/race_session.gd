class_name RaceSession
## Hand-off stash between the race lobby (race_ui) and the drivable race
## scene, plus the single source of truth for payout math (lobby-simulated
## and driven races pay identically).

static var track: Dictionary = {}
static var bet: int = 0
static var frame_id: String = "veil"

const POSITION_MULT := {1: 3.0, 2: 1.5, 3: 1.0}
const DIFFICULTY_BONUS := {"beginner": 1.0, "intermediate": 1.25, "expert": 1.6}

static func payout(position: int, bet_amount: int, track_data: Dictionary) -> int:
	if position > 3:
		return 0
	var mult: float = POSITION_MULT.get(position, 0.0) \
		* DIFFICULTY_BONUS.get(str(track_data.get("difficulty", "beginner")), 1.0)
	var total := int(bet_amount * mult)
	if position == 1:
		total += int(track_data.get("entry_fee", 0))
	return total
