extends RefCounted

const MainScript = preload("res://scripts/os/main.gd")
const RuntimeScript = preload("res://scripts/engine/case_runtime.gd")
const TutorialRuntimeScript = preload("res://scripts/engine/tutorial_runtime.gd")

func run(t) -> void:
	var main_source := FileAccess.get_file_as_string("res://scripts/os/main.gd")
	t.truthy(not main_source.contains('status_label.text = String(current_case_data.get("hook", {}).get("playerGoal"'), "desktop status bar does not become a persistent objective panel")
	var case_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/minimal_case.json"))
	var runtime = RuntimeScript.new()
	runtime.setup(case_data)
	var main = MainScript.new()
	main.runtime = runtime
	main.current_case_data = case_data
	main.campaign_progress = {"older_case": {"grade": "A"}}
	var tutorial_case: Dictionary = case_data.duplicate(true)
	tutorial_case["tutorialMessages"] = [{"id": "save_msg", "sender": "SYSTEM", "text": "保存教学状态。"}]
	tutorial_case["tutorialFlow"] = {"enabled": true, "steps": [{"id": "save_step", "completeWhen": {"type": "mail_opened", "target": "mail_save"}, "delivery": [{"channel": "messenger", "contentId": "save_msg"}], "feedback": {"appId": "mail", "pulse": "soft", "sound": "progress_soft"}, "helpText": "先读取原始邮件。"}]}
	var tutorial = TutorialRuntimeScript.new()
	tutorial.configure(tutorial_case)
	var property_names: Array[String] = []
	for property in main.get_property_list():
		property_names.append(String(property.get("name", "")))
	t.truthy(property_names.has("tutorial_runtime"), "main owns a tutorial runtime")
	if property_names.has("tutorial_runtime"):
		main.set("tutorial_runtime", tutorial)
	t.truthy(main.has_method("_build_save_payload"), "main exposes a campaign-aware save payload builder")
	t.truthy(main.has_method("_record_case_completion"), "main can record a completed case before advancing")
	if main.has_method("_record_case_completion"):
		main._record_case_completion("S")
		t.equal(main.campaign_progress.get("test_case", {}).get("grade"), "S", "completed-case grade is retained")
	if main.has_method("_build_save_payload"):
		var payload: Dictionary = main._build_save_payload()
		t.equal(payload.get("schemaVersion"), 2, "campaign saves use tutorial-aware schema version two")
		t.truthy(payload.has("tutorialState"), "campaign saves include tutorial runtime state")
		t.equal(payload.get("tutorialState", {}).get("caseId"), "test_case", "tutorial state remains associated with the active case")
		t.equal(payload.get("completedCases", {}).get("older_case", {}).get("grade"), "A", "prior case progress remains in the next autosave")
		t.equal(payload.get("completedCases", {}).get("test_case", {}).get("grade"), "S", "current completed case is written to autosave")
	main.free()
	runtime.free()
