extends Node3D
## Shared scene script for the explorable layers. TerrainBridge (Terrain3D
## desktop / ProceduralTerrain web) + DayNightSky + MetaHuman/humanoid player.

@export var layer_id: String = "supraliminal"

var _terrain: TerrainBridge
var _sky: DayNightSky
var _player: ThirdPersonController

func _ready() -> void:
	LayerManager.current_layer_id = layer_id
	add_to_group("layer_world")

	_terrain = TerrainBridge.new()
	add_child(_terrain)
	await _terrain.ensure_built(layer_id)

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
	_player.visual_mode = "identity"
	add_child(_player)

	var spawn := _spawn_point()
	_terrain.stream_around(DiscoveryManager.world_pos_to_chunk(spawn))
	spawn.y = _terrain.height_at(spawn.x, spawn.z) + 2.0
	_player.global_position = spawn
	_player.chunk_changed.connect(_on_chunk_changed)
	add_child(SensoriumAmbience.new()) # your build's own hum, under the music
	var vehicles := VehicleWorldWiring.spawn_hub_vehicles(self, _terrain, spawn)
	VehicleWorldWiring.wire_streaming_bump(vehicles, _terrain, _sky)
	add_child(RealityBendOverlay.new(_reality_bend_baseline()))
	var hotbar := HotbarUI.new()
	hotbar.cast_requested.connect(_on_cast)
	add_child(hotbar)
	add_child(HopeUI.new()) # Hope is always on YOUR screen
	add_child(ChatUI.new()) # T toggles; five channels
	add_child(TouchControls.new()) # mobile: frees itself on non-touch devices
	# B opens the Blueprint Forge anywhere in the open world.
	set_process_unhandled_key_input(true)
	var stats := CharacterCreatorLogic.build_starting_stats(
		PlayerProfile.selected_race_id, PlayerProfile.faction,
		PlayerProfile.selected_frame, PlayerProfile.selected_mod)
	_attack_damage = 14 + int(stats.pow) / 2 + PlayerProfile.level
	_build_hud()
	_wire_presence()
	# Every space off the Liminal keeps a clear, obvious door back into it —
	# only the Periliminal withholds its exit (the blessing door, below).
	if layer_id in ["extraliminal", "subliminal"]:
		var back_door := LayerExitDoor.new()
		back_door.target_layer = "liminal"
		back_door.position = Vector3(8, 0, 8)
		back_door.position.y = _terrain.height_at(8.0, 8.0)
		add_child(back_door)
	# The Extraliminal carries its own guild hideout sites — same registry,
	# same exclusion radii and defender rules as the city sites.
	if layer_id == "extraliminal":
		var xr := RandomNumberGenerator.new()
		xr.seed = hash("extraliminal_hideouts")
		for s in 4:
			var pos := Vector3(xr.randf_range(-300.0, 300.0), 0, xr.randf_range(40.0, 600.0))
			pos.y = _terrain.height_at(pos.x, pos.z)
			var hideout := GuildHideout.new()
			hideout.setup("extra_s%d" % s, "extraliminal", "extraliminal",
				Color(0.75, 0.35, 0.95), _player, pos)
			hideout.position = pos
			add_child(hideout)
	_populate_layer_npcs(spawn)
	if layer_id == "liminal" and LayerManager.is_prototype_mode():
		_spawn_prototype_spine_exits(spawn)

## Prototype-only: a guaranteed Metroplex archway within sight of spawn so
## Gate 3 (layer round-trip) is walkable without RNG hunting. Production
## still relies on the per-chunk random exits in `_liminal_enter`.
func _spawn_prototype_spine_exits(near: Vector3) -> void:
	var metro := LayerExitDoor.new()
	metro.target_layer = "supraliminal"
	metro.position = near + Vector3(6, 0, 4)
	metro.position.y = _terrain.height_at(metro.position.x, metro.position.z)
	add_child(metro)
	var catsino := LayerExitDoor.new()
	catsino.target_layer = "hyperliminal"
	catsino.position = near + Vector3(-6, 0, 4)
	catsino.position.y = _terrain.height_at(catsino.position.x, catsino.position.z)
	add_child(catsino)

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
		func(x, z): return _terrain.height_at(x, z), _player)
	add_child(city)
	_cities_built[hub_id] = city
	# City population: hub ids ARE the generator's supraliminal district
	# ids, so each city pulls its own residents (LOD/impostors inside).
	var spawner := NPCSpawner.new()
	spawner.district_id = hub_id
	spawner.max_npcs_in_district = 50
	spawner.player = _player
	spawner.height_provider = func(x, z): return _terrain.height_at(x, z)
	spawner.position = origin
	add_child(spawner)

