extends RefCounted

const SCENES := [
	"res://scenes/os/main.tscn",
	"res://scenes/apps/terminal_app.tscn",
	"res://scenes/apps/browser_app.tscn",
	"res://scenes/apps/mail_app.tscn",
	"res://scenes/apps/messenger_app.tscn",
	"res://scenes/apps/viewer_app.tscn",
	"res://scenes/apps/notebook_app.tscn",
	"res://scenes/apps/case_report_app.tscn",
	"res://scenes/sites/search_site.tscn",
	"res://scenes/sites/campus_portal.tscn",
	"res://scenes/sites/old_forum.tscn",
	"res://scenes/sites/raven_live.tscn",
	"res://scenes/sites/changming_site.tscn",
	"res://scenes/sites/workorder_site.tscn"
]

func run(t) -> void:
	for path in SCENES:
		var packed = load(path)
		t.truthy(packed != null, "scene loads: %s" % path)
		if packed != null:
			var instance = packed.instantiate()
			t.truthy(instance is Control, "scene root is Control: %s" % path)
			t.truthy(instance.get_script() != null, "scene script is valid: %s" % path)
			instance.free()
	var tree := Engine.get_main_loop() as SceneTree
	var runtime_script = load("res://scripts/engine/case_runtime.gd")
	var case_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/minimal_case.json"))
	var runtime = runtime_script.new()
	runtime.setup(case_data)
	var terminal = load("res://scenes/apps/terminal_app.tscn").instantiate()
	tree.root.add_child(terminal)
	terminal._ready()
	terminal.configure(runtime)
	var terminal_events: Array = []
	t.equal(_signal_argument_count(terminal, "command_executed"), 2, "terminal command facts include raw text and result")
	if _signal_argument_count(terminal, "command_executed") == 2:
		terminal.command_executed.connect(func(raw_text, result): terminal_events.append([raw_text, result]))
	terminal._on_command("scan")
	t.equal(terminal_events.size(), 1, "terminal emits one fact after rendering a command")
	if not terminal_events.is_empty():
		t.equal(terminal_events[0][0], "scan", "terminal fact preserves the raw player command")
		t.equal(terminal_events[0][1].get("code"), "scan_ok", "terminal fact preserves the command result")
	terminal.free()
	var mail = load("res://scenes/apps/mail_app.tscn").instantiate()
	tree.root.add_child(mail)
	mail._ready()
	mail.set_mails([{"id": "mail_test", "subject": "测试邮件", "from": "测试人", "time": "03:17", "body": "原始正文", "signature": "签名", "attachments": []}], runtime)
	t.truthy(mail.list.get_selected_items().is_empty(), "mail refresh does not count automatic selection as player progress")
	t.contains_text(mail.detail.text, "选择邮件", "mail shows a neutral prompt before the player reads anything")
	var mail_events: Array[String] = []
	t.equal(_signal_argument_count(mail, "mail_opened"), 1, "mail exposes a stable player-open fact")
	t.truthy(mail.has_method("_on_mail_selected"), "mail separates user selection from programmatic rendering")
	if _signal_argument_count(mail, "mail_opened") == 1:
		mail.mail_opened.connect(func(mail_id): mail_events.append(mail_id))
	if mail.has_method("_on_mail_selected"):
		mail._on_mail_selected(0)
	t.equal(mail_events, ["mail_test"], "manual mail selection emits its stable ID once")
	mail.free()
	var report = load("res://scenes/apps/case_report_app.tscn").instantiate()
	tree.root.add_child(report)
	report._ready()
	report.configure(runtime, case_data.get("caseReport", []))
	t.equal(_signal_argument_count(report, "answer_submitted"), 2, "report answer facts include question ID and result")
	var answer_events: Array = []
	if _signal_argument_count(report, "answer_submitted") == 2:
		report.answer_submitted.connect(func(question_id, result): answer_events.append([question_id, result]))
	var options := OptionButton.new()
	for option_value in case_data.get("caseReport", [])[0].get("options", []):
		options.add_item(String(option_value))
	options.select(1)
	var feedback := Label.new()
	report._submit_question(case_data.get("caseReport", [])[0], options, feedback)
	t.equal(answer_events.size(), 1, "a valid report submission emits one normalized app fact")
	if not answer_events.is_empty():
		t.equal(answer_events[0][0], "q1", "report fact identifies the submitted question")
		t.equal(answer_events[0][1].get("code"), "correct", "report fact includes the runtime result")
	options.free()
	feedback.free()
	report.free()
	runtime.free()

func _signal_argument_count(object: Object, signal_name: String) -> int:
	for signal_info in object.get_signal_list():
		if String(signal_info.get("name", "")) == signal_name:
			return signal_info.get("args", []).size()
	return -1
