extends SceneTree
## Headless smoke: per-layer dialogue resolve + option progression.
## Run: godot --headless --path godot -s res://src/dev/dialogue_layer_smoke.gd

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("[dialogue_layer_smoke] start")
	await process_frame
	var ok := true
	var dlg: Node = root.get_node_or_null("NPCDialogueSystem")
	var layers: Node = root.get_node_or_null("LayerManager")
	if dlg == null:
		_fail("NPCDialogueSystem missing")
		return
	if layers == null:
		_fail("LayerManager missing")
		return

	# Library registration path (WorldLoader blocks) — call only after boot.
	if NpcDialogueLibrary:
		NpcDialogueLibrary.register_all()
	for arch: String in NpcDialogueLibrary.ARCHETYPES:
		for layer: String in NpcDialogueLibrary.LAYERS:
			var id := "%s_%s" % [arch, layer]
			var block: Dictionary = NpcDialogueLibrary.build_dialogue(arch, layer)
			if str(block.get("dialogue_id", "")) != id:
				ok = false
				print("[dialogue_layer_smoke] build_dialogue id FAIL ", id)
			if not FileAccess.file_exists("res://src/dialogue/%s.json" % id):
				ok = false
				print("[dialogue_layer_smoke] missing JSON ", id)

	# Social system resolves by current layer.
	for layer: String in ["subliminal", "liminal", "hyperliminal", "periliminal"]:
		layers.set("current_layer_id", layer)
		var started: bool = dlg.call("start_dialogue", "barista", "greeting")
		if not started:
			ok = false
			print("[dialogue_layer_smoke] start_dialogue FAIL layer=", layer)
			continue
		var pending: Array = dlg.get("_pending_options")
		if pending.is_empty():
			ok = false
			print("[dialogue_layer_smoke] no options layer=", layer)
			continue
		var resolved: String = str(dlg.get("_pending_resolved_key"))
		var expect := "barista_%s" % layer
		if resolved != expect:
			ok = false
			print("[dialogue_layer_smoke] resolve FAIL got=", resolved, " expect=", expect)
		# Pick Leave (last option) to end cleanly.
		dlg.call("choose_dialogue_option", "barista", pending.size() - 1)

	# Explicit layered id should stick even if current layer differs.
	layers.set("current_layer_id", "hyperliminal")
	if not dlg.call("start_dialogue", "archivist_subliminal", "greeting"):
		ok = false
		print("[dialogue_layer_smoke] explicit layered start FAIL")
	elif str(dlg.get("_pending_resolved_key")) != "archivist_subliminal":
		ok = false
		print("[dialogue_layer_smoke] explicit layered resolve FAIL")
	else:
		var opts: Array = dlg.get("_pending_options")
		if not opts.is_empty():
			dlg.call("choose_dialogue_option", "archivist_subliminal", opts.size() - 1)

	# Hub id with underscore (no layer variants) still resolves.
	if FileAccess.file_exists("res://src/dialogue/warden_scout.json"):
		if not dlg.call("start_dialogue", "warden_scout", "greeting"):
			ok = false
			print("[dialogue_layer_smoke] warden_scout FAIL")
		else:
			var wopts: Array = dlg.get("_pending_options")
			if not wopts.is_empty():
				dlg.call("choose_dialogue_option", "warden_scout", wopts.size() - 1)

	print("[dialogue_layer_smoke] RESULT=", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)

func _fail(msg: String) -> void:
	push_error("[dialogue_layer_smoke] " + msg)
	print("[dialogue_layer_smoke] RESULT=FAIL")
	quit(1)
