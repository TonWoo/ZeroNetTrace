class_name ContentValidator
extends RefCounted

const REQUIRED_FIELDS := ["caseId", "title", "coreQuestion", "unlockRequirements", "investigationLines", "twists", "network", "knowledgeGates", "horrorEvents", "caseReport", "contentManifest", "artAssets", "complianceCheck"]
const FORBIDDEN_PLACEHOLDERS := ["内容略", "示例×", "示例x", "todo", "待补", "此处是描述", "待完善"]
const TUTORIAL_TRIGGERS := ["mail_opened", "attachment_opened", "gate_resolved", "command_succeeded", "counter_trace_reduced", "node_authenticated", "file_opened", "evidence_collected", "report_answered", "report_complete"]
const TUTORIAL_APPS := ["terminal", "browser", "mail", "messenger", "viewer", "report"]
const TUTORIAL_CHANNELS := ["terminal", "messenger", "mail"]

func validate_case(case_data: Dictionary, strict_content := true) -> Array[String]:
	var issues: Array[String] = []
	for field in REQUIRED_FIELDS:
		if not case_data.has(field):
			issues.append("缺少字段: %s" % field)
	var nodes: Array = case_data.get("network", [])
	var node_ids := {}
	var evidence_ids := {}
	for node_value in nodes:
		var node: Dictionary = node_value
		var addr := String(node.get("addr", ""))
		if addr.is_empty() or node_ids.has(addr):
			issues.append("节点地址缺失或重复: %s" % addr)
		node_ids[addr] = true
		for file_value in node.get("files", []):
			var file_entry: Dictionary = file_value
			if bool(file_entry.get("isEvidence", false)):
				var evidence_id := String(file_entry.get("evidenceId", ""))
				if evidence_id.is_empty() or evidence_ids.has(evidence_id):
					issues.append("证据 ID 缺失或重复: %s" % evidence_id)
				evidence_ids[evidence_id] = true
	var gate_ids := {}
	for gate_value in case_data.get("knowledgeGates", []):
		var gate: Dictionary = gate_value
		var gate_id := String(gate.get("id", ""))
		if gate_id.is_empty() or gate_ids.has(gate_id):
			issues.append("知识门 ID 缺失或重复: %s" % gate_id)
		gate_ids[gate_id] = true
		if gate.get("hints", []).size() != 3:
			issues.append("知识门 %s 必须有三级提示" % gate_id)
	for node_value in nodes:
		var node: Dictionary = node_value
		var addr := String(node.get("addr", ""))
		var discovery: Dictionary = node.get("discoverWhen", {"type": "start"})
		var discovery_type := String(discovery.get("type", "start"))
		if discovery_type == "gate" and not gate_ids.has(String(discovery.get("id", ""))):
			issues.append("节点不可达，发现条件引用不存在的知识门: %s" % addr)
		elif discovery_type not in ["start", "gate"]:
			issues.append("节点不可达，未知发现条件: %s" % addr)
		var credential_gate := String(node.get("defense", {}).get("credentialGateId", ""))
		if String(node.get("defense", {}).get("mode", "public")) == "credential" and not gate_ids.has(credential_gate):
			issues.append("凭证节点引用不存在的知识门: %s" % addr)
	var investigation_lines: Array = case_data.get("investigationLines", [])
	var twists: Array = case_data.get("twists", [])
	if int(case_data.get("order", 0)) == 0:
		if investigation_lines.is_empty():
			issues.append("序章至少需要一条调查线")
		if twists.is_empty():
			issues.append("序章至少需要一层认知反转")
	else:
		if investigation_lines.size() < 3 or investigation_lines.size() > 5:
			issues.append("正式关卡调查线必须为 3 至 5 条")
		if twists.size() < 2:
			issues.append("正式关卡至少需要两次反转")
	var report: Array = case_data.get("caseReport", [])
	if report.size() < 3 or report.size() > 5:
		issues.append("结案题数量必须为 3 至 5")
	for question_value in report:
		var question: Dictionary = question_value
		if question.get("options", []).size() != 4:
			issues.append("结案题 %s 必须有四个选项" % question.get("id", question.get("q", "?")))
		for evidence_id in question.get("evidence", []):
			if not evidence_ids.has(String(evidence_id)):
				issues.append("结案题引用不存在的证据: %s" % evidence_id)
	var jumpscares := 0
	var horror_ids := {}
	for event_value in case_data.get("horrorEvents", []):
		var event: Dictionary = event_value
		var event_id := String(event.get("id", ""))
		if event_id.is_empty() or horror_ids.has(event_id):
			issues.append("恐怖事件 ID 缺失或重复: %s" % event_id)
		horror_ids[event_id] = true
		if String(event.get("level", "")).begins_with("C"):
			jumpscares += 1
	if jumpscares > 1:
		issues.append("每关 jumpscare 不得超过 1 次")
	_validate_tutorial(case_data, issues)
	if strict_content:
		_scan_placeholders(case_data, "case", issues)
	return issues

