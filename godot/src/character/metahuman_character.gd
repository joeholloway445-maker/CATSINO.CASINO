class_name MetahumanCharacter
extends RefCounted
## Character visual resolver for the ESO-realistic bar.
##
## Priority (first hit wins):
##   1. MetaHuman export slots — metahuman_player / metahuman_npc /
##      metahuman_<race_id>
##   2. Interim humanoid GLBs — player_human / npc_human
##   3. House-cat GLB — player_cat / npc_cat (Catsino skin only)
##   4. CharacterRig procedural humanoid (last resort)
##
## MetaHuman authoring happens in Unreal (Creator / Mesh-to-MetaHuman).
## Export GLB via the UE→Blender→Godot pipeline documented in
## docs/VISUAL_DIRECTION_ESO.md. Skin/eye/hair shaders from the community
## MetaHumanGodot look-dev tool live under assets/shaders/metahuman/.

const META_PLAYER := "metahuman_player"
const META_NPC := "metahuman_npc"
const HUMAN_PLAYER := "player_human"
const HUMAN_NPC := "npc_human"
const CAT_PLAYER := "player_cat"
const CAT_NPC := "npc_cat"

## Build the local player's body for the given visual mode.
static func build_player(visual_mode: String = "identity") -> Node3D:
	if visual_mode == "cat":
		var cat := AssetLibrary.instance(CAT_PLAYER)
		if cat != null:
			return _as_root(cat)
		# No cat mesh — fall through to human/MetaHuman (ESO bar wins).
	var race_id := ""
	if PlayerProfile:
		race_id = str(PlayerProfile.selected_race_id)
	var meta := _try_slots([
		"metahuman_%s" % race_id if not race_id.is_empty() else "",
		META_PLAYER,
		HUMAN_PLAYER,
	])
	if meta != null:
		_try_apply_metahuman_materials(meta)
		return meta
	return _rig_from_profile(false)

## Build a remote / NPC body.
static func build_npc(visual_mode: String = "identity", race_id: String = "") -> Node3D:
	if visual_mode == "cat":
		var cat := AssetLibrary.instance(CAT_NPC)
		if cat != null:
			return _as_root(cat)
	var meta := _try_slots([
		"metahuman_%s" % race_id if not race_id.is_empty() else "",
		META_NPC,
		HUMAN_NPC,
		HUMAN_PLAYER,
	])
	if meta != null:
		_try_apply_metahuman_materials(meta)
		return meta
	return _rig_from_profile(true)

static func _try_slots(slots: Array) -> Node3D:
	for s in slots:
		var slot := str(s)
		if slot.is_empty():
			continue
		var n := AssetLibrary.instance(slot)
		if n != null:
			return _as_root(n)
	return null

static func _as_root(n: Node) -> Node3D:
	if n is Node3D:
		return n as Node3D
	var root := Node3D.new()
	root.add_child(n)
	return root

static func _rig_from_profile(perceived: bool) -> Node3D:
	var rig := CharacterRig.new()
	rig.perceived = perceived
	var race_id := "KETH"
	var frame_id := "VEIL"
	var mod_id := "CATALYST"
	if PlayerProfile:
		if str(PlayerProfile.selected_race_id) != "":
			race_id = str(PlayerProfile.selected_race_id)
		if str(PlayerProfile.selected_frame) != "":
			frame_id = str(PlayerProfile.selected_frame)
		if str(PlayerProfile.selected_mod) != "":
			mod_id = str(PlayerProfile.selected_mod)
	var loadout := CharacterCreatorLogic.build_loadout(race_id, frame_id, mod_id)
	rig.build_from_loadout(loadout.get("race", {}), loadout.get("frame", {}), loadout.get("mod", {}))
	return rig

## Best-effort: if MetaHumanGodot skin shader exists, leave a marker so look-dev
## tools / future material pass can find surfaces named Skin/Eye/Hair.
static func _try_apply_metahuman_materials(root: Node3D) -> void:
	if not ResourceLoader.exists("res://assets/shaders/metahuman/skin_shader_local.gdshader"):
		return
	# Marker only — full surface remapping needs per-export surface maps
	# (see MetaHumanGodot look-dev). Avoid forcing broken shaders on TPS interim.
	root.set_meta("metahuman_shader_ready", true)
