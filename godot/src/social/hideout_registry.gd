extends Node
## Autoloaded as "HideoutRegistry". Guild territory, in BOTH the
## Supraliminal and the Extraliminal:
##  - MULTIPLE hideout sites per city (seeded by MegaCityBuilder) plus
##    Extraliminal sites — not one per city anymore.
##  - EXCLUSION RADII: no two different guilds may hold sites within
##    MIN_DISTANCE of each other in the same realm. Want a spot inside a
##    rival's radius? You take THEIR site — you don't build next door.
##  - BANNERS ARE OPTIONAL: a guild may fly its colors or stay discreet.
##  - POKÉMON-GO-STYLE DEFENSE: while the guild is offline or elsewhere,
##    ASSIGNED ENTITIES hold the site. An entity left to defend is removed
##    from the player's active party and CANNOT be used anywhere else
##    until recalled or defeated.
## Persisted to user:// so territory survives sessions offline; when
## authenticated, claim/contest also sync through Nakama hideout_* RPCs
## so all clients share one authoritative map (Gate 8).

signal site_changed(site_id: String)

const SAVE_PATH := "user://hideouts.json"
const MIN_DISTANCE := 220.0
const CLAIM_COST_TOKENS := 500

## site_id -> {realm, hub, pos:[x,z], owner, banner, defenders:Array[String]}
var _sites: Dictionary = {}

func _ready() -> void:
	_load()
	call_deferred("_sync_from_server")

## Idempotent — builders re-register the same seeded sites every visit;
## saved ownership/defenders always win over fresh registration.
func register_site(site_id: String, realm: String, hub: String, pos: Vector3) -> void:
	if _sites.has(site_id):
		_sites[site_id]["pos"] = [pos.x, pos.z]
		_sites[site_id]["realm"] = realm
		_sites[site_id]["hub"] = hub
		_save()
		_push_upsert_async(site_id)
		return
	_sites[site_id] = {"realm": realm, "hub": hub, "pos": [pos.x, pos.z],
		"owner": "", "banner": true, "defenders": []}
	_save()
	_push_upsert_async(site_id)

func site(site_id: String) -> Dictionary:
	return _sites.get(site_id, {})

func owner_of(site_id: String) -> String:
	return str(site(site_id).get("owner", ""))

func banner_visible(site_id: String) -> bool:
	return bool(site(site_id).get("banner", true))

func set_banner(site_id: String, visible: bool) -> void:
	if not _sites.has(site_id):
		return
	_sites[site_id]["banner"] = visible
	_save()
	site_changed.emit(site_id)
	if _is_online():
		_rpc_fire("hideout_set_banner", {"site_id": site_id, "banner": visible})

## The exclusion rule: claimable only if no OTHER guild holds a site
## within MIN_DISTANCE in the same realm.
func can_claim(site_id: String, guild: String) -> Dictionary:
	var s := site(site_id)
	if s.is_empty():
		return {ok = false, reason = "Unknown site."}
	if owner_of(site_id) != "":
		return {ok = false, reason = "%s holds this ground. Defeat their defenders to take it." % owner_of(site_id)}
	var my_pos := Vector2(float(s.pos[0]), float(s.pos[1]))
	for other_id in _sites.keys():
		if other_id == site_id:
			continue
		var o: Dictionary = _sites[other_id]
		var o_owner := str(o.get("owner", ""))
		if o_owner == "" or o_owner == guild:
			continue
		if str(o.get("realm", "")) != str(s.get("realm", "")):
			continue
		var o_pos := Vector2(float(o.pos[0]), float(o.pos[1]))
		if my_pos.distance_to(o_pos) < MIN_DISTANCE:
			return {ok = false, reason = "Too close to %s territory — no two guilds build within the same distance. Take theirs instead." % o_owner}
	return {ok = true, reason = ""}

func claim(site_id: String, guild: String) -> bool:
	var check := can_claim(site_id, guild)
	if not check.ok:
		NotificationUI.notify_error(str(check.reason))
		return false
	if not await EconomyManager.spend_currency("tokens", CLAIM_COST_TOKENS, "hideout_claim"):
		NotificationUI.notify_error("Claiming a hideout stakes %d ⚔️ tokens." % CLAIM_COST_TOKENS)
		return false

	if _is_online():
		var remote: Dictionary = await _rpc_await("hideout_claim",
			{"site_id": site_id, "guild": guild})
		if not bool(remote.get("success", remote.get("ok", false))):
			# Refund tokens — server rejected (race / exclusion).
			EconomyManager.earn_currency_local("tokens", CLAIM_COST_TOKENS, "hideout_claim_refund")
			var err := str(remote.get("error", remote.get("reason", "Claim rejected by server.")))
			NotificationUI.notify_error(err)
			if remote.has("site") and remote.site is Dictionary:
				_merge_remote_site(remote.site)
			return false
		if remote.has("site") and remote.site is Dictionary:
			_merge_remote_site(remote.site)
		else:
			_sites[site_id]["owner"] = guild
			_save()
	else:
		_sites[site_id]["owner"] = guild
		_save()

	# Supraliminal claims cast an Extraliminal shadow — rival guilds can
	# also contest them there through the liminal-door guild-war flow.
	if str(_sites[site_id].get("realm", "")) == "supraliminal":
		ExtraliminalManager.claim_landmark("hideout_site_%s" % site_id, guild)
	site_changed.emit(site_id)
	return true