func _validate_tutorial(case_data: Dictionary, issues: Array[String]) -> void:
	var message_ids := {}
	var tutorial_texts: Array[Dictionary] = []
	for message_value in case_data.get("tutorialMessages", []):
		var message: Dictionary = message_value
		var message_id := String(message.get("id", ""))
		if message_id.is_empty() or message_ids.has(message_id):
			issues.append("教学消息 ID 缺失或重复: %s" % message_id)
		message_ids[message_id] = true
		if String(message.get("sender", "")).strip_edges().is_empty() or String(message.get("text", "")).strip_edges().is_empty():
			issues.append("教学消息必须包含完整发送者与正文: %s" % message_id)
		tutorial_texts.append({"id": message_id, "text": String(message.get("text", ""))})
	var flow: Dictionary = case_data.get("tutorialFlow", {})
	if flow.is_empty():
		return
	var step_ids := {}
	for step_value in flow.get("steps", []):
		var step: Dictionary = step_value
		var step_id := String(step.get("id", ""))
		if step_id.is_empty() or step_ids.has(step_id):
			issues.append("教学步骤 ID 缺失或重复: %s" % step_id)
		step_ids[step_id] = true
		if String(step.get("helpText", "")).strip_edges().is_empty():
			issues.append("教学步骤缺少完整 helpText: %s" % step_id)
		else:
			tutorial_texts.append({"id": "%s.helpText" % step_id, "text": String(step.get("helpText", ""))})
		_validate_tutorial_condition(step.get("completeWhen", {}), "步骤 %s" % step_id, issues)
		_validate_tutorial_deliveries(step.get("delivery", []), message_ids, "步骤 %s" % step_id, issues)
		_validate_tutorial_feedback(step.get("feedback", {}), "步骤 %s" % step_id, issues)
		var fallback: Dictionary = step.get("fallback", {})
		if not fallback.is_empty():
			if float(fallback.get("afterSec", 0.0)) <= 0.0:
				issues.append("教学步骤 fallback 时间必须为正数: %s" % step_id)
			_validate_tutorial_deliveries([fallback], message_ids, "步骤 %s fallback" % step_id, issues)
	var milestone_ids := {}
	for milestone_value in flow.get("milestones", []):
		var milestone: Dictionary = milestone_value
		var milestone_id := String(milestone.get("id", ""))
		if milestone_id.is_empty() or milestone_ids.has(milestone_id):
			issues.append("教学里程碑 ID 缺失或重复: %s" % milestone_id)
		milestone_ids[milestone_id] = true
		_validate_tutorial_condition(milestone.get("when", {}), "里程碑 %s" % milestone_id, issues)
		_validate_tutorial_feedback(milestone.get("feedback", {}), "里程碑 %s" % milestone_id, issues)
	var forbidden_answers := _tutorial_forbidden_answers(case_data)
	for text_entry in tutorial_texts:
		var normalized_text := _normalize_tutorial_text(String(text_entry.get("text", "")))
		for answer in forbidden_answers:
			if not answer.is_empty() and normalized_text.contains(answer):
				issues.append("教学文本泄露知识门答案: %s" % text_entry.get("id", "?"))
				break

