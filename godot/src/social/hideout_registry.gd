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
## Persisted to user:// so territory survives sessions; Supraliminal
## claims still mirror into ExtraliminalManager so its guild-war flow
## (forcing a liminal door) can contest them.

signal site_changed(site_id: String)

const SAVE_PATH := "user://hideouts.json"
const MIN_DISTANCE := 220.0
const CLAIM_COST_TOKENS := 500

## site_id -> {realm, hub, pos:[x,z], owner, banner, defenders:Array[String]}
var _sites: Dictionary = {}

func _ready() -> void:
	_load()

## Idempotent — builders re-register the same seeded sites every visit;
## saved ownership/defenders always win over fresh registration.
func register_site(site_id: String, realm: String, hub: String, pos: Vector3) -> void:
	if _sites.has(site_id):
		_sites[site_id]["pos"] = [pos.x, pos.z]
		return
	_sites[site_id] = {"realm": realm, "hub": hub, "pos": [pos.x, pos.z],
		"owner": "", "banner": true, "defenders": []}
	_save()

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
## Attacker strength reads the player as they stand; the hold reads the
## garrison. Defeated defenders are scattered (released from the site);
## a successful attack transfers ownership on the spot.
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
	var tree := get_tree()
	var world: Node3D = null
	if tree:
		world = tree.get_first_node_in_group("layer_world") as Node3D
	if attack <= defense:
		NotificationUI.notify_error("⚔️ %s's defenders hold the line (%d vs %d). The banner stays." % [holder, attack, defense])
		EconomyManager.earn_currency_local("tokens", 5, "hideout_defense_bonus")
		if world:
			SkillVFX.aoe_ring(world, pos, 3.0, Color(0.6, 0.2, 0.2))
		return false
	_sites[site_id]["defenders"] = [] # the garrison is routed
	_sites[site_id]["owner"] = attacker_guild
	_save()
	if str(_sites[site_id].get("realm", "")) == "supraliminal":
		ExtraliminalManager.claim_landmark("hideout_site_%s" % site_id, attacker_guild)
	EconomyManager.earn_currency_local("tokens", 40, "hideout_conquest")
	NotificationUI.notify_win("🏴 %s routs %s's defenders (%d vs %d) and takes the hideout!" % [attacker_guild, holder, attack, defense])
	if world:
		SkillVFX.ultimate_burst(world, pos, 5.0)
		SkillVFX.aoe_ring(world, pos, 4.5, Color(1.0, 0.85, 0.25))
	site_changed.emit(site_id)
	return true

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
