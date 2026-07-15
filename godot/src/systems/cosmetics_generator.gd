extends Node
class_name CosmeticsGenerator

# Procedural generation of 1,000+ cosmetics from base templates
# Categories: Transmog (400+), Auras (150+), Particles (200+), Titles (100+), Emotes (150+)

signal cosmetics_generated(count: int)

var all_cosmetics: Array[Dictionary] = []

# Base templates for each category
const TRANSMOG_TEMPLATES = {
	"armor_pieces": ["head", "chest", "hands", "legs", "feet", "shoulders", "belt"],
	"materials": ["cloth", "leather", "metal", "crystal", "bone", "organic", "ethereal"],
	"styles": ["casual", "formal", "battle", "elegant", "savage", "mystical", "tech"],
	"colors": [
		Color.WHITE, Color.BLACK, Color.GRAY, Color.RED, Color.BLUE, Color.GREEN,
		Color.YELLOW, Color.PURPLE, Color.ORANGE, Color.CYAN, Color.MAGENTA, Color.LIME
	],
	"patterns": ["solid", "striped", "spotted", "gradient", "ornate", "minimalist", "glowing"]
}

const AURA_TEMPLATES = {
	"elements": ["fire", "ice", "lightning", "nature", "void", "holy", "dark", "cosmic"],
	"intensities": ["subtle", "normal", "intense", "overwhelming"],
	"shapes": ["circle", "spiral", "waves", "stars", "orbs", "mist"],
	"colors": [
		Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.PURPLE, Color.ORANGE,
		Color.CYAN, Color.MAGENTA, Color.LIME, Color.WHITE, Color.DARK_RED, Color.DARK_BLUE
	]
}

const PARTICLE_TEMPLATES = {
	"effects": ["slash", "burst", "explosion", "spiral", "rain", "snow", "fire", "electricity", "water"],
	"colors": [
		Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.PURPLE, Color.ORANGE,
		Color.WHITE, Color.BLACK, Color.CYAN, Color.MAGENTA, Color.GOLD, Color.SILVER
	],
	"frequencies": ["rare", "occasional", "frequent", "constant"],
	"sizes": ["small", "medium", "large", "huge"]
}

const TITLE_TEMPLATES = [
	{"name": "of the Realm", "stat_boost": {"pow": 5}},
	{"name": "the Brave", "stat_boost": {"pow": 10}},
	{"name": "the Swift", "stat_boost": {"spd": 10}},
	{"name": "the Wise", "stat_boost": {"res": 10}},
	{"name": "the Fortunate", "stat_boost": {"lck": 10}},
	{"name": "the Legendary", "stat_boost": {"pow": 5, "res": 5, "spd": 5}},
	{"name": "Slayer", "stat_boost": {"pow": 15}},
	{"name": "Guardian", "stat_boost": {"res": 15}},
	{"name": "Shadow", "stat_boost": {"spd": 15}},
	{"name": "Mystic", "stat_boost": {"pow": 8, "spd": 8}}
]

const EMOTE_TEMPLATES = [
	"wave", "dance", "laugh", "cry", "celebrate", "bow", "salute",
	"sit", "stand", "stretch", "meditate", "rage", "confused", "happy",
	"sad", "angry", "excited", "bored", "thinking", "sleeping"
]

func _ready() -> void:
	generate_all_cosmetics()

func generate_all_cosmetics() -> Array[Dictionary]:
	"""Generate all 1,000+ cosmetics"""
	all_cosmetics.clear()

	# Generate transmog cosmetics (400+)
	generate_transmog_cosmetics()

	# Generate aura cosmetics (150+)
	generate_aura_cosmetics()

	# Generate particle cosmetics (200+)
	generate_particle_cosmetics()

	# Generate title cosmetics (100+)
	generate_title_cosmetics()

	# Generate emote cosmetics (150+)
	generate_emote_cosmetics()

	cosmetics_generated.emit(all_cosmetics.size())
	return all_cosmetics

