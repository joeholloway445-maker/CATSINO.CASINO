extends Node3D
## Shared scene script for the explorable layers. Reuses the overworld kit
## (ProceduralTerrain + DayNightSky + ThirdPersonController) with per-layer
## rules from RealityLayers. One script, five moods:
##  - supraliminal: persistent chunks (DiscoveryManager), hubs PvE, wilds PvP
##  - liminal: NEVER static — chunks dissolve behind you; wander timer runs
##  - periliminal: generated-then-static from the run's recorded seed
##  - extraliminal/subliminal get placeholder grounds until their bespoke
##    scenes land (landmark overlay / apartment interior).

@export var layer_id: String = "supraliminal"

var _terrain: ProceduralTerrain
var _sky: DayNightSky
var _player: ThirdPersonController

func _ready() -> void:
	LayerManager.current_layer_id = layer_id

	_terrain = ProceduralTerrain.new()
	add_child(_terrain)

	_sky = DayNightSky.new()
	match layer_id:
		"liminal":
			_sky.day_length_seconds = 90.0 # time slides wrong here
		"periliminal":
			_sky.day_length_seconds = 999999.0
			_sky.start_hour = 3.0 # permanent dead-of-night
	IdentityLens.tune_sky(_sky)
	add_child(_sky)

	_player = ThirdPersonController.new()
	add_child(_player)

	var spawn := _spawn_point()
	_terrain.stream_around(DiscoveryManager.world_pos_to_chunk(spawn))
	spawn.y = _terrain.height_at(spawn.x, spawn.z) + 2.0
	_player.global_position = spawn
	_player.chunk_changed.connect(_on_chunk_changed)
	add_child(SensoriumAmbience.new()) # your build's own hum, under the music
	var hotbar := HotbarUI.new()
	hotbar.cast_requested.connect(_on_cast)
	add_child(hotbar)
	var stats := CharacterCreatorLogic.build_starting_stats(
		PlayerProfile.selected_race_id, PlayerProfile.faction, PlayerProfile.selected_frame)
	_attack_damage = 14 + int(stats.pow) / 2 + PlayerProfile.level
	_build_hud()
	_wire_presence()

var _peers: Dictionary = {} # peer_id -> RemotePlayer
var _peer_hp: Dictionary = {} # peer_id -> hp (open-PvP wilds)
var _player_hp := 100
var _shield := 0
var _attack_damage := 20
var _hostile_tick := 0.0

func _wire_presence() -> void:
	PresenceManager.peer_joined.connect(func(pid, prof):
		if _peers.has(pid): return
		var rp := RemotePlayer.new()
		rp.setup(pid, prof)
		add_child(rp)
		_peers[pid] = rp)
	PresenceManager.peer_updated.connect(func(pid, pos):
		if not _peers.has(pid):
			var rp := RemotePlayer.new()
			rp.setup(pid, PresenceManager.peer_profile(pid))
			add_child(rp)
			_peers[pid] = rp
		_peers[pid].move_to(pos, _terrain))
	PresenceManager.peer_left.connect(func(pid):
		if _peers.has(pid):
			_peers[pid].queue_free()
			_peers.erase(pid))
	PresenceManager.join_layer(layer_id)

func _spawn_point() -> Vector3:
	match layer_id:
		"supraliminal":
			# Factionless start in Arlington's center; faction players in
			# their own hub (Dallas/Fort Worth/Denton).
			var hub_id := {
				"SovereignCrown": "dallas",
				"VeiledCurrent": "fort_worth",
				"WildlandsAscendant": "denton",
			}.get(PlayerProfile.faction, "arlington")
			var hub := HubRegionData.by_id(hub_id)
			var b: Dictionary = hub["chunk_bounds"]
			var size := float(HubRegionData.CHUNK_SIZE)
			return Vector3((b.x + b.w / 2.0) * size, 0, (b.y + b.h / 2.0) * size)
		_:
			return Vector3.ZERO

const HubRegionData = preload("res://src/data/hub_region_data.gd")

var _prev_chunk := Vector2i(2147483647, 0)

func _on_chunk_changed(coord: Vector2i) -> void:
	_terrain.stream_around(coord)
	match layer_id:
		"supraliminal":
			_supraliminal_enter(coord)
		"liminal":
			_liminal_enter(coord)
		"periliminal":
			PeriliminalRuns.advance_depth()
	_prev_chunk = coord

func _supraliminal_enter(coord: Vector2i) -> void:
	var already_known := DiscoveryManager.has_chunk(coord)
	var chunk := DiscoveryManager.get_or_generate_chunk(coord)
	if chunk.is_hub:
		NotificationUI.notify_info("Entering %s — PvE sanctuary." % chunk.hub_id.capitalize())
		return
	var loadout := CharacterCreatorLogic.build_loadout(
		PlayerProfile.selected_race_id, PlayerProfile.selected_frame)
	var pack := PlayerInfluencePack.from_loadout("local_player", loadout, 1)
	DiscoveryManager.register_party_visit(coord, [pack])
	if not already_known:
		QuestManager.update_progress("discover_chunk")
		CrownManager.add_score("Top Terrain Explored", "local_player", 1)
	var owner := TerritoryControl.claim_owner(coord)
	if owner != "" and owner != PlayerProfile.faction:
		NotificationUI.notify_info("⚔️ %s territory — you are fair game here." % owner)

