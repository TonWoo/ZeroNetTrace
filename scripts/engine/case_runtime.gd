extends Node

signal state_changed
signal evidence_collected(evidence_id: String)
signal horror_triggered(event: Dictionary)
signal node_unlocked(addr: String)
signal hint_pushed(hint: Dictionary)
signal file_opened(addr: String, path: String)
signal site_visited(site_id: String)
signal report_answered(question_id: String, option: int, correct: bool)
signal screenshot_pinned(snapshot: Dictionary)
signal gate_resolved(gate_id: String)
signal node_authenticated(addr: String)
signal counter_trace_reduced(target: String)

const SearchServiceScript = preload("res://scripts/engine/search_service.gd")

var case_data: Dictionary = {}
var nodes: Dictionary = {}
var visible_addresses: Array[String] = []
var probed_nodes: Dictionary = {}
var authenticated_nodes: Dictionary = {}
var crack_jobs: Dictionary = {}
var lockout_remaining: Dictionary = {}
var resolved_gates: Dictionary = {}
var collected_evidence: Array[String] = []
var consumed_horror: Dictionary = {}
var triggered_horror: Array[Dictionary] = []
var counter_signal_queue: Array[Dictionary] = []
var seen_counter_signals: Dictionary = {}
var hint_elapsed: Dictionary = {}
var hint_levels: Dictionary = {}
var hint_queue: Array[Dictionary] = []
var content_read_elapsed: Dictionary = {}
var trace_progress := 0.0
var active_trace_node := ""
var intrusion_marks := 0
var report_first_answers: Dictionary = {}
var report_current_answers: Dictionary = {}
var read_files: Array[String] = []
var visited_sites: Array[String] = []
var pinned_screenshots: Array[Dictionary] = []
var notes := ""
var horror_intensity := "full"
var theme_id := "mono"
var crt_enabled := true

var _search_service = SearchServiceScript.new()

func setup(new_case_data: Dictionary) -> void:
	case_data = new_case_data.duplicate(true)
	nodes.clear()
	visible_addresses.clear()
	probed_nodes.clear()
	authenticated_nodes.clear()
	crack_jobs.clear()
	lockout_remaining.clear()
	resolved_gates.clear()
	collected_evidence.clear()
	consumed_horror.clear()
	triggered_horror.clear()
	counter_signal_queue.clear()
	seen_counter_signals.clear()
	hint_elapsed.clear()
	hint_levels.clear()
	hint_queue.clear()
	content_read_elapsed.clear()
	trace_progress = 0.0
	active_trace_node = ""
	report_first_answers.clear()
	report_current_answers.clear()
	read_files.clear()
	visited_sites.clear()
	pinned_screenshots.clear()
	for node_value in case_data.get("network", []):
		var node: Dictionary = node_value
		var addr := String(node.get("addr", ""))
		nodes[addr] = node
		var discovery: Dictionary = node.get("discoverWhen", {"type": "start"})
		if String(discovery.get("type", "start")) == "start":
			_reveal_node(addr)
	for gate_value in case_data.get("knowledgeGates", []):
		var gate_id := String(gate_value.get("id", ""))
		hint_elapsed[gate_id] = 0.0
		hint_levels[gate_id] = 0

func get_visible_addresses() -> Array[String]:
	return visible_addresses.duplicate()

func probe(addr: String) -> Dictionary:
	if not visible_addresses.has(addr) or not nodes.has(addr):
		return _result(false, "unknown_node", "目标不在当前网络边界。")
	probed_nodes[addr] = true
	var defense: Dictionary = nodes[addr].get("defense", {})
	var layers: Array[String] = []
	for layer_value in defense.get("layers", []):
		layers.append("%s(%.1fs)" % [layer_value.get("id", "LOCK"), float(layer_value.get("durationSec", 1.0))])
	var trace: Dictionary = defense.get("trace", {})
	var text := "模式=%s\n锁层=%s\n反追踪=%s" % [defense.get("mode", "public"), " → ".join(layers) if not layers.is_empty() else "无", "启用/%.0fs" % float(trace.get("totalSeconds", 0.0)) if bool(trace.get("enabled", false)) else "关闭"]
	var result := _result(true, "probed", text)
	result["defense"] = defense
	return result