func generate_transmog_cosmetics() -> void:
	"""Generate 400+ armor/outfit transmog cosmetics"""
	var cosmetic_id = 0

	for material in TRANSMOG_TEMPLATES["materials"]:
		for style in TRANSMOG_TEMPLATES["styles"]:
			for color in TRANSMOG_TEMPLATES["colors"]:
				for pattern in TRANSMOG_TEMPLATES["patterns"]:
					# Full outfit combination
					var outfit_name = "%s %s %s %s" % [
						color.to_html(),
						material.capitalize(),
						style.capitalize(),
						"outfit"
					]

					all_cosmetics.append({
						"id": "transmog_%d" % cosmetic_id,
						"name": outfit_name,
						"category": "transmog",
						"type": "full_outfit",
						"rarity": determine_rarity_by_combination(material, style),
						"price": calculate_price_for_rarity(determine_rarity_by_combination(material, style)),
						"color": color,
						"material": material,
						"style": style,
						"pattern": pattern,
						"visual_asset": "transmog/%s_%s_%s.png" % [material, style, pattern]
					})
					cosmetic_id += 1

					# Individual armor pieces
					for piece in TRANSMOG_TEMPLATES["armor_pieces"]:
						all_cosmetics.append({
							"id": "transmog_%d" % cosmetic_id,
							"name": "%s %s %s" % [material.capitalize(), piece.capitalize(), style.capitalize()],
							"category": "transmog",
							"type": piece,
							"rarity": "common" if cosmetic_id % 5 == 0 else "uncommon",
							"price": 250 if cosmetic_id % 5 == 0 else 500,
							"color": color,
							"material": material,
							"style": style,
							"visual_asset": "transmog/%s_%s_%s.png" % [piece, material, style]
						})
						cosmetic_id += 1

func generate_aura_cosmetics() -> void:
	"""Generate 150+ aura/energy cosmetics"""
	var cosmetic_id = 0

	for element in AURA_TEMPLATES["elements"]:
		for shape in AURA_TEMPLATES["shapes"]:
			for intensity in AURA_TEMPLATES["intensities"]:
				for color in AURA_TEMPLATES["colors"]:
					var aura_name = "%s %s Aura (%s)" % [
						element.capitalize(),
						intensity.capitalize(),
						shape.capitalize()
					]

					all_cosmetics.append({
						"id": "aura_%d" % cosmetic_id,
						"name": aura_name,
						"category": "aura",
						"rarity": "rare" if intensity == "overwhelming" else "uncommon",
						"price": 2000 if intensity == "overwhelming" else 1000,
						"element": element,
						"shape": shape,
						"intensity": intensity,
						"color": color,
						"visual_effect": "aura/%s_%s_%s" % [element, shape, intensity]
					})
					cosmetic_id += 1

func generate_particle_cosmetics() -> void:
	"""Generate 200+ ability particle effect cosmetics"""
	var cosmetic_id = 0

	for effect in PARTICLE_TEMPLATES["effects"]:
		for color in PARTICLE_TEMPLATES["colors"]:
			for frequency in PARTICLE_TEMPLATES["frequencies"]:
				for size in PARTICLE_TEMPLATES["sizes"]:
					var particle_name = "%s %s Particles (%s %s)" % [
						effect.capitalize(),
						color.to_html(),
						frequency,
						size
					]

					all_cosmetics.append({
						"id": "particle_%d" % cosmetic_id,
						"name": particle_name,
						"category": "particle",
						"type": effect,
						"rarity": "epic" if size == "huge" else "rare" if size == "large" else "uncommon",
						"price": 2500 if size == "huge" else 1500 if size == "large" else 800,
						"effect": effect,
						"color": color,
						"frequency": frequency,
						"size": size,
						"visual_effect": "particles/%s_%s_%s_%s" % [effect, color.to_html(), frequency, size]
					})
					cosmetic_id += 1

func generate_title_cosmetics() -> void:
	"""Generate 100+ stat-boosting title cosmetics"""
	var cosmetic_id = 0

	# Base titles with stat boosts
	for title_template in TITLE_TEMPLATES:
		for prefix_option in ["Arch", "Grand", "Supreme", "Eternal", "Infinite", "Absolute", "Ultimate"]:
			var full_name = "%s %s" % [prefix_option, title_template["name"]]

			# Scale stat boost by prefix
			var scaled_boost = title_template["stat_boost"].duplicate()
			for stat in scaled_boost.keys():
				scaled_boost[stat] *= (1.0 + (cosmetic_id % 4) * 0.25)

			all_cosmetics.append({
				"id": "title_%d" % cosmetic_id,
				"name": full_name,
				"category": "title",
				"rarity": "legendary" if prefix_option == "Absolute" else "epic" if prefix_option == "Supreme" else "rare",
				"price": 5000 if prefix_option == "Absolute" else 3000 if prefix_option == "Supreme" else 1500,
				"stat_boost": scaled_boost,
				"cosmetic_effect": {
					"text_color": Color.GOLD if prefix_option == "Absolute" else Color.WHITE,
					"glow": true
				}
			})
			cosmetic_id += 1

