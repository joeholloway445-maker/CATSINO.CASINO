class_name RaceDataCharacter
# All 20 playable races with their base stat modifiers

const RACES: Array[Dictionary] = [
	{id="tabby", name="Tabby", pow=0, res=0, spd=0, lck=2, sty=0, lore="The most common and adaptable of all cat races. Luck is their greatest asset."},
	{id="siamese", name="Siamese", pow=0, res=0, spd=2, lck=0, sty=3, lore="Elegant and swift, Siamese cats are natural performers in any arena."},
	{id="maine_coon", name="Maine Coon", pow=3, res=2, spd=-1, lck=0, sty=0, lore="Massive and powerful, Maine Coons dominate in heavy combat."},
	{id="persian", name="Persian", pow=-1, res=2, spd=-1, lck=3, sty=5, lore="Regal and fortunate, Persians are the aristocracy of Catsino."},
	{id="bengal", name="Bengal", pow=2, res=0, spd=3, lck=1, sty=0, lore="Wild-blooded and fast, Bengals excel in racing and light combat."},
	{id="russian_blue", name="Russian Blue", pow=0, res=3, spd=0, lck=2, sty=2, lore="Stoic and resilient. Russian Blues endure where others fold."},
	{id="sphynx", name="Sphynx", pow=1, res=0, spd=1, lck=4, sty=1, lore="Hairless and enigmatic, Sphynx cats seem to attract fortune."},
	{id="ragdoll", name="Ragdoll", pow=0, res=4, spd=-2, lck=1, sty=3, lore="Calm under pressure. Ragdolls absorb punishment without complaint."},
	{id="scottish_fold", name="Scottish Fold", pow=0, res=1, spd=1, lck=3, sty=2, lore="Curious and adaptable, Scottish Folds find luck in unexpected places."},
	{id="abyssinian", name="Abyssinian", pow=1, res=0, spd=4, lck=2, sty=0, lore="Ancient and swift, Abyssinians were racing before racing existed."},
	{id="burmese", name="Burmese", pow=2, res=1, spd=1, lck=1, sty=1, lore="Well-rounded Burmese cats adapt to any role in any district."},
	{id="turkish_angora", name="Turkish Angora", pow=0, res=1, spd=2, lck=2, sty=4, lore="Beautiful and clever, Turkish Angoras are masters of style."},
	{id="norwegian_forest", name="Norwegian Forest", pow=3, res=3, spd=-1, lck=0, sty=0, lore="Built for harsh conditions, Norwegian Forests have unmatched endurance."},
	{id="birman", name="Birman", pow=0, res=2, spd=0, lck=4, sty=2, lore="Sacred cats of ancient legend, Birmans carry luck in their paws."},
	{id="tonkinese", name="Tonkinese", pow=1, res=1, spd=2, lck=2, sty=1, lore="Social and versatile, Tonkinese cats thrive in every district."},
	{id="devon_rex", name="Devon Rex", pow=0, res=0, spd=3, lck=3, sty=2, lore="Mischievous and quick, Devon Rex cats are always where the action is."},
	{id="oriental", name="Oriental", pow=1, res=0, spd=2, lck=1, sty=5, lore="Sleek and sophisticated, Orientals are the ultimate style icons."},
	{id="somali", name="Somali", pow=1, res=1, spd=3, lck=2, sty=0, lore="Wild-spirited Somalis live for the race and the open road."},
	{id="manx", name="Manx", pow=2, res=2, spd=1, lck=1, sty=1, lore="Tailless and balanced, Manx cats are adaptable in any situation."},
	{id="savannah", name="Savannah", pow=4, res=1, spd=3, lck=0, sty=0, lore="Half-wild Savannah cats dominate in raw combat power and speed."},
]

static func get_race(race_id: String) -> Dictionary:
	for r in RACES:
		if r.id == race_id: return r.duplicate()
	return {}

static func get_stat_bonuses(race_id: String) -> Dictionary:
	var race := get_race(race_id)
	if race.is_empty(): return {}
	return {pow=race.pow, res=race.res, spd=race.spd, lck=race.lck, sty=race.sty}
