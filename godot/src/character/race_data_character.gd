class_name RaceDataCharacter
# All 20 playable races with their base stat modifiers.
# texture_type/primary_color drive CharacterRig's procedural PBR look
# (see texture_materials.gd for the full texture_type -> material table).

const RACES: Array[Dictionary] = [
	{id="tabby", name="Tabby", pow=0, res=0, spd=0, lck=2, sty=0, texture_type="morphic", primary_color=Color(0.55, 0.42, 0.25), lore="The most common and adaptable of all cat races. Luck is their greatest asset."},
	{id="siamese", name="Siamese", pow=0, res=0, spd=2, lck=0, sty=3, texture_type="crystalline", primary_color=Color(0.85, 0.78, 0.65), lore="Elegant and swift, Siamese cats are natural performers in any arena."},
	{id="maine_coon", name="Maine Coon", pow=3, res=2, spd=-1, lck=0, sty=0, texture_type="biotech", primary_color=Color(0.4, 0.3, 0.2), lore="Massive and powerful, Maine Coons dominate in heavy combat."},
	{id="persian", name="Persian", pow=-1, res=2, spd=-1, lck=3, sty=5, texture_type="regal", primary_color=Color(0.95, 0.92, 0.85), lore="Regal and fortunate, Persians are the aristocracy of Catsino."},
	{id="bengal", name="Bengal", pow=2, res=0, spd=3, lck=1, sty=0, texture_type="solar", primary_color=Color(0.85, 0.55, 0.2), lore="Wild-blooded and fast, Bengals excel in racing and light combat."},
	{id="russian_blue", name="Russian Blue", pow=0, res=3, spd=0, lck=2, sty=2, texture_type="abyssal", primary_color=Color(0.5, 0.55, 0.6), lore="Stoic and resilient. Russian Blues endure where others fold."},
	{id="sphynx", name="Sphynx", pow=1, res=0, spd=1, lck=4, sty=1, texture_type="spectral", primary_color=Color(0.9, 0.8, 0.7), lore="Hairless and enigmatic, Sphynx cats seem to attract fortune."},
	{id="ragdoll", name="Ragdoll", pow=0, res=4, spd=-2, lck=1, sty=3, texture_type="symbiotic", primary_color=Color(0.9, 0.85, 0.75), lore="Calm under pressure. Ragdolls absorb punishment without complaint."},
	{id="scottish_fold", name="Scottish Fold", pow=0, res=1, spd=1, lck=3, sty=2, texture_type="amphibious", primary_color=Color(0.6, 0.5, 0.4), lore="Curious and adaptable, Scottish Folds find luck in unexpected places."},
	{id="abyssinian", name="Abyssinian", pow=1, res=0, spd=4, lck=2, sty=0, texture_type="electric", primary_color=Color(0.7, 0.45, 0.25), lore="Ancient and swift, Abyssinians were racing before racing existed."},
	{id="burmese", name="Burmese", pow=2, res=1, spd=1, lck=1, sty=1, texture_type="mutated", primary_color=Color(0.35, 0.25, 0.2), lore="Well-rounded Burmese cats adapt to any role in any district."},
	{id="turkish_angora", name="Turkish Angora", pow=0, res=1, spd=2, lck=2, sty=4, texture_type="celestial", primary_color=Color(0.95, 0.95, 0.95), lore="Beautiful and clever, Turkish Angoras are masters of style."},
	{id="norwegian_forest", name="Norwegian Forest", pow=3, res=3, spd=-1, lck=0, sty=0, texture_type="decayed", primary_color=Color(0.45, 0.4, 0.3), lore="Built for harsh conditions, Norwegian Forests have unmatched endurance."},
	{id="birman", name="Birman", pow=0, res=2, spd=0, lck=4, sty=2, texture_type="temporal", primary_color=Color(0.88, 0.82, 0.7), lore="Sacred cats of ancient legend, Birmans carry luck in their paws."},
	{id="tonkinese", name="Tonkinese", pow=1, res=1, spd=2, lck=2, sty=1, texture_type="dimensional", primary_color=Color(0.55, 0.45, 0.35), lore="Social and versatile, Tonkinese cats thrive in every district."},
	{id="devon_rex", name="Devon Rex", pow=0, res=0, spd=3, lck=3, sty=2, texture_type="phasic", primary_color=Color(0.6, 0.55, 0.45), lore="Mischievous and quick, Devon Rex cats are always where the action is."},
	{id="oriental", name="Oriental", pow=1, res=0, spd=2, lck=1, sty=5, texture_type="radiant", primary_color=Color(0.3, 0.25, 0.2), lore="Sleek and sophisticated, Orientals are the ultimate style icons."},
	{id="somali", name="Somali", pow=1, res=1, spd=3, lck=2, sty=0, texture_type="voidlike", primary_color=Color(0.65, 0.4, 0.2), lore="Wild-spirited Somalis live for the race and the open road."},
	{id="manx", name="Manx", pow=2, res=2, spd=1, lck=1, sty=1, texture_type="digital", primary_color=Color(0.4, 0.35, 0.3), lore="Tailless and balanced, Manx cats are adaptable in any situation."},
	{id="savannah", name="Savannah", pow=4, res=1, spd=3, lck=0, sty=0, texture_type="biotech", primary_color=Color(0.75, 0.6, 0.3), lore="Half-wild Savannah cats dominate in raw combat power and speed."},
]

static func get_race(race_id: String) -> Dictionary:
	for r in RACES:
		if r.id == race_id: return r.duplicate()
	return {}

static func get_stat_bonuses(race_id: String) -> Dictionary:
	var race := get_race(race_id)
	if race.is_empty(): return {}
	return {pow=race.pow, res=race.res, spd=race.spd, lck=race.lck, sty=race.sty}