func start_crack(addr: String) -> Dictionary:
	if not visible_addresses.has(addr) or not nodes.has(addr):
		return _result(false, "unknown_node", "目标不在当前网络边界。")
	if not probed_nodes.has(addr):
		return _result(false, "probe_required", "先执行 probe 识别锁层。")
	if float(lockout_remaining.get(addr, 0.0)) > 0.0:
		return _result(false, "node_locked", "节点仍在冷却锁定中：%.1f 秒。" % float(lockout_remaining[addr]))
	var defense: Dictionary = nodes[addr].get("defense", {})
	var mode := String(defense.get("mode", "public"))
	if mode == "credential":
		return _result(false, "credential_required", "该节点只接受有效凭证。")
	if mode == "public":
		_authenticate_node(addr)
		return _result(true, "already_open", "目标无需破解。")
	var duration := 0.0
	for layer_value in defense.get("layers", []):
		duration += float(layer_value.get("durationSec", 1.0))
	crack_jobs[addr] = {"elapsed": 0.0, "duration": maxf(duration, 0.1), "signalIndex": 0}
	active_trace_node = addr
	trace_progress = 0.0
	return _result(true, "crack_started", "破解任务已启动。")

func tick(delta: float, terminal_focused: bool) -> void:
	for addr_value in lockout_remaining.keys():
		var addr := String(addr_value)
		lockout_remaining[addr] = maxf(0.0, float(lockout_remaining[addr]) - delta)
	var completed: Array[String] = []
	for addr_value in crack_jobs.keys():
		var addr := String(addr_value)
		var job: Dictionary = crack_jobs[addr]
		job["elapsed"] = float(job.get("elapsed", 0.0)) + delta
		crack_jobs[addr] = job
		if float(job["elapsed"]) >= float(job["duration"]):
			completed.append(addr)
	for addr in completed:
		crack_jobs.erase(addr)
		_authenticate_node(addr)
		if active_trace_node == addr:
			active_trace_node = addr
		state_changed.emit()
	if not active_trace_node.is_empty():
		_tick_trace(active_trace_node, delta, terminal_focused)
	advance_hint_time(delta)

func _tick_trace(addr: String, delta: float, terminal_focused: bool) -> void:
	var trace: Dictionary = nodes[addr].get("defense", {}).get("trace", {})
	if not bool(trace.get("enabled", false)):
		return
	var total_seconds := maxf(float(trace.get("totalSeconds", 60.0)), 0.1)
	var rate := 1.0 if terminal_focused else float(trace.get("unfocusedRate", 0.25))
	trace_progress = clampf(trace_progress + delta * rate / total_seconds, 0.0, 1.0)
	var signals: Array = trace.get("signals", [])
	for index in signals.size():
		var signal_data: Dictionary = signals[index]
		var signal_key := "%s:%d" % [addr, index]
		if not seen_counter_signals.has(signal_key) and trace_progress >= float(signal_data.get("at", 1.1)):
			seen_counter_signals[signal_key] = true
			counter_signal_queue.append(signal_data.duplicate(true))
	for event_value in case_data.get("horrorEvents", []):
		var event: Dictionary = event_value
		var trigger: Dictionary = event.get("trigger", {})
		if String(trigger.get("type", "")) == "trace_threshold" and String(trigger.get("target", "")) == addr and trace_progress >= float(trigger.get("threshold", 1.1)):
			_trigger_event(event)
	if trace_progress >= 1.0:
		force_disconnect(true)

func get_trace_progress() -> float:
	return trace_progress

func get_crack_status() -> Dictionary:
	if crack_jobs.is_empty():
		return {}
	var addr := String(crack_jobs.keys()[0])
	var job: Dictionary = crack_jobs[addr]
	var progress := clampf(float(job.get("elapsed", 0.0)) / maxf(float(job.get("duration", 1.0)), 0.1), 0.0, 1.0)
	var layers: Array = nodes[addr].get("defense", {}).get("layers", [])
	var layer_index := mini(layers.size() - 1, int(floor(progress * max(layers.size(), 1)))) if not layers.is_empty() else -1
	return {"addr": addr, "progress": progress, "layer": layers[layer_index].get("id", "LOCK") if layer_index >= 0 else "OPEN"}

