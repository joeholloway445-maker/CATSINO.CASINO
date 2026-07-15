extends Control
class_name CombatUI

signal combat_finished(won: bool, stats: Dictionary)

class CooldownRing:
	extends Control

	var ratio := 0.0:
		set(value):
			ratio = clampf(value, 0.0, 1.0)
			queue_redraw()
	var ring_color := Color(0.35, 0.75, 1.0, 0.95)
	var background_color := Color(0.08, 0.1, 0.14, 0.65)

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var radius := minf(size.x, size.y) * 0.42
		if radius <= 1.0:
			return
		var center := size * 0.5
		draw_arc(center, radius, 0.0, TAU, 48, background_color, 4.0, true)
		if ratio > 0.0:
			draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * ratio, 48, ring_color, 5.0, true)

const DEFAULT_PLAYER_ID := "player"
const DEFAULT_ENEMY_ID := "enemy"
const DEFAULT_PLAYER_POS := Vector2.ZERO
const DEFAULT_ENEMY_POS := Vector2(3.0, 0.0)
const MAX_HEALTH := 100.0
const MAX_MANA := 100.0
const ENEMY_THINK_INTERVAL := 1.65
const STATUS_REFRESH_INTERVAL := 0.25
const ABILITY_IDS: Array[String] = [
	"solar_strike",
	"precision_strike",
	"shield_wall",
	"order_decree",
	"shadow_strike",
	"dream_veil",
	"prophecy_strike",
	"temporal_loop",
]

var _combat_id := ""
var _player_id := DEFAULT_PLAYER_ID
var _enemy_id := DEFAULT_ENEMY_ID
var _player_position := DEFAULT_PLAYER_POS
var _enemy_position := DEFAULT_ENEMY_POS
var _active := false
var _player_mana := MAX_MANA
var _enemy_ai_elapsed := 0.0
var _status_refresh_elapsed := 0.0

var _enemy_health_bar: ProgressBar
var _enemy_health_label: Label
var _player_health_bar: ProgressBar
var _player_health_label: Label
var _player_mana_bar: ProgressBar
var _player_mana_label: Label
var _player_energy_bar: ProgressBar
var _player_energy_label: Label
var _status_label: Label
var _player_status_list: HBoxContainer
var _enemy_status_list: HBoxContainer
var _floating_layer: Control
var _hotbar: HBoxContainer
var _ability_slots: Array[Dictionary] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	_connect_combat_signals()
	_refresh_resource_bars()
	_refresh_ability_slots()

func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_child(root)

	var enemy_panel := _build_health_panel("Enemy", false)
	root.add_child(enemy_panel)

	var battlefield := PanelContainer.new()
	battlefield.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(battlefield)

	var battlefield_margin := MarginContainer.new()
	battlefield_margin.add_theme_constant_override("margin_left", 16)
	battlefield_margin.add_theme_constant_override("margin_top", 12)
	battlefield_margin.add_theme_constant_override("margin_right", 16)
	battlefield_margin.add_theme_constant_override("margin_bottom", 12)
	battlefield.add_child(battlefield_margin)

	var battlefield_stack := VBoxContainer.new()
	battlefield_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battlefield_margin.add_child(battlefield_stack)

	_status_label = Label.new()
	_status_label.text = "Ready for live combat."
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_status_label.add_theme_font_size_override("font_size", 20)
	battlefield_stack.add_child(_status_label)

	var status_row := HBoxContainer.new()
	status_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battlefield_stack.add_child(status_row)

	var enemy_status_panel := _build_status_panel("Enemy Effects")
	_enemy_status_list = enemy_status_panel.get_meta("list") as HBoxContainer
	status_row.add_child(enemy_status_panel)

	var player_status_panel := _build_status_panel("Your Effects")
	_player_status_list = player_status_panel.get_meta("list") as HBoxContainer
	status_row.add_child(player_status_panel)

	_floating_layer = Control.new()
	_floating_layer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_floating_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battlefield_stack.add_child(_floating_layer)

	var player_panel := _build_player_panel()
	root.add_child(player_panel)

	_hotbar = HBoxContainer.new()
	_hotbar.custom_minimum_size = Vector2(0.0, 96.0)
	_hotbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hotbar.add_theme_constant_override("separation", 10)
	root.add_child(_hotbar)
	_build_hotbar()

