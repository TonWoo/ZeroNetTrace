extends RefCounted

const RuntimeScript = preload("res://scripts/engine/case_runtime.gd")
const RepositoryScript = preload("res://scripts/engine/data_repository.gd")

func run(t) -> void:
	var repository = RepositoryScript.new()
	var index: Array = repository.load_index()
	t.equal(index.size(), 3, "campaign integration covers the three stage-1 cases")
	var solved_titles: Array[String] = []
	for entry_value in index:
		var case_data: Dictionary = repository.load_case(String(entry_value.get("id", "")))
		var runtime = RuntimeScript.new()
		runtime.setup(case_data)
		_solve_gates(runtime, case_data)
		_authenticate_and_collect(runtime, case_data)
		t.truthy(runtime.can_open_report(), "all report evidence is reachable in %s" % case_data.get("title", "?"))
		for question_value in case_data.get("caseReport", []):
			var question: Dictionary = question_value
			runtime.submit_report_answer(String(question.get("id", "")), int(question.get("answer", -1)))
		t.equal(runtime.get_report_grade(), "S", "correct first answers produce S in %s" % case_data.get("title", "?"))
		solved_titles.append(String(case_data.get("title", "")))
		runtime.free()
	t.equal(solved_titles, ["序章：一封死人的邮件", "01：凌晨两点的门禁", "02：死者在线"], "new campaign runs in required order")
	repository.free()

func _solve_gates(runtime, case_data: Dictionary) -> void:
	for gate_value in case_data.get("knowledgeGates", []):
		var gate: Dictionary = gate_value
		if String(gate.get("channel", "search")) == "search":
			for accepted_value in gate.get("accept", []):
				if accepted_value is String:
					runtime.submit_search(String(accepted_value))
					break
	for node_value in case_data.get("network", []):
		var node: Dictionary = node_value
		if String(node.get("defense", {}).get("mode", "public")) != "credential":
			continue
		var gate_id := String(node.get("defense", {}).get("credentialGateId", ""))
		for gate_value in case_data.get("knowledgeGates", []):
			var gate: Dictionary = gate_value
			if String(gate.get("id", "")) != gate_id:
				continue
			for accepted_value in gate.get("accept", []):
				if accepted_value is Dictionary:
					runtime.login(String(node.get("addr", "")), String(accepted_value.get("user", "")), String(accepted_value.get("pass", "")))
					break

func _authenticate_and_collect(runtime, case_data: Dictionary) -> void:
	for node_value in case_data.get("network", []):
		var node: Dictionary = node_value
		var addr := String(node.get("addr", ""))
		if not runtime.get_visible_addresses().has(addr):
			continue
		if not runtime.is_node_authenticated(addr):
			runtime.probe(addr)
			var crack_result: Dictionary = runtime.start_crack(addr)
			if bool(crack_result.get("ok", false)):
				for _step in 400:
					runtime.tick(0.1, false)
					for signal_value in runtime.consume_counter_signals():
						runtime.trace_target(String(signal_value.get("target", "")))
					if runtime.is_node_authenticated(addr):
						break
		if runtime.is_node_authenticated(addr):
			for file_value in node.get("files", []):
				if bool(file_value.get("isEvidence", false)):
					runtime.collect_evidence(addr, String(file_value.get("path", "")))