func consume_counter_signals() -> Array[Dictionary]:
	var result := counter_signal_queue.duplicate(true)
	counter_signal_queue.clear()
	return result

func trace_target(target: String) -> Dictionary:
	if not active_trace_node.is_empty():
		return counter_trace(target)
	for node_value in case_data.get("network", []):
		var node: Dictionary = node_value
		if String(node.get("addr", "")).to_lower() == target.to_lower() or String(node.get("label", "")).contains(target):
			var chain: Array = node.get("traceChain", [])
			var result := _result(true, "trace_chain", "溯源链：" + (" → ".join(chain) if not chain.is_empty() else "没有可见跳板记录"))
			result["chain"] = chain
			return result
	return _result(false, "trace_missing", "没有找到该地址或账号的溯源记录。")

func counter_trace(target: String) -> Dictionary:
	if active_trace_node.is_empty() or not nodes.has(active_trace_node):
		return _result(false, "no_trace", "当前没有可反制的追踪链。")
	var signals: Array = nodes[active_trace_node].get("defense", {}).get("trace", {}).get("signals", [])
	for signal_value in signals:
		var signal_data: Dictionary = signal_value
		if String(signal_data.get("target", "")).to_lower() == target.to_lower():
			var before := trace_progress
			trace_progress = maxf(0.0, trace_progress - float(signal_data.get("reduction", 0.15)))
			if trace_progress < before:
				counter_trace_reduced.emit(String(signal_data.get("target", target)))
			return _result(true, "trace_reduced", "中继链已识别，反向追踪压力下降。")
	return _result(false, "trace_miss", "该地址不在当前回溯链。")

func force_disconnect(traced := false) -> Dictionary:
	var disconnected_node := active_trace_node
	crack_jobs.clear()
	active_trace_node = ""
	trace_progress = 0.0
	if traced:
		intrusion_marks += 1
		if not disconnected_node.is_empty() and nodes.has(disconnected_node):
			lockout_remaining[disconnected_node] = float(nodes[disconnected_node].get("defense", {}).get("trace", {}).get("lockoutSec", 20.0))
	return _result(true, "traced" if traced else "disconnected", "连接已断开。")

func login(addr: String, user: String, password: String) -> Dictionary:
	if not visible_addresses.has(addr) or not nodes.has(addr):
		return _result(false, "unknown_node", "目标不在当前网络边界。")
	var gate_id := String(nodes[addr].get("defense", {}).get("credentialGateId", ""))
	var gate := _find_gate(gate_id)
	for accepted_value in gate.get("accept", []):
		if accepted_value is Dictionary:
			var accepted: Dictionary = accepted_value
			if String(accepted.get("user", "")).to_lower() == user.to_lower() and String(accepted.get("pass", "")) == password:
				_authenticate_node(addr)
				_resolve_gate(gate_id)
				return _result(true, "login_ok", "凭证通过。")
	return _result(false, "login_failed", "用户名或密码不匹配。")

func is_node_authenticated(addr: String) -> bool:
	return bool(authenticated_nodes.get(addr, false))

func submit_search(text: String) -> Array:
	var matches := _search_service.matching_gates(text, case_data.get("knowledgeGates", []))
	for gate_value in matches:
		_resolve_gate(String(gate_value.get("id", "")))
	return matches

func advance_hint_time(delta: float) -> void:
	var thresholds := [360.0, 720.0, 1080.0]
	for gate_value in case_data.get("knowledgeGates", []):
		var gate: Dictionary = gate_value
		var gate_id := String(gate.get("id", ""))
		if resolved_gates.has(gate_id):
			continue
		hint_elapsed[gate_id] = float(hint_elapsed.get(gate_id, 0.0)) + delta
		var level := int(hint_levels.get(gate_id, 0))
		if level < 3 and float(hint_elapsed[gate_id]) >= float(thresholds[level]):
			var hints: Array = gate.get("hints", [])
			if level < hints.size():
				var hint := {"gateId": gate_id, "level": level + 1, "text": String(hints[level])}
				hint_queue.append(hint)
				hint_pushed.emit(hint)
			hint_levels[gate_id] = level + 1

