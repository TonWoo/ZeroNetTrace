extends Control

signal after_beat_ready(sender: String, text: String)

var intensity := "full"
var audio_director
var flash: ColorRect
var message: Label
var _active_tween: Tween

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 500
	flash = ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0.85, 0.86, 0.83, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	message = Label.new()
	message.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	message.position = Vector2(-260, -36)
	message.size = Vector2(520, 72)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 23)
	message.add_theme_color_override("font_color", Color("#ff2b2b"))
	message.visible = false
	add_child(message)

func play_event(event: Dictionary) -> void:
	if intensity == "off":
		return
	_clear_active_presentation()
	var level := String(event.get("level", "B"))
	var variants: Dictionary = event.get("variants", {})
	var variant_key := "reduced" if intensity == "reduced" else "full"
	var variant: Dictionary = variants.get(variant_key, {})
	var is_c_event := level.begins_with("C")
	message.text = String(variant.get("text", event.get("effect", "屏幕出现了不属于你的内容。")))
	message.visible = true
	_active_tween = create_tween()
	if is_c_event and intensity == "full":
		flash.color = Color(0.92, 0.92, 0.88, 0.94)
		if audio_director:
			audio_director.play_sting(0.4)
			audio_director.begin_silence(float(event.get("afterBeat", {}).get("delay", 5.0)))
		_active_tween.tween_property(flash, "color:a", 0.0, 0.4)
	elif is_c_event:
		var clear_color := flash.color
		clear_color.a = 0.0
		flash.color = clear_color
		_active_tween.tween_interval(0.05)
	else:
		flash.color = Color(0.55, 0.0, 0.0, 0.22)
		_active_tween.tween_property(flash, "color:a", 0.0, 1.2)
	_active_tween.tween_interval(2.0 if level.begins_with("B") else 1.8)
	_active_tween.tween_callback(func(): message.visible = false)
	_schedule_after_beat(event.get("afterBeat", {}))

func _schedule_after_beat(after_beat_value: Variant) -> void:
	if not after_beat_value is Dictionary:
		return
	var after_beat: Dictionary = after_beat_value
	var sender := String(after_beat.get("sender", ""))
	var text := String(after_beat.get("text", ""))
	if text.is_empty():
		return
	var timer := get_tree().create_timer(maxf(0.0, float(after_beat.get("delay", 5.0))))
	timer.timeout.connect(func(): after_beat_ready.emit(sender, text), CONNECT_ONE_SHOT)

func set_intensity(value: String) -> void:
	intensity = value
	_clear_active_presentation()

func _clear_active_presentation() -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	_active_tween = null
	if message:
		message.visible = false
	if flash:
		var clear_color := flash.color
		clear_color.a = 0.0
		flash.color = clear_color
