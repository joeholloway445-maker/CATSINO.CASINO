class_name TitleData
# All earnable titles in the game

const TITLES: Array[Dictionary] = [
	{id="newcomer", name="Newcomer", desc="Starting title", unlock="default"},
	{id="gamer", name="Gamer", desc="Win your first game", unlock="achievement:first_win"},
	{id="lucky", name="Lucky Cat", desc="Win 10 games", unlock="achievement:win_10"},
	{id="veteran", name="Veteran", desc="Win 50 games", unlock="achievement:win_50"},
	{id="legend", name="Legend", desc="Win 100 games", unlock="achievement:win_100"},
	{id="explorer", name="Explorer", desc="Visit all districts", unlock="achievement:visit_district"},
	{id="champion", name="Arena Champion", desc="Win 10 battles", unlock="achievement:arena_champion"},
	{id="tycoon", name="Casino Tycoon", desc="Win 10000 coins", unlock="achievement:big_win"},
	{id="sc_loyalist", name="Crown Loyalist", desc="Join SovereignCrown", unlock="faction:SovereignCrown"},
	{id="wa_ranger", name="Wild Ranger", desc="Join WildlandsAscendant", unlock="faction:WildlandsAscendant"},
	{id="vc_current", name="Currentwalker", desc="Join VeiledCurrent", unlock="faction:VeiledCurrent"},
	{id="fl_free", name="The Unchained", desc="Remain Factionless", unlock="faction:none"},
	{id="master", name="Master", desc="Reach level 25", unlock="achievement:reach_level_25"},
	{id="grandmaster", name="Grandmaster", desc="Reach level 50", unlock="achievement:reach_level_50"},
	{id="blackjack_pro", name="Blackjack Pro", desc="Hit blackjack", unlock="achievement:blackjack"},
	{id="racer", name="Speed Demon", desc="Win a race", unlock="achievement:race_podium"},
	{id="collector", name="Companion Master", desc="Collect 50 companions", unlock="achievement:collect_50_companions"},
	{id="daily_hero", name="Daily Hero", desc="7-day streak", unlock="achievement:daily_streak_7"},
	{id="questmaster", name="Questmaster", desc="Complete 10 quests", unlock="achievement:complete_10_quests"},
	{id="puzzle_king", name="Puzzle King", desc="Score 500 in cat puzzle", unlock="achievement:arcade_champion"},
]

static func get_title(title_id: String) -> Dictionary:
	for t in TITLES:
		if t.id == title_id: return t.duplicate()
	return {}

static func get_titles_for_faction(faction: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for t in TITLES:
		if ("faction:%s" % faction) in t.get("unlock", ""):
			result.append(t.duplicate())
	return result
