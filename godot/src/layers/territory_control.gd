extends Node
## Autoloaded as "TerritoryControl". The Supraliminal war layer: every chunk
## outside the hand-authored hub bounds is PvP and claimable by alliances
## (factions and their guild coalitions). Holding territory generates
## Influence; the alliance holding the most weighted territory crowns its
## top-contributing player **Sovereign of the Metroplex** — ESO-emperor-like,
## but the crown keeps working for the whole alliance, not just the wearer.

signal chunk_claimed(coord: Vector2i, alliance: String)
signal chunk_contested(coord: Vector2i, attacker: String, defender: String)
signal sovereign_crowned(player_id: String, alliance: String)
signal sovereign_deposed(player_id: String)

const HubRegionData = preload("res://src/data/hub_region_data.gd")

## Keystone chunks are worth more — they ring the hub exits.
const KEYSTONE_WEIGHT := 5
const NORMAL_WEIGHT := 1
const CROWN_THRESHOLD := 25 # weighted territory needed before a Sovereign exists

var _claims: Dictionary = {}        # Vector2i -> {alliance, claimed_by, weight}
var _contribution: Dictionary = {}  # alliance -> {player_id -> weighted claims}
var sovereign_id: String = ""
var sovereign_alliance: String = ""

## PvE inside any hub's bounds, PvP everywhere else in the Supraliminal.
func is_pvp_at(world_pos: Vector3) -> bool:
	var coord := DiscoveryManager.world_pos_to_chunk(world_pos)
	return HubRegionData.hub_at_chunk(coord).is_empty()

func claim_owner(coord: Vector2i) -> String:
	return _claims.get(coord, {}).get("alliance", "")

## Claim (or capture) a chunk for an alliance. Hub chunks can never be
## claimed. Capturing contested land emits chunk_contested first so combat
## systems can gate the flip behind an actual fight.
func claim_chunk(coord: Vector2i, alliance: String, player_id: String) -> bool:
	if not HubRegionData.hub_at_chunk(coord).is_empty():
		return false
	var existing: String = claim_owner(coord)
	if existing == alliance:
		return false
	if existing != "":
		chunk_contested.emit(coord, alliance, existing)
	var weight := _chunk_weight(coord)
	_claims[coord] = {"alliance": alliance, "claimed_by": player_id, "weight": weight}
	_contribution.get_or_add(alliance, {})[player_id] = \
		_contribution[alliance].get(player_id, 0) + weight
	EconomyManager.earn_currency("tokens", weight, "territory_claim")
	chunk_claimed.emit(coord, alliance)
	_recompute_sovereign()
	return true

func _chunk_weight(coord: Vector2i) -> int:
	# Keystone if adjacent to any hub boundary.
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if not HubRegionData.hub_at_chunk(coord + Vector2i(dx, dy)).is_empty():
				return KEYSTONE_WEIGHT
	return NORMAL_WEIGHT

func alliance_score(alliance: String) -> int:
	var total := 0
	for c in _claims.values():
		if c["alliance"] == alliance:
			total += c["weight"]
	return total

func _recompute_sovereign() -> void:
	var best_alliance := ""
	var best_score := 0
	for a in _contribution.keys():
		var s := alliance_score(a)
		if s > best_score:
			best_score = s
			best_alliance = a
	if best_score < CROWN_THRESHOLD:
		if sovereign_id != "":
			sovereign_deposed.emit(sovereign_id)
			sovereign_id = ""
			sovereign_alliance = ""
		return
	# Top contributor of the leading alliance wears the crown.
	var top_player := ""
	var top_contrib := 0
	for pid in _contribution.get(best_alliance, {}).keys():
		var c: int = _contribution[best_alliance][pid]
		if c > top_contrib:
			top_contrib = c
			top_player = pid
	if top_player != sovereign_id:
		if sovereign_id != "":
			sovereign_deposed.emit(sovereign_id)
		sovereign_id = top_player
		sovereign_alliance = best_alliance
		sovereign_crowned.emit(top_player, best_alliance)
		NotificationUI.notify_info("👑 %s of %s is crowned Sovereign of the Metroplex!" % [top_player, best_alliance])

## The Sovereign's crown buffs the whole alliance while held.
func sovereign_bonus(alliance: String) -> float:
	return 1.15 if alliance != "" and alliance == sovereign_alliance else 1.0
