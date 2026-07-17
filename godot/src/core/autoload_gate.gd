class_name AutoloadGate
extends RefCounted
## Safe access to autoload singletons from `class_name` scripts.
## Bare Autoload identifiers race during headless -s / first-pass compile
## (see gate5/gate6 CI SCRIPT ERRORs). Always resolve via the SceneTree.

static func get_node(autoload_name: String) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(autoload_name)

## True when a res:// asset can be load()'d without engine ERROR spam.
## Fresh CI checkouts often have `.import` sidecars but no `.godot/imported`
## binaries until `--import` runs.
static func import_binary_ready(path: String) -> bool:
	if path.is_empty() or not ResourceLoader.exists(path):
		return false
	var sidecar := path + ".import"
	if not FileAccess.file_exists(sidecar):
		return true
	var cfg := FileAccess.get_file_as_string(sidecar)
	var key := 'path="'
	var idx := cfg.find(key)
	if idx < 0:
		return true
	var start := idx + key.length()
	var end := cfg.find('"', start)
	if end < 0:
		return true
	var imported: String = cfg.substr(start, end - start)
	if imported.is_empty():
		return true
	return FileAccess.file_exists(imported)
