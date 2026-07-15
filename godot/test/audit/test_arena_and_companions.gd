# GdUnit4 suite — enable the gdUnit4 plugin (docs/ADDONS.md) then run from
# Godot: Project → Tools → GdUnit4, or CI via godot-ci workflow.
# CI invokes: godot --headless … GdUnitCmdTool.gd -a test/ --ignoreHeadlessMode
extends GdUnitTestSuite


func test_arena_modes_have_scenes() -> void:
	for mode in ArenaModes.MODES:
		var path := str(mode.get("scene", ""))
		assert_str(path).is_not_empty()
		assert_bool(ResourceLoader.exists(path)).is_true()


func test_duel_modes_registered() -> void:
	assert_that(ArenaModes.by_id("duel")).is_not_empty()
	assert_that(ArenaModes.by_id("duel_2v2")).is_not_empty()
	assert_that(ArenaModes.by_id("survival").get("scene")).is_equal(
		"res://scenes/world/playtest_arena.tscn")


func test_companion_unlock_api_surface() -> void:
	var sys := auto_free(load("res://src/companion/companion_system.gd").new())
	assert_bool(sys.has_method("get_unlocked_ids")).is_true()
	assert_bool(sys.has_method("equip_companion")).is_true()
	assert_bool(sys.has_method("unlock_random")).is_true()
	assert_bool(sys.has_method("get_unlocked_count")).is_true()
