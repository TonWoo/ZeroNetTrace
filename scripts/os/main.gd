extends Control

const DesktopAtmosphereScript = preload("res://scripts/engine/desktop_atmosphere.gd")
const TutorialRuntimeScript = preload("res://scripts/engine/tutorial_runtime.gd")

const APP_SCENES := {
	"terminal": preload("res://scenes/apps/terminal_app.tscn"),
	"browser": preload("res://scenes/apps/browser_app.tscn"),
	"mail": preload("res://scenes/apps/mail_app.tscn"),
	"messenger": preload("res://scenes/apps/messenger_app.tscn"),
	"viewer": preload("res://scenes/apps/viewer_app.tscn"),
	"notebook": preload("res://scenes/apps/notebook_app.tscn"),
	"report": preload("res://scenes/apps/case_report_app.tscn")
}

var repository
var runtime
var tutorial_runtime
var save_service
var event_bus
var audio_director
var horror_director
var atmosphere
var crt_overlay: ColorRect
var apps: Dictionary = {}
var desktop_layer: Control
var clock_label: Label
var case_label: Label
var status_label: Label
var theme_selector: OptionButton
var horror_selector: OptionButton
var crt_toggle: CheckButton
var case_index: Array = []
var current_case_data: Dictionary = {}
var current_case_position := 0
var campaign_progress: Dictionary = {}
var _z_counter := 10
var _theme_id := "mono"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_create_services()
	_build_desktop()
	_load_initial_case()

