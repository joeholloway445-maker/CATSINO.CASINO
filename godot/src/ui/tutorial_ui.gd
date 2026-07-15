extends Control
class_name TutorialUI
# First-time user tutorial — walks through core game mechanics

signal tutorial_complete()

const STEPS = [
	{
		title = "Welcome to CATSINO.CASINO! 🐱",
		body = "You're now in Paws Vegas — a city where cats gamble, race, and battle for style. This quick tutorial will get you started.",
		icon = "🎰",
	},
	{
		title = "Your Cat's Stats",
		body = "Every cat has 5 stats:\n• POW — combat damage\n• RES — defense\n• SPD — race speed\n• LCK — slot bonuses & crits\n• STY — style multiplier\n\nEquip frames, mods, and items to boost them.",
		icon = "📊",
	},
	{
		title = "Companions",
		body = "Collect up to 500 companions across 4 factions. Equip 3 at a time for synergy bonuses. Rare companions have powerful signature moves.",
		icon = "🐾",
	},
	{
		title = "Factions",
		body = "Choose a faction for bonus multipliers:\n• SovereignCrown: +10% slots, +5% combat\n• WildlandsAscendant: +10% combat, +5 race SPD\n• VeiledCurrent: +12% slots, +8 race SPD\n• Factionless: no bonuses, no restrictions",
		icon = "⚔️",
	},
	{
		title = "Games & Districts",
		body = "Paws Vegas has 5 districts:\n🎰 Paws Vegas — slots & cards\n⚔️ Cat Coliseum — combat\n🏁 Neon Alley — racing\n🌿 Cat Forest — quests\n👾 Arcade Galaxy — mini-games",
		icon = "🗺️",
	},
	{
		title = "Economy",
		body = "CATSINO.CASINO uses Cat Coins 🪙 (free virtual currency) and Gems 💎 (earned through play). No real money is involved. All RNG is server-authoritative.",
		icon = "🪙",
	},
	{
		title = "You're Ready! 🎉",
		body = "Claim your daily login reward, explore Paws Vegas, and start building your roster. Good luck, cat!",
		icon = "🎉",
	},
]

var _current_step: int = 0
var _title_label: Label
var _body_label: Label
var _icon_label: Label
var _step_indicator: Label
var _next_btn: Button
var _skip_btn: Button

func _ready() -> void:
	_build_ui()
	_show_step(0)

func _build_ui() -> void:
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(480, 360)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	_icon_label = Label.new()
	_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_label.add_theme_font_size_override("font_size", 48)
	vbox.add_child(_icon_label)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(_title_label)

	_body_label = Label.new()
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_body_label)

	_step_indicator = Label.new()
	_step_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_step_indicator.modulate = Color(0.5, 0.5, 0.5)
	vbox.add_child(_step_indicator)

	var btn_row = HBoxContainer.new()
	vbox.add_child(btn_row)

	_skip_btn = Button.new()
	_skip_btn.text = "Skip Tutorial"
	_skip_btn.pressed.connect(_finish)
	btn_row.add_child(_skip_btn)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(spacer)

	_next_btn = Button.new()
	_next_btn.text = "Next →"
	_next_btn.add_theme_font_size_override("font_size", 14)
	_next_btn.pressed.connect(_on_next)
	btn_row.add_child(_next_btn)

func _show_step(step: int) -> void:
	if step >= STEPS.size():
		_finish()
		return
	var s = STEPS[step]
	_icon_label.text = s.icon
	_title_label.text = s.title
	_body_label.text = s.body
	_step_indicator.text = "%d / %d" % [step + 1, STEPS.size()]
	_next_btn.text = "Finish! 🎉" if step == STEPS.size() - 1 else "Next →"

func _on_next() -> void:
	_current_step += 1
	_show_step(_current_step)

func _finish() -> void:
	tutorial_complete.emit()
	queue_free()
