# race_lore.gd
# Static class providing lore data for all 20 playable races in CATSINO.CASINO

class_name RaceLore

static func get_lore(race_name: String) -> Dictionary:
	var all_lore := _build_lore_table()
	if all_lore.has(race_name):
		return all_lore[race_name]
	return {name = race_name, description = "Unknown race.", homeworld = "Unknown", affinity_stats = [], lore_blurb = ""}

static func get_all_race_names() -> Array[String]:
	return ["Keth", "Lumari", "Vex", "Ferox", "Azhul", "Sylva", "Geara", "Nyx", "Aquis",
			"Igni", "Kryos", "Myco", "Volt", "Petra", "Sanguis", "Chimera", "Astra",
			"Ferros", "Etherea", "Glyphe"]

static func _build_lore_table() -> Dictionary:
	return {
		"Keth": {
			name = "Keth",
			description = "Shadow-striders of the upper urban canyons. The Keth evolved in the perpetual twilight between megastructure layers, developing unmatched stealth and reflexes.",
			homeworld = "Veltharun — the Shadowstack, a city built vertically inside a dead megaship",
			affinity_stats = ["spd", "lck"],
			lore_blurb = "The Keth do not walk into a room — they arrive. Their presence is felt only in retrospect, in the missing wallet, the cut security feed, the rival who didn't come home. When the neon lights of Paws Vegas flicker, the Keth say it is their ancestors winking. Everyone else just checks their pockets."
		},
		"Lumari": {
			name = "Lumari",
			description = "Crystal-blooded beings whose very veins carry refracted light. Lumari emit a soft bioluminescent glow and can project beams of focused energy from their crystalline fur-nodes.",
			homeworld = "Prismara — a geode-planet whose hollow interior is lit by living crystals",
			affinity_stats = ["sty", "lck"],
			lore_blurb = "To look upon a Lumari in full resonance is to see every color the eye can perceive, and several it cannot. They are artists and scientists in equal measure, and their fashion sense is, without question, the most aggressively beautiful in the known districts. They light their own parties. Literally."
		},
		"Vex": {
			name = "Vex",
			description = "Phase-capable hunters who can briefly shift into a semi-material state, passing through matter and rendering attacks ineffective during transition.",
			homeworld = "Nullhaven — a world that exists partially out of phase with the standard dimension",
			affinity_stats = ["spd", "pow"],
			lore_blurb = "The Vex find walls to be more of a suggestion. Physical barriers, locked doors, force fields — all optional. This makes them exceptional thieves, spies, and messengers, and absolutely terrible guests. Their home world Nullhaven is said to be visible only twice per solar cycle, which is just enough time to remember why no one tries to visit."
		},
		"Ferox": {
			name = "Ferox",
			description = "Apex predators of the open wilds, built for raw power and territorial dominance. Ferox stand a head taller than most races and carry battle scars as status symbols.",
			homeworld = "Grael — a high-gravity death world of endless plains and apex megafauna",
			affinity_stats = ["pow", "res"],
			lore_blurb = "On Grael, the weak are remembered only as cautionary tales. The Ferox carry that philosophy into every district they enter. What they lack in subtlety they more than compensate for in impact — measured in structural damage. They are the best fighters in the casino and the worst people to sit next to at the slots."
		},
		"Azhul": {
			name = "Azhul",
			description = "Psionically-gifted seers who perceive probability fields, giving them an uncanny ability to predict outcomes — and manipulate luck itself.",
			homeworld = "Serenthos — a world where weather is caused by mass emotional events",
			affinity_stats = ["lck", "sty"],
			lore_blurb = "An Azhul will tell you they don't cheat. Technically, they are correct — they simply see which outcomes are most likely and then gently encourage reality toward the favorable ones. The Paws Vegas casino owners hate them. The Azhul find this delightful. They predicted that outcome too."
		},
		"Sylva": {
			name = "Sylva",
			description = "Forest-born biomancers who can accelerate plant growth and commune with ecosystems. Their bodies are partially entwined with living organic networks.",
			homeworld = "Verdaen — a world covered in a single, continent-spanning mega-forest mind",
			affinity_stats = ["res", "sty"],
			lore_blurb = "The Sylva bring the jungle with them. Literally. Within hours of a Sylva settling in a new district, vines creep through the ventilation, moss colonizes the walls, and the residents find their apartments subtly more oxygenated and their stress levels suspiciously lower. Nobody complains. The plants are listening anyway."
		},
		"Geara": {
			name = "Geara",
			description = "Cybernetically augmented engineers who have integrated mechanical components so deeply that the line between machine and organism has blurred completely.",
			homeworld = "Mechspire — a world that is itself a single planet-sized machine of unknown purpose",
			affinity_stats = ["pow", "res"],
			lore_blurb = "The Geara do not upgrade their equipment — they upgrade themselves. A Geara's body is their workshop, their manifesto, and their resume. Every gear, piston, and optical implant tells a story. After three centuries of augmentation, some Geara have only a brain and one original paw remaining, and they consider this beautifully minimalist."
		},
		"Nyx": {
			name = "Nyx",
			description = "Void-touched nocturnal hunters who draw power from darkness and can manipulate local light levels. Their eyes absorb all visible spectrum and emit none.",
			homeworld = "Erevos — a world with a black sun that radiates in infrared only",
			affinity_stats = ["spd", "lck"],
			lore_blurb = "The Nyx see everything in the dark. This is not a metaphor. They see heat, magnetic fields, dimensional seams, and the anxiety of their prey. In Paws Vegas where the neon never sleeps, they wear filter visors — not because they need to see, but because raw neon makes everything taste like copper. They find this offensive."
		},
		"Aquis": {
			name = "Aquis",
			description = "Hydromancers who can shape and weaponize water in any state, from flash-frozen lances to boiling steam jets. Their fur is permanently silken and salt-tinged.",
			homeworld = "Pelagion — an ocean world with no land mass; all civilization is floating or submerged",
			affinity_stats = ["res", "spd"],
			lore_blurb = "Aquis will not fight in a desert. They have checked — nothing will make them. In every other environment, however, they are formidably adaptable. They can draw moisture from the air, from their opponents' bodies, from the beverages of bystanders. The Aquis bartenders of Paws Vegas are both extremely skilled and extremely suspicious."
		},
		"Igni": {
			name = "Igni",
			description = "Pyromancers born in volcanic calderas, the Igni channel geothermal and plasma energies through specially adapted heat-resistant fur and fireproof musculature.",
			homeworld = "Calderix — a volcanic world where the oceans are liquid magma",
			affinity_stats = ["pow", "spd"],
			lore_blurb = "The Igni run hot. Emotionally, physically, and thermodynamically. Their internal body temperature at rest would hospitalize any other race. When angry — which is often — they glow. This makes bluffing at poker difficult, which is why most Igni prefer games of pure chance. The slot machines don't melt as easily as the poker tables did."
		},
		"Kryos": {
			name = "Kryos",
			description = "Cryomancers from a glacier-world who can generate and shape ice structures, slow reaction speeds of opponents with cryo-fields, and survive temperatures that would shatter steel.",
			homeworld = "Glaciurm — a world in perpetual ice age, beautiful and completely inhospitable",
			affinity_stats = ["res", "pow"],
			lore_blurb = "The Kryos perspective on time is different. When your world changes by a centimeter of ice growth per decade, patience becomes a survival trait. In Paws Vegas, Kryos are the calmest gamblers, the most methodical tacticians, and the most infuriating opponents. They will wait you out. They have been waiting since before your grandparents were born."
		},
		"Myco": {
			name = "Myco",
			description = "Fungal-symbiote races who maintain a continuous chemical and spore-based network with their environment. Their bodies host complex mycelial networks that can interface with organic and electronic systems.",
			homeworld = "Rhizoma — a world where the dominant life form is a single continent-spanning fungal intelligence",
			affinity_stats = ["res", "lck"],
			lore_blurb = "The Myco are never truly alone. Their mycelial network connects them to every Myco within a kilometer and, with effort, across the entire planet of Rhizoma. In Paws Vegas they are said to have infiltrated the ventilation network. The casino operators believe this is a conspiracy theory. The Myco find this extremely amusing, in a networked, simultaneous, hive-laugh kind of way."
		},
		"Volt": {
			name = "Volt",
			description = "Bioelectric beings who generate, store, and discharge electricity through their conductive-strand fur. Volt can interface directly with electronic systems via touch.",
			homeworld = "Stormgate — a world of permanent electromagnetic storms and floating charged landmasses",
			affinity_stats = ["spd", "pow"],
			lore_blurb = "You can always tell a Volt by the way electronics behave strangely near them — screens flicker, machines recalibrate, other people's phones lock and unlock at random. They find human technology quaint and biological nervous systems fascinating. Several Volt have become legendary hackers purely by accident, simply by patting a server and thinking hard."
		},
		"Petra": {
			name = "Petra",
			description = "Stone-forged beings whose skeletal structures are silicon-carbide composite. Petra command stone and earth with the casual authority of those who are essentially made of it.",
			homeworld = "Lithanos — a tectonically hyperactive world where mountains rise in years and fall in days",
			affinity_stats = ["res", "pow"],
			lore_blurb = "Petra are technically the oldest race — their fossil record predates all others by several geological epochs. They don't bring this up unless challenged, at which point they bring it up at length. Their skin shifts from granite to sandstone depending on mood, which makes reading a Petra's emotions easy if you know that obsidian means 'furious' and chalk white means 'about to make a terrible financial decision.'"
		},
		"Sanguis": {
			name = "Sanguis",
			description = "Hemomancers with enhanced circulatory systems allowing them to increase strength, speed, or healing on demand by redirecting blood flow with precise control.",
			homeworld = "Veranthos — a world where blood-tide pools are the primary ecosystem driver",
			affinity_stats = ["pow", "res"],
			lore_blurb = "The Sanguis do not bleed the way other races do. Their blood is a resource, a tool, a weapon. In combat, they can harden it subcutaneously into armor or launch pressurized jets from sealed vascular ports. At the poker table they can slow their heartbeat to appear calm when they aren't, or flood with adrenaline to appear threatening when the hand is excellent. They are not popular at card games."
		},
		"Chimera": {
			name = "Chimera",
			description = "Genetic mosaics with unstable phenotypes, the Chimera express random combinations of abilities from their mixed heritage. No two Chimera are alike — they are walking experiments.",
			homeworld = "Varianx — a world where genetic mixing is enforced by ambient mutagenic radiation",
			affinity_stats = ["lck", "sty"],
			lore_blurb = "Being a Chimera is a daily surprise. You might wake up with working Nyx night vision, Volt bioelectric fur, and Aquis hydrokinesis. You might wake up unable to remember which of those three you had yesterday. The Chimera have made unpredictability into an art form, and their chaotic energy makes them either the most entertaining or the most dangerous entity in any given room. Often both."
		},
		"Astra": {
			name = "Astra",
			description = "Stellar descendants who fell from orbital habitats generations ago, the Astra retain vestigial cosmic attunement, allowing them to briefly tap stellar energy for devastating bursts.",
			homeworld = "The Constellation Ring — an orbital habitat network that encircles the system's star",
			affinity_stats = ["pow", "lck"],
			lore_blurb = "The Astra remember the stars the way some remember a childhood home — with nostalgic ache and absolute certainty that it was better then. Their cosmic attunement manifests as streaks of stellar plasma along their fur-lines that glow brighter when they're excited, afraid, or about to do something spectacular. In Paws Vegas, 'Astra moment' has become slang for a catastrophically cinematic overreaction to winning a game."
		},
		"Ferros": {
			name = "Ferros",
			description = "Iron-blooded warriors with metallic dermal plating that grows and sheds like armor scales. Ferros channel magnetic fields to deflect ranged attacks and enhance their strikes.",
			homeworld = "Magnavar — a magnetar-adjacent world where ferrous minerals dominate all geological and biological systems",
			affinity_stats = ["pow", "res"],
			lore_blurb = "The Ferros don't rust — they evolve. Each generation grows thicker, denser plating in response to whatever threat killed the most members of the previous generation. They have now outlived eight planet-scale extinction events. The ninth is widely expected to be a Ferros throwing their armor at it. Their armor regrows from the inside, which means Ferros molting season is genuinely alarming for everyone nearby."
		},
		"Etherea": {
			name = "Etherea",
			description = "Partially incorporeal beings who exist simultaneously in the material and ethereal planes. Etherea can selectively phase body parts through matter and are immune to environmental hazards.",
			homeworld = "The In-Between — a dimensional liminal space with no fixed geography",
			affinity_stats = ["spd", "sty"],
			lore_blurb = "The Etherea have no homeworld in the conventional sense — their origin point is a place that is less a planet and more a navigational accident. They arrived in the material plane several thousand years ago when a dimensional seal failed, and have been collectively deciding whether to leave ever since. They enjoy the food too much. Material-plane cuisine is apparently transcendent when you've spent millennia in the void consuming concept-matter."
		},
		"Glyphe": {
			name = "Glyphe",
			description = "Rune-scribes whose bodies are living inscription surfaces. Ancient Glyphe sigils etched across their fur confer passive ability modifiers that can be rewritten by skilled Glyphe artisans.",
			homeworld = "Scripturon — a world where all geography, weather, and biology is controlled by a global inscription network",
			affinity_stats = ["lck", "res"],
			lore_blurb = "The Glyphe do not distinguish between language and reality — for them, the difference never existed. Their bodies are manuscripts of power, and a fully-inscribed elder Glyphe is both a being and a library simultaneously. In Paws Vegas they work as enchanters, modifiers, and occasionally as walking billboards when funds run low. Their ads are, admittedly, extremely effective. The sigils for 'compelling deals' are literally written into them."
		}
	}
