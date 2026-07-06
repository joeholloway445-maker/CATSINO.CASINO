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
	add_child(RealityBendOverlay.new(_reality_bend_baseline()))
	var hotbar := HotbarUI.new()
	hotbar.cast_requested.connect(_on_cast)
	add_child(hotbar)
	add_child(HopeUI.new()) # Hope is always on YOUR screen
	add_child(ChatUI.new()) # T toggles; five channels
	# B opens the Blueprint Forge anywhere in the open world.
	set_process_unhandled_key_input(true)
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
	PresenceManager.bot_wants_cast.connect(_on_bot_cast)
	PresenceManager.join_layer(layer_id)

## Tiered bots (see PresenceManager) "attacking" — gives them a visible
## skill flash instead of only the silent hostile-tick damage, and feeds
## landed hits back so adaptive bots escalate mid-fight.
func _on_bot_cast(pid: String, skill: Dictionary) -> void:
	if not _peers.has(pid) or not is_instance_valid(_peers[pid]):
		return
	var rp: RemotePlayer = _peers[pid]
	SkillVFX.cast_flash(self, rp.global_position)
	if not _in_pvp_zone():
		return
	if rp.global_position.distance_to(_player.global_position) > 5.0:
		return
	var hit := 4 + randi() % 8
	if _shield > 0:
		var ab := mini(_shield, hit)
		_shield -= ab
		hit -= ab
	_player_hp -= hit
	SkillVFX.hit_spark(self, _player.global_position)
	PresenceManager.report_bot_hit_landed(pid)
	if _player_hp <= 0:
		_on_player_died(pid.trim_prefix("ghost_").replace("_", " "))

## Mega-city: built once per hub the first time the player sets foot in it,
## anchored to the hub's world-space corner. Deterministic per hub, so it's
## the same city every visit; freed when leaving the layer with the scene.
var _cities_built: Dictionary = {} # hub_id -> Node3D

func _ensure_city(hub_id: String) -> void:
	if hub_id == "" or _cities_built.has(hub_id):
		return
	var hub := HubRegionData.by_id(hub_id)
	if hub.is_empty():
		return
	var b: Dictionary = hub["chunk_bounds"]
	var size := float(HubRegionData.CHUNK_SIZE)
	# City origin: a little inset from the hub's near corner so it sits
	# inside the hub bounds rather than straddling the edge.
	var origin := Vector3((b.x + 0.5) * size, 0.0, (b.y + 0.5) * size)
	var city := MegaCityBuilder.build(hub_id, origin, _sky,
		func(x, z): return _terrain.height_at(x, z))
	add_child(city)
	_cities_built[hub_id] = city

func _reality_bend_baseline() -> float:
	match layer_id:
		"liminal": return 0.30
		"periliminal": return 0.55
		"extraliminal": return 0.08
		"supraliminal": return 0.05
		_: return 0.0

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
		MusicManager.play_context("sanctuary")
		_ensure_city(str(chunk.hub_id))
		return
	if MusicManager.current_context() == "sanctuary":
		MusicManager.play_context("overworld")
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
	_maybe_spawn_entity(coord)

var _chunk_entered_at := 0.0

func _liminal_enter(coord: Vector2i) -> void:
	# Hope watches HOW you take each liminal threshold: fast transit reads
	# as rushing (boredom/lust), a long dwell before moving on reads as
	# hesitation (fear/anxiety). Chunk borders are the doors out here.
	var now := Time.get_ticks_msec() / 1000.0
	var dwell := now - _chunk_entered_at
	_chunk_entered_at = now
	var approach := "rushed" if dwell < 4.0 else ("lingered" if dwell > 20.0 else "peeked")
	Hope.observe_door("liminal_%d_%d" % [coord.x, coord.y], approach, dwell)
	# Never static: the chunk you just left stops existing. Erase its
	# record so re-entering regenerates it differently (fresh prop seed
	# via a new WorldChunk), and harvest a little essence for the risk.
	if DiscoveryManager.has_chunk(_prev_chunk) and _prev_chunk != coord:
		DiscoveryManager._chunks.erase(_prev_chunk)
	EconomyManager.earn_currency("fragments", 1, "liminal_wandering")
	QuestManager.update_progress("visit_liminal")
	# Doors: the liminal's whole point. One per fresh chunk, placed off-center.
	var door := LiminalDoor.new()
	door.layer = "liminal"
	var size := float(HubRegionData.CHUNK_SIZE)
	door.position = Vector3(coord.x * size + size * 0.3, 0, coord.y * size + size * 0.6)
	door.position.y = _terrain.height_at(door.position.x, door.position.z)
	add_child(door)
	_maybe_spawn_entity(coord)

