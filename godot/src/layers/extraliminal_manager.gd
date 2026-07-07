extends Node
## Autoloaded as "ExtraliminalManager". The Pokemon-GO-style overlay layer:
## roster entities roam pseudo-real-world landmarks; guilds claim landmarks
## as guild halls and defend them in guild wars. A war starts when one member
## of a challenging guild opens a *liminal door* at the landmark (Secret-
## Power-style hidden entrance) and their guildmates pour through to fight.

signal entity_spotted(entity: Dictionary, landmark_id: String)
signal entity_caught(entity: Dictionary)
signal landmark_claimed(landmark_id: String, guild: String)
signal guild_war_started(landmark_id: String, attacker_guild: String, defender_guild: String)
signal guild_war_resolved(landmark_id: String, winner: String)

const DOOR_TOKEN_COST := 25 # opening a liminal door stakes PvP tokens

## Landmark seeds — stand-ins for real-world POIs until GPS wiring exists.
const LANDMARKS: Array[Dictionary] = [
	{id="lm_fountain", name="Neon Fountain"},
	{id="lm_old_bridge", name="Old Trinity Bridge"},
	{id="lm_water_tower", name="Rusted Water Tower"},
	{id="lm_drive_in", name="Abandoned Drive-In"},
	{id="lm_grain_silo", name="Twin Grain Silos"},
	{id="lm_stockyard_gate", name="Stockyard Gate"},
	{id="lm_planetarium", name="Planetarium Dome"},
	{id="lm_ferris_wheel", name="Fairgrounds Ferris Wheel"},
]

var _claims: Dictionary = {}      # landmark_id -> guild name
var _active_wars: Dictionary = {} # landmark_id -> {attacker, defender}

## Roll a roaming entity at a landmark from the full ~600-entity roster,
## rarity-weighted (rarity 5 is genuinely rare in the wild).
func spawn_wild_entity(landmark_id: String) -> Dictionary:
	# Faction-exclusive rosters: you only ever encounter entities your
	# faction can bond with (Factionless players get the Lone Wolf roster).
	# equivalent_exchange (prestige) is the intended bypass for off-faction
	# entities — wired at the catch UI, not here.
	var roster := CompanionRegistry.accessible_roster(PlayerProfile.faction)
	if roster.is_empty():
		return {}
	var pool: Array = []
	for e in roster:
		var weight: int = [0, 16, 8, 4, 2, 1][clampi(int(e.get("rarity", 1)), 1, 5)]
		for i in range(weight):
			pool.append(e)
	var entity: Dictionary = pool[randi() % pool.size()]
	entity_spotted.emit(entity, landmark_id)
	return entity

## Wild entities can no longer be "caught" by tossing a ball at them.
## They must be DEFEATED first — CaptureSystem then rolls the bond at
## the moment of the kill. This wrapper stays here so any older UI that
## invokes an Extraliminal "attempt_catch" gets routed through the new
## rule instead of silently unlocking an entity that was never fought.
func attempt_catch(_entity: Dictionary, _use_lure: bool = false) -> bool:
	NotificationUI.notify_info("The bond only forms after a real fight. Defeat it first — Hope can help.")
	return false

func landmark_owner(landmark_id: String) -> String:
	return _claims.get(landmark_id, "")

func claim_landmark(landmark_id: String, guild: String) -> bool:
	if landmark_owner(landmark_id) != "":
		return false
	_claims[landmark_id] = guild
	landmark_claimed.emit(landmark_id, guild)
	EconomyManager.earn_currency("tokens", 10, "landmark_claimed")
	return true

## One challenger opens the liminal door; the war is now live and their
## whole guild can come through until it resolves.
func open_liminal_door(landmark_id: String, attacker_guild: String) -> bool:
	var defender := landmark_owner(landmark_id)
	if defender == "" or defender == attacker_guild or _active_wars.has(landmark_id):
		return false
	if not await EconomyManager.spend_currency("tokens", DOOR_TOKEN_COST, "liminal_door"):
		NotificationUI.notify_error("A liminal door costs %d tokens to force open." % DOOR_TOKEN_COST)
		return false
	_active_wars[landmark_id] = {"attacker": attacker_guild, "defender": defender}
	guild_war_started.emit(landmark_id, attacker_guild, defender)
	NotificationUI.notify_info("⚔️ A liminal door creaks open at %s — guild war!" % landmark_id)
	return true

## Called by the combat layer with the war's outcome.
func resolve_guild_war(landmark_id: String, attacker_won: bool) -> void:
	if not _active_wars.has(landmark_id):
		return
	var war: Dictionary = _active_wars[landmark_id]
	var winner: String = war["attacker"] if attacker_won else war["defender"]
	if attacker_won:
		_claims[landmark_id] = winner
	_active_wars.erase(landmark_id)
	guild_war_resolved.emit(landmark_id, winner)
	EconomyManager.earn_currency("tokens", 25, "guild_war_%s" % ("won" if attacker_won else "defended"))
