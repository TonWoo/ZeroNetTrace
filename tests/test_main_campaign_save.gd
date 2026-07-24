extends RefCounted

const MainScript = preload("res://scripts/os/main.gd")
const RuntimeScript = preload("res://scripts/engine/case_runtime.gd")

func run(t) -> void:
	var case_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/minimal_case.json"))
	var runtime = RuntimeScript.new()
	runtime.setup(case_data)
	var main = MainScript.new()
	main.runtime = runtime
	main.current_case_data = case_data
	main.campaign_progress = {"older_case": {"grade": "A"}}
	t.truthy(main.has_method("_build_save_payload"), "main exposes a campaign-aware save payload builder")
	t.truthy(main.has_method("_record_case_completion"), "main can record a completed case before advancing")
	if main.has_method("_record_case_completion"):
		main._record_case_completion("S")
		t.equal(main.campaign_progress.get("test_case", {}).get("grade"), "S", "completed-case grade is retained")
	if main.has_method("_build_save_payload"):
		var payload: Dictionary = main._build_save_payload()
		t.equal(payload.get("completedCases", {}).get("older_case", {}).get("grade"), "A", "prior case progress remains in the next autosave")
		t.equal(payload.get("completedCases", {}).get("test_case", {}).get("grade"), "S", "current completed case is written to autosave")
	main.free()
	runtime.free()
