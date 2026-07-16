class_name NPCData
# All NPC definitions across the 5 districts

const NPCS: Array[Dictionary] = [
	# Paws Vegas NPCs
	{id="dealer_dev", name="Dealer Dev", district="paw_vegas", role="dealer",
	 dialogue_key="dealer_dev", pos=Vector3(5, 0, 3),
	 greeting="Welcome to the main floor! The odds are always interesting here.",
	 quest_ids=[], shop_type="none"},

	{id="lucky_lira", name="Lucky Lira", district="paw_vegas", role="gambler",
	 dialogue_key="lucky_lira", pos=Vector3(-3, 0, 5),
	 greeting="I've been on a 12-game win streak. The secret? Companion synergy.",
	 quest_ids=["find_sovereign_crown"], shop_type="none"},

	{id="crown_rep", name="Crown Representative", district="paw_vegas", role="faction_rep",
	 dialogue_key="crown_rep", pos=Vector3(0, 0, -8),
	 greeting="The SovereignCrown is always looking for exceptional talent.",
	 quest_ids=["faction_allegiance"], shop_type="none"},

	{id="slot_sam", name="Slot Sam", district="paw_vegas", role="vendor",
	 dialogue_key="slot_sam", pos=Vector3(8, 0, 0),
	 greeting="Potions, boosts, and lucky charms. Everything you need to beat the house.",
	 quest_ids=[], shop_type="consumables"},

	{id="mystery_cat", name="???", district="paw_vegas", role="mysterious",
	 dialogue_key="mystery_cat", pos=Vector3(-6, 0, -6),
	 greeting="...",
	 quest_ids=[], shop_type="none"},

	# Cat Coliseum NPCs
	{id="arena_guard", name="Arena Guard Brox", district="cat_coliseum", role="guard",
	 dialogue_key="arena_guard", pos=Vector3(0, 0, -5),
	 greeting="Only the worthy enter the arena. Show me your power.",
	 quest_ids=["first_battle"], shop_type="none"},

	{id="coach_mira", name="Coach Mira", district="cat_coliseum", role="trainer",
	 dialogue_key="coach_mira", pos=Vector3(-4, 0, 0),
	 greeting="Light beats Heavy. Heavy beats Tech. Tech beats Light. Never forget it.",
	 quest_ids=[], shop_type="none"},

	{id="champion_vex", name="Champion Vex", district="cat_coliseum", role="champion",
	 dialogue_key="champion_vex", pos=Vector3(4, 0, 0),
	 greeting="You want to challenge me? Admirable. Foolish. But admirable.",
	 quest_ids=["grand_tournament"], shop_type="none"},

	# Neon Alley NPCs
	{id="aqua_merchant", name="Aqua Merchant Teal", district="neon_alley", role="merchant",
	 dialogue_key="aqua_merchant", pos=Vector3(0, 0, 3),
	 greeting="Fresh off the canal. Speed frames, race boosters, everything.",
	 quest_ids=["help_aqua_merchant"], shop_type="frames"},

	{id="race_starter", name="Race Starter Nara", district="neon_alley", role="race_official",
	 dialogue_key="race_starter", pos=Vector3(0, 0, -3),
	 greeting="Today's track: Neon Canal Circuit. Entry fee: 200 coins.",
	 quest_ids=["neon_alley_racer"], shop_type="none"},

	{id="veiled_scout", name="Veiled Scout", district="neon_alley", role="faction_rep",
	 dialogue_key="veiled_scout", pos=Vector3(-5, 0, 0),
	 greeting="The Current flows through everything. You just have to learn to feel it.",
	 quest_ids=["faction_allegiance"], shop_type="none"},

	# Cat Forest NPCs
	{id="forest_elder", name="Forest Elder Moss", district="cat_forest", role="quest_giver",
	 dialogue_key="forest_elder", pos=Vector3(0, 0, 0),
	 greeting="The forest has been here longer than any faction. It will outlast them too.",
	 quest_ids=["forest_mystery", "intro_district_tour"], shop_type="none"},

	{id="wildlands_ranger", name="Wildlands Ranger", district="cat_forest", role="faction_rep",
	 dialogue_key="wildlands_ranger", pos=Vector3(5, 0, 5),
	 greeting="The WildlandsAscendant welcomes those who respect the forest.",
	 quest_ids=["faction_allegiance"], shop_type="none"},

	{id="companion_keeper", name="Companion Keeper Zara", district="cat_forest", role="vendor",
	 dialogue_key="companion_keeper", pos=Vector3(-5, 0, 5),
	 greeting="I've catalogued every companion in the forest. 500 in total, if you count the Factionless ones.",
	 quest_ids=["companion_collector"], shop_type="companions"},

	# Arcade Galaxy NPCs
	{id="arcade_host", name="Arcade Host Pixel", district="arcade_galaxy", role="host",
	 dialogue_key="arcade_host", pos=Vector3(0, 0, 0),
	 greeting="Welcome to the Arcade Galaxy! No one knows how it got here. No one's asking.",
	 quest_ids=["arcade_champion"], shop_type="none"},

	{id="puzzle_master", name="Puzzle Master Gridlock", district="arcade_galaxy", role="puzzle_vendor",
	 dialogue_key="puzzle_master", pos=Vector3(3, 0, 3),
	 greeting="The cat puzzle is deceptively simple. I've been playing it for 200 hours.",
	 quest_ids=[], shop_type="none"},
]

static func get_npc(npc_id: String) -> Dictionary:
	for npc in NPCS:
		if npc.id == npc_id: return npc.duplicate()
	return {}

static func get_npcs_in_district(district: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for npc in NPCS:
		if npc.get("district", "") == district:
			result.append(npc.duplicate())
	return result
