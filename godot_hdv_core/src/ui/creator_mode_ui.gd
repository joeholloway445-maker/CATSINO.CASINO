extends Control
## Creator-mode sandbox flow: pick a timeline (replay or forge, depending on
## which creator sub-mode is active), then submit it into the shared UGC
## review pipeline (UgcSubmission -> Discord mod ticket -> dev sign-off).

const TimelineData = preload("res://src/data/timeline_data.gd")

@onready var timeline_list: ItemList = $TimelineList
@onready var status_label: Label = $StatusLabel
@onready var submit_button: Button = $SubmitButton

var _shown_timelines: Array[Dictionary] = []
var _current_submission: UgcSubmission

func _ready() -> void:
	var mode := GameModeManager.active_mode()
	var timeline_mode: String = mode.get("timeline_mode", "")
	_shown_timelines = TimelineData.by_mode(timeline_mode) if not timeline_mode.is_empty() else TimelineData.TIMELINES
	timeline_list.clear()
	for t in _shown_timelines:
		timeline_list.add_item(t["name"])
	status_label.text = "Active mode: %s. Select a timeline, then Submit for Review when ready." % mode.get("name", "")
	submit_button.pressed.connect(_on_submit_pressed)

func _on_submit_pressed() -> void:
	var selected := timeline_list.get_selected_items()
	if selected.is_empty():
		status_label.text = "Select a timeline first."
		return
	var timeline: Dictionary = _shown_timelines[selected[0]]
	_current_submission = UgcSubmission.new()
	_current_submission.id = "%s_%d" % [timeline["id"], Time.get_unix_time_from_system()]
	_current_submission.source_mode_id = GameModeManager.active_mode_id
	_current_submission.timeline_mode = timeline["mode"]
	status_label.text = "Submitting '%s' to mod review..." % timeline["name"]
	await _current_submission.submit_ticket()
	status_label.text = "Submitted '%s' (id: %s) — status: %s. Awaiting Discord mod review, then dev sign-off." % [
		timeline["name"], _current_submission.id, UgcSubmission.Status.keys()[_current_submission.status]
	]

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/worlds/world_select.tscn")
