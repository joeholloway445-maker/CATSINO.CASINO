extends GdUnitTestSuite


func test_core_dialogue_json_loads() -> void:
	for npc_id in ["barista", "archivist", "authority", "lover", "reflection"]:
		var path := "res://src/dialogue/%s.json" % npc_id
		assert_bool(FileAccess.file_exists(path)).is_true()
		var text := FileAccess.get_file_as_string(path)
		var data = JSON.parse_string(text)
		assert_that(data).is_not_null()
		assert_bool(data is Dictionary).is_true()
		assert_that(data.get("greeting", {})).is_not_empty()


func test_per_layer_dialogue_json_covers_library() -> void:
	## 5 archetypes × 6 layers — exported by scripts/export_layer_dialogue.py
	for arch in NpcDialogueLibrary.ARCHETYPES:
		for layer in NpcDialogueLibrary.LAYERS:
			var path := "res://src/dialogue/%s_%s.json" % [arch, layer]
			assert_bool(FileAccess.file_exists(path)).is_true()
			var data = JSON.parse_string(FileAccess.get_file_as_string(path))
			assert_bool(data is Dictionary).is_true()
			var greeting: Dictionary = data.get("greeting", {})
			assert_that(greeting.get("line", "")).is_not_empty()
			# Non-hub layers must carry the library greeting verbatim.
			if layer != "hyperliminal":
				var expected := NpcDialogueLibrary.greeting(arch, layer)
				assert_str(str(greeting.get("line", ""))).is_equal(expected)


func test_library_build_dialogue_prefers_json() -> void:
	var block := NpcDialogueLibrary.build_dialogue("barista", "subliminal")
	assert_str(str(block.get("dialogue_id", ""))).is_equal("barista_subliminal")
	assert_str(str(block.get("start_node", ""))).is_equal("greeting")
	assert_that(block.get("nodes", [])).is_not_empty()


func test_metahuman_resolve_tier_known() -> void:
	var tier := MetahumanCharacter.resolve_tier("identity")
	assert_str(tier).is_not_empty()
	# Accept any resolved tier — LFS / missing GLB may fall back to procedural
	# in sparse checkouts; the API must still return a known label.
	var allowed := [
		"peri_human_race", "peri_human_player",
		"metahuman_race", "metahuman_player",
		"player_human", "player_cat", "procedural_rig",
	]
	assert_bool(tier in allowed).is_true()