## Ambient human population for non-city layers. The Subliminal is each
## player's private safe zone — NOTHING auto-spawns there. Ambient figures
## in a Subliminal require an active creator subscription (pay gate).
## The Liminal holds a handful of looping figures; the Periliminal's few
## faces are personal apparitions, never a crowd. Supraliminal cities
## populate per-hub in _ensure_city instead.
func _populate_layer_npcs(near: Vector3) -> void:
	if layer_id == "subliminal":
		return # hard lock — no automatic ambient NPCs in private zones
	var district_and_cap := {
		"liminal": ["liminal_hub", 8],
		"extraliminal": ["territories", 24],
		"periliminal": ["abstract_realm", 6],
	}
	if not district_and_cap.has(layer_id):
		return
	var conf: Array = district_and_cap[layer_id]
	var spawner := NPCSpawner.new()
	spawner.district_id = str(conf[0])
	spawner.max_npcs_in_district = int(conf[1])
	spawner.player = _player
	spawner.height_provider = func(x, z): return _terrain.height_at(x, z)
	spawner.position = Vector3(near.x, 0.0, near.z)
	add_child(spawner)

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
			if DungeonRuns.active:
				DungeonRuns.advance_depth()
				DungeonRuns.try_clear()
			else:
				PeriliminalRuns.advance_depth()
				_maybe_bless(coord)
	_prev_chunk = coord

## The Periliminal's one exit: no door exists until the run has gone deep
## enough (personal — PeriliminalRuns.blessing_ready reads your Hope
## profile), and then one simply IS there, radiant, like it was sent.
var _blessing_spawned := false

func _maybe_bless(coord: Vector2i) -> void:
	# Instanced dungeons suppress the Periliminal blessing exit — clear via
	# DungeonRuns.try_clear() / eject instead.
	if DungeonRuns != null and DungeonRuns.active:
		return
	if _blessing_spawned or not PeriliminalRuns.blessing_ready():
		return
	_blessing_spawned = true
	var door := LayerExitDoor.new()
	door.blessing = true
	var size := float(HubRegionData.CHUNK_SIZE)
	door.position = Vector3(coord.x * size + size * 0.5, 0, coord.y * size + size * 0.45)
	door.position.y = _terrain.height_at(door.position.x, door.position.z)
	add_child(door)
	NotificationUI.notify_win("✦ Light, where there has never been light. A door stands open ahead.")
	Hope.record("blessing_door", {"depth": PeriliminalRuns.depth})

