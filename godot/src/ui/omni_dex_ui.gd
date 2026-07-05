class_name OmniDexUI
extends CanvasLayer
## A browsable index of the world's roster — entities by faction/category,
## companions by faction — named after the Master OmniDex the game's data
## is drawn from. Opened from the title screen (or anywhere via B-adjacent
## menus later); read-only, no gameplay effect.

var _faction_tabs: TabBar
var _list: ItemList
var _detail: RichTextLabel

const FACTIONS := ["SovereignCrown", "WildlandsAscendant", "VeiledCurrent", "Factionless"]

func _ready() -> void:
	layer = 25
	var root := PanelContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.self_modulate = Color(0.08, 0.07, 0.12, 0.97)
	add_child(root)

	var vbox := VBoxContainer.new()
	root.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title := Label.new()
	title.text = "OMNI DEX"
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(queue_free)
	header.add_child(close)

	_faction_tabs = TabBar.new()
	for f in FACTIONS:
		_faction_tabs.add_tab(f)
	_faction_tabs.tab_changed.connect(func(_i): _refresh_list())
	vbox.add_child(_faction_tabs)

	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(cols)

	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(320, 0)
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_on_select)
	cols.add_child(_list)

	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_child(_detail)

	_refresh_list()

func _refresh_list() -> void:
	_list.clear()
	_detail.text = ""
	var faction := FACTIONS[_faction_tabs.current_tab]
	for line in EntityDexData.by_faction(faction):
		var apex: Dictionary = EntityDexData.stage_for(line, 3)
		var shown := str(apex.get("name", line.get("id", "?")))
		_list.add_item("%s  [%s]" % [shown, line.get("category", "?")])
		_list.set_item_metadata(_list.item_count - 1, line)

func _on_select(idx: int) -> void:
	var line: Dictionary = _list.get_item_metadata(idx)
	var lines: Array = []
	lines.append("[b]%s[/b]  —  %s / %s" % [line.get("id", "?"), line.get("faction", "?"), line.get("category", "?")])
	lines.append("")
	for i in 3:
		var stage: Dictionary = EntityDexData.stage_for(line, i + 1)
		if stage.is_empty():
			continue
		lines.append("[color=#ffd88a]Stage %d — %s[/color]" % [i + 1, stage.get("name", "?")])
		lines.append(str(stage.get("desc", "")))
		lines.append("")
	_detail.text = "\n".join(lines)
