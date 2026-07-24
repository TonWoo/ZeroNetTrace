extends "res://scripts/apps/app_window.gd"

signal open_requested(file_entry: Dictionary)
signal command_executed(raw_text: String, result: Dictionary)

var runtime
var router
var output: RichTextLabel
var input: LineEdit
var trace_bar: ProgressBar
var trace_label: Label
var crack_bar: ProgressBar
var crack_label: Label
var _history_index := 0
var _known_auth: Dictionary = {}

func _build_body(parent: MarginContainer) -> void:
	app_id = "terminal"
	app_title = "终端 // ZERO-SHELL"
	title_label.text = " %s" % app_title
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	parent.add_child(column)
	var trace_row := HBoxContainer.new()
	column.add_child(trace_row)
	trace_label = Label.new()
	trace_label.text = "TRACE IDLE"
	trace_label.custom_minimum_size.x = 120
	trace_row.add_child(trace_label)
	trace_bar = ProgressBar.new()
	trace_bar.max_value = 100.0
	trace_bar.show_percentage = false
	trace_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trace_row.add_child(trace_bar)
	var crack_row := HBoxContainer.new()
	column.add_child(crack_row)
	crack_label = Label.new()
	crack_label.text = "CRACK IDLE"
	crack_label.custom_minimum_size.x = 120
	crack_row.add_child(crack_label)
	crack_bar = ProgressBar.new()
	crack_bar.max_value = 100.0
	crack_bar.show_percentage = false
	crack_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	crack_row.add_child(crack_bar)
	output = RichTextLabel.new()
	output.bbcode_enabled = true
	output.scroll_following = true
	output.selection_enabled = true
	output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	output.add_theme_color_override("default_color", Color("#d6ddd8"))
	output.add_theme_font_size_override("normal_font_size", 16)
	var terminal_font = load("res://assets/fonts/SarasaMonoSC-Regular.ttf")
	if terminal_font:
		output.add_theme_font_override("normal_font", terminal_font)
	column.add_child(output)
	input = LineEdit.new()
	input.placeholder_text = "输入命令；↑↓ 历史，Tab 补全"
	if terminal_font:
		input.add_theme_font_override("font", terminal_font)
	input.text_submitted.connect(_on_command)
	input.gui_input.connect(_on_input_event)
	column.add_child(input)
	_print_line("[color=#777f7a]ZERO-SHELL 0.9 // 输入 scan 开始。[/color]")
	_print_line("[color=#777f7a]scan | probe <地址> | crack <地址> | login <地址> -u <用户> -p <密码>[/color]")
	_print_line("[color=#777f7a]ls | cd | cat | open | get | trace | note | disconnect[/color]")

func configure(runtime_ref) -> void:
	runtime = runtime_ref
	var router_script = load("res://scripts/engine/terminal_command_router.gd")
	router = router_script.new(runtime)

func _process(delta: float) -> void:
	if runtime == null:
		return
	var focused := input != null and input.has_focus()
	runtime.tick(delta, focused)
	trace_bar.value = runtime.get_trace_progress() * 100.0
	trace_label.text = "TRACE %03d%%" % int(trace_bar.value)
	trace_label.modulate = Color("#ff2b2b") if trace_bar.value >= 60.0 else Color("#d6ddd8")
	var crack_status: Dictionary = runtime.get_crack_status()
	if crack_status.is_empty():
		crack_bar.value = 0.0
		crack_label.text = "CRACK IDLE"
	else:
		crack_bar.value = float(crack_status.get("progress", 0.0)) * 100.0
		crack_label.text = "%s %03d%%" % [crack_status.get("layer", "LOCK"), int(crack_bar.value)]
	for signal_data in runtime.consume_counter_signals():
		_print_line("[color=#ffb000]COUNTER-PING: %s // 输入 trace %s 可压低追踪[/color]" % [signal_data.get("target", "UNKNOWN"), signal_data.get("target", "UNKNOWN")])
	if router:
		for addr in runtime.authenticated_nodes.keys():
			if not _known_auth.has(addr):
				_known_auth[addr] = true
				router.current_node = String(addr)
				router.current_path = "/"
				_print_line("[color=#33ff66]ACCESS GRANTED: %s[/color]" % addr)

func _on_command(command_text: String) -> void:
	if router == null:
		return
	var command := command_text.strip_edges()
	if command.is_empty():
		return
	_print_line("[color=#8b938e]陈默@zero:~$[/color] %s" % command)
	var result: Dictionary = router.execute(command)
	var color := "#33ff66" if bool(result.get("ok", false)) else "#ff6b6b"
	_print_line("[color=%s]%s[/color]" % [color, String(result.get("text", result.get("content", "")))])
	if result.has("content") and not String(result.get("content", "")).is_empty() and String(result.get("text", "")) != String(result.get("content", "")):
		_print_line(String(result.get("content", "")))
	if String(result.get("action", "")) == "open_viewer":
		open_requested.emit(result)
	input.clear()
	_history_index = router.command_history.size()
	command_executed.emit(command, result)

func _on_input_event(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or router == null:
		return
	if event.keycode == KEY_UP and not router.command_history.is_empty():
		_history_index = maxi(0, _history_index - 1)
		input.text = router.command_history[_history_index]
		input.caret_column = input.text.length()
	elif event.keycode == KEY_DOWN and not router.command_history.is_empty():
		_history_index = mini(router.command_history.size(), _history_index + 1)
		input.text = "" if _history_index == router.command_history.size() else router.command_history[_history_index]
		input.caret_column = input.text.length()
	elif event.keycode == KEY_TAB:
		var completions: Array[String] = router.autocomplete(input.text.get_slice(" ", 0))
		if completions.size() == 1:
			input.text = completions[0] + " "
			input.caret_column = input.text.length()
		input.accept_event()

func _print_line(text: String) -> void:
	output.append_text(text + "\n")

func inject_system_line(text: String) -> void:
	_print_line("[color=#ff2b2b]SYSTEM> %s[/color]" % text)
