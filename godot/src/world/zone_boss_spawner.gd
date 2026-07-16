class_name ZoneBossSpawner
## Gate 6 — Stage-3 elite WorldEntity at each city's landmark sites.
## Spawned when MegaCityBuilder finishes a hub. Announce via NotificationUI;
## kill pays fragments + prestige via EconomyManager (wired in died handler).

static func place_for_hub(city_root: Node3D, hub_id: String, base_y: float,
		player: Node3D) -> void:
	if player == null:
		return
	var landmarks: Array = LandmarkBuilder.CITY_LANDMARKS.get(hub_id, [])
	if landmarks.is_empty():
		return
	var holder := Node3D.new()
	holder.name = "ZoneBosses_%s" % hub_id
	city_root.add_child(holder)
	var faction := CompanionRegistry.normalize_faction(PlayerProfile.faction)
	var placed := 0
	for lm in landmarks:
		# One boss per landmark, seeded so the same site always hosts the same line.
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("zone_boss_%s_%s" % [hub_id, str(lm.id)])
		var line := EntityDexData.random_line(faction)
		if line.is_empty():
			line = {"id": "zone_%s" % lm.id, "faction": "Factionless", "category": "Entropy",
				"stages": [{"name": "Zone Warden", "desc": "Apex guardian of this skyline."}]}
		var osm := OsmCityLayout.landmark_pos(hub_id, str(lm.id))
		var pos: Vector3
		if osm.x != INF:
			pos = Vector3(osm.x + 6.0, base_y, osm.y + 6.0)
		else:
			pos = Vector3(float(lm.cell.x) * CityData.CELL + 6.0, base_y,
				float(lm.cell.y) * CityData.CELL + 6.0)
		var ent := WorldEntity.new()
		holder.add_child(ent)
		ent.global_position = pos
		ent.setup_boss(line, 3, player, "ZONE WARDEN")
		ent.set_meta("zone_boss", true)
		ent.set_meta("landmark_id", str(lm.id))
		ent.died.connect(func(e: WorldEntity): _on_boss_died(e, hub_id))
		placed += 1
		if placed == 1:
			NotificationUI.notify_info("⚠ Zone warden near %s — Stage 3." % str(lm.id).replace("_", " "))

static func _on_boss_died(ent: WorldEntity, hub_id: String) -> void:
	var bounty := ent.bounty() * 3
	EconomyManager.earn_currency("fragments", bounty, "zone_boss_kill")
	EconomyManager.earn_prestige(15, "zone_boss_kill")
	QuestManager.update_progress("defeat_zone_boss")
	QuestManager.update_progress("defeat_entity")
	NotificationUI.notify_win("Zone warden fallen in %s — +%d fragments." % [hub_id, bounty])
	WorldBossScheduler.note_zone_kill(hub_id)
