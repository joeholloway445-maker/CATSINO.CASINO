extends CanvasLayer
class_name NotificationUI
# Toast notification system — shows brief messages in the corner

const DURATION = 3.0
const MAX_NOTIFICATIONS = 5

var _container: VBoxContainer
var _queue: Array[Dictionary] = []

func _ready() -> void:
	_container = VBoxContainer.new()
	_container.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_container.offset_left = -300
	_container.offset_top = -250
	_container.offset_right = -10
	_container.offset_bottom = -10
	_container.custom_minimum_size = Vector2(290, 240)
	add_child(_container)

func show_notification(message: String, color: Color = Color.WHITE, icon: String = "ℹ️") -> void:
	var note: Dictionary = {"message": message, "color": color, "icon": icon}
	_queue.append(note)
	_process_queue()

func _process_queue() -> void:
	if _container.get_child_count() >= MAX_NOTIFICATIONS: return
	if _queue.is_empty(): return
	var note = _queue.pop_front()
	_spawn_notification(note)

func _spawn_notification(note: Dictionary) -> void:
	var panel = PanelContainer.new()
	_container.add_child(panel)

	var hbox = HBoxContainer.new()
	panel.add_child(hbox)

	var icon_lbl = Label.new()
	icon_lbl.text = note.get("icon", "ℹ️")
	hbox.add_child(icon_lbl)

	var msg_lbl = Label.new()
	msg_lbl.text = note.get("message", "")
	msg_lbl.modulate = note.get("color", Color.WHITE)
	msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	msg_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(msg_lbl)

	# Auto-remove after duration
	var timer = get_tree().create_timer(DURATION)
	timer.timeout.connect(func():
		panel.queue_free()
		await get_tree().create_timer(0.1).timeout
		_process_queue()
	)

func notify_win(amount: int) -> void:
	show_notification("+%d 🪙 WIN!" % amount, Color(0.3, 1.0, 0.3), "🎉")

func notify_achievement(name: String) -> void:
	show_notification("Achievement: %s" % name, Color(1.0, 0.85, 0.0), "🏆")

func notify_level_up(level: int) -> void:
	show_notification("Level Up! Now Lv.%d" % level, Color(0.8, 0.4, 1.0), "⬆️")

func notify_companion_unlocked(companion_name: String) -> void:
	show_notification("Companion unlocked: %s" % companion_name, Color(0.3, 0.8, 1.0), "🐾")

func notify_error(message: String) -> void:
	show_notification(message, Color(1.0, 0.3, 0.3), "❌")
