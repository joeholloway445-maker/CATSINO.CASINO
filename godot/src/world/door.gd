class_name LiminalDoor
extends Area3D
## The door template — the psychology instrument. Place anywhere (liminal
## chunks spawn them; hubs can too). It watches the WHOLE approach:
## distance-ring entry starts the clock, circling is measured by bearing
## change, peeking by threshold dwell, open-then-close by state flips.
## On resolution it tells Hope (drive inference + Supabase row) and
## reveals what's behind — which is ALSO seeded by who's opening it.

signal opened(door_id: String, behind: Dictionary)

@export var door_id := ""
@export var layer := "liminal"

var _watch_start := -1.0
var _bearing_accum := 0.0
var _last_bearing := 0.0
var _open_count := 0
var _resolved := false
var _panel: MeshInstance3D
## Fixed per door location (not per player) — the same door is locked to
## the same influence tier for everyone. Not every door in the Liminal is
## meant to open for you; that's what equivalent exchange is for.
var _required_tier := 0

const BEHIND_TABLE := [
	{kind="loot", desc="a room of unclaimed winnings"},
	{kind="hall", desc="another hallway, identical to this one"},
	{kind="drop", desc="a straight fall into the layer below"},
	{kind="mirror", desc="yourself, half a second delayed"},
	{kind="hope", desc="something warm that knows your name"},
	{kind="nothing", desc="paint on a wall pretending to be a door"},
]

func _ready() -> void:
	if door_id == "":
		door_id = "door_%d_%d" % [int(global_position.x), int(global_position.z)]
	# ~40% of doors ask nothing; the rest sit behind tiers 1-3 of
	# equivalent exchange, fixed by location so it's the same lock for
	# every player who finds this particular door.
	var lock_roll := absi(hash(door_id)) % 5
	_required_tier = maxi(lock_roll - 1, 0) # 0,0,1,2,3
	_panel = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.6, 3.0, 0.15)
	_panel.mesh = box
	_panel.position.y = 1.5
	var panel_color := Color(0.4, 0.35, 0.3) if _required_tier == 0 else Color(0.45, 0.3, 0.5)
	_panel.material_override = IdentityLens.world_material(panel_color, 0.4)
	if _required_tier > 0:
		SkillVFX.add_aura_shell(self, Color(0.7, 0.4, 0.9), 0.03 * _required_tier)
	add_child(_panel)
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 6.0 # the watching ring, not the door itself
	cs.shape = sph
	add_child(cs)
	body_entered.connect(_on_body_entered)
	input_ray_pickable = true
	input_event.connect(func(_c, ev, _p, _n, _i):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_open())

func _on_body_entered(b: Node3D) -> void:
	if b is ThirdPersonController and _watch_start < 0.0:
		_watch_start = Time.get_ticks_msec() / 1000.0
		_last_bearing = _bearing_to(b)

func _physics_process(_d: float) -> void:
	if _watch_start < 0.0 or _resolved:
		return
	for b in get_overlapping_bodies():
		if b is ThirdPersonController:
			var bearing := _bearing_to(b)
			_bearing_accum += absf(wrapf(bearing - _last_bearing, -PI, PI))
			_last_bearing = bearing
			return
	# They left the ring without opening: avoided.
	_resolve("avoided", null)

func _bearing_to(b: Node3D) -> float:
	var rel := b.global_position - global_position
	return atan2(rel.x, rel.z)

func _open() -> void:
	_open_count += 1
	if _open_count == 1:
		# Give them a beat to slam it shut — that's data too.
		get_tree().create_timer(1.2).timeout.connect(func():
			if not _resolved and _open_count == 1:
				_walk_through())
	else:
		_resolve("opened_closed", null)

func _walk_through() -> void:
	var hesitated := Time.get_ticks_msec() / 1000.0 - _watch_start
	var approach := "rushed"
	if _bearing_accum > PI:
		approach = "circled"
	elif hesitated > 6.0:
		approach = "lingered"
	elif hesitated > 2.0:
		approach = "peeked"

	if _required_tier > 0 and EconomyManager.influence_level() < _required_tier * 10:
		# Not every door opens for everyone. Influence earned through play
		# opens it free; otherwise it's equivalent exchange, on the spot,
		# or the door stays shut — no in-between.
		if not await EconomyManager.equivalent_exchange("liminal_door_%s" % door_id, _required_tier):
			_resolve("locked", null)
			return

	# What's behind is seeded by WHO opens it — same door, different truths.
	var seed_val := PerceptionEngine.generation_seed(
		PlayerProfile.selected_race_id, EconomyManager.influence_level(),
		int(global_position.x), int(global_position.y), int(global_position.z))
	var behind: Dictionary = BEHIND_TABLE[absi(seed_val) % BEHIND_TABLE.size()]
	_resolve(approach, behind)

func _resolve(approach: String, behind) -> void:
	if _resolved:
		return
	_resolved = true
	var hesitated := maxf(Time.get_ticks_msec() / 1000.0 - _watch_start, 0.0)
	Hope.observe_door(door_id, approach, hesitated)
	if behind != null:
		Hope.record("door_behind", {"door": door_id, "layer": layer, "behind": behind})
		opened.emit(door_id, behind)
		NotificationUI.notify_info("Behind the door: %s" % behind.desc)
		match behind.kind:
			"loot": EconomyManager.earn_currency("fragments", 25, "door_loot")
			"hope": Hope.gain_bond(10, "found her")
			"drop": LayerManager.transition_to("periliminal", true)
			_: pass
		SkillVFX.aoe_ring(self, global_position, 2.0)
		_panel.visible = false
	set_physics_process(false)
