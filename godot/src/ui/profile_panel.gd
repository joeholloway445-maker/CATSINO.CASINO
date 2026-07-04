class_name ProfilePanel
extends Control

@onready var username_label: Label = $Panel/VBox/UsernameLabel
@onready var level_label: Label = $Panel/VBox/LevelLabel
@onready var faction_label: Label = $Panel/VBox/FactionLabel
@onready var frame_label: Label = $Panel/VBox/FrameLabel
@onready var wins_label: Label = $Panel/VBox/Stats/WinsLabel
@onready var xp_bar: ProgressBar = $Panel/VBox/XPBar
@onready var companions_label: Label = $Panel/VBox/Stats/CompanionsLabel
@onready var title_label: Label = $Panel/VBox/TitleLabel

func _ready() -> void:
	_refresh()
	PlayerProfile.profile_updated.connect(_refresh)

func _refresh() -> void:
	username_label.text = PlayerProfile.get_display_name()
	level_label.text = "Level %d  •  Influence %d" % [PlayerProfile.level, EconomyManager.influence_level()]
	title_label.text = '"%s"' % PlayerProfile.active_title if PlayerProfile.active_title else ""
	faction_label.text = "Faction: %s" % PlayerProfile.faction
	var frame_text := PlayerProfile.selected_frame.capitalize()
	if PlayerProfile.ascended_frame != "":
		frame_text += " + %s (ascended)" % PlayerProfile.ascended_frame.capitalize()
	frame_label.text = "Frame: %s" % frame_text
	xp_bar.value = PlayerProfile.xp_progress() * 100
	companions_label.text = "Companions: %d" % PlayerProfile.active_companion_ids.size()
	wins_label.text = IdentityLens.rarity_text()