func _validate_tutorial_condition(condition, label: String, issues: Array[String]) -> void:
	if not condition is Dictionary or condition.is_empty():
		issues.append("%s 缺少教学触发条件" % label)
		return
	if condition.has("allOf") or condition.has("anyOf"):
		var key := "allOf" if condition.has("allOf") else "anyOf"
		var children: Array = condition.get(key, [])
		if children.is_empty():
			issues.append("%s 的 %s 不得为空" % [label, key])
		for child in children:
			_validate_tutorial_condition(child, label, issues)
		return
	var trigger_type := String(condition.get("type", ""))
	if not TUTORIAL_TRIGGERS.has(trigger_type):
		issues.append("%s 使用未知教学触发器: %s" % [label, trigger_type])

func _validate_tutorial_deliveries(raw_deliveries, message_ids: Dictionary, label: String, issues: Array[String]) -> void:
	if not raw_deliveries is Array:
		issues.append("%s 的教学投递必须为数组" % label)
		return
	for delivery_value in raw_deliveries:
		var delivery: Dictionary = delivery_value
		var content_id := String(delivery.get("contentId", ""))
		if content_id.is_empty() or not message_ids.has(content_id):
			issues.append("教学内容引用不存在: %s (%s)" % [content_id, label])
		var channel := String(delivery.get("channel", ""))
		if not TUTORIAL_CHANNELS.has(channel):
			issues.append("教学投递渠道无效: %s (%s)" % [channel, label])

func _validate_tutorial_feedback(raw_feedback, label: String, issues: Array[String]) -> void:
	if not raw_feedback is Dictionary or raw_feedback.is_empty():
		return
	var app_id := String(raw_feedback.get("appId", ""))
	if not TUTORIAL_APPS.has(app_id):
		issues.append("教学反馈 App 无效: %s (%s)" % [app_id, label])
	if String(raw_feedback.get("pulse", "soft")) != "soft":
		issues.append("教学反馈脉冲样式无效: %s" % label)
	if String(raw_feedback.get("sound", "")) not in ["", "progress_soft"]:
		issues.append("教学反馈声音无效: %s" % label)

func _tutorial_forbidden_answers(case_data: Dictionary) -> Array[String]:
	var answers: Array[String] = []
	for gate_value in case_data.get("knowledgeGates", []):
		var gate: Dictionary = gate_value
		for accepted_value in gate.get("accept", []):
			if accepted_value is String:
				var accepted := _normalize_tutorial_text(accepted_value)
				if not accepted.is_empty():
					answers.append(accepted)
			elif accepted_value is Dictionary:
				for key in ["user", "pass"]:
					var credential := _normalize_tutorial_text(String(accepted_value.get(key, "")))
					if credential.length() >= 4:
						answers.append(credential)
		for alias_value in gate.get("aliases", []):
			var alias := _normalize_tutorial_text(String(alias_value))
			if not alias.is_empty():
				answers.append(alias)
	return answers

func _normalize_tutorial_text(value: String) -> String:
	var normalized := value.to_lower()
	for marker in [" ", "\t", "\r", "\n", "-", "_", "'", "\"", "“", "”", "『", "』", "，", "。", ",", ".", "：", ":", "/", "\\"]:
		normalized = normalized.replace(marker, "")
	return normalized

func _scan_placeholders(value: Variant, path: String, issues: Array[String]) -> void:
	if value is String:
		var lowered := String(value).to_lower()
		for marker in FORBIDDEN_PLACEHOLDERS:
			if lowered.contains(marker):
				issues.append("剧情占位文本: %s (%s)" % [marker, path])
	elif value is Dictionary:
		for key in value.keys():
			if String(key) in ["prompt", "assetId"]:
				continue
			_scan_placeholders(value[key], "%s.%s" % [path, key], issues)
	elif value is Array:
		for index in value.size():
			_scan_placeholders(value[index], "%s[%d]" % [path, index], issues)
