extends RefCounted

const RuntimeScript = preload("res://scripts/engine/case_runtime.gd")
const TutorialRuntimeScript = preload("res://scripts/engine/tutorial_runtime.gd")
const RouterScript = preload("res://scripts/engine/terminal_command_router.gd")

func run(t) -> void:
	var prologue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cases/prologue.json"))
	var runtime = RuntimeScript.new()
	runtime.setup(prologue)
	var tutorial = TutorialRuntimeScript.new()
	tutorial.configure(prologue)
	var router = RouterScript.new(runtime, tutorial)
	var advanced_ids: Array[String] = []
	var delivered_ids: Array[String] = []
	tutorial.step_advanced.connect(func(step, deliveries):
		advanced_ids.append(String(step.get("id", "")))
		for delivery in deliveries:
			delivered_ids.append(String(delivery.get("contentId", "")))
	)
	runtime.gate_resolved.connect(func(gate_id): tutorial.observe("gate_resolved", gate_id))
	runtime.node_authenticated.connect(func(addr): tutorial.observe("node_authenticated", addr))
	runtime.counter_trace_reduced.connect(func(target): tutorial.observe("counter_trace_reduced", target))
	runtime.file_opened.connect(func(addr, path): tutorial.observe("file_opened", path, {"addr": addr}))
	runtime.evidence_collected.connect(func(evidence_id): tutorial.observe("evidence_collected", evidence_id))
	runtime.report_answered.connect(func(question_id, _option, correct): tutorial.observe("report_answered", question_id, {"correct": correct}))
	t.equal(tutorial.get_current_step_id(), "read_dead_mail", "real prologue starts with the unopened dead-letter mail")
	tutorial.observe("mail_opened", "mail_deadletter_primary")
	t.equal(tutorial.get_current_step_id(), "open_attachment", "mail reading advances to attachment investigation")
	tutorial.observe("attachment_opened", "attachment_deadletter_link")
	t.equal(tutorial.get_current_step_id(), "resolve_mirror_search", "attachment reading advances to free search")
	runtime.submit_search("零时邮局 mirror17")
	t.equal(tutorial.get_current_step_id(), "scan_network", "a valid free search advances to network discovery")
	var scan_result := _execute_and_observe(router, tutorial, "scan")
	t.truthy(scan_result.get("ok"), "real prologue scan succeeds")
	t.equal(tutorial.get_current_step_id(), "probe_mirror", "scan advances to defense inspection")
	var probe_result := _execute_and_observe(router, tutorial, "probe mirror17.deadletter.zero")
	t.truthy(probe_result.get("ok"), "real prologue probe succeeds")
	t.equal(tutorial.get_current_step_id(), "evade_counter_trace", "probe advances to the crack and trace lesson")
	var crack_result := _execute_and_observe(router, tutorial, "crack mirror17.deadletter.zero")
	t.equal(crack_result.get("code"), "crack_started", "real prologue starts the short fictional crack")
	runtime.tick(5.0, true)
	var counter_signals := runtime.consume_counter_signals()
	t.truthy(counter_signals.any(func(signal_data): return String(signal_data.get("target", "")) == "relay.deadletter-17"), "real prologue exposes the intended counter relay")
	var trace_result := _execute_and_observe(router, tutorial, "trace relay.deadletter-17")
	t.equal(trace_result.get("code"), "trace_reduced", "using the visible relay lowers counter-trace pressure")
	t.equal(tutorial.get_current_step_id(), "enter_filesystem", "successful counter tracing advances to filesystem access")
	runtime.tick(3.0, true)
	t.truthy(runtime.is_node_authenticated("mirror17.deadletter.zero"), "the short crack authenticates the mirror")
	t.equal(tutorial.get_current_step_id(), "collect_linwei_log", "authentication advances to original-file collection")
	t.truthy(_execute_and_observe(router, tutorial, "cd mirror17.deadletter.zero:/").get("ok"), "router attaches to the authenticated mirror")
	t.truthy(_execute_and_observe(router, tutorial, "ls /").get("ok"), "player lists the mirror filesystem")
	t.truthy(_execute_and_observe(router, tutorial, "cat /archive/LW_最后一次校对.zlog").get("ok"), "player reads Lin Wei's original log")
	t.truthy(_execute_and_observe(router, tutorial, "get /archive/LW_最后一次校对.zlog").get("ok"), "player preserves Lin Wei's original log")
	t.equal(tutorial.get_current_step_id(), "complete_report", "the three evidence facts advance to the report lesson")
	t.truthy(_execute_and_observe(router, tutorial, "get /meta/delivery.log").get("ok"), "player preserves the delivery log cited by the report")
	t.truthy(runtime.can_open_report(), "tutorial evidence path unlocks the real report")
	for question_value in prologue.get("caseReport", []):
		var question: Dictionary = question_value
		runtime.submit_report_answer(String(question.get("id", "")), int(question.get("answer", -1)))
	t.truthy(runtime.is_report_complete(), "all real prologue answers complete the report")
	tutorial.observe("report_complete", "prologue_dead_mail")
	t.truthy(tutorial.is_complete(), "real prologue completes the immersive tutorial")
	t.equal(advanced_ids, ["read_dead_mail", "open_attachment", "resolve_mirror_search", "scan_network", "probe_mirror", "evade_counter_trace", "enter_filesystem", "collect_linwei_log", "complete_report"], "real prologue advances exactly nine ordered tutorial steps")
	var unique_deliveries := {}
	for content_id in delivered_ids:
		unique_deliveries[content_id] = true
	t.equal(unique_deliveries.size(), delivered_ids.size(), "every progression tutorial message is delivered at most once")
	_assert_no_answer_leak(t, prologue)
	for forbidden_key in ["objectivePanel", "taskList", "currentObjective", "stepNumber"]:
		t.truthy(not _contains_key_recursive(prologue, forbidden_key), "prologue data has no fixed tutorial UI field: %s" % forbidden_key)
	runtime.free()
	var case01: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cases/case_01_gate.json"))
	var runtime01 = RuntimeScript.new()
	runtime01.setup(case01)
	var tutorial01 = TutorialRuntimeScript.new()
	tutorial01.configure(case01)
	var router01 = RouterScript.new(runtime01, tutorial01)
	t.truthy(tutorial01.is_complete() and tutorial01.get_current_step_id().is_empty(), "case 01 has no step-by-step tutorial flow")
	t.truthy(router01.execute("help").get("ok"), "global terminal help remains available after the prologue")
	t.contains_text(router01.execute("help tutorial").get("text", ""), "当前案件", "contextual help reports that later cases have no tutorial flow")
	runtime01.free()

