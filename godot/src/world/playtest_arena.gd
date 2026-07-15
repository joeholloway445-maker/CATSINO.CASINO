extends Node3D
## Root script for playtest_arena.tscn. Spawns the real production player
## controller (ThirdPersonController — same class overworld.gd/layer_world.gd
## use) rather than a scene-file instance, matching how it's built
## everywhere else in the codebase. visual_mode = "cat" because this arena
## represents the Catsino (hyperliminal layer): cat is mandatory there,
## identity-default everywhere else, and PvXC forces identity in PvP
## regardless of zone — see PvxcZone._apply_phase() for that override.

@export var spawn_position := Vector3(0, 2, 0)

func _ready() -> void:
	var queued := ""
	if Engine.has_meta("arena_queued_mode"):
		queued = str(Engine.get_meta("arena_queued_mode"))
		Engine.remove_meta("arena_queued_mode")
	var player := ThirdPersonController.new()
	player.name = "Player"
	player.visual_mode = "cat"
	add_child(player)
	player.global_position = spawn_position
	if queued != "":
		NotificationUI.notify_info("Arena mode: %s — survive the pit." % queued)
