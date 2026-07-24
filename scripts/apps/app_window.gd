class_name AppWindow
extends PanelContainer

signal activated(window: Control)

@export var app_title := "应用"
@export var app_id := "app"

var body: MarginContainer
var title_label: Label
var resize_handle: Control
var _dragging := false
var _resizing := false
var _drag_offset := Vector2.ZERO
var _resize_origin := Vector2.ZERO
var _resize_start := Vector2.ZERO
var _restore_rect := Rect2()
var _maximized := false
var _collapsed := false
var _collapse_restore_height := 260.0
var _collapse_restore_minimum := Vector2(360, 240)

func _ready() -> void:
	custom_minimum_size = Vector2(360, 240)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_chrome()
	_build_body(body)

func _build_chrome() -> void:
	var root := VBoxContainer.new()
	root.name = "WindowRoot"
	root.add_theme_constant_override("separation", 0)
	add_child(root)
	var title_bar := HBoxContainer.new()
	title_bar.name = "TitleBar"
	title_bar.custom_minimum_size.y = 30
	title_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	title_bar.gui_input.connect(_on_title_input)
	root.add_child(title_bar)
	title_label = Label.new()
	title_label.text = " %s" % app_title
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_bar.add_child(title_label)
	var minimize := Button.new()
	minimize.text = "_"
	minimize.tooltip_text = "最小化"
	minimize.pressed.connect(_toggle_collapse)
	title_bar.add_child(minimize)
	var maximize := Button.new()
	maximize.text = "□"
	maximize.tooltip_text = "最大化/恢复"
	maximize.pressed.connect(toggle_maximize)
	title_bar.add_child(maximize)
	var close := Button.new()
	close.text = "×"
	close.tooltip_text = "隐藏窗口"
	close.pressed.connect(hide)
	title_bar.add_child(close)
	body = MarginContainer.new()
	body.name = "Body"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("margin_left", 8)
	body.add_theme_constant_override("margin_top", 8)
	body.add_theme_constant_override("margin_right", 8)
	body.add_theme_constant_override("margin_bottom", 8)
	root.add_child(body)
	resize_handle = Control.new()
	resize_handle.name = "ResizeHandle"
	resize_handle.custom_minimum_size = Vector2(14, 14)
	resize_handle.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	resize_handle.mouse_filter = Control.MOUSE_FILTER_STOP
	resize_handle.gui_input.connect(_on_resize_input)
	root.add_child(resize_handle)

func _build_body(_parent: MarginContainer) -> void:
	pass

func focus_window() -> void:
	show()
	move_to_front()
	activated.emit(self)

func snap_left() -> void:
	var viewport_size := get_viewport_rect().size
	position = Vector2(8, 38)
	size = Vector2(viewport_size.x * 0.62 - 12, viewport_size.y - 96)

func snap_right() -> void:
	var viewport_size := get_viewport_rect().size
	position = Vector2(viewport_size.x * 0.62 + 4, 38)
	size = Vector2(viewport_size.x * 0.38 - 12, viewport_size.y - 96)

func toggle_maximize() -> void:
	if _maximized:
		position = _restore_rect.position
		size = _restore_rect.size
		_maximized = false
	else:
		_restore_rect = Rect2(position, size)
		position = Vector2(8, 38)
		size = get_viewport_rect().size - Vector2(16, 96)
		_maximized = true

func _toggle_collapse() -> void:
	_collapsed = not _collapsed
	if _collapsed:
		_collapse_restore_height = size.y
		_collapse_restore_minimum = custom_minimum_size
		body.visible = false
		resize_handle.visible = false
		custom_minimum_size = Vector2(custom_minimum_size.x, 44.0)
		body.get_parent().update_minimum_size()
		update_minimum_size()
		reset_size()
		size = Vector2(size.x, 48.0)
	else:
		custom_minimum_size = _collapse_restore_minimum
		body.visible = true
		resize_handle.visible = true
		body.get_parent().update_minimum_size()
		update_minimum_size()
		size = Vector2(size.x, maxf(_collapse_restore_height, custom_minimum_size.y))

func _on_title_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		_drag_offset = get_global_mouse_position() - global_position
		if event.double_click:
			toggle_maximize()
		focus_window()
	elif event is InputEventMouseMotion and _dragging and not _maximized:
		position = get_global_mouse_position() - _drag_offset

func _on_resize_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_resizing = event.pressed
		_resize_origin = size
		_resize_start = get_global_mouse_position()
		focus_window()
	elif event is InputEventMouseMotion and _resizing and not _maximized:
		var delta := get_global_mouse_position() - _resize_start
		size = Vector2(maxf(custom_minimum_size.x, _resize_origin.x + delta.x), maxf(custom_minimum_size.y, _resize_origin.y + delta.y))
