extends RefCounted

func run(t) -> void:
	var script = load("res://scripts/engine/save_service.gd")
	t.truthy(script != null, "save service script must exist")
	if script == null:
		return
	var service = script.new()
	var payload := {"schemaVersion": 1, "currentCase": "case_01", "notes": "测试笔记", "evidence": ["ev_a"]}
	var path := "user://save_test.json"
	t.truthy(service.write_to(path, payload), "save writes atomically")
	var loaded: Dictionary = service.read_from(path)
	t.equal(loaded.get("notes"), "测试笔记", "save round trip preserves Chinese text")
	t.equal(loaded.get("evidence"), ["ev_a"], "save round trip preserves arrays")
	service.remove_at(path)
	service.free()
