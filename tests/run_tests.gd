extends SceneTree

const TestAssertScript = preload("res://tests/test_assert.gd")

var _assert = TestAssertScript.new()

func _initialize() -> void:
	var suites: Array[String] = [
		"res://tests/test_terminal_parser.gd",
		"res://tests/test_terminal_execution.gd",
		"res://tests/test_tutorial_runtime.gd",
		"res://tests/test_search_service.gd",
		"res://tests/test_case_runtime.gd",
		"res://tests/test_content_validator.gd",
		"res://tests/test_data_repository.gd",
		"res://tests/test_save_service.gd",
		"res://tests/test_audio_director.gd",
		"res://tests/test_project_services.gd",
		"res://tests/test_main_campaign_save.gd",
		"res://tests/test_ui_scenes.gd",
		"res://tests/test_site_identity.gd",
		"res://tests/test_viewer_data_driven.gd",
		"res://tests/test_mvp_content.gd",
		"res://tests/test_content_unlock.gd",
		"res://tests/test_horror_effects.gd",
		"res://tests/test_browser_resolution.gd",
		"res://tests/test_campaign_integration.gd",
	]
	for suite_path in suites:
		var suite_script = load(suite_path)
		if suite_script == null or not suite_script.can_instantiate():
			_assert.failures.append("Unable to load suite: %s" % suite_path)
			continue
		suite_script.new().run(_assert)
	if _assert.failures.is_empty():
		print("PASS: %d assertions" % _assert.assertions)
		quit(0)
	else:
		for failure in _assert.failures:
			printerr("FAIL: %s" % failure)
		printerr("FAILED: %d assertion(s), %d failure(s)" % [_assert.assertions, _assert.failures.size()])
		quit(1)
