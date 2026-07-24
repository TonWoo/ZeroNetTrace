extends RefCounted

func run(t) -> void:
	var repository_script = load("res://scripts/engine/data_repository.gd")
	var runtime_script = load("res://scripts/engine/case_runtime.gd")
	t.truthy(repository_script != null and runtime_script != null, "content unlock dependencies load")
	if repository_script == null or runtime_script == null:
		return
	var repository = repository_script.new()
	var case01: Dictionary = repository.load_json("res://data/cases/case_01_gate.json")
	var case02: Dictionary = repository.load_json("res://data/cases/case_02_dead_streamer.json")
	var runtime = runtime_script.new()
	t.truthy(runtime.has_method("filter_unlocked_entries"), "runtime exposes data-driven content filtering")
	if not runtime.has_method("filter_unlocked_entries"):
		runtime.free()
		repository.free()
		return

	runtime.setup(case01)
	var initial_case01_mails: Array = runtime.filter_unlocked_entries(case01.get("mails", []))
	t.equal(initial_case01_mails.size(), 2, "case 01 hides its police resolution mail at case start")
	t.truthy(not _mail_subjects(initial_case01_mails).contains("确认安全"), "case 01 opening mailbox does not spoil the outcome")

	runtime.setup(case02)
	var initial_case02_mails: Array = runtime.filter_unlocked_entries(case02.get("mails", []))
	var initial_case02_messages: Array = runtime.filter_unlocked_entries(case02.get("conversations", [])[0].get("messages", []))
	t.equal(initial_case02_mails.size(), 1, "case 02 starts with only the client request mail")
	t.equal(initial_case02_messages.size(), 10, "case 02 starts with only the opening conversation beat")
	var initial_text := _message_text(initial_case02_messages)
	for spoiler in ["0713", "CM-041", "棚B", "第 39", "第一题"]:
		t.truthy(not initial_text.contains(spoiler), "case 02 opening conversation hides spoiler: %s" % spoiler)
	var refresh := {"count": 0}
	runtime.state_changed.connect(func(): refresh["count"] = int(refresh["count"]) + 1)
	runtime.mark_site_read("site_raven_live")
	t.equal(refresh["count"], 1, "visiting a site notifies content apps to reveal the next conversation beat")
	t.equal(runtime.filter_unlocked_entries(case02.get("conversations", [])[0].get("messages", [])).size(), 20, "raven page visit reveals observations without revealing the password date")
	refresh["count"] = 0
	runtime.trigger_context("viewer_frame", "raven_47s:39")
	t.equal(refresh["count"], 1, "triggering a horror beat notifies content apps to reveal its conversation follow-up")
	t.equal(runtime.filter_unlocked_entries(case02.get("conversations", [])[0].get("messages", [])).size(), 28, "frame 39 immediately unlocks its eight follow-up messages")
	runtime.free()
	repository.free()

func _mail_subjects(mails: Array) -> String:
	var subjects: Array[String] = []
	for mail_value in mails:
		subjects.append(String(mail_value.get("subject", "")))
	return "\n".join(subjects)

func _message_text(messages: Array) -> String:
	var lines: Array[String] = []
	for message_value in messages:
		lines.append(String(message_value.get("text", "")))
	return "\n".join(lines)
