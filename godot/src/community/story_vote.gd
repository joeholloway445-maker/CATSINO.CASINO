extends Node
## Autoloaded as "StoryVote". The Arena's development referendum: players
## vote on where the main storyline, DLCs, and expansions go next. This is
## the "they made it happen" machine — ballots are proposed by the devs
## (or promoted from UGC submissions), one vote per account per ballot,
## results feed the roadmap. Server-side tally goes through Nakama when
## connected; local tally keeps it functional offline.

signal voted(ballot_id: String, option: String)

const SAVE_PATH := "user://story_votes.json"

## Live ballots — edit/extend per season. Promoted UGC proposals append here.
const BALLOTS: Array[Dictionary] = [
	{
		id="s1_next_layer", title="Season 1: which layer gets its expansion first?",
		desc="The winning layer gets the next major content drop.",
		options=["The Periliminal: Deeper Floors", "Extraliminal: Real-World GPS Launch", "The PVXC: Underground Leagues"],
	},
	{
		id="s1_main_story", title="Main story: who opened the first liminal door?",
		desc="Canon will follow the vote. You are writing this world.",
		options=["The first Sovereign, on purpose", "A factionless nobody, by accident", "Hope. It was always Hope."],
	},
	{
		id="s1_dlc_theme", title="First DLC theme",
		desc="The next paid expansion's identity.",
		options=["Naval — the Trinity River floods", "Vertical — the Dallas spires open", "Below — what the PVXC dug into"],
	},
]

var _my_votes: Dictionary = {}  # ballot_id -> option index
var _tallies: Dictionary = {}   # ballot_id -> {option_index: count}

func _ready() -> void:
	_load()

func has_voted(ballot_id: String) -> bool:
	return _my_votes.has(ballot_id)

func vote(ballot_id: String, option_index: int) -> bool:
	if has_voted(ballot_id):
		NotificationUI.notify_error("One vote per account. Yours is cast.")
		return false
	_my_votes[ballot_id] = option_index
	var t: Dictionary = _tallies.get_or_add(ballot_id, {})
	t[option_index] = t.get(option_index, 0) + 1
	_save()
	if NetworkManager.is_connected_to_server():
		NetworkManager.call_rpc("story_vote", {"ballot": ballot_id, "option": option_index}, func(_r): pass)
	EconomyManager.earn_prestige(5, "civic_duty")
	voted.emit(ballot_id, str(option_index))
	NotificationUI.notify_win("🗳️ Vote cast. This world is partly yours now.")
	return true

func tally(ballot_id: String) -> Dictionary:
	return _tallies.get(ballot_id, {})

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify({"mine": _my_votes, "tallies": _tallies}))

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f: return
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		_my_votes = d.get("mine", {})
		_tallies = d.get("tallies", {})
