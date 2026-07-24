extends RefCounted

func run(t) -> void:
	var script = load("res://scripts/engine/content_validator.gd")
	t.truthy(script != null, "content validator script must exist")
	if script == null:
		return
	var validator = script.new()
	var case_data = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/minimal_case.json"))
	var issues: Array = validator.validate_case(case_data, false)
	t.equal(issues, [], "minimal fixture passes structural validation")
	case_data["horrorEvents"].append({"id": "h_jump_1", "level": "C", "trigger": {"type": "flag", "target": "a"}})
	case_data["horrorEvents"].append({"id": "h_jump_2", "level": "C", "trigger": {"type": "flag", "target": "b"}})
	issues = validator.validate_case(case_data, false)
	t.truthy(issues.any(func(issue): return String(issue).contains("jumpscare")), "more than one jumpscare is rejected")
	var unreachable_case: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/minimal_case.json"))
	unreachable_case["network"][1]["discoverWhen"] = {"type": "gate", "id": "missing_gate"}
	issues = validator.validate_case(unreachable_case, false)
	t.truthy(issues.any(func(issue): return String(issue).contains("不可达")), "node with a missing discovery gate is rejected")
	var tutorial_case: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/minimal_case.json"))
	tutorial_case["tutorialMessages"] = [{"id": "msg_a", "sender": "SYSTEM", "text": "完整内容。"}]
	tutorial_case["tutorialFlow"] = {"enabled": true, "steps": [
		{"id": "step_a", "completeWhen": {"type": "mail_opened", "target": "mail_a"}, "delivery": [{"channel": "messenger", "contentId": "missing_msg"}], "feedback": {"appId": "mail", "pulse": "soft", "sound": "progress_soft"}, "helpText": "先读原始邮件。"}
	]}
	issues = validator.validate_case(tutorial_case, false)
	t.truthy(issues.any(func(issue): return String(issue).contains("教学内容引用不存在")), "tutorial deliveries require valid content IDs")
	tutorial_case["tutorialFlow"]["steps"][0]["delivery"][0]["contentId"] = "msg_a"
	tutorial_case["tutorialMessages"][0]["text"] = "直接输入 长明"
	issues = validator.validate_case(tutorial_case, false)
	t.truthy(issues.any(func(issue): return String(issue).contains("教学文本泄露知识门答案")), "tutorial messages cannot contain accepted puzzle answers")
