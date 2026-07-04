extends Node
## Autoloaded as "RaceStorylines". Every one of the 20 races gets its own
## three-act storyline generated from its lore — so from minute one no two
## players are on the same mission unless they chose the same blood.
## Chains register as dynamic quests in QuestManager; YOUR race's Act I is
## auto-accepted at startup. Other races' chains exist in the world but are
## gated to their own (equivalent exchange can buy a foreign chain open).

func _ready() -> void:
	# QuestManager may still be loading saved state this frame.
	call_deferred("_register_all")

func _register_all() -> void:
	for race in RaceDataCharacter.RACES:
		for quest in _chain_for(race):
			QuestManager.register_quest(quest)
	# Your own Act I begins immediately — everyone's opening mission differs.
	var act1 := "race_%s_1" % PlayerProfile.selected_race_id
	if not QuestManager.is_active(act1) and not QuestManager.is_complete(act1):
		QuestManager.accept(act1)
		NotificationUI.notify_info("📜 Your blood remembers something. (%s storyline begun)" %
			RaceDataCharacter.get_race(PlayerProfile.selected_race_id).get("name", "?"))

## Three acts per race, themed by its dominant stat and told through its
## own lore text. Act structure: awakening → trial → the truth.
func _chain_for(race: Dictionary) -> Array[Dictionary]:
	var rid: String = race.id
	var rname: String = race.name
	var lore: String = race.get("lore", "")
	var chain: Array[Dictionary] = []
	chain.append({
		"id": "race_%s_1" % rid, "type": QuestManager.QuestType.MAIN,
		"name": "%s: What the Blood Remembers" % rname,
		"desc": "%s Something in you woke up when you crossed into the Metroplex. Follow it." % lore,
		"objectives": [
			{"id": "r1_%s_visit" % rid, "desc": "Visit any district", "target": 1, "type": "visit_district"},
			{"id": "r1_%s_play" % rid, "desc": "Play 2 games — the blood watches how you win", "target": 2, "type": "play_game"},
		],
		"rewards": {"coins": 400, "xp": 120},
		"prereq": [],
	})
	chain.append({
		"id": "race_%s_2" % rid, "type": QuestManager.QuestType.MAIN,
		"name": "%s: The Trial of Kind" % rname,
		"desc": "Every %s faces this. Not every %s comes back the same." % [rname, rname],
		"objectives": [
			{"id": "r2_%s_combat" % rid, "desc": "Win 2 fights", "target": 2, "type": "win_combat"},
			{"id": "r2_%s_explore" % rid, "desc": "Discover 3 wild chunks", "target": 3, "type": ""},
		],
		"rewards": {"coins": 900, "xp": 300, "companion_unlock": ""},
		"prereq": ["race_%s_1" % rid],
	})
	chain.append({
		"id": "race_%s_3" % rid, "type": QuestManager.QuestType.MAIN,
		"name": "%s: The Truth Underneath" % rname,
		"desc": "The lens isn't decoration. What you are decides what the world is made of — and the %s were made knowing it." % rname,
		"objectives": [
			{"id": "r3_%s_win" % rid, "desc": "Win a race or tournament", "target": 1, "type": "win_race"},
			{"id": "r3_%s_layers" % rid, "desc": "Walk the Liminal and come back", "target": 1, "type": ""},
		],
		"rewards": {"coins": 2000, "xp": 700},
		"prereq": ["race_%s_2" % rid],
	})
	# discover/liminal objective ids also answer the shared triggers:
	chain[1].objectives[1]["id"] = "discover_chunk"
	chain[2].objectives[1]["id"] = "visit_liminal"
	return chain
