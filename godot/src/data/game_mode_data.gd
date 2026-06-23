extends Node
## Purchasable game modes. "aware" controls whether ambient NPCs (and other
## players) can perceive that a given character is different/AI-touched —
## see AmbientNpc._on_player_entered_awareness(). Creator modes are fully
## sandboxed and split in two for separate marketing/sale: replaying a past
## canon scene vs. authoring a new one. Both feed the same UGC review
## pipeline (see ugc_submission.gd) — Discord mod ticket approval, then dev
## (currently just us) sign-off before anything reaches game canon.

const MODES: Array[Dictionary] = [
	{
		"id": "persistent_aware", "name": "Persistent — Aware",
		"description": "The standard always-on shared world. NPCs and other players are aware you're different from the start.",
		"persistent": true, "sandboxed": false, "npc_awareness": "aware",
		"reveal_to_other_players": true,
	},
	{
		"id": "persistent_incognito", "name": "Persistent — Incognito (Dev Mode)",
		"description": "The same persistent shared world, but NPCs don't react to you until you interact with them, and neither they nor other players can tell you're different unless you give yourself away.",
		"persistent": true, "sandboxed": false, "npc_awareness": "incognito",
		"reveal_to_other_players": false,
	},
	{
		"id": "creator_replay", "name": "Creator — Timeline Replay",
		"description": "Fully sandboxed. Select a past canon scene and replay/remix it. Submissions go through the Discord mod ticket review before they can be considered for canon.",
		"persistent": false, "sandboxed": true, "npc_awareness": "n/a",
		"reveal_to_other_players": false, "timeline_mode": "replay",
	},
	{
		"id": "creator_original", "name": "Creator — Timeline Forge",
		"description": "Fully sandboxed. Build a brand-new future scene from scratch. Submissions go through the Discord mod ticket review before they can be considered for canon.",
		"persistent": false, "sandboxed": true, "npc_awareness": "n/a",
		"reveal_to_other_players": false, "timeline_mode": "original",
	},
]

static func by_id(id: String) -> Dictionary:
	for mode in MODES:
		if mode["id"] == id:
			return mode
	return {}