func _supraliminal_enter(coord: Vector2i) -> void:
	var already_known := DiscoveryManager.has_chunk(coord)
	var chunk := DiscoveryManager.get_or_generate_chunk(coord)
	if chunk.is_hub:
		var hub_name := str(HubRegionData.by_id(chunk.hub_id).get("name", chunk.hub_id.capitalize()))
		NotificationUI.notify_info("Entering %s — PvE sanctuary." % hub_name)
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
	# The obvious exits: most liminal chunks also carry a clearly-marked
	# archway out. Weighted so the Hyperliminal (the Catsino) is the easy
	# find; the Periliminal is NEVER on this list — it takes you, you
	# don't walk in.
	var exit_rng := RandomNumberGenerator.new()
	exit_rng.seed = hash("liminal_exit_%d_%d" % [coord.x, coord.y])
	if exit_rng.randf() < 0.6:
		var r := exit_rng.randf()
		var target := "hyperliminal" # 40% — easy to find
		if r >= 0.4 and r < 0.65:
			target = "supraliminal"
		elif r >= 0.65 and r < 0.85:
			target = "subliminal"
		elif r >= 0.85:
			target = "extraliminal" # guild-war grounds
		var exit_door := LayerExitDoor.new()
		exit_door.target_layer = target
		exit_door.position = Vector3(coord.x * size + size * 0.7, 0, coord.y * size + size * 0.25)
		exit_door.position.y = _terrain.height_at(exit_door.position.x, exit_door.position.z)
		add_child(exit_door)
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
	# The Periliminal spawns to YOUR measure: PeriliminalRuns.difficulty()
	# folds Hope's playstyle read and your word-of-mouth reputation into
	# the spawn rate and the stages the layer sends at you.
	var spawn_chance := ENTITY_SPAWN_CHANCE
	var max_stage := 2 if layer_id == "supraliminal" else 3
	var min_stage := 1
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	if DungeonRuns != null and DungeonRuns.active:
		# Stable seed ledger → same dungeon run regenerates the same dens.
		rng.seed = hash("dungeon_spawn_%s_%d_%d_%d" % [
			DungeonRuns.dungeon_id, DungeonRuns.run_seed(), coord.x, coord.y])
		spawn_chance = clampf(0.55 + float(DungeonRuns.depth) * 0.08, 0.45, 0.95)
		min_stage = 2
		max_stage = 3
	elif layer_id == "periliminal":
		var diff := PeriliminalRuns.difficulty()
		spawn_chance = clampf(ENTITY_SPAWN_CHANCE * diff, 0.15, 0.9)
		if diff > 1.6:
			min_stage = 2 # the hard cases never see a Stage 1 down here
	if _entities.size() >= MAX_CONCURRENT_ENTITIES or rng.randf() > spawn_chance:
		return
	var faction := CompanionRegistry.normalize_faction(PlayerProfile.faction)
	var line := EntityDexData.random_line(faction)
	if line.is_empty():
		return
	var stage := rng.randi_range(min_stage, max_stage)
	var ent := WorldEntity.new()
	var size := float(HubRegionData.CHUNK_SIZE)
	var spawn_pos := Vector3(coord.x * size + rng.randf_range(0.2, 0.8) * size, 0,
		coord.y * size + rng.randf_range(0.2, 0.8) * size)
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
	# The only way to bond with an entity is to defeat it — solo, or with
	# Hope's help. CaptureSystem rolls the moment: your remaining HP is
	# the "you earned this" input, so a clean win reads clean.
	var hp_ratio := clampf(float(_player_hp) / 100.0, 0.0, 1.0)
	CaptureSystem.on_defeated(ent, hp_ratio)

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
	# Element rider — the entity force this line channels (SkillData.ELEMENTS).
	var elem := str(sk.get("element", ""))
	if elem == "energy":
		dmg = int(dmg * 1.15)
	# Demolishable city props are fair game for any cast.
	for node in get_tree().get_nodes_in_group("breakable"):
		if node is BreakableProp and is_instance_valid(node):
			if node.global_position.distance_to(_player.global_position) <= reach:
				node.take_hit(dmg)
	# World-threat wildlife lands regardless of PvP zone — entities aren't
	# players, hitting them was never a PvP question.
	for iid in _entities.keys().duplicate():
		var ent: WorldEntity = _entities[iid]
		if not is_instance_valid(ent): continue
		if ent.global_position.distance_to(_player.global_position) > reach: continue
		ent.take_hit(dmg)
		SkillVFX.hit_spark(self, ent.global_position)
		_apply_element_rider(elem, ent, dmg)
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
		_apply_element_rider(elem, rp, dmg)
		if elem == "quantum" and randf() < 0.2:
			# The timeline disagrees: the hit lands twice.
			_peer_hp[pid] -= dmg
			SkillVFX.hit_spark(self, rp.global_position)
		elif elem == "entropy":
			# Decay echo: a second tick a beat later.
			get_tree().create_timer(1.0).timeout.connect(func():
				if _peer_hp.has(pid):
					_peer_hp[pid] -= int(dmg * 0.4))
		SkillManager.gain_ultimate(6.0)
		if _peer_hp[pid] <= 0:
			_on_peer_killed(pid, rp)
	if elem == "matter":
		# Substance answers you: landing casts skins you in shield.
		_shield += 8

## Physical element effects that act on a target's transform.
func _apply_element_rider(elem: String, target: Node3D, _dmg: int) -> void:
	match elem:
		"gravity":
			# Space bends your way: drag the target 3m toward you.
			var toward := (_player.global_position - target.global_position).normalized()
			target.global_position += toward * 3.0
		"psyche":
			# The mind falters: knock their facing wide.
			target.rotation.y += randf_range(-1.2, 1.2)
		_:
			pass

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
func get_local_player() -> ThirdPersonController:
	return _player

func _on_player_died(killer: String) -> void:
	# Gate 6 dungeon: eject with no wipe (DungeonRuns owns the flag).
	if DungeonRuns.active or Engine.has_meta("dungeon_no_wipe"):
		_player_hp = 100
		_shield = 0
		DungeonRuns.eject("death_to_%s" % killer)
		return
	# Periliminal wipe path (shared fate) — only when a wipe-run is active.
	if layer_id == "periliminal" and PeriliminalRuns.active and not Engine.has_meta("dungeon_no_wipe"):
		PeriliminalRuns.member_died("local_player")
		_player_hp = 100
		_shield = 0
		return
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
