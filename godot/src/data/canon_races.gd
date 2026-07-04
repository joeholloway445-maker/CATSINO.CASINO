class_name CanonRaces
## The 20 canonical Periliminal.Space races (project spec + Races.gs).
## The hyperliminal's 20 cat breeds are those races as the CASINO renders
## them — every breed is a canon race wearing the house skin. This mapping
## keeps both true at once: gameplay ids stay the cat ids; lore, canon
## names, and cross-layer rendering read from here.
const RACES := [
	"Keth", "Lumari", "Vex", "Ferox", "Azhul", "Sylva", "Geara", "Nyx",
	"Aquis", "Igni", "Kryos", "Myco", "Volt", "Petra", "Sanguis",
	"Chimera", "Astra", "Ferros", "Etherea", "Glyphe",
]

## cat-breed id -> canon race. Order-matched to RaceDataCharacter.RACES.
static func canon_of(race_index: int) -> String:
	return RACES[race_index % RACES.size()]

static func canon_for_id(race_id: String) -> String:
	for i in range(RaceDataCharacter.RACES.size()):
		if RaceDataCharacter.RACES[i].id == race_id:
			return canon_of(i)
	return RACES[0]
