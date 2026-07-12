class_name ProfilePanel
extends Control

@onready var username_label: Label = $Panel/VBox/UsernameLabel
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var perception_label: Label = $Panel/VBox/PerceptionLabel
@onready var prestige_bar: ProgressBar = $Panel/VBox/PrestigeBar
@onready var prestige_label: Label = $Panel/VBox/PrestigeLabel
@onready var stats_list: VBoxContainer = $Panel/VBox/Tabs/Stats/List
@onready var skills_list: VBoxContainer = $Panel/VBox/Tabs/Skills/List
@onready var equipment_list: VBoxContainer = $Panel/VBox/Tabs/Equipment/List
@onready var titles_list: VBoxContainer = $Panel/VBox/Tabs/Titles/List
@onready var achievements_list: VBoxContainer = $Panel/VBox/Tabs/Achievements/List

const GAME_STATE_NAMES := {
	0: "Loading",
	1: "Login",
	2: "World",
	3: "Game",
	4: "Social",
	5: "Settings",
}

func _ready() -> void:
	_refresh()
	if not PlayerProfile.profile_updated.is_connected(_refresh):
		PlayerProfile.profile_updated.connect(_refresh)

func _refresh() -> void:
	username_label.text = PlayerProfile.get_display_name()
	title_label.text = '"%s"' % PlayerProfile.active_title if not PlayerProfile.active_title.is_empty() else "No title selected"
	perception_label.text = "Perception: %d" % PlayerProfile.level
	var progress := PlayerProfile.xp_progress()
	prestige_bar.value = progress * 100.0
	prestige_label.text = "Prestige: %d%% to Perception %d" % [roundi(progress * 100.0), PlayerProfile.level + 1]
	_populate_stats()
	_populate_skills()
	_populate_equipment()
	_populate_titles()
	_populate_achievements()

func _populate_stats() -> void:
	_clear_list(stats_list)
	_add_section(stats_list, "Identity")
	_add_line(stats_list, "Username: %s" % PlayerProfile.username)
	_add_line(stats_list, "Display name: %s" % PlayerProfile.get_display_name())
	_add_line(stats_list, "Faction: %s" % PlayerProfile.faction)
	var frame_text := PlayerProfile.selected_frame.capitalize()
	if PlayerProfile.ascended_frame != "":
		frame_text += " + %s (ascended)" % PlayerProfile.ascended_frame.capitalize()
	_add_line(stats_list, "Frame: %s" % frame_text)
	_add_line(stats_list, "Race: %s" % PlayerProfile.selected_race_id.capitalize())
	_add_line(stats_list, "Mod: %s" % (PlayerProfile.selected_mod.capitalize() if not PlayerProfile.selected_mod.is_empty() else "None"))
	_add_line(stats_list, "Active companions: %d" % PlayerProfile.active_companion_ids.size())
	_add_line(stats_list, IdentityLens.rarity_text())

	_add_section(stats_list, "Progress")
	_add_line(stats_list, "Perception: %d" % PlayerProfile.level)
	_add_line(stats_list, "XP: %d" % PlayerProfile.xp)
	_add_line(stats_list, "Influence: %d" % EconomyManager.influence_level())
	_add_line(stats_list, "Game state: %s" % GAME_STATE_NAMES.get(int(GameManager.game_state), "Unknown"))

	_add_section(stats_list, "Wallet")
	for currency_id in EconomyManager.CURRENCIES.keys():
		var currency: Dictionary = EconomyManager.CURRENCIES[currency_id]
		_add_line(stats_list, "%s %s: %d" % [
			str(currency.get("icon", "")),
			str(currency.get("name", currency_id)),
			EconomyManager.get_balance(str(currency_id)),
		])

func _populate_skills() -> void:
	_clear_list(skills_list)
	_add_line(skills_list, "Skill points: %d" % SkillManager.skill_points)
	_add_line(skills_list, "Active bar: %s" % ["I", "II"][SkillManager.active_bar])
	_add_line(skills_list, "Flux: %d / %d" % [roundi(SkillManager.flux), roundi(SkillManager.flux_max)])
	_add_line(skills_list, "Ultimate charge: %d" % roundi(SkillManager.ultimate_charge))

	_add_section(skills_list, "Equipped bars")
	for bar_index in range(SkillManager.bars.size()):
		var bar: Dictionary = SkillManager.bars[bar_index]
		_add_line(skills_list, "Bar %s" % ["I", "II"][bar_index])
		var actives: Array = bar.get("actives", [])
		for slot_index in range(actives.size()):
			_add_skill_line(skills_list, slot_index + 1, str(actives[slot_index]))
		_add_skill_line(skills_list, 0, str(bar.get("ultimate", "")), true)

	_add_section(skills_list, "Known lines")
	for line in SkillManager.known_lines():
		var line_data: Dictionary = line
		var attunement := SkillManager.attunement_of(str(line_data.get("id", "")))
		var element_name := "none"
		if attunement != "":
			element_name = str(SkillData.element(attunement).get("name", attunement))
		_add_line(skills_list, "%s - attunement: %s" % [str(line_data.get("name", "Unknown line")), element_name])

