extends "res://scripts/apps/app_window.gd"

signal notes_changed(text: String)

var runtime
var editor: TextEdit
var pins: ItemList

func _build_body(parent: MarginContainer) -> void:
	app_id = "notebook"
	app_title = "笔记本 // CASE-NOTES"
	title_label.text = " %s" % app_title
	var column := VBoxContainer.new()
	parent.add_child(column)
	editor = TextEdit.new()
	editor.placeholder_text = "自己整理案情。游戏不会替你连线。"
	editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor.text_changed.connect(_on_text_changed)
	column.add_child(editor)
	var label := Label.new()
	label.text = "钉入的画面"
	column.add_child(label)
	pins = ItemList.new()
	pins.custom_minimum_size.y = 100
	column.add_child(pins)

func configure(runtime_ref) -> void:
	runtime = runtime_ref
	editor.text = runtime.notes
	pins.clear()
	for snapshot_value in runtime.pinned_screenshots:
		_render_pin(snapshot_value)

func pin_snapshot(label: String, image_path: String) -> void:
	if runtime:
		runtime.pin_screenshot(label, image_path)
	_render_pin({"label": label, "path": image_path})

func _render_pin(snapshot: Dictionary) -> void:
	pins.add_item("%s\n%s" % [snapshot.get("label", "未命名画面"), snapshot.get("path", "")])

func _on_text_changed() -> void:
	if runtime:
		runtime.notes = editor.text
	notes_changed.emit(editor.text)