func consume_hints() -> Array[Dictionary]:
	var result := hint_queue.duplicate(true)
	hint_queue.clear()
	return result

func advance_content_read(target: String, delta: float) -> void:
	content_read_elapsed[target] = float(content_read_elapsed.get(target, 0.0)) + delta
	for event_value in case_data.get("horrorEvents", []):
		var event: Dictionary = event_value
		var trigger: Dictionary = event.get("trigger", {})
		if String(trigger.get("type", "")) == "content_read_seconds" and String(trigger.get("target", "")) == target and float(content_read_elapsed[target]) >= float(trigger.get("threshold", INF)):
			_trigger_event(event)

func open_file(addr: String, path: String) -> Dictionary:
	var normalized := _normalize_path(path)
	var file_entry := _find_file(addr, normalized)
	if file_entry.is_empty():
		return _result(false, "file_missing", "文件不存在或当前无权读取。")
	var read_key := "%s:%s" % [addr, normalized]
	if not read_files.has(read_key):
		read_files.append(read_key)
	file_opened.emit(addr, normalized)
	var result := _result(true, "file_read", "文件已打开。")
	result.merge(file_entry, true)
	return result

func read_file(addr: String, path: String) -> Dictionary:
	return open_file(addr, path)

func mark_site_read(site_id: String) -> void:
	if site_id.is_empty():
		return
	if not visited_sites.has(site_id):
		visited_sites.append(site_id)
		site_visited.emit(site_id)
		state_changed.emit()

func pin_screenshot(label: String, image_path: String) -> void:
	var snapshot := {"label": label, "path": image_path}
	for existing in pinned_screenshots:
		if String(existing.get("path", "")) == image_path and not image_path.is_empty():
			return
	pinned_screenshots.append(snapshot)
	screenshot_pinned.emit(snapshot)
	state_changed.emit()

func directory_exists(addr: String, path: String) -> bool:
	if not nodes.has(addr) or not is_node_authenticated(addr):
		return false
	var normalized := _normalize_path(path)
	if normalized == "/":
		return true
	var prefix := normalized.trim_suffix("/") + "/"
	for file_value in nodes[addr].get("files", []):
		if _normalize_path(String(file_value.get("path", ""))).begins_with(prefix):
			return true
	return false

func list_directory(addr: String, path: String) -> Array[String]:
	var entries: Array[String] = []
	if not directory_exists(addr, path):
		return entries
	var normalized := _normalize_path(path)
	var prefix := "/" if normalized == "/" else normalized.trim_suffix("/") + "/"
	for file_value in nodes[addr].get("files", []):
		var file_path := _normalize_path(String(file_value.get("path", "")))
		if not file_path.begins_with(prefix):
			continue
		var remainder := file_path.substr(prefix.length())
		var name := remainder.get_slice("/", 0)
		if remainder.contains("/"):
			name += "/"
		if not entries.has(name):
			entries.append(name)
	entries.sort()
	return entries

func collect_evidence(addr: String, path: String) -> Dictionary:
	var file_entry := _find_file(addr, _normalize_path(path))
	if file_entry.is_empty() or not bool(file_entry.get("isEvidence", false)):
		return _result(false, "not_evidence", "该文件未标记为可取证物。")
	var evidence_id := String(file_entry.get("evidenceId", ""))
	if not collected_evidence.has(evidence_id):
		collected_evidence.append(evidence_id)
		evidence_collected.emit(evidence_id)
		_evaluate_horror("evidence_collected", evidence_id)
	state_changed.emit()
	return _result(true, "evidence_collected", "证据已复制到本地。")

func submit_report_answer(question_id: String, option: int) -> Dictionary:
	var question := _find_question(question_id)
	if question.is_empty():
		return _result(false, "question_missing", "结案题不存在。")
	if not report_first_answers.has(question_id):
		report_first_answers[question_id] = option
	report_current_answers[question_id] = option
	var correct := int(question.get("answer", -1)) == option
	report_answered.emit(question_id, option, correct)
	state_changed.emit()
	var result := _result(correct, "correct" if correct else "incorrect", "答案正确。" if correct else "证据不支持这个结论，请重选。")
	result["correct"] = correct
	return result

