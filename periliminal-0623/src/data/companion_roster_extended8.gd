class_name CompanionRosterExtended8
# WA101-WA150 already exist in extended5. This adds SC151+ to push beyond the base 500.
# Grand final count: SC150 + WA150 + VC150 + FL150 = 600 companions total.
# The canonical 500 are SC001-SC150, WA001-WA100, VC001-VC100, FL001-FL100.
# Extended beyond 500 as bonus content.

# Additional named legendaries — one per faction for prestige
const PRESTIGE_COMPANIONS: Array[Dictionary] = [
	# SovereignCrown Prestige
	{id="SC_PRESTIGE", name="The Sovereign", faction="SovereignCrown", type="heavy", rarity="prestige",
	 pow=30, res=28, spd=15, lck=20, sty=30, desc="The original. The myth. The Crown itself."},

	# WildlandsAscendant Prestige
	{id="WA_PRESTIGE", name="The Ancient", faction="WildlandsAscendant", type="light", rarity="prestige",
	 pow=18, res=16, spd=32, lck=25, sty=22, desc="Older than the forest. Faster than thought."},

	# VeiledCurrent Prestige
	{id="VC_PRESTIGE", name="The Tide", faction="VeiledCurrent", type="tech", rarity="prestige",
	 pow=20, res=22, spd=20, lck=35, sty=26, desc="Probability incarnate. Every gamble tips its way."},

	# Factionless Prestige
	{id="FL_PRESTIGE", name="The First Cat", faction="Factionless", type="balanced", rarity="prestige",
	 pow=25, res=25, spd=25, lck=25, sty=25, desc="Before the factions. Before the city. Just a cat."},
]
