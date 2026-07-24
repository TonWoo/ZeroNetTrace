class_name DesktopAtmosphere
extends Control

var intensity := "full"
var _elapsed := 0.0
var _event_index := 0
var _ghost_cursor := Vector2.ZERO
var _ghost_alpha := 0.0
var _notice: Label
var _persistent_marks: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 420
	_notice = Label.new()
	_notice.position = Vector2(12, 812)
	_notice.size = Vector2(720, 28)
	_notice.add_theme_color_override("font_color", Color("#7a827d"))
	_notice.visible = false
	add_child(_notice)

func _process(delta: float) -> void:
	if intensity == "off":
		_notice.visible = false
		_ghost_alpha = 0.0
		return
	_elapsed += delta
	_ghost_alpha = maxf(0.0, _ghost_alpha - delta * 1.8)
	if _elapsed >= 42.0:
		_elapsed = 0.0
		_play_next()
	queue_redraw()

func _play_next() -> void:
	_event_index = (_event_index + 1) % 3
	match _event_index:
		0:
			_notice.text = "索引提示：你在找谁，还是谁正在找你？"
			_show_notice()
		1:
			_notice.text = "文件修改时间：明天 03:17"
			_show_notice()
		2:
			_ghost_cursor = get_viewport().get_mouse_position() - Vector2(18, 0)
			_ghost_alpha = 0.45 if intensity == "full" else 0.18

func _show_notice() -> void:
	_notice.visible = true
	var tween := create_tween()
	tween.tween_interval(2.5)
	tween.tween_callback(func(): _notice.visible = false)

func _draw() -> void:
	if _ghost_alpha > 0.0:
		draw_circle(_ghost_cursor, 5.0, Color(0.75, 0.8, 0.77, _ghost_alpha))
		draw_line(_ghost_cursor, _ghost_cursor + Vector2(12, 18), Color(0.75, 0.8, 0.77, _ghost_alpha), 1.0)
	if _persistent_marks.has("counter_trace"):
		draw_circle(Vector2(10, size.y - 52), 3.0, Color("#ff2b2b"))

func set_persistent_mark(mark_id: String) -> void:
	if not mark_id.is_empty():
		_persistent_marks[mark_id] = true
		queue_redraw()

func clear_persistent_marks() -> void:
	_persistent_marks.clear()
	queue_redraw()
