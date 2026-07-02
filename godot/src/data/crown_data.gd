class_name CrownData
## The 60 crowns of Periliminal.Space, ported verbatim from the Apps Script
## source of truth (docs/reference/periliminal_space_v0.0.1/Crowns.gs).
## 50 visible + 10 hidden (hidden crowns are token-gated). Each crown is
## bound to a leaderboard; its current #1 wears it (see CrownManager).

const CROWNS: Array[Dictionary] = [
	{id=1, name="Crown of Valor", category="Visible", leaderboard="Top PvP Kills", type="visible", passive_bonus="5% damage in PvP", playstyle_bonus="Faster attack recovery", min_champion_level=1, token_required=false},
	{id=2, name="Crown of Wisdom", category="Visible", leaderboard="Top Quest Completions", type="visible", passive_bonus="5% XP gain", playstyle_bonus="Reduced cooldowns on abilities", min_champion_level=1, token_required=false},
	{id=3, name="Crown of Shadows", category="Visible", leaderboard="Top Stealth Kills", type="visible", passive_bonus="5% critical chance in stealth", playstyle_bonus="Reduced detection range", min_champion_level=1, token_required=false},
	{id=4, name="Crown of the Gladiator", category="Visible", leaderboard="Top Arena Victories", type="visible", passive_bonus="5% damage in arenas", playstyle_bonus="Faster attack recovery", min_champion_level=1, token_required=false},
	{id=5, name="Crown of the Enchanter", category="Visible", leaderboard="Top Enchantments Applied", type="visible", passive_bonus="5% enchantment potency", playstyle_bonus="Reduced resource cost for enchantments", min_champion_level=1, token_required=false},
	{id=6, name="Crown of the Shadow Slayer", category="Visible", leaderboard="Top Shadow Entity Kills", type="visible", passive_bonus="5% damage vs shadows", playstyle_bonus="Extended critical chance against shadow types", min_champion_level=1, token_required=false},
	{id=7, name="Crown of the Pathfinder", category="Visible", leaderboard="Top Terrain Explored", type="visible", passive_bonus="5% movement speed", playstyle_bonus="Reduced stamina drain when exploring", min_champion_level=1, token_required=false},
	{id=8, name="Crown of the Vanguard", category="Visible", leaderboard="Top Frontline Engagements", type="visible", passive_bonus="5% damage resistance", playstyle_bonus="Increased threat generation to draw enemies", min_champion_level=1, token_required=false},
	{id=9, name="Crown of the Collector", category="Visible", leaderboard="Top Rare Items Gathered", type="visible", passive_bonus="5% item drop chance", playstyle_bonus="Increased luck on rare finds", min_champion_level=1, token_required=false},
	{id=10, name="Crown of the Duelist", category="Visible", leaderboard="Top 1v1 Victories", type="visible", passive_bonus="5% attack speed in duels", playstyle_bonus="Reduced cooldowns on duel skills", min_champion_level=1, token_required=false},
	{id=11, name="Crown of the Innovator", category="Visible", leaderboard="Top Game Mechanics Explored", type="visible", passive_bonus="5% efficiency with custom mechanics", playstyle_bonus="Access to advanced crafting options", min_champion_level=1, token_required=false},
	{id=12, name="Crown of the Artisan of War", category="Visible", leaderboard="Top Weapon Crafts", type="visible", passive_bonus="5% weapon effectiveness", playstyle_bonus="Reduced crafting material cost", min_champion_level=1, token_required=false},
	{id=13, name="Crown of the Arbiter", category="Visible", leaderboard="Top Judicial Decisions in Factions", type="visible", passive_bonus="5% faction influence", playstyle_bonus="Ability to resolve disputes faster", min_champion_level=1, token_required=false},
	{id=14, name="Crown of the Scout", category="Visible", leaderboard="Top Recon Missions", type="visible", passive_bonus="5% detection range", playstyle_bonus="Faster stealth movement", min_champion_level=1, token_required=false},
	{id=15, name="Crown of the Builder", category="Visible", leaderboard="Top Structures Built", type="visible", passive_bonus="5% building speed", playstyle_bonus="Reduced resource cost on structures", min_champion_level=1, token_required=false},
	{id=16, name="Crown of the Scribe", category="Visible", leaderboard="Top Lore Contributions", type="visible", passive_bonus="5% knowledge gain", playstyle_bonus="Access to hidden lore recipes", min_champion_level=1, token_required=false},
	{id=17, name="Crown of the Ranger", category="Visible", leaderboard="Top Wildlife Tames", type="visible", passive_bonus="5% taming success", playstyle_bonus="Reduced cooldown on pet commands", min_champion_level=1, token_required=false},
	{id=18, name="Crown of the Strategist", category="Visible", leaderboard="Top Battle Plans Executed", type="visible", passive_bonus="5% efficiency in large-scale fights", playstyle_bonus="Reduced preparation time for events", min_champion_level=1, token_required=false},
	{id=19, name="Crown of the Alchemist", category="Visible", leaderboard="Top Potions Brewed", type="visible", passive_bonus="5% potion potency", playstyle_bonus="Reduced ingredient use", min_champion_level=1, token_required=false},
	{id=20, name="Crown of the Historian", category="Visible", leaderboard="Top Artifact Discoveries", type="visible", passive_bonus="5% artifact drop chance", playstyle_bonus="Increased analysis speed", min_champion_level=1, token_required=false},
	{id=21, name="Crown of the Gladiator", category="Visible", leaderboard="Top Arena Victories", type="visible", passive_bonus="5% damage in arenas", playstyle_bonus="Faster attack recovery", min_champion_level=1, token_required=false},
	{id=22, name="Crown of the Enchanter", category="Visible", leaderboard="Top Enchantments Applied", type="visible", passive_bonus="5% enchantment potency", playstyle_bonus="Reduced resource cost for enchantments", min_champion_level=1, token_required=false},
	{id=23, name="Crown of the Shadow Slayer", category="Visible", leaderboard="Top Shadow Entity Kills", type="visible", passive_bonus="5% damage vs shadows", playstyle_bonus="Extended critical chance against shadow types", min_champion_level=1, token_required=false},
	{id=24, name="Crown of the Pathfinder", category="Visible", leaderboard="Top Terrain Explored", type="visible", passive_bonus="5% movement speed", playstyle_bonus="Reduced stamina drain when exploring", min_champion_level=1, token_required=false},
	{id=25, name="Crown of the Vanguard", category="Visible", leaderboard="Top Frontline Engagements", type="visible", passive_bonus="5% damage resistance", playstyle_bonus="Increased threat generation to draw enemies", min_champion_level=1, token_required=false},
	{id=26, name="Crown of the Collector", category="Visible", leaderboard="Top Rare Items Gathered", type="visible", passive_bonus="5% item drop chance", playstyle_bonus="Increased luck on rare finds", min_champion_level=1, token_required=false},
	{id=27, name="Crown of the Duelist", category="Visible", leaderboard="Top 1v1 Victories", type="visible", passive_bonus="5% attack speed in duels", playstyle_bonus="Reduced cooldowns on duel skills", min_champion_level=1, token_required=false},
	{id=28, name="Crown of the Innovator", category="Visible", leaderboard="Top Game Mechanics Explored", type="visible", passive_bonus="5% efficiency with custom mechanics", playstyle_bonus="Access to advanced crafting options", min_champion_level=1, token_required=false},
	{id=29, name="Crown of the Artisan of War", category="Visible", leaderboard="Top Weapon Crafts", type="visible", passive_bonus="5% weapon effectiveness", playstyle_bonus="Reduced crafting material cost", min_champion_level=1, token_required=false},
	{id=30, name="Crown of the Arbiter", category="Visible", leaderboard="Top Judicial Decisions in Factions", type="visible", passive_bonus="5% faction influence", playstyle_bonus="Ability to resolve disputes faster", min_champion_level=1, token_required=false},
	{id=31, name="Crown of the Scout", category="Visible", leaderboard="Top Recon Missions", type="visible", passive_bonus="5% detection range", playstyle_bonus="Faster stealth movement", min_champion_level=1, token_required=false},
	{id=32, name="Crown of the Builder", category="Visible", leaderboard="Top Structures Built", type="visible", passive_bonus="5% building speed", playstyle_bonus="Reduced resource cost on structures", min_champion_level=1, token_required=false},
	{id=33, name="Crown of the Scribe", category="Visible", leaderboard="Top Lore Contributions", type="visible", passive_bonus="5% knowledge gain", playstyle_bonus="Access to hidden lore recipes", min_champion_level=1, token_required=false},
	{id=34, name="Crown of the Ranger", category="Visible", leaderboard="Top Wildlife Tames", type="visible", passive_bonus="5% taming success", playstyle_bonus="Reduced cooldown on pet commands", min_champion_level=1, token_required=false},
	{id=35, name="Crown of the Strategist", category="Visible", leaderboard="Top Battle Plans Executed", type="visible", passive_bonus="5% efficiency in large-scale fights", playstyle_bonus="Reduced preparation time for events", min_champion_level=1, token_required=false},
	{id=36, name="Crown of the Alchemist", category="Visible", leaderboard="Top Potions Brewed", type="visible", passive_bonus="5% potion potency", playstyle_bonus="Reduced ingredient use", min_champion_level=1, token_required=false},
	{id=37, name="Crown of the Historian", category="Visible", leaderboard="Top Artifact Discoveries", type="visible", passive_bonus="5% artifact drop chance", playstyle_bonus="Increased analysis speed", min_champion_level=1, token_required=false},
	{id=38, name="Crown of the Duelist", category="Visible", leaderboard="Top 1v1 Victories", type="visible", passive_bonus="5% attack speed in duels", playstyle_bonus="Reduced cooldowns on duel skills", min_champion_level=1, token_required=false},
	{id=39, name="Crown of the Innovator", category="Visible", leaderboard="Top Game Mechanics Explored", type="visible", passive_bonus="5% efficiency with custom mechanics", playstyle_bonus="Access to advanced crafting options", min_champion_level=1, token_required=false},
	{id=40, name="Crown of the Artisan of War", category="Visible", leaderboard="Top Weapon Crafts", type="visible", passive_bonus="5% weapon effectiveness", playstyle_bonus="Reduced crafting material cost", min_champion_level=1, token_required=false},
	{id=41, name="Crown of the Arbiter", category="Visible", leaderboard="Top Judicial Decisions in Factions", type="visible", passive_bonus="5% faction influence", playstyle_bonus="Ability to resolve disputes faster", min_champion_level=1, token_required=false},
	{id=42, name="Crown of the Shadow Hunter", category="Visible", leaderboard="Top Dark Realm Kills", type="visible", passive_bonus="5% shadow damage", playstyle_bonus="Increased movement in shadow zones", min_champion_level=1, token_required=false},
	{id=43, name="Crown of the Protector", category="Visible", leaderboard="Top Players Defended", type="visible", passive_bonus="5% ally protection effectiveness", playstyle_bonus="Reduced cooldowns on defensive skills", min_champion_level=1, token_required=false},
	{id=44, name="Crown of the Explorer", category="Visible", leaderboard="Top Hidden Locations Discovered", type="visible", passive_bonus="5% movement speed", playstyle_bonus="Reveal hidden paths faster", min_champion_level=1, token_required=false},
	{id=45, name="Crown of the Inventor", category="Visible", leaderboard="Top Devices Created", type="visible", passive_bonus="5% efficiency with gadgets", playstyle_bonus="Reduced cooldowns on mechanical devices", min_champion_level=1, token_required=false},
	{id=46, name="Crown of the Beastmaster", category="Visible", leaderboard="Top Pets Controlled", type="visible", passive_bonus="5% pet damage", playstyle_bonus="Increased pet command range", min_champion_level=1, token_required=false},
	{id=47, name="Crown of the Conqueror", category="Visible", leaderboard="Top Territory Captures", type="visible", passive_bonus="5% damage to forts", playstyle_bonus="Increased movement speed near objectives", min_champion_level=1, token_required=false},
	{id=48, name="Crown of the Diplomat", category="Visible", leaderboard="Top Faction Alliances Formed", type="visible", passive_bonus="5% faction relations boost", playstyle_bonus="Reduced negotiation cooldowns", min_champion_level=1, token_required=false},
	{id=49, name="Crown of the Librarian", category="Visible", leaderboard="Top Knowledge Collected", type="visible", passive_bonus="5% skill XP gain", playstyle_bonus="Reduced cooldown on research abilities", min_champion_level=1, token_required=false},
	{id=50, name="Crown of the Mystic", category="Visible", leaderboard="Top Magical Achievements", type="visible", passive_bonus="5% magic damage", playstyle_bonus="Reduced mana costs", min_champion_level=1, token_required=false},
	{id=51, name="Crown of the Forgotten", category="Hidden", leaderboard="Top Secret PvE Events", type="hidden", passive_bonus="5% rare item drops", playstyle_bonus="Extra resource yields", min_champion_level=1, token_required=true},
	{id=52, name="Crown of the Veil", category="Hidden", leaderboard="Top Hidden PvP Events", type="hidden", passive_bonus="5% stealth efficiency", playstyle_bonus="Extended invisibility duration", min_champion_level=1, token_required=true},
	{id=53, name="Crown of the Eclipse", category="Hidden", leaderboard="Top Shadow Realm Activities", type="hidden", passive_bonus="5% damage vs rare bosses", playstyle_bonus="Reduced cooldowns in shadow zones", min_champion_level=1, token_required=true},
	{id=54, name="Crown of the Revenant", category="Hidden", leaderboard="Top Resurrection Events", type="hidden", passive_bonus="5% revival speed", playstyle_bonus="Reduced death penalties", min_champion_level=1, token_required=true},
	{id=55, name="Crown of the Phantom", category="Hidden", leaderboard="Top Illusive Feats", type="hidden", passive_bonus="5% dodge chance", playstyle_bonus="Reduced detection by AI", min_champion_level=1, token_required=true},
	{id=56, name="Crown of the Obscured", category="Hidden", leaderboard="Top Hidden Crafting Feats", type="hidden", passive_bonus="5% crafting efficiency", playstyle_bonus="Access to secret recipes", min_champion_level=1, token_required=true},
	{id=57, name="Crown of the Ascendant", category="Hidden", leaderboard="Top Ascension Trials", type="hidden", passive_bonus="5% all stats", playstyle_bonus="Reduced cooldowns on ascension skills", min_champion_level=1, token_required=true},
	{id=58, name="Crown of the Eternal", category="Hidden", leaderboard="Top Endgame PvE Feats", type="hidden", passive_bonus="5% damage to endgame bosses", playstyle_bonus="Reduced resource cost in epic events", min_champion_level=1, token_required=true},
	{id=59, name="Crown of the Veiled God", category="Hidden", leaderboard="Top Secret World Manipulations", type="hidden", passive_bonus="5% all rare interactions", playstyle_bonus="Extra event rewards", min_champion_level=1, token_required=true},
	{id=60, name="Crown of the Shadow King", category="Hidden", leaderboard="Top Hidden PvP Conquests", type="hidden", passive_bonus="5% damage in hidden arenas", playstyle_bonus="Extended invisibility and stealth", min_champion_level=1, token_required=true},
]

static func by_id(crown_id: int) -> Dictionary:
	for c in CROWNS:
		if c.id == crown_id: return c
	return {}

static func by_leaderboard(lb: String) -> Dictionary:
	for c in CROWNS:
		if c.leaderboard == lb: return c
	return {}

static func visible() -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for c in CROWNS:
		if c.type == "visible": r.append(c)
	return r

static func hidden() -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for c in CROWNS:
		if c.type == "hidden": r.append(c)
	return r