## ── Defenders: leave an entity, lose the entity (until it's back) ──────

func assign_defender(site_id: String, companion_id: String) -> bool:
	if not _sites.has(site_id):
		return false
	if companion_id not in PlayerProfile.active_companion_ids:
		NotificationUI.notify_error("That entity isn't in your active party.")
		return false
	PlayerProfile.active_companion_ids.erase(companion_id)
	PlayerProfile.profile_updated.emit()
	_sites[site_id]["defenders"].append(companion_id)
	_save()
	var ent := CompanionRegistry.get_by_id(companion_id)
	NotificationUI.notify_info("🛡️ %s now defends this hideout — it cannot fight for you anywhere else until recalled." % str(ent.get("name", companion_id)))
	site_changed.emit(site_id)
	return true

func recall_defenders(site_id: String) -> void:
	if not _sites.has(site_id):
		return
	var back: Array = _sites[site_id]["defenders"]
	for cid in back:
		if str(cid) not in PlayerProfile.active_companion_ids:
			PlayerProfile.active_companion_ids.append(str(cid))
	_sites[site_id]["defenders"] = []
	PlayerProfile.profile_updated.emit()
	_save()
	if not back.is_empty():
		NotificationUI.notify_info("🛡️ %d defender(s) recalled to your party. The site stands unguarded." % back.size())
	site_changed.emit(site_id)

func defenders(site_id: String) -> Array:
	return _sites.get(site_id, {}).get("defenders", [])

func is_defending(companion_id: String) -> bool:
	for s in _sites.values():
		if companion_id in s.get("defenders", []):
			return true
	return false

func defense_power(site_id: String) -> int:
	var power := 20 # the walls themselves count for something
	for cid in defenders(site_id):
		power += 15 + _rarity_power(CompanionRegistry.get_by_id(str(cid)))
	return power

static func _rarity_power(ent: Dictionary) -> int:
	var r = ent.get("rarity", 1)
	if r is String:
		return {"common": 10, "uncommon": 18, "rare": 28, "epic": 40, "legendary": 55}.get(str(r).to_lower(), 10)
	return clampi(int(r), 1, 5) * 11

## ── Contest: fight the defenders, take the ground ──────────────────────
## Preferred path: GuildHideout spawns live WorldEntity defenders and calls
## `resolve_contest_win` when the garrison is cleared. `contest()` remains as
## a soft offline fallback (dice) when no live siege is available.

## Transfer ownership after a live siege clears the garrison. No dice.
func resolve_contest_win(site_id: String, attacker_guild: String) -> bool:
	var holder := owner_of(site_id)
	if holder == "" or holder == attacker_guild:
		return false

	if _is_online():
		var remote: Dictionary = await _rpc_await("hideout_contest_win",
			{"site_id": site_id, "attacker_guild": attacker_guild})
		if not bool(remote.get("success", remote.get("ok", false))):
			var err := str(remote.get("error", "Contest rejected by server."))
			NotificationUI.notify_error(err)
			if remote.has("site") and remote.site is Dictionary:
				_merge_remote_site(remote.site)
			return false
		if remote.has("site") and remote.site is Dictionary:
			_merge_remote_site(remote.site)
		else:
			_sites[site_id]["defenders"] = []
			_sites[site_id]["owner"] = attacker_guild
			_save()
	else:
		_sites[site_id]["defenders"] = []
		_sites[site_id]["owner"] = attacker_guild
		_save()

	if str(_sites[site_id].get("realm", "")) == "supraliminal":
		ExtraliminalManager.claim_landmark("hideout_site_%s" % site_id, attacker_guild)
	EconomyManager.earn_currency_local("tokens", 40, "hideout_conquest")
	NotificationUI.notify_win("🏴 %s clears the garrison and takes the hideout from %s!" % [attacker_guild, holder])
	var s: Dictionary = site(site_id)
	var pos_arr: Array = s.get("pos", [0.0, 0.0])
	var pos := Vector3(float(pos_arr[0]) if pos_arr.size() > 0 else 0.0, 1.5,
		float(pos_arr[1]) if pos_arr.size() > 1 else 0.0)
	_play_contest_vfx(pos, true)
	site_changed.emit(site_id)
	return true