func _populate_equipment() -> void:
	_clear_list(equipment_list)
	_add_section(equipment_list, "Equipped")
	_add_equipment_slot("Cosmetic skin", InventoryManager.ItemType.COSMETIC_SKIN)
	_add_equipment_slot("Companion accessory", InventoryManager.ItemType.COMPANION_ACCESSORY)
	_add_equipment_slot("Trail effect", InventoryManager.ItemType.TRAIL_EFFECT)
	_add_equipment_slot("Title item", InventoryManager.ItemType.TITLE)
	_add_equipment_slot("Emote", InventoryManager.ItemType.EMOTE)

	var items := InventoryManager.get_all_items()
	_add_section(equipment_list, "Inventory")
	if items.is_empty():
		_add_line(equipment_list, "No inventory items yet.")
		return
	for item in items:
		var item_data: Dictionary = item
		var equipped := " (equipped)" if bool(item_data.get("equipped", false)) else ""
		_add_line(equipment_list, "%s%s" % [str(item_data.get("name", item_data.get("id", "Unknown item"))), equipped])

func _populate_titles() -> void:
	_clear_list(titles_list)
	_add_line(titles_list, "Active title: %s" % (PlayerProfile.active_title if not PlayerProfile.active_title.is_empty() else "None"))
	if PlayerProfile.titles.is_empty():
		_add_line(titles_list, "No titles unlocked yet.")
		return
	for title in PlayerProfile.titles:
		var suffix := " (active)" if str(title) == PlayerProfile.active_title else ""
		_add_line(titles_list, "%s%s" % [str(title), suffix])

func _populate_achievements() -> void:
	_clear_list(achievements_list)
	var achievements := AchievementManager.get_all_achievements()
	var unlocked_count := 0
	for achievement in achievements:
		var counted_achievement: Dictionary = achievement
		if bool(counted_achievement.get("unlocked", false)):
			unlocked_count += 1
	_add_line(achievements_list, "Unlocked: %d / %d" % [unlocked_count, achievements.size()])

	_add_section(achievements_list, "Unlocked")
	var added_unlocked := false
	for achievement in achievements:
		var unlocked_achievement: Dictionary = achievement
		if bool(unlocked_achievement.get("unlocked", false)):
			_add_achievement_line(unlocked_achievement)
			added_unlocked = true
	if not added_unlocked:
		_add_line(achievements_list, "No achievements unlocked yet.")

	_add_section(achievements_list, "Locked")
	for achievement in achievements:
		var locked_achievement: Dictionary = achievement
		if not bool(locked_achievement.get("unlocked", false)):
			_add_achievement_line(locked_achievement)

func _add_skill_line(list: VBoxContainer, slot: int, skill_id: String, is_ultimate: bool = false) -> void:
	var slot_name := "Ultimate" if is_ultimate else "Slot %d" % slot
	if skill_id.is_empty():
		_add_line(list, "%s: Empty" % slot_name)
		return
	var skill := SkillManager.resolved(skill_id)
	var rank := SkillManager.rank_of(skill_id)
	var rank_text := "" if rank <= 0 else " rank %s" % ["I", "II", "III", "IV"][rank - 1]
	_add_line(list, "%s: %s%s" % [slot_name, str(skill.get("name", skill_id)), rank_text])

func _add_equipment_slot(label_text: String, item_type: int) -> void:
	var item := InventoryManager.get_equipped_by_type(item_type)
	if item.is_empty():
		_add_line(equipment_list, "%s: Empty" % label_text)
		return
	_add_line(equipment_list, "%s: %s" % [label_text, str(item.get("name", item.get("id", "Unknown item")))])

func _add_achievement_line(achievement: Dictionary) -> void:
	var status := "Unlocked" if bool(achievement.get("unlocked", false)) else "Locked"
	_add_line(achievements_list, "%s - %s: %s (+%d XP)" % [
		status,
		str(achievement.get("name", "Unknown achievement")),
		str(achievement.get("desc", "")),
		int(achievement.get("xp", 0)),
	])

func _clear_list(list: VBoxContainer) -> void:
	for child in list.get_children():
		child.queue_free()

func _add_section(list: VBoxContainer, text: String) -> Label:
	var label := _add_line(list, text)
	label.add_theme_font_size_override("font_size", 18)
	label.modulate = Color(0.85, 0.8, 1.0)
	return label

func _add_line(list: VBoxContainer, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list.add_child(label)
	return label