func _liminal_enter(coord: Vector2i) -> void:
	# Never static: the chunk you just left stops existing. Erase its
	# record so re-entering regenerates it differently (fresh prop seed
	# via a new WorldChunk), and harvest a little essence for the risk.
	if DiscoveryManager.has_chunk(_prev_chunk) and _prev_chunk != coord:
		DiscoveryManager._chunks.erase(_prev_chunk)
	EconomyManager.earn_currency("fragments", 1, "liminal_wandering")

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var back := Button.new()
	back.text = "⬅ Catsino"
	back.position = Vector2(10, 10)
	back.pressed.connect(func():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		LayerManager.transition_to("hyperliminal"))
	layer.add_child(back)

	var name_lbl := Label.new()
	name_lbl.text = RealityLayers.by_id(layer_id).get("name", layer_id)
	name_lbl.position = Vector2(10, 44)
	name_lbl.modulate = Color(1, 1, 1, 0.7)
	layer.add_child(name_lbl)

	if layer_id == "liminal":
		var timer_lbl := Label.new()
		timer_lbl.name = "WanderTimer"
		timer_lbl.position = Vector2(10, 68)
		timer_lbl.modulate = Color(0.8, 0.6, 1.0)
		layer.add_child(timer_lbl)

func _in_pvp_zone() -> bool:
	match layer_id:
		"liminal": return true
		"supraliminal": return TerritoryControl.is_pvp_at(_player.global_position)
		_: return false

## Cast resolution in the open world — targets are other players (or their
## offline ghost stand-ins). Hub interiors are sanctuaries: nothing lands.
func _on_cast(sk: Dictionary) -> void:
	SkillVFX.cast_flash(self, _player.global_position)
	var shape: String = sk.get("shape", "single")
	var radius: float = float(sk.get("radius", 3.0))
	var power: float = float(sk.get("power", 1.0))
	if sk.get("ult_cost", 0) > 0:
		SkillVFX.ultimate_burst(self, _player.global_position, maxf(radius, 6.0))
	elif shape == "aoe":
		SkillVFX.aoe_ring(self, _player.global_position, radius)
	elif shape == "line":
		SkillVFX.line_beam(self, _player.global_position, -_player.global_transform.basis.z, radius)
	match sk.get("kind", "damage"):
		"shield":
			_shield = maxi(_shield, int(30 * power))
			SkillVFX.shield_bubble(self, _player, 6.0)
			return
		"mobility":
			_player.global_position += -_player.global_transform.basis.z * (6.0 + 6.0 * power)
			return
		_:
			pass
	if not _in_pvp_zone():
		NotificationUI.notify_info("PvE sanctuary — your skills won't land on anyone here.")
		return
	var dmg := int(_attack_damage * power)
	var reach := maxf(radius, 4.0)
	for pid in _peers.keys():
		var rp: RemotePlayer = _peers[pid]
		if not is_instance_valid(rp): continue
		if rp.global_position.distance_to(_player.global_position) > reach: continue
		_peer_hp[pid] = _peer_hp.get(pid, 80 + randi() % 60) - dmg
		SkillVFX.hit_spark(self, rp.global_position)
		SkillManager.gain_ultimate(6.0)
		if _peer_hp[pid] <= 0:
			_on_peer_killed(pid, rp)

func _on_peer_killed(pid: String, rp: RemotePlayer) -> void:
	_peers.erase(pid)
	_peer_hp.erase(pid)
	rp.queue_free()
	var loot := 15 + randi() % 40
	EconomyManager.earn_currency("tokens", loot, "open_pvp_kill")
	EconomyManager.earn_prestige(6, "pvp_kill")
	CrownManager.add_score("Top PvP Kills", "local_player", 1, PlayerProfile.faction)
	CrownManager.log_provisional_pvp("local_player", 0.05)
	NotificationUI.notify_win("⚔️ %s falls in the wilds (+%d tokens)" % [pid.trim_prefix("ghost_").replace("_", " "), loot])

## Dying in the open: lose 20% of your tokens and wake up at your hub —
## Arlington for the factionless. Getting TO your faction the first time
## means surviving this gauntlet (or getting carried).
func _on_player_died(killer: String) -> void:
	var lost := int(EconomyManager.get_balance("tokens") * 0.2)
	if lost > 0:
		await EconomyManager.spend_currency("tokens", lost, "open_pvp_death")
	NotificationUI.notify_error("💀 %s got you in the open. -%d tokens. The wilds don't care who you were." % [killer, lost])
	_player_hp = 100
	_shield = 0
	var spawn := _spawn_point()
	spawn.y = _terrain.height_at(spawn.x, spawn.z) + 2.0
	_player.global_position = spawn
	_player.velocity = Vector3.ZERO

func _process(_delta: float) -> void:
	if is_instance_valid(_player):
		PresenceManager.report_position(_player.global_position)
	# The wilds bite back: in open PvP, nearby hostiles take swings at you.
	if is_instance_valid(_player) and _in_pvp_zone():
		_hostile_tick += _delta
		if _hostile_tick >= 2.0:
			_hostile_tick = 0.0
			for pid in _peers.keys():
				var rp: RemotePlayer = _peers[pid]
				if not is_instance_valid(rp): continue
				if rp.global_position.distance_to(_player.global_position) < 10.0:
					var hit := 6 + randi() % 10
					if _shield > 0:
						var ab := mini(_shield, hit)
						_shield -= ab
						hit -= ab
					_player_hp -= hit
					SkillManager.gain_ultimate(3.0)
					if _player_hp <= 0:
						_on_player_died(pid.trim_prefix("ghost_").replace("_", " "))
					break
	if layer_id == "liminal":
		var lbl: Label = get_node_or_null("CanvasLayer/WanderTimer")
		if lbl == null:
			for child in get_children():
				if child is CanvasLayer:
					lbl = child.get_node_or_null("WanderTimer")
		if lbl:
			lbl.text = "The Periliminal notices you in %d s" % int(LayerManager.wander_seconds_left())
