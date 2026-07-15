extends CanvasLayer
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

# Accepts either a coin amount or a pre-formatted message — callers across
# the codebase use both.
func notify_win(amount_or_message) -> void:
	var msg: String = "+%d 🪙 WIN!" % amount_or_message if amount_or_message is int else str(amount_or_message)
	show_notification(msg, Color(0.3, 1.0, 0.3), "🎉")
	_play_ui_sfx("ui_confirm")

func notify_info(message: String) -> void:
	show_notification(message, Color(0.7, 0.85, 1.0), "ℹ️")
	_play_ui_sfx("ui_click")

func notify_achievement(name: String) -> void:
	show_notification("Achievement: %s" % name, Color(1.0, 0.85, 0.0), "🏆")
	_play_ui_sfx("ui_confirm")

func notify_level_up(level: int) -> void:
	show_notification("Level Up! Now Lv.%d" % level, Color(0.8, 0.4, 1.0), "⬆️")
	_play_ui_sfx("ui_switch")

func notify_companion_unlocked(companion_name: String) -> void:
	show_notification("Companion unlocked: %s" % companion_name, Color(0.3, 0.8, 1.0), "🐾")
	_play_ui_sfx("ui_confirm")

func notify_error(message: String) -> void:
	show_notification(message, Color(1.0, 0.3, 0.3), "❌")
	_play_ui_sfx("ui_error")

func _play_ui_sfx(slot: String) -> void:
	var stream := AssetLibrary.sound(slot)
	if stream == null:
		return
	# Duplicate so we don't flip loop on the AssetLibrary cache (ambience beds).
	var playable: AudioStream = stream.duplicate() if stream.has_method("duplicate") else stream
	if playable is AudioStreamOggVorbis:
		(playable as AudioStreamOggVorbis).loop = false
	elif playable is AudioStreamWAV:
		(playable as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
	var player := AudioStreamPlayer.new()
	player.stream = playable
	player.bus = "Master"
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
