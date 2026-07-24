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