func can_open_report() -> bool:
	var required: Array[String] = []
	for question_value in case_data.get("caseReport", []):
		for evidence_value in question_value.get("evidence", []):
			var evidence_id := String(evidence_value)
			if not required.has(evidence_id):
				required.append(evidence_id)
	for evidence_id in required:
		if not collected_evidence.has(evidence_id):
			return false
	return not required.is_empty()

func is_report_complete() -> bool:
	var report: Array = case_data.get("caseReport", [])
	if report.is_empty():
		return false
	for question_value in report:
		var question: Dictionary = question_value
		var question_id := String(question.get("id", ""))
		if int(report_current_answers.get(question_id, -99)) != int(question.get("answer", -1)):
			return false
	return true

func filter_unlocked_entries(entries: Array) -> Array:
	var result: Array = []
	for entry_value in entries:
		if entry_value is Dictionary and is_content_unlocked(entry_value):
			result.append(entry_value)
	return result

func is_content_unlocked(entry: Dictionary) -> bool:
	return _unlock_condition_met(entry.get("unlockWhen", {"type": "start"}))

func _unlock_condition_met(condition_value: Variant) -> bool:
	if condition_value == null or (condition_value is String and String(condition_value) in ["", "start"]):
		return true
	if not condition_value is Dictionary:
		return false
	var condition: Dictionary = condition_value
	var condition_type := String(condition.get("type", "start"))
	var condition_id := String(condition.get("id", ""))
	match condition_type:
		"start":
			return true
		"site":
			return visited_sites.has(condition_id)
		"gate":
			return resolved_gates.has(condition_id)
		"evidence":
			return collected_evidence.has(condition_id)
		"horror":
			return consumed_horror.has(condition_id)
		"report_complete":
			return is_report_complete()
		"all":
			for child in condition.get("conditions", []):
				if not _unlock_condition_met(child):
					return false
			return true
		"any":
			for child in condition.get("conditions", []):
				if _unlock_condition_met(child):
					return true
			return false
	return false

func get_report_grade() -> String:
	var report: Array = case_data.get("caseReport", [])
	if report.is_empty():
		return "B"
	var correct := 0
	for question_value in report:
		var question: Dictionary = question_value
		var question_id := String(question.get("id", ""))
		if int(report_first_answers.get(question_id, -99)) == int(question.get("answer", -1)):
			correct += 1
	var accuracy := float(correct) / float(report.size())
	if is_equal_approx(accuracy, 1.0):
		return "S"
	if accuracy >= 0.8:
		return "A"
	return "B"

func consume_triggered_horror() -> Array[Dictionary]:
	var result := triggered_horror.duplicate(true)
	triggered_horror.clear()
	return result

func trigger_context(trigger_type: String, target: String) -> void:
	_evaluate_horror(trigger_type, target)

func to_save_data() -> Dictionary:
	return {
		"schemaVersion": 1,
		"currentCase": case_data.get("caseId", ""),
		"visibleNodes": visible_addresses,
		"probedNodes": probed_nodes.keys(),
		"authenticatedNodes": authenticated_nodes.keys(),
		"resolvedGates": resolved_gates.keys(),
		"evidence": collected_evidence,
		"consumedHorror": consumed_horror.keys(),
		"notes": notes,
		"horrorIntensity": horror_intensity,
		"theme": theme_id,
		"crtEnabled": crt_enabled,
		"intrusionMarks": intrusion_marks,
		"reportFirstAnswers": report_first_answers,
		"reportCurrentAnswers": report_current_answers,
		"reportGrade": get_report_grade(),
		"readFiles": read_files,
		"visitedSites": visited_sites,
		"contentReadElapsed": content_read_elapsed,
		"hintElapsed": hint_elapsed,
		"hintLevels": hint_levels,
		"screenshots": pinned_screenshots
	}