func _process(delta: float) -> void:
	if clock_label:
		clock_label.text = Time.get_time_string_from_system().left(5)
	if runtime and horror_director:
		for event in runtime.consume_triggered_horror():
			horror_director.play_event(event)
			_apply_horror_effect(event)
			status_label.text = "检测到桌面异常：%s" % event.get("id", "UNKNOWN")
		for hint in runtime.consume_hints():
			apps["messenger"].push_hint("线人提示", String(hint.get("text", "")), clock_label.text)
			status_label.text = "通讯器收到 %d 级提示" % int(hint.get("level", 1))
	if tutorial_runtime:
		tutorial_runtime.tick(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		var mode := DisplayServer.window_get_mode()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode != DisplayServer.WINDOW_MODE_WINDOWED else DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

func _create_services() -> void:
	repository = get_node("/root/DataRepository")
	runtime = get_node("/root/CaseRuntime")
	save_service = get_node("/root/SaveService")
	event_bus = get_node("/root/EventBus")
	audio_director = get_node("/root/AudioDirector")
	horror_director = get_node("/root/HorrorDirector")

func _build_desktop() -> void:
	var background := ColorRect.new()
	background.color = Color("#0a0c0b")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var topbar := HBoxContainer.new()
	topbar.position = Vector2(8, 5)
	topbar.size = Vector2(1584, 28)
	add_child(topbar)
	case_label = Label.new()
	case_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	case_label.text = "零网寻踪 // 正在加载"
	topbar.add_child(case_label)
	status_label = Label.new()
	status_label.text = "OFFLINE"
	status_label.custom_minimum_size.x = 360
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	topbar.add_child(status_label)
	clock_label = Label.new()
	clock_label.custom_minimum_size.x = 72
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	topbar.add_child(clock_label)
	theme_selector = OptionButton.new()
	for label in ["黑白", "磷光绿", "琥珀"]:
		theme_selector.add_item(label)
	theme_selector.item_selected.connect(_set_theme)
	topbar.add_child(theme_selector)
	horror_selector = OptionButton.new()
	for label in ["恐怖：完整", "恐怖：减弱", "恐怖：关闭"]:
		horror_selector.add_item(label)
	horror_selector.item_selected.connect(_set_horror)
	topbar.add_child(horror_selector)
	crt_toggle = CheckButton.new()
	crt_toggle.text = "CRT"
	crt_toggle.button_pressed = true
	crt_toggle.toggled.connect(_set_crt)
	topbar.add_child(crt_toggle)
	desktop_layer = Control.new()
	desktop_layer.name = "DesktopLayer"
	desktop_layer.position = Vector2.ZERO
	desktop_layer.size = Vector2(1600, 900)
	add_child(desktop_layer)
	for app_id in APP_SCENES:
		var app = APP_SCENES[app_id].instantiate()
		app.name = "%sApp" % String(app_id).capitalize()
		app.visible = false
		app.activated.connect(_raise_window)
		desktop_layer.add_child(app)
		apps[app_id] = app
	var taskbar := HBoxContainer.new()
	taskbar.position = Vector2(8, 852)
	taskbar.size = Vector2(1584, 40)
	add_child(taskbar)
	for app_id in ["terminal", "browser", "mail", "messenger", "viewer", "notebook", "report"]:
		var button := Button.new()
		button.text = {"terminal":"终端", "browser":"浏览器", "mail":"邮件", "messenger":"通讯器", "viewer":"查看器", "notebook":"笔记本", "report":"结案报告"}[app_id]
		button.pressed.connect(_open_app.bind(app_id))
		taskbar.add_child(button)
	horror_director.audio_director = audio_director
	if not horror_director.after_beat_ready.is_connected(_on_after_beat_ready):
		horror_director.after_beat_ready.connect(_on_after_beat_ready)
	atmosphere = DesktopAtmosphereScript.new()
	atmosphere.name = "DesktopAtmosphere"
	add_child(atmosphere)
	crt_overlay = ColorRect.new()
	crt_overlay.name = "CRTOverlay"
	crt_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	crt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crt_overlay.z_index = 410
	var crt_material := ShaderMaterial.new()
	crt_material.shader = load("res://assets/shaders/crt.gdshader")
	crt_overlay.material = crt_material
	add_child(crt_overlay)
	apps["terminal"].open_requested.connect(_open_viewer)
	apps["terminal"].command_executed.connect(_on_terminal_command)
	apps["mail"].mail_opened.connect(_on_mail_opened)
	apps["mail"].attachment_open_requested.connect(_on_mail_attachment_requested)
	apps["viewer"].pin_requested.connect(_pin_snapshot)
	apps["notebook"].notes_changed.connect(func(_text): _save_now())
	apps["report"].answer_submitted.connect(_on_report_answer_submitted)
	apps["report"].report_completed.connect(_on_report_completed)
	if not runtime.gate_resolved.is_connected(_on_gate_resolved):
		runtime.gate_resolved.connect(_on_gate_resolved)
	if not runtime.node_authenticated.is_connected(_on_node_authenticated):
		runtime.node_authenticated.connect(_on_node_authenticated)
	if not runtime.counter_trace_reduced.is_connected(_on_counter_trace_reduced):
		runtime.counter_trace_reduced.connect(_on_counter_trace_reduced)
	if not runtime.file_opened.is_connected(_on_runtime_file_opened):
		runtime.file_opened.connect(_on_runtime_file_opened)
	if not runtime.evidence_collected.is_connected(_on_runtime_evidence_collected):
		runtime.evidence_collected.connect(_on_runtime_evidence_collected)
	_apply_theme("mono")

func _load_initial_case() -> void:
	case_index = repository.load_index()
	if case_index.is_empty():
		status_label.text = repository.last_error if not repository.last_error.is_empty() else "未找到案件数据"
		return
	var saved: Dictionary = save_service.load_game()
	campaign_progress = saved.get("completedCases", {}).duplicate(true)
	var saved_case := String(saved.get("currentCase", ""))
	for index in case_index.size():
		if String(case_index[index].get("id", "")) == saved_case:
			current_case_position = index
			break
	_load_case_at(current_case_position, saved)

func _load_case_at(index: int, saved := {}) -> void:
	if index < 0 or index >= case_index.size():
		return
	current_case_position = index
	current_case_data = repository.load_case(String(case_index[index].get("id", "")))
	if current_case_data.is_empty():
		status_label.text = repository.last_error
		return
	tutorial_runtime = null
	runtime.setup(current_case_data)
	atmosphere.clear_persistent_marks()
	if saved is Dictionary and String(saved.get("currentCase", "")) == String(current_case_data.get("caseId", "")):
		runtime.apply_save_data(saved)
	_restore_persistent_horror_marks()
	var saved_tutorial_state: Dictionary = {}
	if saved is Dictionary and String(saved.get("currentCase", "")) == String(current_case_data.get("caseId", "")):
		saved_tutorial_state = saved.get("tutorialState", {})
	tutorial_runtime = TutorialRuntimeScript.new()
	tutorial_runtime.configure(current_case_data, saved_tutorial_state, _build_tutorial_facts())
	tutorial_runtime.step_advanced.connect(_on_tutorial_step_advanced)
	tutorial_runtime.feedback_requested.connect(_on_tutorial_feedback_requested)
	tutorial_runtime.nudge_requested.connect(_deliver_tutorial_content)
	case_label.text = "零网寻踪 // %s" % current_case_data.get("title", "未知案件")
	status_label.text = "本地工作区就绪"
	apps["terminal"].configure(runtime)
	apps["browser"].configure(runtime, current_case_data)
	apps["mail"].set_mails(current_case_data.get("mails", []), runtime)
	apps["messenger"].set_conversations(current_case_data.get("conversations", []), runtime)
	apps["viewer"].configure(runtime)
	apps["notebook"].configure(runtime)
	apps["report"].configure(runtime, current_case_data.get("caseReport", []))
	horror_director.set_intensity(runtime.horror_intensity)
	atmosphere.intensity = runtime.horror_intensity
	crt_overlay.visible = runtime.crt_enabled
	_apply_theme(runtime.theme_id)
	theme_selector.select(["mono", "green", "amber"].find(runtime.theme_id))
	horror_selector.select(["full", "reduced", "off"].find(runtime.horror_intensity))
	crt_toggle.set_pressed_no_signal(runtime.crt_enabled)
	_open_app("mail")
	_open_app("terminal")
	apps["terminal"].snap_left()
	apps["mail"].snap_right()
	_save_now()

func _open_app(app_id: String) -> void:
	if not apps.has(app_id):
		return
	if app_id == "report" and runtime and not runtime.can_open_report():
		status_label.text = "结案报告尚未解锁：仍有题目引用的证据未取得。"
		return
	apps[app_id].focus_window()

func _raise_window(window: Control) -> void:
	_z_counter += 1
	window.z_index = _z_counter

func _open_viewer(file_entry: Dictionary) -> void:
	audio_director.play_hard_drive()
	apps["viewer"].open_file(file_entry)
	apps["viewer"].snap_right()

func _on_terminal_command(raw_text: String, result: Dictionary) -> void:
	audio_director.play_key_tick()
	if not bool(result.get("ok", false)):
		return
	var parsed: Dictionary = apps["terminal"].router.parse(raw_text) if apps.has("terminal") and apps["terminal"].router != null else {}
	var command := String(parsed.get("command", raw_text.get_slice(" ", 0))).to_lower()
	var metadata := {"resultCode": String(result.get("code", ""))}
	var args: Array = parsed.get("args", [])
	if not args.is_empty() and command in ["probe", "crack", "login"]:
		metadata["addr"] = String(args[0])
	_observe_tutorial("command_succeeded", command, metadata)

func _on_mail_opened(mail_id: String) -> void:
	_observe_tutorial("mail_opened", mail_id)

func _on_mail_attachment_requested(file_entry: Dictionary) -> void:
	var attachment_id := String(file_entry.get("id", file_entry.get("path", "")))
	_observe_tutorial("attachment_opened", attachment_id, {"path": String(file_entry.get("path", ""))})
	_open_viewer(file_entry)

func _on_gate_resolved(gate_id: String) -> void:
	_observe_tutorial("gate_resolved", gate_id)

func _on_node_authenticated(addr: String) -> void:
	_observe_tutorial("node_authenticated", addr)

func _on_counter_trace_reduced(target: String) -> void:
	_observe_tutorial("counter_trace_reduced", target)

func _on_runtime_file_opened(addr: String, path: String) -> void:
	_observe_tutorial("file_opened", path, {"addr": addr})

func _on_runtime_evidence_collected(evidence_id: String) -> void:
	_observe_tutorial("evidence_collected", evidence_id)

func _on_report_answer_submitted(question_id: String, result: Dictionary) -> void:
	_observe_tutorial("report_answered", question_id, {"resultCode": String(result.get("code", "")), "correct": bool(result.get("correct", false))})

func _observe_tutorial(action_type: String, target: String = "", metadata: Dictionary = {}) -> void:
	if tutorial_runtime == null:
		return
	tutorial_runtime.observe(action_type, target, metadata)
	_save_now()

func _on_tutorial_step_advanced(_step: Dictionary, deliveries: Array) -> void:
	for delivery in deliveries:
		_deliver_tutorial_content(delivery)

func _deliver_tutorial_content(delivery: Dictionary) -> void:
	var content_id := String(delivery.get("contentId", ""))
	var message := _tutorial_message(content_id)
	if message.is_empty():
		return
	var sender := String(message.get("sender", "ZERO-SHELL"))
	var body_text := String(message.get("text", ""))
	match String(delivery.get("channel", "messenger")):
		"terminal":
			apps["terminal"].inject_system_line("%s // %s" % [sender, body_text])
		_:
			apps["messenger"].push_hint(sender, body_text, clock_label.text if clock_label else "--:--")
	if status_label:
		status_label.text = "恢复了一条离线记录"
	_save_now()

func _tutorial_message(content_id: String) -> Dictionary:
	for message_value in current_case_data.get("tutorialMessages", []):
		if String(message_value.get("id", "")) == content_id:
			return message_value
	return {}

func _on_tutorial_feedback_requested(_app_id: String, _style: String, _sound: String) -> void:
	pass

func _pin_snapshot(label: String, image_path: String) -> void:
	apps["notebook"].pin_snapshot(label, image_path)
	status_label.text = "画面已钉入笔记本"
	_save_now()

func _on_after_beat_ready(sender: String, text: String) -> void:
	apps["messenger"].push_hint(sender if not sender.is_empty() else "线人", text, clock_label.text)
	status_label.text = "通讯器收到一条新消息"

func _apply_horror_effect(event: Dictionary) -> void:
	if runtime == null or runtime.horror_intensity == "off":
		return
	var effect: Dictionary = event.get("desktopEffect", {})
	if String(effect.get("type", "")) == "terminal_injection":
		apps["terminal"].inject_system_line(String(effect.get("text", "UNKNOWN INPUT")))
	var persistent_mark := String(effect.get("persistentMark", ""))
	if not persistent_mark.is_empty():
		atmosphere.set_persistent_mark(persistent_mark)

func _restore_persistent_horror_marks() -> void:
	for event_value in current_case_data.get("horrorEvents", []):
		var event: Dictionary = event_value
		if not runtime.consumed_horror.has(String(event.get("id", ""))):
			continue
		var mark_id := String(event.get("desktopEffect", {}).get("persistentMark", ""))
		if not mark_id.is_empty():
			atmosphere.set_persistent_mark(mark_id)

func _on_report_completed(grade: String) -> void:
	if runtime and runtime.is_report_complete():
		_observe_tutorial("report_complete", String(current_case_data.get("caseId", "")))
	status_label.text = "本案评级 %s // 证据已封存" % grade
	_record_case_completion(grade)
	_save_now()
	var resolution: Dictionary = current_case_data.get("resolution", {})
	var fragment: Dictionary = resolution.get("darklineFragment", {})
	var dialog := AcceptDialog.new()
	dialog.title = "%s // 评级 %s" % [current_case_data.get("title", "结案"), grade]
	dialog.dialog_text = "%s\n\n%s\n\n暗线碎片：%s" % [resolution.get("surfaceTruth", "证据已封存。"), resolution.get("clientOutcome", ""), fragment.get("content", "")]
	add_child(dialog)
	dialog.confirmed.connect(_advance_after_case)
	dialog.canceled.connect(_advance_after_case)
	dialog.popup_centered(Vector2i(760, 460))

func _advance_after_case() -> void:
	if current_case_position + 1 < case_index.size():
		_load_case_at(current_case_position + 1)
	else:
		_show_coda()

func _show_coda() -> void:
	apps["report"].hide()
	var coda := AcceptDialog.new()
	coda.title = "档案同步完成"
	coda.dialog_text = "%s\n\n后续档案尚未解封。" % current_case_data.get("resolution", {}).get("darklineFragment", {}).get("content", "REN-0 仍在网络另一端。")
	add_child(coda)
	coda.popup_centered(Vector2i(720, 380))

func _set_theme(index: int) -> void:
	_apply_theme(["mono", "green", "amber"][index])
	if runtime:
		runtime.theme_id = _theme_id
	_save_now()

func _apply_theme(theme_id: String) -> void:
	_theme_id = theme_id
	var foreground := Color("#d7ddd8")
	if theme_id == "green":
		foreground = Color("#33ff66")
	elif theme_id == "amber":
		foreground = Color("#ffb000")
	var theme_resource := Theme.new()
	theme_resource.set_color("font_color", "Label", foreground)
	theme_resource.set_color("font_color", "Button", foreground)
	theme_resource.set_color("font_color", "LineEdit", foreground)
	theme_resource.set_color("font_color", "TextEdit", foreground)
	theme_resource.set_color("font_color", "RichTextLabel", foreground)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("#111412")
	panel.border_color = foreground.darkened(0.45)
	panel.set_border_width_all(1)
	theme_resource.set_stylebox("panel", "PanelContainer", panel)
	var button := StyleBoxFlat.new()
	button.bg_color = Color("#171b18")
	button.border_color = foreground.darkened(0.5)
	button.set_border_width_all(1)
	theme_resource.set_stylebox("normal", "Button", button)
	var body_font = load("res://assets/fonts/NotoSansSC-VF.ttf")
	if body_font:
		theme_resource.default_font = body_font
		theme_resource.default_font_size = 16
	theme = theme_resource

func _set_horror(index: int) -> void:
	var setting: String = ["full", "reduced", "off"][index]
	horror_director.set_intensity(setting)
	atmosphere.intensity = setting
	if runtime:
		runtime.horror_intensity = setting
	_save_now()

func _set_crt(enabled: bool) -> void:
	if crt_overlay:
		crt_overlay.visible = enabled
	if runtime:
		runtime.crt_enabled = enabled
	_save_now()

func _save_now() -> void:
	if runtime == null or current_case_data.is_empty():
		return
	save_service.save_game(_build_save_payload())

func _record_case_completion(grade: String) -> void:
	if runtime == null or current_case_data.is_empty():
		return
	var case_id := String(current_case_data.get("caseId", ""))
	if case_id.is_empty():
		return
	campaign_progress[case_id] = {
		"grade": grade,
		"evidence": runtime.collected_evidence.duplicate(),
		"intrusionMarks": runtime.intrusion_marks,
		"reportFirstAnswers": runtime.report_first_answers.duplicate(true),
		"completedAt": Time.get_datetime_string_from_system(true)
	}

func _build_save_payload() -> Dictionary:
	var payload: Dictionary = runtime.to_save_data() if runtime else {}
	payload["schemaVersion"] = 2
	payload["tutorialState"] = tutorial_runtime.to_save_data() if tutorial_runtime != null else {}
	payload["completedCases"] = campaign_progress.duplicate(true)
	return payload

func _build_tutorial_facts() -> Array:
	var facts: Array = []
	if runtime == null:
		return facts
	for gate_id in runtime.resolved_gates.keys():
		facts.append({"type": "gate_resolved", "target": String(gate_id)})
	for addr in runtime.authenticated_nodes.keys():
		facts.append({"type": "node_authenticated", "target": String(addr)})
	for read_key_value in runtime.read_files:
		var read_key := String(read_key_value)
		var separator := read_key.find(":")
		var addr := read_key.left(separator) if separator >= 0 else ""
		var path := read_key.substr(separator + 1) if separator >= 0 else read_key
		facts.append({"type": "file_opened", "target": path, "metadata": {"addr": addr}})
	for evidence_id in runtime.collected_evidence:
		facts.append({"type": "evidence_collected", "target": String(evidence_id)})
	for question_id in runtime.report_current_answers.keys():
		facts.append({"type": "report_answered", "target": String(question_id), "metadata": {"option": runtime.report_current_answers[question_id]}})
	if runtime.is_report_complete():
		facts.append({"type": "report_complete", "target": String(current_case_data.get("caseId", ""))})
	return facts

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_now()
		get_tree().quit()
