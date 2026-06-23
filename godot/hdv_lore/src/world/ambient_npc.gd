class_name AmbientNpc
extends Node3D
## A "mob" NPC going about a day-to-day task in a persistent world. Whether
## it reacts to the player at all is governed by GameModeManager's active
## mode (persistent_aware vs. persistent_incognito): in incognito, this NPC
## stays scripted/oblivious until the player directly interacts with it, and
## can't tell the player is different unless the player gives that away
## during the interaction. Recruitable NPCs can become companions, pets, or
## mounts once recruit() succeeds.

signal reaction_received(result: Dictionary)
signal recruited(npc_id: String, kind: String)

## "dream" | "hope" | "no_one" | "vision" | "apex" — passed straight through
## to PersonaMatrixClient, matching lib/personamatrix/types.ts's PersonaModule.
@export var persona_module: String = "dream"
@export var persona_role: String = "ambient_npc"
@export var npc_id: String = ""
@export var daily_task: String = "wandering"
## "" (not recruitable), "companion", "pet", or "mount".
@export var recruitable_as: String = ""

## Wander behavior: picks a random point within wander_radius of the spawn
## origin, walks to it, idles briefly, repeats — the visible "day-to-day
## task" loop. Purely cosmetic; has no bearing on _should_react_to_player_presence().
@export var wander_radius: float = 6.0
@export var wander_speed: float = 1.6
@export var idle_time_range: Vector2 = Vector2(1.5, 4.0)

var _has_been_interacted_with: bool = false
var _origin: Vector3
var _wander_target: Vector3
var _idle_timer: float = 0.0
var _is_idling: bool = true

func _ready() -> void:
	_origin = position
	_wander_target = _origin

func _process(delta: float) -> void:
	if _is_idling:
		_idle_timer -= delta
		if _idle_timer <= 0.0:
			_pick_new_wander_target()
		return
	var to_target := _wander_target - position
	to_target.y = 0.0
	if to_target.length() <= 0.1:
		_is_idling = true
		_idle_timer = randf_range(idle_time_range.x, idle_time_range.y)
		return
	position += to_target.normalized() * wander_speed * delta
	if to_target.length() > 0.01:
		look_at(position + to_target, Vector3.UP)

func _pick_new_wander_target() -> void:
	var angle := randf_range(0.0, TAU)
	var dist := randf_range(0.0, wander_radius)
	_wander_target = _origin + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
	_is_idling = false

func _should_react_to_player_presence() -> bool:
	return GameModeManager.is_aware() or _has_been_interacted_with

## Called when a player directly engages this NPC (dialogue, emote, combat,
## etc.) — the only way to get a reaction out of it in incognito mode.
func interact(player_id: String, give_away_difference: bool = false) -> void:
	_has_been_interacted_with = true
	if give_away_difference:
		# Player chose to reveal themselves mid-interaction; from here on this
		# NPC (and whatever it gossips to) treats them as aware would.
		_has_been_interacted_with = true
	_request_ai_reaction(player_id)

func _request_ai_reaction(player_id: String) -> void:
	if not _should_react_to_player_presence():
		return
	var task := {
		"npc_id": npc_id,
		"player_id": player_id,
		"daily_task": daily_task,
		"aware": GameModeManager.is_aware(),
	}
	var response := await PersonaMatrixClient.request_persona(persona_module, persona_role, task)
	reaction_received.emit(response)

func recruit(player_id: String) -> bool:
	if recruitable_as.is_empty():
		return false
	GameData.recruit_companion(npc_id, recruitable_as, name)
	recruited.emit(npc_id, recruitable_as)
	return true