func apply_save_data(saved: Dictionary) -> void:
	for addr_value in saved.get("visibleNodes", []):
		_reveal_node(String(addr_value))
	for addr_value in saved.get("probedNodes", []):
		probed_nodes[String(addr_value)] = true
	for addr_value in saved.get("authenticatedNodes", []):
		authenticated_nodes[String(addr_value)] = true
	for gate_value in saved.get("resolvedGates", []):
		resolved_gates[String(gate_value)] = true
	collected_evidence.assign(saved.get("evidence", []))
	for event_value in saved.get("consumedHorror", []):
		consumed_horror[String(event_value)] = true
	notes = String(saved.get("notes", ""))
	horror_intensity = String(saved.get("horrorIntensity", "full"))
	theme_id = String(saved.get("theme", "mono"))
	crt_enabled = bool(saved.get("crtEnabled", true))
	intrusion_marks = int(saved.get("intrusionMarks", 0))
	report_first_answers = saved.get("reportFirstAnswers", {}).duplicate(true)
	report_current_answers = saved.get("reportCurrentAnswers", {}).duplicate(true)
	read_files.assign(saved.get("readFiles", []))
	visited_sites.assign(saved.get("visitedSites", []))
	content_read_elapsed = saved.get("contentReadElapsed", {}).duplicate(true)
	hint_elapsed = saved.get("hintElapsed", hint_elapsed).duplicate(true)
	hint_levels = saved.get("hintLevels", hint_levels).duplicate(true)
	pinned_screenshots.clear()
	for snapshot_value in saved.get("screenshots", []):
		if snapshot_value is Dictionary:
			pinned_screenshots.append(snapshot_value.duplicate(true))

func _evaluate_horror(trigger_type: String, target: String) -> void:
	for event_value in case_data.get("horrorEvents", []):
		var event: Dictionary = event_value
		var event_id := String(event.get("id", ""))
		if consumed_horror.has(event_id):
			continue
		var trigger: Dictionary = event.get("trigger", {})
		if String(trigger.get("type", "")) == trigger_type and String(trigger.get("target", "")) == target:
			_trigger_event(event)

func _trigger_event(event: Dictionary) -> void:
	var event_id := String(event.get("id", ""))
	if event_id.is_empty() or consumed_horror.has(event_id):
		return
	consumed_horror[event_id] = true
	triggered_horror.append(event)
	horror_triggered.emit(event)
	state_changed.emit()

func _resolve_gate(gate_id: String) -> void:
	if gate_id.is_empty() or resolved_gates.has(gate_id):
		return
	resolved_gates[gate_id] = true
	gate_resolved.emit(gate_id)
	hint_elapsed.erase(gate_id)
	hint_levels.erase(gate_id)
	for node_value in case_data.get("network", []):
		var node: Dictionary = node_value
		var discovery: Dictionary = node.get("discoverWhen", {})
		if String(discovery.get("type", "")) == "gate" and String(discovery.get("id", "")) == gate_id:
			_reveal_node(String(node.get("addr", "")))
	state_changed.emit()

func _reveal_node(addr: String) -> void:
	if not addr.is_empty() and not visible_addresses.has(addr):
		visible_addresses.append(addr)
		if nodes.has(addr) and String(nodes[addr].get("defense", {}).get("mode", "public")) == "public":
			_authenticate_node(addr)
		node_unlocked.emit(addr)

func _authenticate_node(addr: String) -> bool:
	if addr.is_empty() or authenticated_nodes.has(addr):
		return false
	authenticated_nodes[addr] = true
	node_authenticated.emit(addr)
	return true

func _find_gate(gate_id: String) -> Dictionary:
	for gate_value in case_data.get("knowledgeGates", []):
		if String(gate_value.get("id", "")) == gate_id:
			return gate_value
	return {}

func _find_question(question_id: String) -> Dictionary:
	for question_value in case_data.get("caseReport", []):
		if String(question_value.get("id", "")) == question_id:
			return question_value
	return {}

func _find_file(addr: String, path: String) -> Dictionary:
	if not nodes.has(addr) or not is_node_authenticated(addr):
		return {}
	for file_value in nodes[addr].get("files", []):
		if _normalize_path(String(file_value.get("path", ""))) == path:
			return file_value
	return {}

func _normalize_path(path: String) -> String:
	var parts: Array[String] = []
	for part in path.replace("\\", "/").split("/", false):
		if part == "." or part.is_empty():
			continue
		if part == "..":
			if not parts.is_empty():
				parts.pop_back()
		else:
			parts.append(part)
	return "/" + "/".join(parts)

func _result(ok: bool, code: String, text: String) -> Dictionary:
	return {"ok": ok, "code": code, "text": text}
