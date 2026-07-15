extends Node
class_name SceneLoader
## Lightweight scene loader used until/unless maaacks_menus_template is enabled.
## When the plugin is enabled it registers its own SceneLoader autoload — disable
## or delete this stub then (see docs/ADDONS.md).

static func load_scene(path: String, _loading_screen: bool = false) -> void:
	if path.is_empty():
		push_warning("SceneLoader: empty path")
		return
	if not ResourceLoader.exists(path):
		push_error("SceneLoader: missing scene %s" % path)
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		push_error("SceneLoader: no SceneTree")
		return
	var err := tree.change_scene_to_file(path)
	if err != OK:
		push_error("SceneLoader: change_scene_to_file(%s) failed (%d)" % [path, err])