## Soft fallback — used when a live siege cannot start. Prefer resolve_contest_win.
func contest(site_id: String, attacker_guild: String) -> bool:
	var holder := owner_of(site_id)
	if holder == "" or holder == attacker_guild:
		return false
	var attack := PlayerProfile.level * 6 + randi() % 45
	for cid in PlayerProfile.active_companion_ids:
		attack += 8 + _rarity_power(CompanionRegistry.get_by_id(str(cid))) / 2
	var defense := defense_power(site_id) + randi() % 45
	var s: Dictionary = site(site_id)
	var pos_arr: Array = s.get("pos", [0.0, 0.0])
	var pos := Vector3(float(pos_arr[0]) if pos_arr.size() > 0 else 0.0, 1.5,
		float(pos_arr[1]) if pos_arr.size() > 1 else 0.0)
	if attack <= defense:
		NotificationUI.notify_error("⚔️ %s's defenders hold the line (%d vs %d). The banner stays." % [holder, attack, defense])
		EconomyManager.earn_currency_local("tokens", 5, "hideout_defense_bonus")
		_play_contest_vfx(pos, false)
		return false
	return await resolve_contest_win(site_id, attacker_guild)

## Load SkillVFX by path — never reference the class_name at parse time.
## Autoloads that name class_name types fail hard on cold CI class caches.
func _play_contest_vfx(pos: Vector3, won: bool) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var world: Node3D = tree.get_first_node_in_group("layer_world") as Node3D
	if world == null:
		world = tree.current_scene as Node3D
	if world == null:
		return
	var vfx: GDScript = load("res://src/skills/skill_vfx.gd") as GDScript
	if vfx == null:
		return
	if won:
		vfx.call("ultimate_burst", world, pos, 5.0)
		vfx.call("aoe_ring", world, pos, 4.5, Color(1.0, 0.85, 0.25))
	else:
		vfx.call("aoe_ring", world, pos, 3.0, Color(0.6, 0.2, 0.2))

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_sites))

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		_sites = d

## ── Gate 8 online helpers ──────────────────────────────────────────────

func _is_online() -> bool:
	var acct := get_node_or_null("/root/AccountManager")
	if acct == null:
		return false
	return bool(acct.get("is_authenticated"))

func _merge_remote_site(remote: Dictionary) -> void:
	var sid := str(remote.get("site_id", ""))
	if sid.is_empty():
		return
	var local: Dictionary = _sites.get(sid, {
		"realm": "supraliminal", "hub": "", "pos": [0.0, 0.0],
		"owner": "", "banner": true, "defenders": []
	}).duplicate(true)
	if remote.has("realm"):
		local["realm"] = str(remote.realm)
	if remote.has("hub"):
		local["hub"] = str(remote.hub)
	if remote.has("pos") and remote.pos is Array and remote.pos.size() >= 2:
		local["pos"] = [float(remote.pos[0]), float(remote.pos[1])]
	if remote.has("owner"):
		local["owner"] = str(remote.owner)
	if remote.has("banner"):
		local["banner"] = bool(remote.banner)
	# Keep local defenders unless the remote explicitly cleared them (contest).
	if remote.has("defenders") and remote.defenders is Array:
		if (remote.defenders as Array).is_empty() or not local.has("defenders"):
			local["defenders"] = (remote.defenders as Array).duplicate()
	_sites[sid] = local
	_save()
	site_changed.emit(sid)

func _sync_from_server() -> void:
	if not _is_online():
		return
	var remote: Dictionary = await _rpc_await("hideout_get", {})
	if not bool(remote.get("success", remote.get("ok", false))):
		return
	var list: Array = remote.get("sites", [])
	for item in list:
		if item is Dictionary:
			_merge_remote_site(item)
	# Push any local-only seeded sites so the server learns the map.
	for sid in _sites.keys():
		_push_upsert_async(str(sid))

func _push_upsert_async(site_id: String) -> void:
	if not _is_online() or not _sites.has(site_id):
		return
	var s: Dictionary = _sites[site_id]
	var pos_arr: Array = s.get("pos", [0.0, 0.0])
	_rpc_fire("hideout_upsert_site", {
		"site_id": site_id,
		"realm": str(s.get("realm", "supraliminal")),
		"hub": str(s.get("hub", "")),
		"pos": [float(pos_arr[0]) if pos_arr.size() > 0 else 0.0,
			float(pos_arr[1]) if pos_arr.size() > 1 else 0.0],
	})

func _rpc_fire(rpc_id: String, payload: Dictionary, cb: Callable = Callable()) -> void:
	var net := get_node_or_null("/root/NetworkManager")
	if net == null or not net.has_method("call_rpc"):
		if cb.is_valid():
			cb.call({"success": false, "error": "NetworkManager missing", "ok": false})
		return
	net.call("call_rpc", rpc_id, payload, func(result: Dictionary):
		if cb.is_valid():
			cb.call(result))

func _rpc_await(rpc_id: String, payload: Dictionary) -> Dictionary:
	var out := {"success": false, "ok": false}
	var done := false
	_rpc_fire(rpc_id, payload, func(result: Dictionary):
		out = result
		done = true)
	var deadline := Time.get_ticks_msec() + 8000
	while not done and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	return out
