class_name NPCDialogue
# Static dialogue trees for world NPCs by district

const DIALOGUES: Dictionary = {
	"paw_vegas": [
		{
			npc_id="pvg_merchant", name="Gilded Merchant Voss", faction="SovereignCrown", emoji="🪙",
			lines=[
				"Welcome to Paws Vegas! Coins flow like water here — make sure yours flows toward you.",
				"The SovereignCrown controls the finest establishments. Shop wisely, friend.",
				"I've seen cats arrive with nothing and leave with empires. And the reverse. Often the reverse.",
				"Looking for companions? Check the Companion Hall on the east side of the district.",
			],
			quest_trigger="",
		},
		{
			npc_id="pvg_informant", name="Whisper Syx", faction="Factionless", emoji="🌀",
			lines=[
				"*glances around* You look new. Good. New cats don't have enemies yet.",
				"The VeiledCurrent is up to something in Neon Alley. Just thought you should know.",
				"Factionless is the smartest faction. We get to watch everyone else fight.",
				"Daily bonuses are your best friend. Don't forget them.",
			],
			quest_trigger="main_003",
		},
		{
			npc_id="pvg_guard", name="Crown Guard Rax", faction="SovereignCrown", emoji="👑",
			lines=[
				"Move along, citizen. The Crown's peace must be maintained.",
				"Cat Coliseum is accepting challengers. Have you the courage?",
				"All paths in Paws Vegas lead back to the Crown. Remember that.",
			],
			quest_trigger="",
		},
		{
			npc_id="pvg_scholar", name="Scholar Luminara", faction="Factionless", emoji="📚",
			lines=[
				"Fascinating! I'm documenting all companion species in Paws Vegas.",
				"Did you know there are 200 named companions across all four factions?",
				"The race bloodlines are ancient. Each has unique affinities — study them well.",
				"I could use your help collecting companion data. What do you say?",
			],
			quest_trigger="side_003",
		},
	],
	"neon_alley": [
		{
			npc_id="na_racer", name="Speed Queen Zira", faction="VeiledCurrent", emoji="🌊",
			lines=[
				"You race? Or you just watch others race?",
				"Neon Alley belongs to the VeiledCurrent. The current carries us to victory.",
				"SPD is everything here. If your build isn't fast, you're not a racer.",
				"I'll race you anytime. But don't cry when you lose.",
			],
			quest_trigger="side_002",
		},
		{
			npc_id="na_mechanic", name="Wrench Glitch", faction="Factionless", emoji="🔧",
			lines=[
				"Custom mods? I've got everything. For a price.",
				"Mods can push your build beyond its natural limits. Temporarily.",
				"My workshop is the best in Neon Alley. The only one, actually.",
			],
			quest_trigger="",
		},
		{
			npc_id="na_bookie", name="Odds Maker Fenn", faction="Factionless", emoji="🎲",
			lines=[
				"I give better odds than the house. Don't tell the house.",
				"Racing predictions? The current flows, but luck flows stronger.",
				"Place your bets before the lights go green. House rules.",
			],
			quest_trigger="",
		},
	],
	"cat_coliseum": [
		{
			npc_id="cc_champion", name="The Champion", faction="SovereignCrown", emoji="⚔️",
			lines=[
				"You seek glory? The Coliseum has plenty. Take it if you can.",
				"Five tiers stand between you and the championship. Each harder than the last.",
				"I've held this title for 40 seasons. Come take it from me.",
			],
			quest_trigger="main_002",
		},
		{
			npc_id="cc_trainer", name="Elder Strategist Mox", faction="Factionless", emoji="🧠",
			lines=[
				"Combat is not just power. It is timing, faction awareness, and synergy.",
				"Learn the triangle: Light beats Heavy, Heavy beats Tech, Tech beats Light.",
				"Your companion roster matters as much as your own stats in team battles.",
				"A sleeper burst at 80+ LCK can turn any match. Keep your luck high.",
			],
			quest_trigger="",
		},
		{
			npc_id="cc_announcer", name="Commentator Prisma", faction="Factionless", emoji="📣",
			lines=[
				"WELCOME to Cat Coliseum! Tonight's battles will be LEGENDARY!",
				"The crowd wants blood! Metaphorically. Mostly.",
				"Sign up for the next tournament at the registration desk. Prize pool is massive!",
			],
			quest_trigger="",
		},
	],
	"arcade_galaxy": [
		{
			npc_id="ag_operator", name="Manager Byte", faction="Factionless", emoji="🕹️",
			lines=[
				"Every machine in Arcade Galaxy is fair. Mostly.",
				"The Coin Pusher is the most popular. And the most addictive. You've been warned.",
				"Jackpots happen. Someone wins big every day. Today could be you.",
			],
			quest_trigger="",
		},
		{
			npc_id="ag_veteran", name="Old Timer Crisp", faction="Factionless", emoji="🎯",
			lines=[
				"I've been playing here since this place opened. Still haven't won big.",
				"The wheel has 8 segments. The jackpot is one of them. Simple math.",
				"Scratch cards have the best variance. High risk, high reward.",
			],
			quest_trigger="side_001",
		},
	],
	"cat_forest": [
		{
			npc_id="cf_ranger", name="Forest Ranger Bloom", faction="WildlandsAscendant", emoji="🌿",
			lines=[
				"The Forest is not for the weak. It tests you. It shapes you.",
				"WildlandsAscendant are born from this place. RES is our way of life.",
				"There's an artifact deep in the forest. Few have found it. Fewer returned.",
			],
			quest_trigger="main_004",
		},
		{
			npc_id="cf_hermit", name="Hermit Mosswhisker", faction="Factionless", emoji="🍄",
			lines=[
				"*stares at a mushroom for 10 seconds* ...What were we talking about?",
				"The forest remembers everything. Every fight. Every coin spent.",
				"Companions found in the forest are the strongest. But they test you first.",
			],
			quest_trigger="",
		},
		{
			npc_id="cf_wildcat", name="Wild Cat Krix", faction="WildlandsAscendant", emoji="🐆",
			lines=[
				"No faction born us. The wilderness claimed us. That is enough.",
				"RES is not just endurance. It is the will to rise after every fall.",
				"Defeat enough wild creatures here and you'll earn our respect.",
			],
			quest_trigger="faction_wa_001",
		},
	],
}

static func get_district_npcs(district: String) -> Array[Dictionary]:
	if district in DIALOGUES:
		return DIALOGUES[district]
	return []

static func get_npc_lines(district: String, npc_id: String) -> Array[String]:
	var npcs = get_district_npcs(district)
	for npc in npcs:
		if npc.get("npc_id", "") == npc_id:
			return npc.get("lines", [])
	return []

static func get_npc_quest(district: String, npc_id: String) -> String:
	var npcs = get_district_npcs(district)
	for npc in npcs:
		if npc.get("npc_id", "") == npc_id:
			return npc.get("quest_trigger", "")
	return ""
