extends RefCounted

func run(t) -> void:
	var script = load("res://scripts/engine/data_repository.gd")
	t.truthy(script != null, "data repository script must exist")
	if script == null:
		return
	var repository = script.new()
	var loaded: Dictionary = repository.load_json("res://tests/fixtures/minimal_case.json")
	t.equal(loaded.get("caseId"), "test_case", "repository loads strict JSON")
	t.equal(repository.last_error, "", "valid JSON leaves no error")
	var missing: Dictionary = repository.load_json("res://tests/fixtures/missing.json")
	t.equal(missing, {}, "missing JSON returns empty dictionary")
	t.truthy(not repository.last_error.is_empty(), "missing JSON records an error")
	repository.free()
