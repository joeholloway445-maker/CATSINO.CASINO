class_name DialogueData
# Extended dialogue trees for all 16 NPCs

const DIALOGUES: Dictionary = {
	"dealer_dev": [
		"Welcome to the main floor! The odds are always interesting here.",
		"We run 7 games here. Slots, blackjack, poker, fortune wheel... you name it.",
		"My personal tip? Always watch your balance. The house edge is real.",
		"The SovereignCrown has a stake in three of our tables. Food for thought.",
	],
	"lucky_lira": [
		"I've been on a 12-game win streak. The secret? Companion synergy.",
		"Get three VeiledCurrent companions equipped — the LCK bonus is insane.",
		"Heard you're new here. Talk to Forest Elder Moss. Trust me.",
		"A 50-pull pity system exists in the gacha. Don't tell the house.",
	],
	"crown_rep": [
		"The SovereignCrown is always looking for exceptional talent.",
		"We offer the highest combat bonuses of any faction. Seventeen percent.",
		"Join us and you'll never face the arena alone.",
		"The Sovereign Frame... let's say there are perks to loyalty.",
	],
	"slot_sam": [
		"Potions, boosts, and lucky charms. Everything you need to beat the house.",
		"The Luck Charm stacks with your companion LCK bonus. Just saying.",
		"Slot Multiplier ×2 during Jackpot Hour? Now you're thinking smart.",
		"I've seen people turn 100 coins into 100,000. I've seen the opposite more.",
	],
	"mystery_cat": [
		"...",
		"You can feel it, can't you? The pattern beneath the pattern.",
		"Find the Forest Elder. Before the next Faction War.",
		"...",
	],
	"arena_guard": [
		"Only the worthy enter the arena. Show me your power.",
		"Light beats Heavy. Heavy beats Tech. Tech beats Light. Master the triangle.",
		"Champion Vex hasn't lost in sixty matches. Something to aspire to.",
		"Bring your best frame. The arena doesn't forgive the underprepared.",
	],
	"coach_mira": [
		"Light beats Heavy. Heavy beats Tech. Tech beats Light. Never forget it.",
		"Your companion synergy adds to your combat stats. Check it before every fight.",
		"The Sleeper Burst activates when LCK hits 80 and synergy's above 20%. Devastating.",
		"Vex uses a balanced frame with a Crown Jewel mod. Adapt accordingly.",
	],
	"champion_vex": [
		"You want to challenge me? Admirable. Foolish. But admirable.",
		"I've studied every frame in the game. There are no surprises left.",
		"Win the Grand Tournament quest first. Then we'll talk.",
		"The Sovereign Frame. Yes, I have one. No, I won't tell you where I got it.",
	],
	"aqua_merchant": [
		"Fresh off the canal. Speed frames, race boosters, everything.",
		"The Bolt Frame is great for beginners. Wind Frame if you want to dominate.",
		"Race Nitro stacks with your SPD stat for the next race segment.",
		"The VeiledCurrent controls these waterways. Which is why I pay good coins.",
	],
	"race_starter": [
		"Today's track: Neon Canal Circuit. Entry fee: 200 coins.",
		"First place pays 3× your bet. Second gets 1.5×. Third goes home sad.",
		"Four racers per heat. Three AI, one you. May the fastest frame win.",
		"The Wind Frame hasn't lost on this circuit in three weeks. Consider upgrading.",
	],
	"veiled_scout": [
		"The Current flows through everything. You just have to learn to feel it.",
		"Our LCK bonus is the highest in the game. Coincidence? We don't believe in those.",
		"The VeiledCurrent has eyes in every district. Even this one.",
		"Join us. The water remembers those who respect it.",
	],
	"forest_elder": [
		"The forest has been here longer than any faction. It will outlast them too.",
		"The 500 companions aren't legend. They're real. Most just haven't been found.",
		"Your faction shapes your path. But the Factionless have a path of their own.",
		"Come back when you've completed the Forest Mystery. I have something for you.",
	],
	"wildlands_ranger": [
		"The WildlandsAscendant welcomes those who respect the forest.",
		"Our combat bonus is 12%. Our race speed bonus is the best in game.",
		"We have 150 companions unique to our faction. Each one earned, not bought.",
		"The forest is alive. The companions you find here will feel it.",
	],
	"companion_keeper": [
		"I've catalogued every companion in the forest. 500 in total, if you count the Factionless ones.",
		"Feed your companions regularly. A fed companion gains levels. A leveled companion evolves.",
		"Evolution costs 5,000 coins and an Evolution Crystal. Worth every bit.",
		"Legendary companions have been sighted near the ancient grove. Full moon only.",
	],
	"arcade_host": [
		"Welcome to the Arcade Galaxy! No one knows how it got here. No one's asking.",
		"We have Cat Puzzle, Fortune Wheel, Scratch Cards, and Paw Poker.",
		"Score 500 in Cat Puzzle and something interesting happens. I'm told.",
		"The Puzzle Master has been here for years. Has he left? I genuinely don't know.",
	],
	"puzzle_master": [
		"The cat puzzle is deceptively simple. I've been playing it for 200 hours.",
		"Match 3 to clear. Match 5 for a bonus clear. Match 7... don't worry about 7.",
		"Your score determines your payout. 50, 150, 300, 500. Plan accordingly.",
		"I once saw a 12-chain combo. I haven't been the same since.",
	],
}

static func get_lines(npc_id: String) -> Array[String]:
	var result: Array[String] = []
	if DIALOGUES.has(npc_id):
		for line in DIALOGUES[npc_id]:
			result.append(line)
	return result

static func get_random_line(npc_id: String) -> String:
	var lines := get_lines(npc_id)
	if lines.is_empty(): return "..."
	return lines[randi() % lines.size()]