func _process(delta: float) -> void:
	if not _active:
		return
	_player_mana = minf(MAX_MANA, _player_mana + 8.0 * delta)
	_enemy_ai_elapsed += delta
	_status_refresh_elapsed += delta
	if _enemy_ai_elapsed >= ENEMY_THINK_INTERVAL:
		_enemy_ai_elapsed = 0.0
		_use_enemy_ability()
	if _status_refresh_elapsed >= STATUS_REFRESH_INTERVAL:
		_status_refresh_elapsed = 0.0
		_refresh_status_effects()
	_refresh_resource_bars()
	_refresh_ability_slots()

func start_combat(
	player_id: String = DEFAULT_PLAYER_ID,
	enemy_id: String = DEFAULT_ENEMY_ID,
	player_pos: Vector2 = DEFAULT_PLAYER_POS,
	enemy_pos: Vector2 = DEFAULT_ENEMY_POS
) -> void:
	_player_id = player_id
	_enemy_id = enemy_id
	_player_position = player_pos
	_enemy_position = enemy_pos
	_player_mana = MAX_MANA
	_enemy_ai_elapsed = 0.0
	_status_refresh_elapsed = 0.0
	_combat_id = CombatRealtime.start_combat(_player_id, _enemy_id, _player_position, _enemy_position)
	_active = not _combat_id.is_empty()
	_status_label.text = "Combat live. Use abilities as cooldowns open."
	_refresh_resource_bars()
	_refresh_status_effects()
	_refresh_ability_slots()

func _build_health_panel(title: String, is_player: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	margin.add_child(box)

	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 18)
	box.add_child(title_label)

	var hp_bar := ProgressBar.new()
	hp_bar.max_value = MAX_HEALTH
	hp_bar.value = MAX_HEALTH
	hp_bar.show_percentage = false
	box.add_child(hp_bar)

	var hp_label := Label.new()
	hp_label.text = "%d / %d HP" % [int(MAX_HEALTH), int(MAX_HEALTH)]
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hp_label)

	if is_player:
		_player_health_bar = hp_bar
		_player_health_label = hp_label
	else:
		_enemy_health_bar = hp_bar
		_enemy_health_label = hp_label
	return panel

func _build_player_panel() -> PanelContainer:
	var panel := _build_health_panel("You", true)
	var margin := panel.get_child(0) as MarginContainer
	var box := margin.get_child(0) as VBoxContainer
	box.add_child(_build_resource_row("Mana", MAX_MANA, true))
	box.add_child(_build_resource_row("Energy", float(CombatRealtime.ENERGY_MAX), false))
	return panel

func _build_resource_row(label_text: String, max_value: float, is_mana: bool) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)

	var bar := ProgressBar.new()
	bar.max_value = max_value
	bar.value = max_value
	bar.show_percentage = false
	box.add_child(bar)

	var label := Label.new()
	label.text = "%s %d / %d" % [label_text, int(max_value), int(max_value)]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)

	if is_mana:
		_player_mana_bar = bar
		_player_mana_label = label
	else:
		_player_energy_bar = bar
		_player_energy_label = label
	return box

func _build_status_panel(title: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	margin.add_child(box)

	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title_label)

	var list := HBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(list)
	panel.set_meta("list", list)
	return panel

func _build_hotbar() -> void:
	_ability_slots.clear()
	for i in range(8):
		var ability_id := ABILITY_IDS[i]
		var ability: Dictionary = CombatRealtime.ABILITY_DATABASE.get(ability_id, {})
		var slot := Control.new()
		slot.custom_minimum_size = Vector2(116.0, 86.0)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_hotbar.add_child(slot)

		var button := Button.new()
		button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.text = "%d\n%s" % [i + 1, str(ability.get("name", ability_id))]
		button.tooltip_text = str(ability.get("description", ""))
		button.pressed.connect(_on_ability_pressed.bind(ability_id))
		slot.add_child(button)

		var ring := CooldownRing.new()
		ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		slot.add_child(ring)

		_ability_slots.append({
			"ability_id": ability_id,
			"button": button,
			"ring": ring,
		})

