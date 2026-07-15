extends GdUnitTestSuite


func test_core_dialogue_json_loads() -> void:
	for npc_id in ["barista", "archivist", "authority"]:
		var path := "res://src/dialogue/%s.json" % npc_id
		assert_bool(FileAccess.file_exists(path)).is_true()
		var text := FileAccess.get_file_as_string(path)
		var data = JSON.parse_string(text)
		assert_that(data).is_not_null()
		assert_bool(data is Dictionary).is_true()
		assert_that(data.get("greeting", {})).is_not_empty()


func test_metahuman_resolve_tier_known() -> void:
	var tier := MetahumanCharacter.resolve_tier("identity")
	assert_str(tier).is_not_empty()
	# With player_human.glb present, identity should not fall to procedural.
	assert_str(tier).is_not_equal("procedural_rig")
