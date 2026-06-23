extends Node
## Autoloaded as "DiscoveryManager". Owns the Supraliminal chunk grid: lazy
## generation on first entry, plus the "discover mechanic" — a party's
## PlayerInfluencePacks repaint a chunk's dominant_pack, weighted by
## perception, accumulating across visits rather than overwriting instantly.
##
## Hub chunks (HubRegionData) are pre-authored and excluded from both
## generation and influence painting.

signal chunk_discovered(coord: Vector2i, chunk: WorldChunk)
signal chunk_repainted(coord: Vector2i, chunk: WorldChunk)

const HubRegionData = preload("res://src/data/hub_region_data.gd")
const ProceduralRegionGenerator = preload("res://src/world/procedural_region_generator.gd")

var _chunks: Dictionary = {} # Vector2i -> WorldChunk

## Influence accrual rate per visit, scaled by relative perception weight.
const INFLUENCE_GAIN_PER_VISIT: float = 0.15
const MAX_INFLUENCE_WEIGHT: float = 1.0

func world_pos_to_chunk(pos: Vector3) -> Vector2i:
	var size: float = float(HubRegionData.CHUNK_SIZE)
	return Vector2i(floori(pos.x / size), floori(pos.z / size))

## Returns the chunk at coord, generating it on first access. Hub-bound
## coords always resolve to the frozen, hand-authored hub chunk.
func get_or_generate_chunk(coord: Vector2i) -> WorldChunk:
	if _chunks.has(coord):
		return _chunks[coord]

	var chunk := WorldChunk.new()
	chunk.coord = coord

	var hub := HubRegionData.hub_at_chunk(coord)
	if not hub.is_empty():
		chunk.is_hub = true
		chunk.hub_id = hub["id"]
		chunk.generated = true
	else:
		chunk.biome = ProceduralRegionGenerator.generate(coord)
		chunk.generated = true

	_chunks[coord] = chunk
	chunk_discovered.emit(coord, chunk)
	return chunk

## Called when a party of players enters a chunk together. The member with
## the highest perception dominates the repaint; everyone else still
## contributes, smaller and accumulating rather than instant/winner-take-all.
## No-op on hub chunks — those never get repainted.
func register_party_visit(coord: Vector2i, party: Array[PlayerInfluencePack]) -> void:
	if party.is_empty():
		return
	var chunk := get_or_generate_chunk(coord)
	if chunk.is_hub:
		return

	var total_perception := 0
	for pack in party:
		total_perception += pack.perception

	for pack in party:
		var share := float(pack.perception) / float(max(total_perception, 1))
		var prev: float = chunk.influence_weights.get(pack.player_id, 0.0)
		var gained: float = share * INFLUENCE_GAIN_PER_VISIT
		chunk.influence_weights[pack.player_id] = minf(prev + gained, MAX_INFLUENCE_WEIGHT)
		_remember_pack(pack)

	_recompute_dominant_pack(chunk, party)
	chunk_repainted.emit(coord, chunk)

var _known_packs: Dictionary = {} # player_id -> PlayerInfluencePack

func _remember_pack(pack: PlayerInfluencePack) -> void:
	_known_packs[pack.player_id] = pack

## Blends every contributing player's pack into chunk.dominant_pack,
## weighted by each player's accumulated influence_weight. The highest
## single-visit perception still wins the lion's share because it earns
## weight fastest, but low-perception party members keep nudging the blend
## as long as they keep coming back.
func _recompute_dominant_pack(chunk: WorldChunk, party: Array[PlayerInfluencePack]) -> void:
	var total_weight := chunk.total_influence_weight()
	if total_weight <= 0.0:
		return

	var blended := PlayerInfluencePack.new()
	var tint := Color(0, 0, 0, 0)
	var light := Color(0, 0, 0, 0)
	var energy := 0.0

	for player_id in chunk.influence_weights.keys():
		if not _known_packs.has(player_id):
			continue
		var pack: PlayerInfluencePack = _known_packs[player_id]
		var w: float = chunk.influence_weights[player_id] / total_weight
		tint += pack.texture_tint * w
		light += pack.light_color * w
		energy += pack.light_energy_mult * w

	blended.texture_tint = tint
	blended.light_color = light
	blended.light_energy_mult = energy if energy > 0.0 else 1.0
	chunk.dominant_pack = blended
