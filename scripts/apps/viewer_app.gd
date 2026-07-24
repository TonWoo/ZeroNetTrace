extends "res://scripts/apps/app_window.gd"

signal pin_requested(label: String, image_path: String)

var runtime
var current_file: Dictionary = {}
var heading: Label
var placeholder: PanelContainer
var placeholder_label: Label
var asset_texture: TextureRect
var text_view: RichTextLabel
var frame_controls: HBoxContainer
var frame_slider: HSlider
var frame_label: Label
var zoom_slider: HSlider

func _build_body(parent: MarginContainer) -> void:
	app_id = "viewer"
	app_title = "查看器 // FORENSIC"
	title_label.text = " %s" % app_title
	var column := VBoxContainer.new()
	parent.add_child(column)
	heading = Label.new()
	heading.add_theme_font_size_override("font_size", 18)
	column.add_child(heading)
	placeholder = PanelContainer.new()
	placeholder.custom_minimum_size = Vector2(420, 240)
	placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var placeholder_style := StyleBoxFlat.new()
	placeholder_style.bg_color = Color("#252826")
	placeholder_style.border_color = Color("#676d69")
	placeholder_style.set_border_width_all(2)
	placeholder.add_theme_stylebox_override("panel", placeholder_style)
	column.add_child(placeholder)
	asset_texture = TextureRect.new()
	asset_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	asset_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	asset_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	asset_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placeholder.add_child(asset_texture)
	placeholder_label = Label.new()
	placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	placeholder.add_child(placeholder_label)
	text_view = RichTextLabel.new()
	text_view.bbcode_enabled = true
	text_view.selection_enabled = true
	text_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(text_view)
	frame_controls = HBoxContainer.new()
	column.add_child(frame_controls)
	var previous := Button.new()
	previous.text = "◀ 上一格"
	previous.pressed.connect(func(): _set_frame(int(frame_slider.value) - 1))
	frame_controls.add_child(previous)
	frame_slider = HSlider.new()
	frame_slider.min_value = 1
	frame_slider.max_value = 47
	frame_slider.step = 1
	frame_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame_slider.value_changed.connect(func(value): _set_frame(int(value)))
	frame_controls.add_child(frame_slider)
	var next := Button.new()
	next.text = "下一格 ▶"
	next.pressed.connect(func(): _set_frame(int(frame_slider.value) + 1))
	frame_controls.add_child(next)
	frame_label = Label.new()
	frame_label.custom_minimum_size.x = 76
	frame_controls.add_child(frame_label)
	var footer := HBoxContainer.new()
	column.add_child(footer)
	footer.add_child(Label.new())
	footer.get_child(0).text = "缩放"
	zoom_slider = HSlider.new()
	zoom_slider.min_value = 0.5
	zoom_slider.max_value = 3.0
	zoom_slider.step = 0.1
	zoom_slider.value = 1.0
	zoom_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zoom_slider.value_changed.connect(func(value): placeholder.scale = Vector2(value, value))
	footer.add_child(zoom_slider)
	var pin := Button.new()
	pin.text = "钉入笔记"
	pin.pressed.connect(_capture_pin)
	footer.add_child(pin)
	_clear_view()

func configure(runtime_ref) -> void:
	runtime = runtime_ref

func open_file(file_entry: Dictionary) -> void:
	current_file = file_entry.duplicate(true)
	focus_window()
	heading.text = String(file_entry.get("path", file_entry.get("name", "未命名文件")))
	var type := String(file_entry.get("type", "text"))
	var is_visual := type in ["image", "video", "audio"] or file_entry.has("assetId")
	placeholder.visible = is_visual
	text_view.visible = not is_visual or not String(file_entry.get("content", "")).is_empty()
	frame_controls.visible = type == "video"
	_present_asset(String(file_entry.get("assetId", "asset_unassigned")), String(file_entry.get("description", "深灰占位画面")))
	text_view.text = String(file_entry.get("content", ""))
	if type == "video":
		frame_slider.max_value = int(file_entry.get("frames", 47))
		_set_frame(1)

func _set_frame(frame: int) -> void:
	if not frame_controls.visible:
		return
	var clamped := clampi(frame, 1, int(frame_slider.max_value))
	frame_slider.set_value_no_signal(clamped)
	frame_label.text = "%02d/%02d" % [clamped, int(frame_slider.max_value)]
	var frame_event: Dictionary = current_file.get("frameEvents", {}).get(str(clamped), {})
	if not frame_event.is_empty():
		_present_asset(String(frame_event.get("assetId", current_file.get("assetId", "asset_unassigned"))), String(frame_event.get("description", "取证帧 %02d" % clamped)))
		var trigger: Dictionary = frame_event.get("trigger", {})
		if runtime and not trigger.is_empty():
			runtime.trigger_context(String(trigger.get("type", "viewer_frame")), String(trigger.get("target", "")))
	else:
		_present_asset(String(current_file.get("assetId", "asset_unassigned")), "取证帧 %02d" % clamped)

func asset_resource_path(asset_id: String) -> String:
	var safe_id := asset_id.strip_edges().get_file()
	if safe_id.is_empty():
		safe_id = "asset_unassigned"
	return "res://assets/art/%s.png" % safe_id

func _present_asset(asset_id: String, description: String) -> void:
	var path := asset_resource_path(asset_id)
	var loaded_resource = load(path) if ResourceLoader.exists(path, "Texture2D") else null
	if loaded_resource is Texture2D:
		asset_texture.texture = loaded_resource
		asset_texture.visible = true
		placeholder_label.visible = false
	else:
		asset_texture.texture = null
		asset_texture.visible = false
		placeholder_label.visible = true
		placeholder_label.text = "资产 ID：%s\n待替换\n%s" % [asset_id, description]

func _capture_pin() -> void:
	var directory := DirAccess.open("user://")
	if directory and not directory.dir_exists("screenshots"):
		directory.make_dir("screenshots")
	var filename := "user://screenshots/pin_%d.png" % Time.get_unix_time_from_system()
	var image := get_viewport().get_texture().get_image()
	var result := image.save_png(filename)
	pin_requested.emit(heading.text, filename if result == OK else "")

func _clear_view() -> void:
	heading.text = "尚未打开文件"
	placeholder.visible = false
	asset_texture.texture = null
	asset_texture.visible = false
	text_view.visible = true
	text_view.text = "在终端中使用 open <文件>，或双击邮件附件。"
	frame_controls.visible = false
