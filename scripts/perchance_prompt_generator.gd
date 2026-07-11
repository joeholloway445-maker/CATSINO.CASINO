extends Node
class_name PerchancePromptGenerator

# Entity data structure
var entity_database: Dictionary = {}
var generated_prompts: Array[Dictionary] = []

func _ready() -> void:
	load_entity_database()

func load_entity_database() -> void:
	# Load from entity_dex_data.gd
	# For now, using a simplified structure
	entity_database = {
		"SC-SURLING": {
			"name": "Surling",
			"faction": "SovereignCrown",
			"type": "light",
			"stage_1_desc": "A small luminous orb of structured light",
			"stage_2_desc": "A refined beacon of ordered radiance",
			"stage_3_desc": "A perfect sun of calculated light"
		},
		# ... more entities (144 total)
	}

func generate_all_prompts() -> Array[Dictionary]:
	generated_prompts.clear()

	for entity_id in entity_database.keys():
		var entity = entity_database[entity_id]
		var prompt_set = generate_entity_prompts(entity_id, entity)
		generated_prompts.append(prompt_set)

	return generated_prompts

func generate_entity_prompts(entity_id: String, entity: Dictionary) -> Dictionary:
	var faction_color = get_faction_color(entity["faction"])
	var faction_theme = get_faction_theme(entity["faction"])
	var element = entity["type"]
	var element_style = get_element_style(element)

	# Base prompt for all 3 evolution stages
	var base_prompt = "A creature from the Periliminal.Space game universe. Faction: %s. Type: %s. "
	var stage_1_prompt = base_prompt % [entity["faction"], element]
	stage_1_prompt += "Stage 1 (Juvenile): %s. Art style: semi-realistic anime, %s aesthetic, vibrant colors. Game sprite asset, 256x256 pixels. Square composition." % [entity["stage_1_desc"], faction_theme]

	var stage_2_prompt = base_prompt % [entity["faction"], element]
	stage_2_prompt += "Stage 2 (Evolved): %s. More defined features. Art style: semi-realistic anime, %s aesthetic, rich colors. Game sprite asset, 256x256 pixels." % [entity["stage_2_desc"], faction_theme]

	var stage_3_prompt = base_prompt % [entity["faction"], element]
	stage_3_prompt += "Stage 3 (Apex): %s. Mature and powerful appearance. Art style: semi-realistic anime, %s aesthetic, vibrant and striking. Game sprite asset, 256x256 pixels." % [entity["stage_3_desc"], faction_theme]

	return {
		"entity_id": entity_id,
		"entity_name": entity["name"],
		"faction": entity["faction"],
		"stage_1": {
			"prompt": stage_1_prompt,
			"seed": hash(entity_id + "_stage1") % 1000000
		},
		"stage_2": {
			"prompt": stage_2_prompt,
			"seed": hash(entity_id + "_stage2") % 1000000
		},
		"stage_3": {
			"prompt": stage_3_prompt,
			"seed": hash(entity_id + "_stage3") % 1000000
		}
	}

func get_faction_color(faction: String) -> String:
	var colors = {
		"SovereignCrown": "gold, silver, and white",
		"VeiledCurrent": "deep purple, midnight blue, and dark teal",
		"WildlandsAscendant": "emerald green, amber, and bronze"
	}
	return colors.get(faction, "neutral grays")

func get_faction_theme(faction: String) -> String:
	var themes = {
		"SovereignCrown": "ordered, geometric, authoritarian",
		"VeiledCurrent": "mystical, ethereal, dreamlike",
		"WildlandsAscendant": "primal, organic, savage"
	}
	return themes.get(faction, "neutral")

func get_element_style(element: String) -> String:
	var styles = {
		"light": "glowing and radiant",
		"lightning": "electric and crackling",
		"fire": "flame-touched and burning",
		"wind": "flowing and aerodynamic",
		"sound": "wave-patterned",
		"heat": "shimmering and molten",
		"kinetic": "dynamic and fast",
		"time": "temporal and warped",
		"rot": "decaying and twisted",
		"plague": "toxic and corrupted",
		"ash": "charred and skeletal",
		"void": "dark and consuming",
		"rust": "oxidized and fragile",
		"dust": "particulate and dispersing"
	}
	return styles.get(element, "elemental")

func export_prompts_as_csv(output_path: String) -> bool:
	var csv_content = "entity_id,entity_name,faction,stage_1_prompt,stage_2_prompt,stage_3_prompt\n"

	for prompt_set in generated_prompts:
		var row = "%s,%s,%s,\"%s\",\"%s\",\"%s\"\n" % [
			prompt_set["entity_id"],
			prompt_set["entity_name"],
			prompt_set["faction"],
			prompt_set["stage_1"]["prompt"].json_escape(),
			prompt_set["stage_2"]["prompt"].json_escape(),
			prompt_set["stage_3"]["prompt"].json_escape()
		]
		csv_content += row

	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if file:
		file.store_string(csv_content)
		return true
	return false

func export_prompts_as_json(output_path: String) -> bool:
	var json_str = JSON.stringify(generated_prompts)
	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		return true
	return false
