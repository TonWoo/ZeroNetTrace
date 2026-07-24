extends RefCounted

const TutorialRuntimeScript = preload("res://scripts/engine/tutorial_runtime.gd")

func run(t) -> void:
	var router_script = load("res://scripts/engine/terminal_command_router.gd")
	var runtime_script = load("res://scripts/engine/case_runtime.gd")
	t.truthy(router_script != null and runtime_script != null, "terminal execution dependencies load")
	if router_script == null or runtime_script == null:
		return
	var case_data = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/minimal_case.json"))
	var runtime = runtime_script.new()
	runtime.setup(case_data)
	var router = router_script.new(runtime)
	var tutorial_case := {
		"caseId": "terminal_tutorial",
		"tutorialFlow": {"enabled": true, "steps": [{"id": "read_mail", "completeWhen": {"type": "mail_opened", "target": "mail_primary"}, "delivery": [], "feedback": {}, "helpText": "先核对死者留下的原始邮件。"}]}
	}
	var tutorial = TutorialRuntimeScript.new()
	tutorial.configure(tutorial_case)
	t.equal(_method_argument_count(router, "configure"), 2, "terminal router accepts a tutorial runtime alongside the case runtime")
	if _method_argument_count(router, "configure") == 2:
		router.configure(runtime, tutorial)
	t.contains_text(router.execute("help tutorial").get("text", ""), "原始邮件", "help tutorial returns contextual diegetic guidance")
	t.truthy(router.execute("tutorial skip").get("ok"), "tutorial skip is accepted")
	t.truthy(tutorial.is_skipped(), "tutorial skip updates runtime state")
	t.truthy(router.execute("tutorial restart").get("ok"), "tutorial restart is accepted")
	t.truthy(not tutorial.is_skipped(), "tutorial restart resumes the tutorial")
	t.equal(router.execute("tutorial erase").get("code"), "tutorial_usage", "unknown tutorial actions show safe usage")
	var help_result: Dictionary = router.execute("help")
	t.truthy(help_result.get("ok"), "help is an executable terminal command")
	t.contains_text(help_result.get("text", ""), "网络侦察", "help groups reconnaissance commands")
	t.contains_text(help_result.get("text", ""), "文件系统", "help groups filesystem commands")
	t.contains_text(help_result.get("text", ""), "help <命令>", "help advertises contextual syntax")
	var probe_help: Dictionary = router.execute("help probe")
	t.contains_text(probe_help.get("text", ""), "probe <节点>", "help probe shows syntax")
	t.contains_text(probe_help.get("text", ""), "NODE", "command examples use generic placeholders")
	var typo: Dictionary = router.execute("hlep")
	t.contains_text(typo.get("text", ""), "help", "nearby unknown commands suggest the intended command")
	var missing_probe: Dictionary = router.execute("probe")
	t.equal(missing_probe.get("code"), "missing_argument", "missing required arguments fail before runtime dispatch")
	t.contains_text(missing_probe.get("text", ""), "probe <节点>", "missing argument output includes syntax")
	t.contains_text(router.execute("scan").get("text", ""), "local.test", "scan prints visible nodes")
	t.equal(router.execute("crack locked.test").get("code"), "unknown_node", "hidden nodes stay unreachable")
	runtime.submit_search("长明")
	t.equal(router.execute("crack locked.test").get("code"), "probe_required", "terminal crack relays probe requirement")
	t.truthy(router.execute("probe locked.test").get("ok"), "terminal probe works")
	t.truthy(router.execute("crack locked.test").get("ok"), "terminal crack starts")
	runtime.tick(3.0, true)
	t.truthy(router.execute("cd locked.test:/").get("ok"), "cd can attach to authenticated node")
	t.contains_text(router.execute("ls /").get("text", ""), "secret.txt", "ls shows remote files")
	t.equal(router.execute("cat /secret.txt").get("content"), "隐藏文本。", "cat returns file content")
	t.equal(router.execute("open /secret.txt").get("action"), "open_viewer", "open requests viewer")
	t.truthy(router.execute("get /secret.txt").get("ok"), "get collects evidence")
	t.truthy(router.execute("note 镜子位置反了").get("ok"), "note stores text")
	t.contains_text(runtime.notes, "镜子位置反了", "note reaches notebook state")
	t.equal(router.execute("wat").get("code"), "unknown_command", "unknown command is explicit")
	t.truthy(router.execute("disconnect").get("ok"), "disconnect succeeds")
	runtime.free()

func _method_argument_count(object: Object, method_name: String) -> int:
	for method_info in object.get_method_list():
		if String(method_info.get("name", "")) == method_name:
			return method_info.get("args", []).size()
	return -1