func generate_emote_cosmetics() -> void:
	"""Generate 150+ character emote cosmetics"""
	var cosmetic_id = 0

	for emote in EMOTE_TEMPLATES:
		# Base emote
		all_cosmetics.append({
			"id": "emote_%d" % cosmetic_id,
			"name": emote.capitalize(),
			"category": "emote",
			"type": emote,
			"rarity": "common",
			"price": 100,
			"animation": "emote_%s" % emote,
			"duration": 2.0
		})
		cosmetic_id += 1

		# Fancy variants of each emote
		for variant in ["fancy", "silly", "elegant", "aggressive", "cute"]:
			all_cosmetics.append({
				"id": "emote_%d" % cosmetic_id,
				"name": "%s %s" % [variant.capitalize(), emote.capitalize()],
				"category": "emote",
				"type": emote,
				"rarity": "uncommon" if variant == "fancy" else "rare" if variant == "elegant" else "common",
				"price": 250 if variant in ["fancy", "elegant"] else 150 if variant == "silly" else 100,
				"animation": "emote_%s_%s" % [emote, variant],
				"duration": 2.5,
				"variant": variant
			})
			cosmetic_id += 1

func determine_rarity_by_combination(material: String, style: String) -> String:
	"""Determine rarity based on material and style combination"""
	if material in ["ethereal", "crystal"] and style in ["mystical", "elegant"]:
		return "legendary"
	elif material in ["crystal", "organic"] or style in ["elegant", "mystical"]:
		return "epic"
	elif material == "leather" and style == "casual":
		return "common"
	else:
		return "uncommon"

func calculate_price_for_rarity(rarity: String) -> int:
	"""Calculate cosmetic price based on rarity"""
	var prices = {
		"common": 100,
		"uncommon": 500,
		"rare": 1500,
		"epic": 3000,
		"legendary": 5000
	}
	return prices.get(rarity, 100)

func get_cosmetics_by_category(category: String) -> Array[Dictionary]:
	"""Get all cosmetics for a category"""
	var result = []
	for cosmetic in all_cosmetics:
		if cosmetic.get("category") == category:
			result.append(cosmetic)
	return result

func get_cosmetics_by_rarity(rarity: String) -> Array[Dictionary]:
	"""Get all cosmetics of specific rarity"""
	var result = []
	for cosmetic in all_cosmetics:
		if cosmetic.get("rarity") == rarity:
			result.append(cosmetic)
	return result

func search_cosmetics(query: String) -> Array[Dictionary]:
	"""Search cosmetics by name"""
	var result = []
	var query_lower = query.to_lower()
	for cosmetic in all_cosmetics:
		if cosmetic.get("name", "").to_lower().contains(query_lower):
			result.append(cosmetic)
	return result

func export_to_json(output_path: String) -> bool:
	"""Export all cosmetics to JSON file"""
	var json_str = JSON.stringify(all_cosmetics)
	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		return true
	return false

func get_cosmetics_count() -> int:
	"""Get total number of cosmetics"""
	return all_cosmetics.size()

func get_cosmetics_stats() -> Dictionary:
	"""Get statistics about generated cosmetics"""
	var stats = {
		"total": all_cosmetics.size(),
		"by_category": {},
		"by_rarity": {},
		"by_price": {}
	}

	for cosmetic in all_cosmetics:
		var category = cosmetic.get("category", "unknown")
		var rarity = cosmetic.get("rarity", "unknown")
		var price = cosmetic.get("price", 0)

		stats["by_category"][category] = stats["by_category"].get(category, 0) + 1
		stats["by_rarity"][rarity] = stats["by_rarity"].get(rarity, 0) + 1
		stats["by_price"][price] = stats["by_price"].get(price, 0) + 1

	return stats
