extends Node
class_name XPManager
# Central XP award routing — all XP goes through here

signal xp_awarded(source: String, amount: int)

const XP_TABLE = {
	"spin_win":          10,
	"spin_play":         3,
	"blackjack_win":     15,
	"blackjack_play":    5,
	"poker_win":         20,
	"poker_play":        7,
	"holdem_win":        25,
	"holdem_play":       8,
	"fortune_win":       12,
	"fortune_play":      4,
	"race_win":          20,
	"race_play":         8,
	"combat_win":        25,
	"combat_play":       10,
	"quest_complete":    50,
	"achievement_unlock": 30,
	"daily_login":       20,
	"companion_evolve":  15,
	"faction_join":      25,
	"tournament_win":    100,
	"tournament_play":   15,
}

func award(source: String, multiplier: float = 1.0) -> int:
	var base = XP_TABLE.get(source, 5)
	var event_mult = EventManager.get_xp_multiplier() if EventManager else 1.0
	var final_xp = int(base * multiplier * event_mult)

	if PlayerProfile:
		PlayerProfile.add_xp(final_xp)
	if BattlePass:
		BattlePass.add_xp(final_xp)

	xp_awarded.emit(source, final_xp)
	return final_xp

func award_game(game: String, won: bool) -> int:
	var play_key = game + "_play"
	var win_key = game + "_win"
	var xp = award(play_key)
	if won:
		xp += award(win_key)
	return xp
