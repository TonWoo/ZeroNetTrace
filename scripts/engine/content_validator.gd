class_name ContentValidator
extends RefCounted

const REQUIRED_FIELDS := ["caseId", "title", "coreQuestion", "unlockRequirements", "investigationLines", "twists", "network", "knowledgeGates", "horrorEvents", "caseReport", "contentManifest", "artAssets", "complianceCheck"]
const FORBIDDEN_PLACEHOLDERS := ["内容略", "示例×", "示例x", "todo", "待补", "此处是描述", "待完善"]

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
	if strict_content:
		_scan_placeholders(case_data, "case", issues)
	return issues

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