func _connect_combat_signals() -> void:
	if not CombatRealtime.combat_started.is_connected(_on_combat_started):
		CombatRealtime.combat_started.connect(_on_combat_started)
	if not CombatRealtime.ability_used.is_connected(_on_ability_used):
		CombatRealtime.ability_used.connect(_on_ability_used)
	if not CombatRealtime.damage_dealt.is_connected(_on_damage_dealt):
		CombatRealtime.damage_dealt.connect(_on_damage_dealt)
	if not CombatRealtime.status_applied.is_connected(_on_status_applied):
		CombatRealtime.status_applied.connect(_on_status_applied)
	if not CombatRealtime.ability_ready.is_connected(_on_ability_ready):
		CombatRealtime.ability_ready.connect(_on_ability_ready)
	if not CombatRealtime.ability_on_cooldown.is_connected(_on_ability_on_cooldown):
		CombatRealtime.ability_on_cooldown.connect(_on_ability_on_cooldown)
	if not CombatRealtime.combat_ended.is_connected(_on_combat_ended):
		CombatRealtime.combat_ended.connect(_on_combat_ended)

func _on_combat_started(player_id: String, enemy_id: String) -> void:
	if player_id != _player_id or enemy_id != _enemy_id:
		return
	_status_label.text = "Combat started: %s versus %s" % [player_id, enemy_id]

func _on_ability_pressed(ability_id: String) -> void:
	if not _active:
		_status_label.text = "Start combat before using abilities."
		return
	var ability: Dictionary = CombatRealtime.ABILITY_DATABASE.get(ability_id, {})
	if ability.is_empty():
		return

	var target_id := _enemy_id
	var target_position := _enemy_position
	var ability_type := str(ability.get("type", "damage"))
	if ability_type in ["defense", "buff", "utility"]:
		target_id = _player_id
		target_position = _player_position

	var used := CombatRealtime.use_ability(_player_id, ability_id, target_id, target_position)
	if not used:
		_status_label.text = "%s is not ready." % ability.get("name", ability_id)
	_refresh_resource_bars()
	_refresh_ability_slots()

func _on_ability_used(attacker_id: String, ability_id: String, target_id: String, damage: int) -> void:
	if attacker_id != _player_id and attacker_id != _enemy_id:
		return
	var ability: Dictionary = CombatRealtime.ABILITY_DATABASE.get(ability_id, {})
	var actor_name := "You" if attacker_id == _player_id else "Enemy"
	var target_name := "enemy" if target_id == _enemy_id else "you"
	_status_label.text = "%s used %s on %s for %d." % [
		actor_name,
		ability.get("name", ability_id),
		target_name,
		damage,
	]

func _on_damage_dealt(source: String, target: String, amount: int, crit: bool, distance: float) -> void:
	if target != _player_id and target != _enemy_id:
		return
	_refresh_resource_bars()
	if amount > 0:
		_spawn_damage_number(target, amount, crit, distance)
	if source == _player_id or source == _enemy_id:
		var hit_word := "crit" if crit else "hit"
		_status_label.text = "%s %s for %d at %.1fm." % [
			"You" if source == _player_id else "Enemy",
			hit_word,
			amount,
			distance,
		]

func _on_status_applied(target_id: String, status: String, duration: float) -> void:
	if target_id != _player_id and target_id != _enemy_id:
		return
	_status_label.text = "%s gained %s for %.1fs." % [
		"You" if target_id == _player_id else "Enemy",
		status.capitalize(),
		duration,
	]
	_refresh_status_effects()

func _on_ability_ready(actor_id: String, ability_id: String) -> void:
	if actor_id != _player_id:
		return
	var ability: Dictionary = CombatRealtime.ABILITY_DATABASE.get(ability_id, {})
	_status_label.text = "%s is ready." % ability.get("name", ability_id)
	_refresh_ability_slots()

func _on_ability_on_cooldown(actor_id: String, ability_id: String, remaining: float) -> void:
	if actor_id != _player_id:
		return
	var ability: Dictionary = CombatRealtime.ABILITY_DATABASE.get(ability_id, {})
	_status_label.text = "%s ready in %.1fs." % [ability.get("name", ability_id), remaining]
	_refresh_ability_slots()

func _on_combat_ended(winner_id: String, loser_id: String, stats: Dictionary) -> void:
	if winner_id != _player_id and loser_id != _player_id:
		return
	_active = false
	_refresh_resource_bars()
	_refresh_ability_slots()
	var won := winner_id == _player_id
	_status_label.text = "Victory." if won else "Defeated."
	var result_stats := stats.duplicate(true)
	result_stats["winner_id"] = winner_id
	result_stats["loser_id"] = loser_id
	result_stats["combat_id"] = _combat_id
	combat_finished.emit(won, result_stats)

func _use_enemy_ability() -> void:
	if not _active:
		return
	var enemy_abilities := ["feral_strike", "shadow_strike", "precision_strike", "primal_fury"]
	for ability_id in enemy_abilities:
		if CombatRealtime.use_ability(_enemy_id, ability_id, _player_id, _player_position):
			return