func _execute_and_observe(router, tutorial, raw_text: String) -> Dictionary:
	var result: Dictionary = router.execute(raw_text)
	if not bool(result.get("ok", false)):
		return result
	var parsed: Dictionary = router.parse(raw_text)
	var command := String(parsed.get("command", ""))
	var metadata := {"resultCode": String(result.get("code", ""))}
	var args: Array = parsed.get("args", [])
	if not args.is_empty() and command in ["probe", "crack", "login"]:
		metadata["addr"] = String(args[0])
	tutorial.observe("command_succeeded", command, metadata)
	return result

func _assert_no_answer_leak(t, case_data: Dictionary) -> void:
	var accepted: Array[String] = []
	for gate_value in case_data.get("knowledgeGates", []):
		for accepted_value in gate_value.get("accept", []):
			if accepted_value is String:
				accepted.append(_normalize(accepted_value))
		for alias_value in gate_value.get("aliases", []):
			accepted.append(_normalize(String(alias_value)))
	for message_value in case_data.get("tutorialMessages", []):
		var text := _normalize(String(message_value.get("text", "")))
		for answer in accepted:
			t.truthy(not text.contains(answer), "real tutorial messages do not reveal a complete accepted search phrase")

func _contains_key_recursive(value: Variant, target_key: String) -> bool:
	if value is Dictionary:
		if value.has(target_key):
			return true
		for child in value.values():
			if _contains_key_recursive(child, target_key):
				return true
	elif value is Array:
		for child in value:
			if _contains_key_recursive(child, target_key):
				return true
	return false

func _normalize(value: String) -> String:
	return value.to_lower().replace(" ", "").replace("-", "").replace("_", "").replace("\t", "").replace("\n", "")

