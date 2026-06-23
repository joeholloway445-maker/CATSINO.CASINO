class_name GameLore
# World lore, district histories, and faction backstories for CATSINO.CASINO

const WORLD_INTRO = """
PAW VEGAS — a city built on luck, speed, and the eternal battle for style.

Once a sleepy desert outpost, Paw Vegas was transformed overnight when the SovereignCrown
arrived and declared it the capital of the new world order. Within a decade, five districts
rose from the sand: each one a battlefield for the four great factions.

The slots spin. The reels turn. The cats race.

And somewhere beneath it all — in the roots, in the currents, in the void — something watches.
"""

const DISTRICT_LORE = {
	"paw_vegas": """
PAW VEGAS CENTRAL
The crown jewel of the city. Neon towers and slot machines stretch as far as the eye can see.
The SovereignCrown's casino empire began here — and all the other factions followed.
If you want to make your name in this world, you start in Paw Vegas.
	""",
	"cat_coliseum": """
CAT COLISEUM
Ancient before the city existed. The Coliseum predates Paw Vegas by centuries —
carved from black obsidian by the original Wildlands settlers. Now it serves as the
city's premier combat arena. Every faction sends their best here. Only the strong endure.
	""",
	"neon_alley": """
NEON ALLEY
The VeiledCurrent's territory. Neon canals, water races, and underground betting dens.
The fastest cats in the world come to Neon Alley to prove their speed — and leave either
rich or humbled. The lights never go out here. Neither do the races.
	""",
	"cat_forest": """
CAT FOREST
The Wildlands' sacred territory. Ancient trees, hidden clearings, and companions who
haven't seen the city in decades. Quests begin here. Legends are born here.
The forest doesn't forget who entered — or what they were seeking.
	""",
	"arcade_galaxy": """
ARCADE GALAXY
No one knows who built it. The Arcade Galaxy appeared one morning — a floating platform
above the city, full of machines, games, and companions no one had seen before.
The factions all claim ownership. None have proven it. The games keep running regardless.
	""",
}

const FACTION_LORE = {
	"SovereignCrown": """
THE SOVEREIGNCROWN
They arrived first. They built fastest. They rule hardest.
The SovereignCrown is Paw Vegas' founding faction — a coalition of elite cats who pooled
their resources to build the city's casino empire. Membership is impossible to fake.
They know every face, every tail, every whisker.
Emperor Maximus Vex (SC100) personally approved every member above rank 50.
The Crown doesn't forgive. It doesn't forget. And it never sleeps.
	""",
	"WildlandsAscendant": """
WILDLANDS ASCENDANT
Before the city, there was the forest.
The Wildlands faction traces its lineage to the original settlers of Cat Forest —
cats who communicated through root networks and moved faster than any machine.
They didn't choose to become a faction. The city forced the label on them.
They carry it now like a weapon.
The Wild Sovereign (WA100) speaks for the forest. The forest does not negotiate.
	""",
	"VeiledCurrent": """
VEILED CURRENT
You don't see the Current. You feel it.
The VeiledCurrent emerged from Neon Alley's underground water network — a faction
born of smugglers, racers, and cats who preferred to operate unseen.
Their slot bonuses are the highest because they control the distribution systems
that feed the city's machines. No one has ever found their headquarters.
The Tideweaver (VC100) is said to be the original founder. No one has confirmed this.
The Tideweaver doesn't confirm things.
	""",
	"Factionless": """
THE FACTIONLESS
Not a faction. An absence of one.
Every cat who walks into Paw Vegas without an allegiance is Factionless by default.
Some stay that way by choice. Some are refused by all three factions.
And a rare few — the ones like The Unaffiliated (FL100) — transcend faction entirely,
earning the respect of all four without belonging to any.
Being Factionless means freedom. It also means no safety net.
	""",
}

static func get_world_intro() -> String:
	return WORLD_INTRO

static func get_district_lore(district: String) -> String:
	return DISTRICT_LORE.get(district, "No lore available.")

static func get_faction_lore(faction: String) -> String:
	return FACTION_LORE.get(faction, "No lore available.")