func _refresh_resource_bars() -> void:
	var player_health := MAX_HEALTH
	var enemy_health := MAX_HEALTH
	if not _combat_id.is_empty() and CombatRealtime.active_combats.has(_combat_id):
		var combat: Dictionary = CombatRealtime.active_combats[_combat_id]
		player_health = float(combat.get("player_health", MAX_HEALTH))
		enemy_health = float(combat.get("enemy_health", MAX_HEALTH))

	_set_bar(_player_health_bar, _player_health_label, player_health, MAX_HEALTH, "HP")
	_set_bar(_enemy_health_bar, _enemy_health_label, enemy_health, MAX_HEALTH, "HP")
	_set_bar(_player_mana_bar, _player_mana_label, _player_mana, MAX_MANA, "Mana")
	var energy := CombatRealtime.get_energy_level(_player_id) * CombatRealtime.ENERGY_MAX
	_set_bar(_player_energy_bar, _player_energy_label, energy, float(CombatRealtime.ENERGY_MAX), "Energy")

func _set_bar(bar: ProgressBar, label: Label, value: float, max_value: float, suffix: String) -> void:
	if not is_instance_valid(bar) or not is_instance_valid(label):
		return
	bar.max_value = max_value
	bar.value = clampf(value, 0.0, max_value)
	label.text = "%s %d / %d" % [suffix, int(bar.value), int(max_value)]

func _refresh_ability_slots() -> void:
	for slot in _ability_slots:
		var ability_id: String = slot["ability_id"]
		var button := slot["button"] as Button
		var ring := slot["ring"] as CooldownRing
		var ability: Dictionary = CombatRealtime.ABILITY_DATABASE.get(ability_id, {})
		var cooldown := CombatRealtime.get_ability_cooldown(_player_id, ability_id)
		var max_cooldown := maxf(float(ability.get("cooldown", 1.0)), 0.01)
		var energy_cost := int(ability.get("energy_cost", 0))
		var energy := CombatRealtime.get_energy_level(_player_id) * CombatRealtime.ENERGY_MAX
		var ready := _active and cooldown <= 0.0 and energy >= energy_cost
		button.disabled = not ready
		ring.ratio = cooldown / max_cooldown
		if cooldown > 0.0:
			button.text = "%s\n%.1fs" % [ability.get("name", ability_id), cooldown]
		else:
			button.text = "%s\n%d Energy" % [ability.get("name", ability_id), energy_cost]

func _refresh_status_effects() -> void:
	_populate_status_list(_player_status_list, _player_id)
	_populate_status_list(_enemy_status_list, _enemy_id)

func _populate_status_list(list: HBoxContainer, actor_id: String) -> void:
	if not is_instance_valid(list):
		return
	for child in list.get_children():
		child.queue_free()
	var effects: Array = CombatRealtime.player_status_effects.get(actor_id, [])
	if effects.is_empty():
		var none_label := Label.new()
		none_label.text = "None"
		list.add_child(none_label)
		return
	for effect in effects:
		var data := effect as Dictionary
		var label := Label.new()
		var remaining := maxf(float(data.get("duration", 0.0)) - float(data.get("elapsed", 0.0)), 0.0)
		label.text = "%s %.0fs" % [str(data.get("type", "effect")).capitalize(), remaining]
		list.add_child(label)

func _spawn_damage_number(target_id: String, amount: int, crit: bool, distance: float) -> void:
	if not is_instance_valid(_floating_layer):
		return
	var label := Label.new()
	label.text = "%s%d" % ["CRIT " if crit else "-", amount]
	label.add_theme_font_size_override("font_size", 28 if crit else 22)
	label.add_theme_color_override("font_color", Color.ORANGE_RED if crit else Color.WHITE)
	label.position = _floating_anchor(target_id) + Vector2(randf_range(-24.0, 24.0), randf_range(-10.0, 10.0))
	label.tooltip_text = "%.1fm" % distance
	_floating_layer.add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 48.0, 0.75).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.75).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)

func _floating_anchor(target_id: String) -> Vector2:
	var layer_size := _floating_layer.size
	if layer_size == Vector2.ZERO:
		layer_size = size
	if target_id == _enemy_id:
		return Vector2(layer_size.x * 0.68, layer_size.y * 0.25)
	return Vector2(layer_size.x * 0.32, layer_size.y * 0.65)
