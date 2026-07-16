class_name NPCSpawner
extends Node3D
## Spawns NPCs from WorldLoader (handcrafted npcs.json + NPCGenerator output)
## at the ESO-realistic bar: every NPC is an AmbientNpc (day-to-day wander,
## persistent-aware vs incognito reactions) wearing an NpcBody (MetaHuman →
## interim humanoid GLB visuals with natural per-NPC variation).
##
## Performance: NPCManager decides which NPCs deserve full detail; this node
## instantiates at most max_npcs_in_district and lets NpcBody.update_lod
## swap far NPCs to silhouette impostors.

@export var district_id: String = "paw_vegas"
@export var max_npcs_in_district: int = 50
## Set by the layer/city that owns this spawner (codebase convention —
## systems get _player handed to them, there is no "player" group).
var player: Node3D = null

const DIALOGUE_SCENE := "res://scenes/ui/npc_dialogue.tscn"
## Destination NPCs (quest givers / shopkeepers) greet you at arm's reach;
## pure ambient crowd members only speak if you walk right into them, and
## won't re-greet for a while — a street of 50 people must not be a wall
## of popups.
const INTERACTION_RADIUS_DESTINATION := 2.5
const INTERACTION_RADIUS_AMBIENT := 1.4
const REGREET_COOLDOWN_S := 45.0

## Optional terrain-height callback `func(x, z) -> float` (same shape
## MegaCityBuilder takes) so NPCs stand ON the ground, not at y = 0.
var height_provider: Callable = Callable()

var _spawned_npcs: Dictionary = {}  # npc_id -> AmbientNpc root
var _last_greeted: Dictionary = {}  # npc_id -> msec tick
var _dialogue_ui: Control = null

func _ready() -> void:
	if WorldLoader.districts.is_empty():
		await WorldLoader.world_loaded
	if player:
		NPCManager.set_player(player)
	_spawn_npcs()

func _spawn_npcs() -> void:
	var player_pos := player.global_position if player else Vector3.ZERO
	var npc_list := NPCManager.get_npcs_in_district(district_id, player_pos)
	var to_spawn := npc_list.slice(0, mini(max_npcs_in_district, npc_list.size()))
	for npc_data in to_spawn:
		_create_npc(npc_data)

func _create_npc(data: Dictionary) -> void:
	var npc_id: String = str(data.get("id", "npc"))
	if _spawned_npcs.has(npc_id):
		return

	var pos: Dictionary = data.get("position", {})

	# Root: the existing world-awareness behavior — wander loop, aware vs
	# incognito reaction rules, recruit signal. Integrated, not replaced.
	var root := AmbientNpc.new()
	root.name = npc_id
	root.npc_id = npc_id
	root.persona_role = str(data.get("role", "ambient_npc"))
	root.daily_task = str(data.get("daily_schedule", "wandering"))
	root.recruitable_as = str(data.get("recruitable_as", ""))
	# Real people stroll; they don't power-walk in circles.
	root.wander_speed = 1.15 + randf() * 0.35
	root.wander_radius = 4.0 + randf() * 5.0
	root.position = Vector3(
		float(pos.get("x", 0.0)), float(pos.get("y", 0.0)), float(pos.get("z", 0.0)))
	if height_provider.is_valid():
		var gx := global_position.x + root.position.x
		var gz := global_position.z + root.position.z
		root.position.y = float(height_provider.call(gx, gz)) - global_position.y
	add_child(root)

	# Visual: photoreal-proportioned human via the MetaHuman resolver chain.
	var body := NpcBody.new()
	root.add_child(body)
	body.build(data)

	# Interaction: walk close → lore dialogue + the NPC's AI reaction path.
	var is_destination: bool = str(data.get("shop_id", "")) != "" \
		or not (data.get("quest_ids", []) as Array).is_empty()
	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = INTERACTION_RADIUS_DESTINATION if is_destination else INTERACTION_RADIUS_AMBIENT
	shape.shape = sphere
	area.add_child(shape)
	root.add_child(area)
	area.body_entered.connect(func(other):
		if other is ThirdPersonController:
			_on_player_reached(npc_id, root)
	)

	_spawned_npcs[npc_id] = root
	NPCManager.register_instance(npc_id, body)

func _on_player_reached(npc_id: String, root: AmbientNpc) -> void:
	var now := Time.get_ticks_msec()
	var last: int = _last_greeted.get(npc_id, -1000000)
	if now - last < int(REGREET_COOLDOWN_S * 1000.0):
		return
	_last_greeted[npc_id] = now
	_open_dialogue(npc_id)
	# The aware/incognito reaction rules live in AmbientNpc — a direct
	# engagement is the one thing that always reaches an incognito NPC.
	root.interact(PlayerProfile.username)

func _open_dialogue(npc_id: String) -> void:
	if _dialogue_ui == null or not is_instance_valid(_dialogue_ui):
		if not ResourceLoader.exists(DIALOGUE_SCENE):
			return
		var packed: PackedScene = load(DIALOGUE_SCENE)
		if packed == null:
			return
		var canvas := CanvasLayer.new()
		add_child(canvas)
		_dialogue_ui = packed.instantiate()
		_dialogue_ui.hide()
		canvas.add_child(_dialogue_ui)
		if _dialogue_ui.has_signal("game_opened"):
			_dialogue_ui.game_opened.connect(_on_dialogue_game_opened)
	if _dialogue_ui.has_method("open_for_npc"):
		_dialogue_ui.call("open_for_npc", npc_id)

## Dialogue JSON actions like open_game:blackjack → real table scenes.
func _on_dialogue_game_opened(game_id: String) -> void:
	var scene := _scene_for_game_id(game_id)
	if scene != "" and ResourceLoader.exists(scene):
		get_tree().change_scene_to_file(scene)
		return
	NotificationUI.notify_info("Table '%s' isn't open yet — try the lobby." % game_id)

static func _scene_for_game_id(game_id: String) -> String:
	match game_id:
		"blackjack":
			return "res://scenes/games/arcade/blackjack.tscn"
		"poker":
			return "res://scenes/games/arcade/paw_poker.tscn"
		"holdem":
			return "res://scenes/games/arcade/holdem.tscn"
		"slots":
			return "res://scenes/games/slots/slot_machine.tscn"
		"race", "racing":
			return "res://scenes/games/racing/race_track.tscn"
		"combat":
			return "res://scenes/ui/combat_ui.tscn"
		_:
			return ""

func _exit_tree() -> void:
	for npc_id in _spawned_npcs.keys():
		NPCManager.unregister_instance(str(npc_id))
	_spawned_npcs.clear()
