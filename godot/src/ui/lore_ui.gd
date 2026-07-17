class_name LoreUI
extends Control

@onready var category_option: OptionButton = $Panel/VBox/CategoryOption
@onready var lore_text: RichTextLabel = $Panel/VBox/ScrollContainer/LoreText

const CATEGORIES := {
	"World Overview": "world",
	"Paws Vegas": "paw_vegas",
	"Cat Coliseum": "cat_coliseum",
	"Neon Alley": "neon_alley",
	"Cat Forest": "cat_forest",
	"Arcade Galaxy": "arcade_galaxy",
	"SovereignCrown": "SovereignCrown",
	"WildlandsAscendant": "WildlandsAscendant",
	"VeiledCurrent": "VeiledCurrent",
	"Factionless": "Factionless",
	"Companions": "companion_lore",
}

func _ready() -> void:
	for cat_name in CATEGORIES.keys():
		category_option.add_item(cat_name)
	category_option.item_selected.connect(func(_i): _refresh())
	_refresh()

func _refresh() -> void:
	var cat_keys := CATEGORIES.keys()
	var key := CATEGORIES[cat_keys[category_option.selected]]
	var text := ""

	if key == "world":
		text = GameLore.WORLD_INTRO if GameLore else "Loading..."
	elif key in WorldLoreExtended.DISTRICT_HISTORIES:
		text = WorldLoreExtended.DISTRICT_HISTORIES[key]
	elif key in WorldLoreExtended.FACTION_ORIGINS:
		text = WorldLoreExtended.FACTION_ORIGINS[key]
	elif key == "companion_lore":
		text = ""
		for lore_key in WorldLoreExtended.COMPANION_LORE.keys():
			text += "[b]%s[/b]\n%s\n\n" % [lore_key.replace("_", " "), WorldLoreExtended.COMPANION_LORE[lore_key]]
	else:
		text = GameLore.DISTRICT_LORE.get(key, "No lore found for this category.")

	lore_text.text = text
