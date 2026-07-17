extends SceneTree
## Verifies combat sound slots resolve via AssetLibrary (post-import) and that
## CombatSfx never returns a null stream for known slots.
## Run: godot --headless --path godot -s res://src/dev/combat_sfx_smoke.gd

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("[combat_sfx_smoke] start")
	await process_frame
	var ok := true
	for slot in CombatSfx.SLOTS:
		var packed: AudioStream = AssetLibrary.sound(slot)
		var resolved: AudioStream = CombatSfx.resolve(slot)
		print("[combat_sfx_smoke] ", slot, " packed=", packed != null, " resolved=", resolved != null)
		if resolved == null:
			ok = false
			print("[combat_sfx_smoke] resolve FAIL ", slot)
	var host := Node3D.new()
	root.add_child(host)
	# Off-tree then on-tree play path.
	var early := Node3D.new()
	CombatSfx.play(early, "boss_spawn", Vector3.ZERO)
	root.add_child(early)
	await process_frame
	for slot in CombatSfx.SLOTS:
		CombatSfx.play(host, slot, Vector3(1, 0, 0))
	SkillVFX.cast_flash(host, Vector3.ZERO)
	SkillVFX.hit_spark(host, Vector3.ZERO)
	SkillVFX.ultimate_burst(host, Vector3.ZERO, 3.0)
	SkillVFX.shield_bubble(host, host, 0.05)
	SkillVFX.blueprint_cast(host, Vector3.ZERO, {"params": {}, "audio": {}})
	SkillVFX.blueprint_cast(host, Vector3.ZERO, {
		"params": {"shape_style": "ring"},
		"audio": {"waveform": "sine", "pitch": 1.2, "attack": 0.02, "decay": 0.2},
	})
	var boss := WorldEntity.new()
	root.add_child(boss)
	boss.setup_boss({
		"id": "sfx",
		"faction": "Factionless",
		"category": "Matter",
		"stages": [{"name": "SFX Titan", "desc": ""}],
	}, 3, null)
	boss.take_hit(int(boss.max_hp * 0.40))
	boss.take_hit(int(boss.max_hp * 0.35))
	boss.take_hit(boss.hp + 1)
	await process_frame
	print("[combat_sfx_smoke] RESULT=", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