## World-threat wildlife from EntityDexData — separate from player/bot
## "peers". Faction-exclusive: your own faction's roster (or the
## Factionless ancient-pantheon lines if you have none), a random line,
## stage picked by rough danger of the area (liminal runs hotter than
## the open superliminal wilds).
var _entities: Dictionary = {} # instance_id -> WorldEntity

const ENTITY_SPAWN_CHANCE := 0.35
const MAX_CONCURRENT_ENTITIES := 3

func _maybe_spawn_entity(coord: Vector2i) -> void:
	if _entities.size() >= MAX_CONCURRENT_ENTITIES or randf() > ENTITY_SPAWN_CHANCE:
		return
	var faction := CompanionRegistry.normalize_faction(PlayerProfile.faction)
	var line := EntityDexData.random_line(faction)
	if line.is_empty():
		return
	var max_stage := 2 if layer_id == "supraliminal" else 3
	var stage := randi_range(1, max_stage)
	var ent := WorldEntity.new()
	var size := float(HubRegionData.CHUNK_SIZE)
	var spawn_pos := Vector3(coord.x * size + randf_range(0.2, 0.8) * size, 0,
		coord.y * size + randf_range(0.2, 0.8) * size)
	spawn_pos.y = _terrain.height_at(spawn_pos.x, spawn_pos.z)
	ent.position = spawn_pos
	ent.setup(line, stage, _player)
	ent.bit_player.connect(func(dmg): _on_entity_bite(ent, dmg))
	ent.died.connect(_on_entity_died)
	add_child(ent)
	_entities[ent.get_instance_id()] = ent

func _on_entity_bite(ent: WorldEntity, dmg: int) -> void:
	var hit := dmg
	if _shield > 0:
		var ab := mini(_shield, hit)
		_shield -= ab
		hit -= ab
	_player_hp -= hit
	SkillVFX.hit_spark(self, _player.global_position)
	if _player_hp <= 0:
		_on_player_died(str(ent.stage_info.get("name", "the wilds")))

func _on_entity_died(ent: WorldEntity) -> void:
	_entities.erase(ent.get_instance_id())
	EconomyManager.earn_currency("fragments", ent.bounty(), "world_entity_kill")
	QuestManager.update_progress("defeat_entity")

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

func _in_pvp_zone() -> bool:
	match layer_id:
		"liminal": return true
		"supraliminal": return TerritoryControl.is_pvp_at(_player.global_position)
		_: return false

## Cast resolution in the open world — targets are other players (or their
## offline ghost stand-ins). Hub interiors are sanctuaries: nothing lands.
func _on_cast(sk: Dictionary) -> void:
	# Forge override: an equipped skill blueprint replaces the stock flash
	# with the player's own shape/color/sound design.
	var cast_bp := BlueprintManager.equipped_for("skill", str(sk.get("id", "")))
	if not cast_bp.is_empty():
		SkillVFX.blueprint_cast(self, _player.global_position, cast_bp)
	else:
		SkillVFX.cast_flash(self, _player.global_position)
	if Hope.maybe_manifest(str(sk.get("id", ""))):
		SkillVFX.aoe_ring(self, _player.global_position, 2.0, Color(1.0, 0.95, 0.6))
		# If the player forged a companion form, Hope wears it when she shows.
		var hope_bp := BlueprintManager.equipped_for("entity", "companion")
		if not hope_bp.is_empty():
			var form := BlueprintMesh.build(hope_bp)
			form.position = _player.global_position + Vector3(1.2, 0, 1.2)
			add_child(form)
			SkillVFX.add_aura_shell(form, Color(1.0, 0.9, 0.65))
			BlueprintAudio.play(self, hope_bp)
			get_tree().create_timer(4.0).timeout.connect(form.queue_free)
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
	var dmg := int(_attack_damage * power)
	var reach := maxf(radius, 4.0)
	# World-threat wildlife lands regardless of PvP zone — entities aren't
	# players, hitting them was never a PvP question.
	for iid in _entities.keys().duplicate():
		var ent: WorldEntity = _entities[iid]
		if not is_instance_valid(ent): continue
		if ent.global_position.distance_to(_player.global_position) > reach: continue
		ent.take_hit(dmg)
		SkillManager.gain_ultimate(4.0)
	if not _in_pvp_zone():
		if _entities.is_empty():
			NotificationUI.notify_info("PvE sanctuary — your skills won't land on anyone here.")
		return
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

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_B:
		if get_node_or_null("BlueprintForge") == null:
			var forge := BlueprintForgeUI.new()
			forge.name = "BlueprintForge"
			add_child(forge)

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
				# Static-tier bots ignore the player entirely — only real
				# players and reactive/adaptive bots bite in the open.
				if pid.begins_with("ghost_") and PresenceManager.peer_tier(pid) == PresenceManager.BotTier.STATIC:
					continue
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
