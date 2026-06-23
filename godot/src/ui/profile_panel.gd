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
	PlayerProfile.xp_changed.connect(func(_xp, _lv): _refresh())

func _refresh() -> void:
	username_label.text = PlayerProfile.get_display_name()
	level_label.text = "Level %d" % PlayerProfile.level
	title_label.text = '"%s"' % PlayerProfile.current_title
	faction_label.text = "Faction: %s" % PlayerProfile.faction if PlayerProfile.faction else "No Faction"
	frame_label.text = "Frame: %s" % PlayerProfile.frame_id.capitalize()
	xp_bar.value = PlayerProfile.xp_progress() * 100
	companions_label.text = "Companions: %d" % PlayerProfile.companions.size()
	wins_label.text = "Wins: %d" % PlayerProfile.total_wins
