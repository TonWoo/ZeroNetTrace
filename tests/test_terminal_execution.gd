extends RefCounted

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

